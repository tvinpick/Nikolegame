package com.nikole.kidslauncher

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextClock
import android.widget.TextView

/**
 * Главный экран (HOME): часы и заряд сверху, сетка 2×2 крупных кнопок.
 * Удержание часов 5 секунд — вход в родительский режим.
 */
class MainActivity : Activity() {

    private lateinit var prefs: Prefs
    private lateinit var topBar: LinearLayout
    private lateinit var battery: TextView
    private val cells = ArrayList<Cell>(Prefs.SLOT_COUNT)
    private val handler = Handler(Looper.getMainLooper())
    private var batteryRegistered = false

    private class Cell(val root: LinearLayout, val icon: ImageView, val label: TextView) {
        var component: ComponentName? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = Prefs(this)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF000000.toInt())
            setPadding(dp(3), dp(2), dp(3), dp(3))
        }

        // --- Верхняя панель: время + батарея ---
        topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(6), 0, dp(6), 0)
        }
        val clock = TextClock(this).apply {
            format24Hour = "HH:mm"
            format12Hour = "HH:mm"
            setTextColor(0xFFFFFFFF.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER_VERTICAL or Gravity.START
            setAutoSizeTextTypeUniformWithConfiguration(12, 40, 1, TypedValue.COMPLEX_UNIT_SP)
        }
        battery = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER_VERTICAL or Gravity.END
            maxLines = 1
            setAutoSizeTextTypeUniformWithConfiguration(10, 24, 1, TypedValue.COMPLEX_UNIT_SP)
        }
        topBar.addView(clock, lp(0, MATCH, 1.4f))
        topBar.addView(battery, lp(0, MATCH, 1f))
        setupSecretHold(topBar)
        root.addView(topBar, lp(MATCH, 0, 0.17f))

        // --- Сетка 2×2 ---
        val grid = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        for (r in 0 until 2) {
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (c in 0 until 2) {
                val cell = makeCell(CELL_COLORS[r * 2 + c])
                cells.add(cell)
                row.addView(cell.root, lp(0, MATCH, 1f).apply {
                    setMargins(dp(3), dp(3), dp(3), dp(3))
                })
            }
            grid.addView(row, lp(MATCH, 0, 1f))
        }
        root.addView(grid, lp(MATCH, 0, 0.83f))

        setContentView(root)
    }

    private fun makeCell(color: Int): Cell {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(4), dp(4), dp(4), dp(2))
            background = roundedBg(color, dp(14).toFloat())
            isClickable = true
        }
        val icon = ImageView(this).apply { scaleType = ImageView.ScaleType.FIT_CENTER }
        val label = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            maxLines = 2
            setAutoSizeTextTypeUniformWithConfiguration(9, 22, 1, TypedValue.COMPLEX_UNIT_SP)
        }
        box.addView(icon, lp(MATCH, 0, 0.6f))
        box.addView(label, lp(MATCH, 0, 0.4f))
        val cell = Cell(box, icon, label)
        box.setOnClickListener { cell.component?.let { Apps.launch(this, it) } }
        return cell
    }

    /** Долгое удержание (5 с) верхней панели открывает ввод кода. */
    private fun setupSecretHold(view: View) {
        val openPin = Runnable {
            view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
            view.background = null
            startActivity(Intent(this, PinActivity::class.java))
        }
        view.setOnTouchListener { v, ev ->
            when (ev.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    v.background = roundedBg(0xFF222222.toInt(), dp(8).toFloat())
                    handler.postDelayed(openPin, HOLD_MS)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.background = null
                    handler.removeCallbacks(openPin)
                }
            }
            true
        }
    }

    override fun onResume() {
        super.onResume()
        refreshCells()
        val sticky = registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        batteryRegistered = true
        sticky?.let { updateBattery(it) }
    }

    override fun onPause() {
        super.onPause()
        handler.removeCallbacksAndMessages(null)
        topBar.background = null
        if (batteryRegistered) {
            unregisterReceiver(batteryReceiver)
            batteryRegistered = false
        }
    }

    private fun refreshCells() {
        val pm = packageManager
        val slots = prefs.slots
        for ((i, cell) in cells.withIndex()) {
            val cn = slots.getOrNull(i)
            val info = cn?.let {
                try {
                    pm.getActivityInfo(it, 0)
                } catch (e: PackageManager.NameNotFoundException) {
                    null // приложение удалено
                }
            }
            if (info != null) {
                cell.component = cn
                cell.icon.setImageDrawable(info.loadIcon(pm))
                cell.label.text = info.loadLabel(pm)
                cell.root.alpha = 1f
            } else {
                cell.component = null
                cell.icon.setImageDrawable(null)
                cell.label.text = ""
                cell.root.alpha = 0.25f
            }
        }
        if (slots.isEmpty()) {
            cells[0].label.text = "Держи часы 5 сек"
            cells[0].root.alpha = 1f
        }
    }

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = updateBattery(intent)
    }

    private fun updateBattery(intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        if (level < 0 || scale <= 0) {
            battery.text = ""
            return
        }
        val pct = level * 100 / scale
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        battery.text = (if (charging) "⚡" else "") + "$pct%"
        battery.setTextColor(
            when {
                charging -> 0xFF66BB6A.toInt()
                pct <= 15 -> 0xFFFF5252.toInt()
                else -> 0xFFFFFFFF.toInt()
            }
        )
    }

    /** На главном экране «Назад» ничего не делает. */
    override fun onBackPressed() {}

    companion object {
        private const val HOLD_MS = 5000L
        private val CELL_COLORS = intArrayOf(
            0xFF1E88E5.toInt(), 0xFF43A047.toInt(), 0xFFFB8C00.toInt(), 0xFF8E24AA.toInt()
        )
    }
}
