package com.nikole.kidslauncher

import android.app.Activity
import android.app.AlertDialog
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView

/**
 * Родительский режим: выбор до 4 приложений для главного экрана
 * (порядок выбора = порядок кнопок), смена кода, выход в стандартный лаунчер.
 */
class ParentActivity : Activity() {

    private lateinit var prefs: Prefs
    private lateinit var apps: List<AppEntry>
    private lateinit var counter: TextView
    private val selected = ArrayList<ComponentName>()
    private val adapter = Adapter()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = Prefs(this)

        val header = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(4), dp(2), dp(4), dp(4))
        }
        header.addView(bigButton("Готово") { finish() }, lp(MATCH, WRAP))
        header.addView(bigButton("Открыть стандартный лаунчер") { openOtherLauncher() }, lp(MATCH, WRAP))
        header.addView(bigButton("Лаунчер по умолчанию…") { openHomeSettings() }, lp(MATCH, WRAP))
        header.addView(bigButton("Сменить код") {
            startActivity(Intent(this, PinActivity::class.java)
                .putExtra(PinActivity.EXTRA_MODE, PinActivity.MODE_CHANGE))
        }, lp(MATCH, WRAP))
        header.addView(bigButton("Все приложения (список, экспорт)") {
            startActivity(Intent(this, AppListActivity::class.java))
        }, lp(MATCH, WRAP))
        counter = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(dp(4), dp(6), dp(4), 0)
        }
        header.addView(counter, lp(MATCH, WRAP))

        val list = ListView(this).apply {
            setBackgroundColor(0xFF000000.toInt())
            addHeaderView(header, null, false)
            adapter = this@ParentActivity.adapter
            setOnItemClickListener { _, _, pos, _ ->
                val index = pos - headerViewsCount
                if (index in apps.indices) toggle(apps[index].component)
            }
        }
        setContentView(list)
    }

    override fun onResume() {
        super.onResume()
        // Наше собственное приложение детям не показываем.
        apps = Apps.launchable(packageManager).filter { it.packageName != packageName }
        val installed = apps.map { it.component }.toSet()
        selected.clear()
        selected.addAll(prefs.slots.filter { it in installed })
        updateCounter()
        adapter.notifyDataSetChanged()
    }

    private fun toggle(cn: ComponentName) {
        if (!selected.remove(cn)) {
            if (selected.size >= Prefs.SLOT_COUNT) {
                toast("Можно выбрать только ${Prefs.SLOT_COUNT}")
                return
            }
            selected.add(cn)
        }
        prefs.slots = selected
        updateCounter()
        adapter.notifyDataSetChanged()
    }

    private fun updateCounter() {
        counter.text = "Приложения на главном экране: ${selected.size}/${Prefs.SLOT_COUNT}\n" +
            "(номер = место в сетке)"
    }

    private fun openOtherLauncher() {
        val homes = Apps.otherHomes(this)
        when (homes.size) {
            0 -> toast("Другие лаунчеры не найдены")
            1 -> Apps.launchHome(this, homes[0].component)
            else -> AlertDialog.Builder(this)
                .setTitle("Какой лаунчер открыть?")
                .setItems(homes.map { "${it.label}\n${it.packageName}" }.toTypedArray()) { _, which ->
                    Apps.launchHome(this, homes[which].component)
                }
                .setNegativeButton("Отмена", null)
                .show()
        }
    }

    /** Системный экран выбора лаунчера по умолчанию (если прошивка его поддерживает). */
    private fun openHomeSettings() {
        val candidates = listOf(
            Intent(Settings.ACTION_HOME_SETTINGS),
            Intent(Settings.ACTION_SETTINGS),
        )
        for (i in candidates) {
            try {
                startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (e: Exception) {
                // пробуем следующий вариант
            }
        }
        toast("Настройки недоступны")
    }

    private inner class Adapter : BaseAdapter() {
        override fun getCount() = if (::apps.isInitialized) apps.size else 0
        override fun getItem(position: Int) = apps[position]
        override fun getItemId(position: Int) = position.toLong()
        override fun getView(position: Int, convertView: View?, parent: ViewGroup?): View {
            val row = convertView as? AppRow ?: AppRow(this@ParentActivity)
            val a = apps[position]
            row.icon.setImageDrawable(a.icon(packageManager))
            row.title.text = a.label
            row.subtitle.text = a.packageName
            val slot = selected.indexOf(a.component)
            if (slot >= 0) {
                row.badge.visibility = View.VISIBLE
                row.badge.text = (slot + 1).toString()
                row.badge.background = roundedBg(0xFFFFD54F.toInt(), dp(15).toFloat())
                row.setBackgroundColor(0xFF263238.toInt())
            } else {
                row.badge.visibility = View.INVISIBLE
                row.setBackgroundColor(0x00000000)
            }
            return row
        }
    }
}
