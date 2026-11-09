package com.nikole.kidslauncher

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/** Запускаемое приложение (одна LAUNCHER-активность). */
class AppEntry(val info: ResolveInfo, val label: String) {
    val component: ComponentName =
        ComponentName(info.activityInfo.packageName, info.activityInfo.name)
    val packageName: String get() = component.packageName
    private var iconCache: Drawable? = null
    fun icon(pm: PackageManager): Drawable =
        iconCache ?: info.loadIcon(pm).also { iconCache = it }
}

object Apps {
    /** Все активности с ACTION_MAIN + CATEGORY_LAUNCHER, отсортированные по названию. */
    fun launchable(pm: PackageManager): List<AppEntry> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .map { AppEntry(it, it.loadLabel(pm).toString()) }
            .sortedWith(Comparator { a, b ->
                val c = a.label.compareTo(b.label, ignoreCase = true)
                if (c != 0) c else a.packageName.compareTo(b.packageName)
            })
    }

    /** Все HOME-активности (лаунчеры), кроме нашей. */
    fun otherHomes(ctx: Context): List<AppEntry> {
        val pm = ctx.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return pm.queryIntentActivities(intent, 0)
            .filter { it.activityInfo.packageName != ctx.packageName }
            .map { AppEntry(it, it.loadLabel(pm).toString()) }
    }

    fun launch(ctx: Context, component: ComponentName): Boolean {
        val intent = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .setComponent(component)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        return try {
            ctx.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            ctx.toast("Не удалось запустить")
            false
        } catch (e: SecurityException) {
            ctx.toast("Нет доступа к приложению")
            false
        }
    }

    fun launchHome(ctx: Context, component: ComponentName) {
        val intent = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_HOME)
            .setComponent(component)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            ctx.startActivity(intent)
        } catch (e: Exception) {
            ctx.toast("Не удалось открыть лаунчер")
        }
    }
}

/** Настройки: код родителя и до 4 выбранных приложений (в порядке выбора). */
class Prefs(ctx: Context) {
    private val sp = ctx.getSharedPreferences("launcher", Context.MODE_PRIVATE)

    var pin: String
        get() = sp.getString(KEY_PIN, DEFAULT_PIN) ?: DEFAULT_PIN
        set(value) = sp.edit().putString(KEY_PIN, value).apply()

    var slots: List<ComponentName>
        get() = (0 until SLOT_COUNT).mapNotNull { i ->
            sp.getString("slot_$i", null)?.let { ComponentName.unflattenFromString(it) }
        }
        set(value) {
            val e = sp.edit()
            for (i in 0 until SLOT_COUNT) {
                val cn = value.getOrNull(i)
                if (cn == null) e.remove("slot_$i") else e.putString("slot_$i", cn.flattenToString())
            }
            e.apply()
        }

    companion object {
        const val SLOT_COUNT = 4
        const val DEFAULT_PIN = "1234"
        private const val KEY_PIN = "pin"
    }
}

// ---------- Мелкие помощники для UI без XML-разметки ----------

fun Context.dp(v: Float): Int =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics).toInt()

fun Context.dp(v: Int): Int = dp(v.toFloat())

fun Context.toast(msg: String) = Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()

fun roundedBg(color: Int, radiusPx: Float): GradientDrawable =
    GradientDrawable().apply {
        setColor(color)
        cornerRadius = radiusPx
    }

fun lp(w: Int, h: Int, weight: Float = 0f): LinearLayout.LayoutParams =
    LinearLayout.LayoutParams(w, h, weight)

const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT
const val WRAP = ViewGroup.LayoutParams.WRAP_CONTENT

fun Context.bigButton(text: String, onClick: () -> Unit): Button =
    Button(this).apply {
        this.text = text
        setAllCaps(false)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        setOnClickListener { onClick() }
    }

/** Строка списка: иконка + название + (необязательно) вторая строка. */
class AppRow(ctx: Context) : LinearLayout(ctx) {
    val icon = ImageView(ctx)
    val title = TextView(ctx)
    val subtitle = TextView(ctx)
    val badge = TextView(ctx)

    init {
        orientation = HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        val p = ctx.dp(6)
        setPadding(p, p, p, p)
        addView(icon, lp(ctx.dp(40), ctx.dp(40)))
        val texts = LinearLayout(ctx).apply {
            orientation = VERTICAL
            setPadding(ctx.dp(8), 0, ctx.dp(4), 0)
        }
        title.setTextColor(0xFFFFFFFF.toInt())
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        subtitle.setTextColor(0xFFAAAAAA.toInt())
        subtitle.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
        texts.addView(title, lp(MATCH, WRAP))
        texts.addView(subtitle, lp(MATCH, WRAP))
        addView(texts, lp(0, WRAP, 1f))
        badge.setTextColor(0xFF000000.toInt())
        badge.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        badge.gravity = Gravity.CENTER
        badge.visibility = View.GONE
        addView(badge, lp(ctx.dp(30), ctx.dp(30)))
    }
}
