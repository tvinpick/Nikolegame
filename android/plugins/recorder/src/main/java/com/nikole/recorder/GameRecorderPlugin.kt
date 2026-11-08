package com.nikole.recorder

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.StatFs
import android.util.Log
import androidx.core.content.FileProvider
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.io.File

/**
 * Developer-mode screen recorder for "Мой сказочный домик".
 *  - Video: MediaProjection -> VirtualDisplay -> MediaRecorder (H.264 MP4).
 *    Android shows its consent dialog before EVERY session.
 *  - Audio: never the microphone. The game records its own mix (Godot
 *    AudioEffectRecord -> WAV); [muxWavIntoMp4] encodes it to AAC and muxes it.
 *  - Sharing only on explicit adult action via Android Sharesheet + FileProvider.
 */
class GameRecorderPlugin(godot: Godot) : GodotPlugin(godot), RecorderService.Listener {

    companion object {
        private const val TAG = "GameRecorder"
        private const val REQ_CAPTURE = 47021
    }

    private var pendingPath = ""
    private var pendingBitrate = 5_000_000
    private var pendingMaxSec = 300
    private var pendingFps = 30

    override fun getPluginName() = "GameRecorder"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("recording_started"),
        SignalInfo("recording_stopped", String::class.java, String::class.java),
        SignalInfo("recording_error", String::class.java),
        SignalInfo("mux_finished", Boolean::class.javaObjectType, String::class.java, String::class.java),
        SignalInfo("share_result", Boolean::class.javaObjectType, String::class.java),
    )

    private fun emitOnGodot(name: String, vararg args: Any) {
        runOnRenderThread { emitSignal(name, *args) }
    }

    @UsedByGodot
    fun getFreeSpaceMb(): Int {
        val ctx: Context = activity ?: return -1
        return try {
            (StatFs(ctx.filesDir.path).availableBytes / (1024L * 1024L)).toInt()
        } catch (e: Exception) {
            -1
        }
    }

    @UsedByGodot
    fun isRecording(): Boolean = RecorderService.instance?.isRecording == true

    @UsedByGodot
    fun startRecording(path: String, bitrate: Int, maxSeconds: Int, fps: Int) {
        val act: Activity = activity ?: run { emitOnGodot("recording_error", "no_activity"); return }
        if (isRecording()) { emitOnGodot("recording_error", "already_recording"); return }
        pendingPath = path
        pendingBitrate = bitrate
        pendingMaxSec = maxSeconds
        pendingFps = fps
        val mpm = act.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        act.runOnUiThread {
            try {
                act.startActivityForResult(mpm.createScreenCaptureIntent(), REQ_CAPTURE)
            } catch (e: Exception) {
                Log.e(TAG, "consent intent failed", e)
                emitOnGodot("recording_error", "consent_failed:" + e.message)
            }
        }
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onMainActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_CAPTURE) return
        val act = activity ?: return
        if (resultCode != Activity.RESULT_OK || data == null) {
            emitOnGodot("recording_error", "permission_denied")
            return
        }
        RecorderService.listener = this
        val svc = Intent(act, RecorderService::class.java).apply {
            putExtra(RecorderService.EXTRA_RESULT_CODE, resultCode)
            putExtra(RecorderService.EXTRA_DATA, data)
            putExtra(RecorderService.EXTRA_PATH, pendingPath)
            putExtra(RecorderService.EXTRA_BITRATE, pendingBitrate)
            putExtra(RecorderService.EXTRA_MAX_SEC, pendingMaxSec)
            putExtra(RecorderService.EXTRA_FPS, pendingFps)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) act.startForegroundService(svc) else act.startService(svc)
        } catch (e: Exception) {
            emitOnGodot("recording_error", "service_failed:" + e.message)
        }
    }

    @UsedByGodot
    fun stopRecording() {
        RecorderService.instance?.stopRecording("user")
    }

    override fun onMainPause() {
        super.onMainPause()
        // App went to background / screen locked: finish the file cleanly.
        RecorderService.instance?.stopRecording("app_paused")
    }

    override fun onMainDestroy() {
        RecorderService.instance?.stopRecording("app_destroyed")
        super.onMainDestroy()
    }

    // RecorderService.Listener
    override fun onRecordingStarted() = emitOnGodot("recording_started")
    override fun onRecordingStopped(path: String, reason: String) = emitOnGodot("recording_stopped", path, reason)
    override fun onRecordingError(message: String) = emitOnGodot("recording_error", message)

    @UsedByGodot
    fun muxWavIntoMp4(videoPath: String, wavPath: String, outPath: String) {
        Thread {
            try {
                WavMuxer.mux(videoPath, wavPath, outPath)
                emitOnGodot("mux_finished", true, outPath, "")
            } catch (e: Throwable) {
                Log.e(TAG, "mux failed", e)
                File(outPath).delete()
                emitOnGodot("mux_finished", false, videoPath, e.javaClass.simpleName + ":" + (e.message ?: ""))
            }
        }.start()
    }

    @UsedByGodot
    fun shareFile(path: String, mime: String) {
        val act = activity ?: run { emitOnGodot("share_result", false, "no_activity"); return }
        act.runOnUiThread {
            try {
                val file = File(path)
                if (!file.exists()) {
                    emitOnGodot("share_result", false, "missing")
                    return@runOnUiThread
                }
                val uri = FileProvider.getUriForFile(act, act.packageName + ".gamerecorder.fileprovider", file)
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = mime
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                act.startActivity(Intent.createChooser(send, null))
                emitOnGodot("share_result", true, "")
            } catch (e: Exception) {
                Log.e(TAG, "share failed", e)
                emitOnGodot("share_result", false, e.message ?: "error")
            }
        }
    }
}
