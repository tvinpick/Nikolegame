package com.nikole.kidslauncher

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Этап 1 — разведка: список всех запускаемых приложений (иконка, название, пакет).
 * Тап по строке запускает приложение, «Экспорт» сохраняет список в Download.
 */
class AppListActivity : Activity() {

    private lateinit var apps: List<AppEntry>
    private lateinit var header: TextView
    private val adapter = Adapter()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF000000.toInt())
        }
        val top = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(6), dp(2), dp(2), dp(2))
        }
        header = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        }
        top.addView(header, lp(0, WRAP, 1f))
        top.addView(bigButton("Экспорт") { exportWithPermission() }, lp(WRAP, WRAP))
        root.addView(top, lp(MATCH, WRAP))

        val list = ListView(this).apply {
            adapter = this@AppListActivity.adapter
            setOnItemClickListener { _, _, pos, _ ->
                Apps.launch(this@AppListActivity, apps[pos].component)
            }
        }
        root.addView(list, lp(MATCH, 0, 1f))
        setContentView(root)
    }

    override fun onResume() {
        super.onResume()
        apps = Apps.launchable(packageManager)
        header.text = "Приложений: ${apps.size}"
        adapter.notifyDataSetChanged()
    }

    private fun exportWithPermission() {
        // На API 26–28 запись в общую папку Download требует WRITE_EXTERNAL_STORAGE.
        if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            export()
        } else {
            requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), REQ_WRITE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        if (requestCode != REQ_WRITE) return
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            export()
        } else {
            toast("Нет разрешения на запись")
        }
    }

    private fun export() {
        val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val text = buildString {
            append("Запускаемые приложения: ${apps.size}\n")
            append("Устройство: ${Build.MANUFACTURER} ${Build.MODEL} (${Build.DEVICE}), ")
            append("Android ${Build.VERSION.RELEASE}, API ${Build.VERSION.SDK_INT}\n")
            append("Дата: $stamp\n\n")
            append("# Название\tПакет\tАктивность\n")
            for (a in apps) {
                append(a.label).append('\t')
                    .append(a.packageName).append('\t')
                    .append(a.component.className).append('\n')
            }
            append("\n# HOME-активности (лаунчеры)\n")
            val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN)
                .addCategory(android.content.Intent.CATEGORY_HOME)
            for (r in packageManager.queryIntentActivities(homeIntent, 0)) {
                append(r.loadLabel(packageManager)).append('\t')
                    .append(r.activityInfo.packageName).append('\t')
                    .append(r.activityInfo.name).append('\n')
            }
        }
        try {
            @Suppress("DEPRECATION")
            val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, "apps_$stamp.txt")
            file.writeText(text, Charsets.UTF_8)
            // Чтобы файл сразу был виден при подключении по USB (MTP).
            MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf("text/plain"), null)
            toast("Сохранено: Download/${file.name}")
        } catch (e: Exception) {
            toast("Ошибка записи: ${e.message}")
        }
    }

    private inner class Adapter : BaseAdapter() {
        override fun getCount() = if (::apps.isInitialized) apps.size else 0
        override fun getItem(position: Int) = apps[position]
        override fun getItemId(position: Int) = position.toLong()
        override fun getView(position: Int, convertView: View?, parent: ViewGroup?): View {
            val row = convertView as? AppRow ?: AppRow(this@AppListActivity)
            val a = apps[position]
            row.icon.setImageDrawable(a.icon(packageManager))
            row.title.text = a.label
            row.subtitle.text = a.packageName
            return row
        }
    }

    companion object {
        private const val REQ_WRITE = 1
    }
}
