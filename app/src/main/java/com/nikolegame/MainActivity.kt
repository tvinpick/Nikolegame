package com.nikolegame

import android.content.Context
import android.os.Bundle
import android.view.View
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.input.pointer.consume
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.min
import kotlin.math.max

private const val WORLD = 2700f
private val Ivory = Color(0xFFFFFBF5)
private val Violet = Color(0xFF7C599B)
private val Pink = Color(0xFFFFC3D5)

class MainActivity : ComponentActivity() {
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
        setContent {
            MaterialTheme { NicoleGame() }
        }
    }
}

@Composable
private fun NicoleGame() {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("nicole_save", Context.MODE_PRIVATE) }
    var locale by remember { mutableStateOf(prefs.getString("locale", "ru") ?: "ru") }
    var pet by remember { mutableStateOf(prefs.getString("pet", "") ?: "") }
    var isNight by remember { mutableStateOf(false) }
    var weather by remember { mutableIntStateOf(0) }
    var leftDoor by remember { mutableStateOf(false) }
    var rightDoor by remember { mutableStateOf(false) }
    var girlX by remember { mutableFloatStateOf(1350f) }
    var girlY by remember { mutableFloatStateOf(810f) }
    var targetX by remember { mutableFloatStateOf(1350f) }
    var targetY by remember { mutableFloatStateOf(810f) }
    var viewWidth by remember { mutableFloatStateOf(1600f) }
    var camera by remember { mutableFloatStateOf(550f) }
    var manualCamera by remember { mutableStateOf(false) }
    var frames by remember { mutableIntStateOf(0) }
    var uiVisible by remember { mutableStateOf(true) }
    var lastTouch by remember { mutableIntStateOf(0) }
    var dialog by remember { mutableStateOf<String?>(null) }
    var message by remember { mutableStateOf<String?>(null) }

    fun tr(ru: String, de: String) = if (locale == "ru") ru else de
    fun interact() { uiVisible = true; lastTouch++ }
    fun toast(ru: String, de: String) { message = tr(ru, de) }

    LaunchedEffect(viewWidth) {
        camera = (girlX - viewWidth / 2f).coerceIn(0f, max(0f, WORLD - viewWidth))
    }
    LaunchedEffect(lastTouch, dialog) {
        if (dialog == null) {
            delay(10_000)
            uiVisible = false
        }
    }
    LaunchedEffect(message) {
        if (message != null) {
            delay(2300)
            message = null
        }
    }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameNanos { }
            frames++
            val dx = targetX - girlX
            val dy = targetY - girlY
            val distance = hypot(dx, dy)
            if (distance > 3f) {
                val step = min(5.6f, distance)
                val nx = girlX + dx / distance * step
                val ny = girlY + dy / distance * step
                // Simple collision volumes for the initial furniture.
                val bed = nx in 340f..850f && ny in 610f..746f
                val desk = nx in 1870f..2260f && ny in 615f..740f
                val closet = nx in 1500f..1820f && ny < 670f
                if (bed || desk || closet) {
                    targetX = girlX
                    targetY = girlY
                } else {
                    girlX = nx
                    girlY = ny
                }
                if (!manualCamera) {
                    camera = (girlX - viewWidth / 2f).coerceIn(0f, max(0f, WORLD - viewWidth))
                }
            }
        }
    }

    Box(Modifier.fillMaxSize().background(Ivory)) {
        Canvas(
            Modifier.fillMaxSize()
                .onSizeChanged {
                    val scale = it.height / 900f
                    if (scale > 0f) viewWidth = it.width / scale
                }
                .pointerInput(Unit) {
                    detectTapGestures { touch ->
                        interact()
                        val scale = size.height / 900f
                        val worldX = touch.x / scale + camera
                        val worldY = touch.y / scale
                        when {
                            worldY in 160f..610f && worldX in 115f..325f -> {
                                leftDoor = !leftDoor
                                toast("Дверь открыта!", "Tür geöffnet!")
                            }
                            worldY in 160f..610f && worldX in 2345f..2570f -> {
                                rightDoor = !rightDoor
                                toast("Дверь открыта!", "Tür geöffnet!")
                            }
                            worldX in 340f..860f && worldY in 360f..740f -> {
                                targetX = 870f; targetY = 775f; manualCamera = false
                                toast("Уютная кроватка!", "Ein gemütliches Bett!")
                            }
                            worldX in 1510f..1840f && worldY in 280f..635f -> {
                                targetX = 1815f; targetY = 760f; manualCamera = false
                                toast("Здесь мой шкаф!", "Das ist mein Schrank!")
                            }
                            worldX in 1870f..2280f && worldY in 355f..710f -> {
                                targetX = 2285f; targetY = 760f; manualCamera = false
                                toast("Будем рисовать!", "Lass uns malen!")
                            }
                            else -> {
                                targetX = worldX.coerceIn(65f, WORLD - 65f)
                                targetY = worldY.coerceIn(680f, 842f)
                                manualCamera = false
                            }
                        }
                    }
                }
                .pointerInput(Unit) {
                    detectDragGestures { change, dragAmount ->
                        change.consume()
                        interact()
                        manualCamera = true
                        val scale = size.height / 900f
                        camera = (camera - dragAmount.x / scale)
                            .coerceIn(0f, max(0f, WORLD - viewWidth))
                    }
                }
        ) {
            val s = size.height / 900f
            withTransform({
                scale(s, s, Offset.Zero)
                translate(-camera, 0f)
            }) {
                drawRoom(isNight, weather, frames, leftDoor, rightDoor)
                val depth = (0.82f + (girlY - 680f) / 800f).coerceIn(0.80f, 1.05f)
                drawNicole(girlX, girlY, depth, frames, abs(targetX - girlX) > 3f)
                if (pet.isNotEmpty()) drawPet(pet, girlX + 150f, 835f, frames)
            }
        }

        if (uiVisible && dialog == null) {
            Row(
                Modifier.align(Alignment.TopStart)
                    .padding(start = 11.dp, top = 8.dp)
                    .clip(RoundedCornerShape(22.dp))
                    .background(Ivory.copy(alpha = 0.95f))
                    .padding(horizontal = 15.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("🪙 0", fontSize = 17.sp, color = Violet, fontWeight = FontWeight.Bold)
            }
            Column(
                Modifier.align(Alignment.CenterStart).padding(start = 8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                MenuKey("🛍️", tr("Магазин", "Laden")) { interact(); dialog = "shop" }
                MenuKey("👗", tr("Гардероб", "Kleidung")) { interact(); dialog = "wardrobe" }
                MenuKey("🐾", tr("Питомцы", "Tiere")) { interact(); dialog = "pets" }
                MenuKey("🎮", tr("Игры", "Spiele")) { interact(); dialog = "games" }
            }
            Column(
                Modifier.align(Alignment.CenterEnd).padding(end = 8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                MenuKey("🎨", tr("Оформление", "Gestalten")) {
                    interact(); toast("Режим оформления будет добавлен позже", "Gestalten kommt später")
                }
                MenuKey(if (isNight) "🌙" else "☀️", tr("День/ночь", "Tag/Nacht")) {
                    interact(); isNight = !isNight
                }
                MenuKey(arrayOf("☀️", "🌧️", "❄️")[weather], tr("Погода", "Wetter")) {
                    interact(); weather = (weather + 1) % 3
                }
            }
            Box(Modifier.align(Alignment.TopEnd).padding(top = 8.dp, end = 10.dp)) {
                MenuKey("⚙️", tr("Настройки", "Optionen")) { interact(); dialog = "settings" }
            }
        }
        if (message != null && dialog == null) {
            Box(
                Modifier.align(Alignment.BottomCenter).padding(bottom = 16.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(Ivory.copy(alpha = 0.95f))
                    .padding(horizontal = 18.dp, vertical = 10.dp)
            ) {
                Text(message ?: "", color = Violet, fontWeight = FontWeight.SemiBold)
            }
        }
    }

    if (pet.isEmpty() || dialog == "pets") {
        AlertDialog(
            onDismissRequest = { if (pet.isNotEmpty()) dialog = null },
            title = { Text(tr("Выбери первого питомца", "Wähle dein erstes Tier")) },
            text = {
                Column {
                    listOf(
                        "dog" to "🐶", "cat" to "🐱", "parrot" to "🦜",
                        "hamster" to "🐹", "turtle" to "🐢"
                    ).forEach { (id, emoji) ->
                        TextButton(onClick = {
                            pet = id
                            prefs.edit().putString("pet", id).apply()
                            dialog = null
                        }) {
                            Text(emoji + "  " + when(id) {
                                "dog" -> tr("Собачка", "Hund")
                                "cat" -> tr("Кошечка", "Katze")
                                "parrot" -> tr("Попугай", "Papagei")
                                "hamster" -> tr("Хомячок", "Hamster")
                                else -> tr("Черепаха", "Schildkröte")
                            })
                        }
                    }
                }
            },
            confirmButton = {
                if (pet.isNotEmpty()) TextButton(onClick = { dialog = null }) {
                    Text(tr("Закрыть", "Schließen"))
                }
            }
        )
    } else if (dialog != null) {
        AlertDialog(
            onDismissRequest = { dialog = null },
            title = {
                Text(when (dialog) {
                    "shop" -> tr("Магазин", "Laden")
                    "wardrobe" -> tr("Гардероб", "Kleidung")
                    "games" -> tr("Мини-игры", "Minispiele")
                    else -> tr("Настройки", "Einstellungen")
                })
            },
            text = {
                if (dialog == "settings") {
                    TextButton(onClick = {
                        locale = if (locale == "ru") "de" else "ru"
                        prefs.edit().putString("locale", locale).apply()
                    }) { Text(tr("Язык: Русский → Deutsch", "Sprache: Deutsch → Русский")) }
                } else {
                    Text(tr("Этот раздел появится в следующих версиях. Комната уже интерактивна!",
                        "Dieser Bereich folgt später. Das Zimmer ist bereits interaktiv!"))
                }
            },
            confirmButton = {
                TextButton(onClick = { dialog = null }) { Text(tr("Понятно", "OK")) }
            }
        )
    }
}

@Composable
private fun MenuKey(symbol: String, label: String, onClick: () -> Unit) {
    Column(
        Modifier.width(88.dp).clip(RoundedCornerShape(19.dp))
            .background(Ivory.copy(alpha = 0.92f)).clickable(onClick = onClick)
            .padding(horizontal = 3.dp, vertical = 5.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(symbol, fontSize = 23.sp, lineHeight = 25.sp)
        Text(label, fontSize = 9.sp, lineHeight = 11.sp, color = Color(0xFF443183),
            textAlign = TextAlign.Center, fontWeight = FontWeight.Bold, maxLines = 2)
    }
}

private fun DrawScope.drawRoom(night: Boolean, weather: Int, tick: Int, lOpen: Boolean, rOpen: Boolean) {
    // A wide scrollable illustrated room (all coordinates in a 2700 x 900 design space).
    drawRect(Color(0xFFBFB1CB), size = Size(WORLD, 900f))
    drawRect(if (night) Color(0xFF91819D) else Color(0xFFC7BCD3),
        topLeft = Offset.Zero, size = Size(WORLD, 600f))
    for (i in 0..70) {
        val x = i * 43f
        val y = (i * 79 % 440) + 75f
        drawCircle(Color(0xFFE4D7DD).copy(alpha = 0.40f), radius = (i % 5 + 2) * 4f,
            center = Offset(x, y))
    }
    // Worn wall patches.
    listOf(Offset(365f, 440f), Offset(1040f, 475f), Offset(2270f, 460f)).forEach {
        drawRoundRect(Color(0xFFE5CEBF), topLeft = it, size = Size(145f, 88f),
            cornerRadius = CornerRadius(13f))
        for (j in 0..3) drawLine(Color(0xFFBB9C91), it + Offset(j * 27f, 18f),
            it + Offset(j * 27f + 45f, 65f), 2f)
    }
    drawRect(Color(0xFF9C6E53), topLeft = Offset(0f, 590f), size = Size(WORLD, 310f))
    for (i in 0..14) {
        val y = 595f + i * 23f
        drawLine(Color(0xFFBB8A63), Offset(0f, y), Offset(WORLD, y), 4f)
    }
    for (i in 0..29) {
        val x = i * 96f
        drawLine(Color(0xFF78533F).copy(alpha = .35f), Offset(x, 600f),
            Offset(x + 17f, 900f), 2f)
    }
    drawRect(Color(0xFFEAD2BD), topLeft = Offset(0f, 570f), size = Size(WORLD, 24f))
    drawRect(Color(0xFF8E6D6A), topLeft = Offset(0f, 28f), size = Size(WORLD, 13f))
    drawWindow(500f, night, weather, tick)
    drawWindow(1850f, night, weather, tick)
    drawDoor(135f, lOpen)
    drawDoor(2370f, rOpen)

    // Bed to the left, leaving the entire door unobstructed.
    drawRoundRect(Color(0xFF7C4936), Offset(375f, 467f), Size(450f, 185f), CornerRadius(21f))
    drawRoundRect(Color(0xFFB88573), Offset(390f, 515f), Size(440f, 183f), CornerRadius(28f))
    drawRoundRect(Color(0xFFD8B4C9), Offset(405f, 532f), Size(405f, 150f), CornerRadius(18f))
    drawRoundRect(Color(0xFFC8A0B8), Offset(405f, 603f), Size(405f, 88f), CornerRadius(10f))
    for (i in 0..7) drawLine(Color(0xFFE7C8D5), Offset(420f + i * 46f, 615f),
        Offset(420f + i * 46f, 682f), 6f)
    drawRoundRect(Ivory, Offset(420f, 525f), Size(118f, 44f), CornerRadius(19f))
    drawRoundRect(Color(0xFFB88F6C), Offset(374f, 647f), Size(28f, 103f), CornerRadius(8f))
    drawRoundRect(Color(0xFFB88F6C), Offset(795f, 647f), Size(28f, 103f), CornerRadius(8f))

    // Old wardrobe, on the right half.
    drawRoundRect(Color(0xFFF3E5DA), Offset(1550f, 285f), Size(275f, 340f), CornerRadius(19f))
    drawRoundRect(Color(0xFFCDB7AB), Offset(1565f, 304f), Size(115f, 290f), CornerRadius(9f))
    drawRoundRect(Color(0xFFE3D0BD), Offset(1688f, 304f), Size(123f, 290f), CornerRadius(9f))
    drawCircle(Color(0xFF84694F), 7f, Offset(1660f, 450f))
    drawCircle(Color(0xFF84694F), 7f, Offset(1705f, 450f))

    // Study desk, chair, and their shadows.
    drawOval(Color.Black.copy(alpha = .12f), Offset(1920f, 678f), Size(420f, 40f))
    drawRoundRect(Color(0xFFE2C7B4), Offset(1920f, 473f), Size(372f, 36f), CornerRadius(5f))
    for (x in listOf(1940f, 2255f)) {
        drawRoundRect(Color(0xFFD0AB93), Offset(x, 504f), Size(19f, 193f), CornerRadius(4f))
    }
    drawRoundRect(Color(0xFFBE937A), Offset(2015f, 520f), Size(125f, 42f), CornerRadius(7f))
    drawCircle(Color(0xFF8B604C), 5f, Offset(2075f, 545f))
    drawRoundRect(Color(0xFFE9CAB2), Offset(2080f, 535f), Size(70f, 140f), CornerRadius(13f))
    drawRoundRect(Color(0xFFC49E83), Offset(2050f, 590f), Size(135f, 25f), CornerRadius(4f))
    for (x in listOf(2070f, 2160f)) {
        drawRect(Color(0xFFB58B73), Offset(x, 611f), Size(12f, 120f))
    }
    drawRoundRect(Ivory, Offset(1990f, 452f), Size(85f, 17f), CornerRadius(4f))
    drawRoundRect(Color(0xFF97ABC0), Offset(2095f, 445f), Size(60f, 23f), CornerRadius(3f))
    // Warm sunlight over the wood floor.
    if (!night && weather == 0) {
        drawOval(Color(0xFFFFD59A).copy(alpha = .26f), Offset(1020f, 680f),
            Size(920f, 170f))
    }
    if (night) drawRect(Color(0xFF1C204D).copy(alpha = .26f), size = Size(WORLD, 900f))
}

private fun DrawScope.drawDoor(x: Float, open: Boolean) {
    drawRoundRect(Color(0xFFF0DCC9), Offset(x - 18f, 157f), Size(236f, 445f),
        CornerRadius(100f, 90f))
    drawRoundRect(Color(0xFF684334), Offset(x, 175f), Size(199f, 424f),
        CornerRadius(80f, 80f))
    if (!open) {
        drawRoundRect(Color(0xFF965D44), Offset(x + 13f, 188f), Size(173f, 398f),
            CornerRadius(76f, 65f))
        drawRoundRect(Color(0xFFAB7155), Offset(x + 42f, 268f), Size(106f, 217f),
            CornerRadius(25f))
    } else {
        drawRect(Color(0xFF624D75), Offset(x + 22f, 241f), Size(165f, 344f))
        drawRoundRect(Color(0xFFA36C55), Offset(x + 5f, 178f), Size(65f, 413f),
            CornerRadius(28f))
    }
    drawCircle(Color(0xFFFFCB71), 10f, Offset(x + (if (open) 56f else 166f), 435f))
}

private fun DrawScope.drawWindow(x: Float, night: Boolean, weather: Int, tick: Int) {
    drawRoundRect(Color(0xFF8B5A41), Offset(x - 11f, 120f), Size(342f, 325f),
        CornerRadius(14f))
    drawRect(if (night) Color(0xFF50618D) else Color(0xFFADE4FA),
        Offset(x + 8f, 137f), Size(302f, 285f))
    drawRect(Color(0xFF8AB57B), Offset(x + 8f, 322f), Size(302f, 100f))
    for (i in 0..4) {
        drawCircle(Color(0xFF72A46F), 35f,
            Offset(x + 20f + i * 72f, 325f + (i % 2) * 19f))
        drawCircle(Color(0xFFFFD8AA), 9f, Offset(x + 27f + i * 60f, 385f))
    }
    if (weather == 1) {
        for (i in 0..22) {
            val rx = x + 20f + (i * 71 % 275)
            val ry = 145f + ((i * 43 + tick * 6) % 260)
            drawLine(Color(0xFFEDF6FF), Offset(rx, ry), Offset(rx - 7f, ry + 17f), 3f)
        }
    }
    if (weather == 2) {
        for (i in 0..23) {
            val rx = x + 18f + (i * 61 % 286)
            val ry = 143f + ((i * 47 + tick * 2) % 267)
            drawCircle(Color.White, 4.5f, Offset(rx, ry))
        }
    }
    drawRect(Color(0xFFA7745E), Offset(x + 153f, 130f), Size(13f, 300f))
    drawRect(Color(0xFFA7745E), Offset(x + 8f, 285f), Size(303f, 13f))
    drawRect(Color(0xFFD9AE97), Offset(x - 20f, 429f), Size(362f, 22f))
    // Pink drapes, deliberately faded and simple.
    drawRoundRect(Color(0xFFD19AAE), Offset(x - 34f, 108f), Size(63f, 260f),
        CornerRadius(18f))
    drawRoundRect(Color(0xFFD19AAE), Offset(x + 284f, 108f), Size(63f, 260f),
        CornerRadius(18f))
    drawLine(Color(0xFFF1C1D0), Offset(x - 18f, 120f), Offset(x - 2f, 350f), 5f)
    drawLine(Color(0xFFF1C1D0), Offset(x + 325f, 120f), Offset(x + 308f, 350f), 5f)
}

private fun DrawScope.drawNicole(x: Float, footY: Float, depth: Float, tick: Int, walking: Boolean) {
    withTransform({ translate(x, footY); scale(depth, depth, Offset.Zero) }) {
        drawOval(Color.Black.copy(alpha = .17f), Offset(-56f, -11f), Size(120f, 24f))
        val bob = if (walking && tick % 18 < 9) -4f else 0f
        withTransform({ translate(0f, bob) }) {
            // Shoes and blue jeans, as agreed for Nicole's default outfit.
            drawRoundRect(Color(0xFF668EBD), Offset(-46f, -99f), Size(38f, 79f), CornerRadius(12f))
            drawRoundRect(Color(0xFF668EBD), Offset(7f, -99f), Size(38f, 79f), CornerRadius(12f))
            drawRoundRect(Color.White, Offset(-57f, -29f), Size(56f, 28f), CornerRadius(14f))
            drawRoundRect(Color.White, Offset(6f, -29f), Size(56f, 28f), CornerRadius(14f))
            // Arms, blouse, and flowers.
            drawLine(Color(0xFFFFDBBF), Offset(-60f, -156f), Offset(-74f, -109f), 25f)
            drawLine(Color(0xFFFFDBBF), Offset(60f, -156f), Offset(74f, -109f), 25f)
            drawRoundRect(Color(0xFFFFF9F5), Offset(-66f, -175f), Size(132f, 92f),
                CornerRadius(38f))
            for (fx in listOf(-30f, 15f, 42f)) {
                drawCircle(Pink, 7f, Offset(fx, -138f))
                drawCircle(Color(0xFFE8A9CA), 5f, Offset(fx + 5f, -142f))
            }
            // Blonde wavy hair (back layer).
            drawOval(Color(0xFFDBB06A), Offset(-94f, -330f), Size(191f, 199f))
            for (i in 0..4) {
                drawCircle(Color(0xFFE6BB78), 21f, Offset(-75f + i * 38f, -159f))
            }
            drawCircle(Color(0xFFFFD9BE), 67f, Offset(0f, -248f))
            drawOval(Color(0xFFEAC581), Offset(-73f, -323f), Size(145f, 65f))
            for (i in 0..4) {
                drawCircle(Color(0xFFEAC581), 18f, Offset(-61f + i * 29f, -298f))
            }
            // Eyes, eyebrows, pupils and permanent round glasses.
            for (eyeX in listOf(-28f, 28f)) {
                drawCircle(Color.White, 16f, Offset(eyeX, -250f))
                drawCircle(Color(0xFF6D513A), 10f, Offset(eyeX, -249f))
                drawCircle(Color.Black, 5f, Offset(eyeX, -248f))
                drawCircle(Color.White, 3f, Offset(eyeX + 3f, -254f))
                drawCircle(Color(0xFFAA7992), 28f, Offset(eyeX, -250f),
                    style = Stroke(width = 5f))
            }
            drawLine(Color(0xFFAA7992), Offset(-1f, -251f), Offset(1f, -251f), 5f)
            drawCircle(Color(0xFFF0ACAA).copy(alpha = .7f), 13f, Offset(-48f, -223f))
            drawCircle(Color(0xFFF0ACAA).copy(alpha = .7f), 13f, Offset(48f, -223f))
            drawLine(Color(0xFFA45F67), Offset(-12f, -214f), Offset(12f, -214f),
                3.5f)
        }
    }
}

private fun DrawScope.drawPet(pet: String, x: Float, y: Float, tick: Int) {
    withTransform({ translate(x, y + if(tick % 72 < 36) 0f else -2f) }) {
        drawOval(Color.Black.copy(alpha = .17f), Offset(-58f, -10f), Size(116f, 18f))
        when (pet) {
            "turtle" -> {
                drawOval(Color(0xFF679870), Offset(-60f, -65f), Size(125f, 58f))
                drawCircle(Color(0xFF9DC57D), 24f, Offset(58f, -30f))
                drawCircle(Color.Black, 4f, Offset(67f, -38f))
            }
            "parrot" -> {
                drawOval(Color(0xFF82C5A6), Offset(-35f, -91f), Size(69f, 85f))
                drawCircle(Color(0xFF6EB7AC), 36f, Offset(-3f, -104f))
                drawCircle(Color(0xFFFFC77A), 13f, Offset(24f, -102f))
                drawCircle(Color.Black, 5f, Offset(6f, -113f))
            }
            else -> {
                val fur = when (pet) {
                    "cat" -> Color(0xFFAEB4C0)
                    "hamster" -> Color(0xFFF1C18E)
                    else -> Color(0xFFC78E63)
                }
                drawOval(fur, Offset(-52f, -68f), Size(102f, 65f))
                drawCircle(fur, 39f, Offset(33f, -72f))
                drawCircle(fur, 19f, Offset(9f, -105f))
                drawCircle(fur, 19f, Offset(58f, -106f))
                drawCircle(Color.White, 16f, Offset(40f, -58f))
                drawCircle(Color.Black, 5f, Offset(16f, -82f))
                drawCircle(Color.Black, 5f, Offset(55f, -82f))
                drawCircle(Color(0xFF694852), 7f, Offset(44f, -65f))
            }
        }
    }
}
