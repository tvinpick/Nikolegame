package com.nikole.kidslauncher

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Ввод 4-значного кода на собственной цифровой клавиатуре (удобнее экранной на 240×296).
 * MODE_VERIFY — проверка кода и вход в родительский режим.
 * MODE_CHANGE — ввод нового кода и подтверждение.
 */
class PinActivity : Activity() {

    private lateinit var prefs: Prefs
    private lateinit var title: TextView
    private lateinit var dots: TextView
    private val entered = StringBuilder()
    private var mode = MODE_VERIFY
    private var firstNewPin: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = Prefs(this)
        mode = intent.getIntExtra(EXTRA_MODE, MODE_VERIFY)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF101010.toInt())
            setPadding(dp(4), dp(2), dp(4), dp(4))
        }
        title = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        }
        dots = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
        }
        root.addView(title, lp(MATCH, WRAP))
        root.addView(dots, lp(MATCH, WRAP))

        val keys = arrayOf(
            arrayOf("1", "2", "3"),
            arrayOf("4", "5", "6"),
            arrayOf("7", "8", "9"),
            arrayOf("✕", "0", "⌫"),
        )
        for (rowKeys in keys) {
            val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            for (k in rowKeys) {
                val b = Button(this).apply {
                    text = k
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                    setPadding(0, 0, 0, 0)
                    minHeight = 0
                    minimumHeight = 0
                    setOnClickListener { onKey(k) }
                }
                row.addView(b, lp(0, MATCH, 1f))
            }
            root.addView(row, lp(MATCH, 0, 1f))
        }
        setContentView(root)
        updateUi()
    }

    private fun onKey(k: String) {
        when (k) {
            "✕" -> { finish(); return }
            "⌫" -> if (entered.isNotEmpty()) entered.setLength(entered.length - 1)
            else -> if (entered.length < PIN_LEN) entered.append(k)
        }
        updateUi()
        if (entered.length == PIN_LEN) onComplete(entered.toString())
    }

    private fun onComplete(pin: String) {
        entered.setLength(0)
        when (mode) {
            MODE_VERIFY -> {
                if (pin == prefs.pin) {
                    startActivity(Intent(this, ParentActivity::class.java))
                    finish()
                    return
                }
                toast("Неверный код")
            }
            MODE_CHANGE -> {
                val first = firstNewPin
                if (first == null) {
                    firstNewPin = pin
                } else if (first == pin) {
                    prefs.pin = pin
                    toast("Код изменён")
                    finish()
                    return
                } else {
                    firstNewPin = null
                    toast("Коды не совпали")
                }
            }
        }
        updateUi()
    }

    private fun updateUi() {
        title.text = when {
            mode == MODE_VERIFY -> "Код родителя"
            firstNewPin == null -> "Новый код"
            else -> "Повторите код"
        }
        dots.text = (0 until PIN_LEN).joinToString(" ") { if (it < entered.length) "●" else "○" }
    }

    companion object {
        const val EXTRA_MODE = "mode"
        const val MODE_VERIFY = 0
        const val MODE_CHANGE = 1
        private const val PIN_LEN = 4
    }
}
