package com.nikole.recorder

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Encodes the game's own 16-bit PCM WAV mix to AAC and muxes it with the
 * silent MediaProjection video into one MP4. No microphone involved.
 */
object WavMuxer {

    private data class Wav(val sampleRate: Int, val channels: Int, val dataOffset: Long, val dataSize: Long)

    private fun readWav(path: String): Wav {
        RandomAccessFile(path, "r").use { f ->
            val hdr = ByteArray(12)
            f.readFully(hdr)
            require(String(hdr, 0, 4) == "RIFF" && String(hdr, 8, 4) == "WAVE") { "not a wav" }
            var sr = 44100
            var ch = 2
            var bits = 16
            while (f.filePointer < f.length()) {
                val chunk = ByteArray(8)
                f.readFully(chunk)
                val id = String(chunk, 0, 4)
                val size = ByteBuffer.wrap(chunk, 4, 4).order(ByteOrder.LITTLE_ENDIAN).int.toLong() and 0xffffffffL
                if (id == "fmt ") {
                    val fmt = ByteArray(size.toInt())
                    f.readFully(fmt)
                    val bb = ByteBuffer.wrap(fmt).order(ByteOrder.LITTLE_ENDIAN)
                    bb.short // format
                    ch = bb.short.toInt()
                    sr = bb.int
                    bb.int; bb.short
                    bits = bb.short.toInt()
                } else if (id == "data") {
                    require(bits == 16) { "only 16-bit pcm" }
                    val avail = f.length() - f.filePointer
                    return Wav(sr, ch, f.filePointer, minOf(size, avail))
                } else {
                    f.seek(f.filePointer + size + (size and 1))
                }
            }
        }
        throw IllegalArgumentException("no data chunk")
    }

    fun mux(videoPath: String, wavPath: String, outPath: String) {
        val wav = readWav(wavPath)
        val muxer = MediaMuxer(outPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val vEx = MediaExtractor()
        vEx.setDataSource(videoPath)
        var vIndex = -1
        for (i in 0 until vEx.trackCount) {
            if (vEx.getTrackFormat(i).getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true) { vIndex = i; break }
        }
        require(vIndex >= 0) { "no video track" }
        vEx.selectTrack(vIndex)
        val vTrack = muxer.addTrack(vEx.getTrackFormat(vIndex))

        val fmt = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, wav.sampleRate, wav.channels)
        fmt.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
        fmt.setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
        fmt.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
        val codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        codec.configure(fmt, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        codec.start()

        val raf = RandomAccessFile(wavPath, "r")
        raf.seek(wav.dataOffset)
        var remaining = wav.dataSize
        val bytesPerFrame = 2 * wav.channels
        var framesFed = 0L
        var inputDone = false
        var aTrack = -1
        var started = false
        val info = MediaCodec.BufferInfo()
        val chunk = ByteArray(8192)
        try {
            while (true) {
                if (!inputDone) {
                    val inIdx = codec.dequeueInputBuffer(10_000)
                    if (inIdx >= 0) {
                        val buf = codec.getInputBuffer(inIdx)!!
                        buf.clear()
                        val want = minOf(chunk.size.toLong(), remaining, buf.capacity().toLong()).toInt() / bytesPerFrame * bytesPerFrame
                        val pts = framesFed * 1_000_000L / wav.sampleRate
                        if (want <= 0) {
                            codec.queueInputBuffer(inIdx, 0, 0, pts, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            raf.readFully(chunk, 0, want)
                            buf.put(chunk, 0, want)
                            codec.queueInputBuffer(inIdx, 0, want, pts, 0)
                            remaining -= want
                            framesFed += want / bytesPerFrame
                        }
                    }
                }
                val outIdx = codec.dequeueOutputBuffer(info, 10_000)
                if (outIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    aTrack = muxer.addTrack(codec.outputFormat)
                    muxer.start()
                    started = true
                    copyVideo(vEx, muxer, vTrack)
                } else if (outIdx >= 0) {
                    val out = codec.getOutputBuffer(outIdx)!!
                    if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) info.size = 0
                    if (info.size > 0 && started) {
                        out.position(info.offset)
                        out.limit(info.offset + info.size)
                        muxer.writeSampleData(aTrack, out, info)
                    }
                    codec.releaseOutputBuffer(outIdx, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }
            }
        } finally {
            raf.close()
            try { codec.stop() } catch (_: Exception) {}
            codec.release()
            vEx.release()
            if (started) muxer.stop()
            muxer.release()
        }
        require(started) { "audio encoder produced no format" }
    }

    private fun copyVideo(ex: MediaExtractor, muxer: MediaMuxer, track: Int) {
        val buf = ByteBuffer.allocate(4 * 1024 * 1024)
        val info = MediaCodec.BufferInfo()
        while (true) {
            val size = ex.readSampleData(buf, 0)
            if (size < 0) break
            info.offset = 0
            info.size = size
            info.presentationTimeUs = ex.sampleTime
            info.flags = if (ex.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) MediaCodec.BUFFER_FLAG_KEY_FRAME else 0
            muxer.writeSampleData(track, buf, info)
            ex.advance()
        }
    }
}
