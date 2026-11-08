package com.nikole.recorder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager

/** Foreground service (type mediaProjection) that owns the capture session. */
class RecorderService : Service() {

    interface Listener {
        fun onRecordingStarted()
        fun onRecordingStopped(path: String, reason: String)
        fun onRecordingError(message: String)
    }

    companion object {
        const val EXTRA_RESULT_CODE = "rc"
        const val EXTRA_DATA = "data"
        const val EXTRA_PATH = "path"
        const val EXTRA_BITRATE = "bitrate"
        const val EXTRA_MAX_SEC = "max_sec"
        const val EXTRA_FPS = "fps"
        private const val CHANNEL = "game_recorder"
        private const val NOTIF_ID = 47022
        private const val TAG = "GameRecorderSvc"
        @Volatile var listener: Listener? = null
        @Volatile var instance: RecorderService? = null
    }

    private var projection: MediaProjection? = null
    private var display: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private var outPath = ""
    @Volatile var isRecording = false
    private var stopping = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        if (intent == null) { stopSelf(); return START_NOT_STICKY }
        startAsForeground()
        try {
            begin(intent)
        } catch (e: Throwable) {
            Log.e(TAG, "start failed", e)
            listener?.onRecordingError("start_failed:" + (e.message ?: e.javaClass.simpleName))
            cleanup()
            stopSelf()
        }
        return START_NOT_STICKY
    }

    private fun startAsForeground() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "Запись экрана (режим разработчика)", NotificationManager.IMPORTANCE_LOW))
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
        val n = builder
            .setContentTitle("Идёт запись экрана")
            .setContentText("Режим разработчика · только экран и звук игры")
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    @Suppress("DEPRECATION")
    private fun begin(intent: Intent) {
        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
        val data: Intent = (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(EXTRA_DATA, Intent::class.java) else intent.getParcelableExtra(EXTRA_DATA))
            ?: throw IllegalStateException("no projection data")
        outPath = intent.getStringExtra(EXTRA_PATH) ?: throw IllegalStateException("no path")
        val bitrate = intent.getIntExtra(EXTRA_BITRATE, 5_000_000)
        val maxSec = intent.getIntExtra(EXTRA_MAX_SEC, 300)
        val fps = intent.getIntExtra(EXTRA_FPS, 30)

        val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val proj = mpm.getMediaProjection(resultCode, data) ?: throw IllegalStateException("projection null")
        projection = proj
        // Required before createVirtualDisplay on Android 14+; also catches user revoking capture.
        proj.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() { stopRecording("projection_stopped") }
        }, Handler(Looper.getMainLooper()))

        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        wm.defaultDisplay.getRealMetrics(metrics)
        var w = metrics.widthPixels
        var h = metrics.heightPixels
        // keep files reasonable: longest side max 1920, even dimensions for the encoder
        val longest = maxOf(w, h)
        if (longest > 1920) {
            val k = 1920.0 / longest
            w = (w * k).toInt()
            h = (h * k).toInt()
        }
        w -= w % 2
        h -= h % 2

        val rec = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(this) else MediaRecorder()
        rec.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        rec.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        rec.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        rec.setVideoSize(w, h)
        rec.setVideoFrameRate(fps)
        rec.setVideoEncodingBitRate(bitrate)
        rec.setMaxDuration(maxSec * 1000)
        rec.setMaxFileSize(1800L * 1024L * 1024L)
        rec.setOutputFile(outPath)
        rec.setOnInfoListener { _, what, _ ->
            if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) stopRecording("max_duration")
            if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_FILESIZE_REACHED) stopRecording("max_filesize")
        }
        rec.setOnErrorListener { _, what, extra ->
            listener?.onRecordingError("recorder_error:$what/$extra")
            stopRecording("error")
        }
        rec.prepare()
        recorder = rec
        display = proj.createVirtualDisplay("GameRecorder", w, h, metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, rec.surface, null, null)
        rec.start()
        isRecording = true
        listener?.onRecordingStarted()
    }

    @Synchronized
    fun stopRecording(reason: String) {
        if (stopping) return
        stopping = true
        var ok = true
        if (isRecording) {
            try {
                recorder?.stop()
            } catch (e: RuntimeException) {
                // stop() throws if no frames were captured; the file is unusable then
                ok = false
                Log.w(TAG, "stop failed", e)
            }
        }
        val wasRecording = isRecording
        isRecording = false
        cleanup()
        if (wasRecording) {
            if (ok) listener?.onRecordingStopped(outPath, reason) else listener?.onRecordingError("empty_recording:$reason")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) stopForeground(STOP_FOREGROUND_REMOVE) else @Suppress("DEPRECATION") stopForeground(true)
        stopSelf()
    }

    private fun cleanup() {
        try { recorder?.reset(); recorder?.release() } catch (_: Exception) {}
        recorder = null
        try { display?.release() } catch (_: Exception) {}
        display = null
        try { projection?.stop() } catch (_: Exception) {}
        projection = null
    }

    override fun onDestroy() {
        if (isRecording) stopRecording("service_destroyed")
        instance = null
        super.onDestroy()
    }
}
