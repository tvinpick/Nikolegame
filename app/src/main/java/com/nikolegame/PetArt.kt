package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import kotlin.math.abs
import kotlin.math.sin

// v0.6: independent pastel pets. Every animal has its own silhouette and
// small idle/walking animation. Its shadow stays at world floor coordinates.
internal fun DrawScope.renderPet(
    type: String, x: Float, footY: Float, tick: Int, moving: Boolean
) {
    val phase = tick * .11f
    val walk = if (moving) sin(phase) else 0f
    val bob = if (moving) -abs(walk) * 2.6f else sin(tick * .055f) * .85f
    withTransform({ translate(x, footY) }) {
        drawOval(Color(0xFF4F3B49).copy(alpha = .15f),
            Offset(-57f, -12f), Size(114f, 20f))
        withTransform({ translate(0f, bob) }) {
            when (type) {
                "cat" -> paintKitten(tick, walk)
                "parrot" -> paintParrot(tick)
                "hamster" -> paintHamster(tick, walk)
                "turtle" -> paintTurtle(tick, walk)
                else -> paintPuppy(tick, walk)
            }
        }
    }
}

private fun DrawScope.petEye(x: Float, y: Float, r: Float, blink: Boolean) {
    if (blink) {
        drawLine(Color(0xFF493F50), Offset(x - r, y),
            Offset(x + r, y), 2.6f, cap = StrokeCap.Round)
    } else {
        drawCircle(Color(0xFF363344), r, Offset(x, y))
        drawCircle(Color.White.copy(alpha = .94f), r * .34f,
            Offset(x - r * .27f, y - r * .35f))
    }
}

private fun DrawScope.paintPuppy(tick: Int, walk: Float) {
    val fur = Color(0xFFE3B48B)
    val caramel = Color(0xFFC78D6B)
    val cream = Color(0xFFFFEBD5)
    val wag = sin(tick * .21f) * 13f
    // Wagging tail behind a lightly rounded body.
    val tail = Path().apply {
        moveTo(-45f, -47f)
        quadraticBezierTo(-81f, -71f + wag, -77f, -89f + wag)
    }
    drawPath(tail, caramel, style = Stroke(width = 13f, cap = StrokeCap.Round))
    for (xx in listOf(-31f, 21f)) {
        val step = if (xx < 0) walk else -walk
        drawRoundRect(caramel, Offset(xx - 11f + step * 3f, -32f),
            Size(21f, 27f), CornerRadius(9f))
        drawOval(cream, Offset(xx - 13f + step * 3f, -13f),
            Size(27f, 12f))
    }
    drawOval(Brush.verticalGradient(listOf(Color(0xFFF2C9A2), fur, caramel),
        startY = -85f, endY = -19f), Offset(-57f, -84f), Size(106f, 72f))
    drawOval(cream, Offset(-6f, -49f), Size(36f, 34f))
    // Actual floppy ears, different from a cat's pointed ears.
    drawOval(caramel, Offset(8f, -115f), Size(28f, 55f))
    drawOval(caramel, Offset(60f, -111f), Size(25f, 50f))
    drawCircle(fur, 38f, Offset(46f, -77f))
    drawOval(Color(0xFFE8A97C), Offset(41f, -75f), Size(28f, 24f))
    drawOval(cream, Offset(31f, -65f), Size(40f, 29f))
    drawOval(Color(0xFF77545C), Offset(44f, -66f), Size(15f, 11f))
    drawLine(Color(0xFF84616A), Offset(52f, -55f),
        Offset(58f, -52f), 2.4f, cap = StrokeCap.Round)
    val blink = tick % 183 in 0..5
    petEye(27f, -89f, 5.8f, blink)
    petEye(62f, -89f, 5.8f, blink)
    // Small rose collar and heart tag.
    drawLine(Color(0xFFD38DAD), Offset(17f, -51f),
        Offset(62f, -42f), 6f, cap = StrokeCap.Round)
    drawCircle(Color(0xFFFFE0A5), 5f, Offset(43f, -43f))
}

private fun DrawScope.paintKitten(tick: Int, walk: Float) {
    val silver = Color(0xFFBFC8D5)
    val shade = Color(0xFF8F9CAC)
    val pale = Color(0xFFE8EDF1)
    val sway = sin(tick * .065f) * 10f
    val tail = Path().apply {
        moveTo(-43f, -36f)
        quadraticBezierTo(-91f, -40f + sway, -76f, -93f + sway)
        quadraticBezierTo(-63f, -111f + sway, -49f, -95f + sway)
    }
    drawPath(tail, shade, style = Stroke(width = 13f,
        cap = StrokeCap.Round))
    for (xx in listOf(-32f, 17f)) {
        val sx = xx + if (xx < 0) walk * 3f else -walk * 3f
        drawRoundRect(shade, Offset(sx, -31f), Size(23f, 27f),
            CornerRadius(10f))
        drawOval(pale, Offset(sx - 3f, -13f), Size(27f, 10f))
    }
    drawOval(Brush.verticalGradient(listOf(pale, silver, shade),
        startY = -90f, endY = -12f), Offset(-54f, -86f), Size(101f, 75f))
    drawOval(pale, Offset(0f, -57f), Size(32f, 36f))
    // Triangular, forward-facing ears.
    for (xx in listOf(13f, 64f)) {
        val ear = Path().apply {
            moveTo(xx - 19f, -93f)
            lineTo(xx - 9f, -137f)
            lineTo(xx + 19f, -100f)
            close()
        }
        drawPath(ear, shade)
        val inner = Path().apply {
            moveTo(xx - 8f, -107f)
            lineTo(xx - 6f, -125f)
            lineTo(xx + 8f, -105f)
            close()
        }
        drawPath(inner, Color(0xFFEDB9C7))
    }
    drawCircle(silver, 38f, Offset(38f, -86f))
    drawOval(pale, Offset(20f, -82f), Size(37f, 31f))
    val blink = tick % 173 in 0..6
    if (blink) {
        petEye(19f, -93f, 5.3f, true)
        petEye(58f, -93f, 5.3f, true)
    } else {
        for (xx in listOf(19f, 58f)) {
            drawOval(Color(0xFFA7B88B), Offset(xx - 6f, -100f),
                Size(13f, 17f))
            drawOval(Color(0xFF343344), Offset(xx - 2f, -98f),
                Size(5f, 12f))
            drawCircle(Color.White, 2.5f, Offset(xx + 1f, -94f))
        }
    }
    val nose = Path().apply {
        moveTo(34f, -76f)
        lineTo(45f, -76f)
        lineTo(39f, -69f)
        close()
    }
    drawPath(nose, Color(0xFFCD91A4))
    for (sign in listOf(-1f, 1f)) {
        val cx = 39f + sign * 6f
        for (dy in listOf(-3f, 4f)) {
            drawLine(Color(0xFF7C8092).copy(alpha = .72f),
                Offset(cx, -69f + dy),
                Offset(cx + sign * 38f, -72f + dy * 2f),
                1.6f, cap = StrokeCap.Round)
        }
    }
    drawLine(Color(0xFFD497AC), Offset(-3f, -42f),
        Offset(38f, -39f), 4.2f, cap = StrokeCap.Round)
    drawCircle(Color(0xFFFFE4A8), 5f, Offset(20f, -36f))
}

private fun DrawScope.paintHamster(tick: Int, walk: Float) {
    val golden = Color(0xFFF1C28F)
    val warm = Color(0xFFD99D74)
    val cream = Color(0xFFFFEEE1)
    for (xx in listOf(-25f, 20f)) {
        drawOval(warm, Offset(xx + walk * 2f, -13f), Size(22f, 12f))
    }
    // Hamsters are deliberately round and smaller than cats and dogs.
    drawOval(Brush.verticalGradient(
        listOf(Color(0xFFFFD5AA), golden, warm),
        startY = -74f, endY = -10f),
        Offset(-51f, -77f), Size(103f, 73f))
    for (xx in listOf(-29f, 26f)) {
        drawCircle(warm, 16f, Offset(xx, -78f))
        drawCircle(Color(0xFFF3BFC6), 10f, Offset(xx, -80f))
    }
    drawOval(cream, Offset(-38f, -58f), Size(36f, 33f))
    drawOval(cream, Offset(2f, -59f), Size(36f, 33f))
    drawOval(cream, Offset(-22f, -42f), Size(45f, 33f))
    val blink = tick % 181 in 0..5
    petEye(-23f, -61f, 5.7f, blink)
    petEye(23f, -61f, 5.7f, blink)
    drawCircle(Color(0xFFB87E80), 5.5f, Offset(0f, -43f))
    drawLine(Color(0xFF98727C), Offset(0f, -38f),
        Offset(-6f, -34f), 1.8f, cap = StrokeCap.Round)
    drawLine(Color(0xFF98727C), Offset(0f, -38f),
        Offset(6f, -34f), 1.8f, cap = StrokeCap.Round)
    for (sign in listOf(-1f, 1f)) {
        drawLine(Color(0xFFC3988F), Offset(sign * 10f, -44f),
            Offset(sign * 43f, -48f), 1.4f)
    }
}

private fun DrawScope.paintTurtle(tick: Int, walk: Float) {
    val leaf = Color(0xFF9FC784)
    val shell = Color(0xFF719979)
    val shellDark = Color(0xFF527963)
    val pale = Color(0xFFC4DCA0)
    // Four small stepping feet behind the shell.
    for (xx in listOf(-43f, -6f, 28f, 49f)) {
        val bounce = if (xx < 0) walk * 2f else -walk * 2f
        drawOval(leaf, Offset(xx, -22f + bounce),
            Size(25f, 19f))
    }
    val headBob = sin(tick * .05f) * 1.5f
    drawOval(leaf, Offset(34f, -48f + headBob), Size(54f, 45f))
    drawOval(pale, Offset(61f, -30f + headBob), Size(22f, 15f))
    val blink = tick % 190 in 0..6
    petEye(65f, -39f + headBob, 4.7f, blink)
    drawCircle(Color(0xFFE2A4AB).copy(alpha = .63f),
        4.3f, Offset(76f, -21f + headBob))
    // Domed, tessellated tortoise shell with cream edging.
    drawOval(shellDark, Offset(-57f, -74f), Size(117f, 66f))
    drawOval(Brush.verticalGradient(
        listOf(Color(0xFFB1D3A0), shell, shellDark),
        startY = -73f, endY = -13f),
        Offset(-54f, -79f), Size(110f, 68f))
    drawOval(Color(0xFFD8E4AD), Offset(-53f, -27f),
        Size(108f, 13f))
    for ((cx,cy) in listOf(-29f to -55f, 0f to -63f, 31f to -54f,
        -16f to -31f, 18f to -31f)) {
        val tile = Path().apply {
            moveTo(cx - 12f, cy)
            lineTo(cx - 6f, cy - 10f)
            lineTo(cx + 7f, cy - 10f)
            lineTo(cx + 14f, cy)
            lineTo(cx + 6f, cy + 9f)
            lineTo(cx - 7f, cy + 9f)
            close()
        }
        drawPath(tile, Color(0xFFCEE2B7).copy(alpha = .52f),
            style = Stroke(width = 2.4f))
    }
    drawCircle(leaf, 8f, Offset(-52f, -26f))
}

private fun DrawScope.paintParrot(tick: Int) {
    val teal = Color(0xFF78BFAE)
    val dark = Color(0xFF448F8E)
    val cream = Color(0xFFE3F4D5)
    val wing = sin(tick * .095f) * 5f
    // Small wooden perch anchored at pet's floor position.
    drawRoundRect(Color(0xFFC5967A), Offset(-40f, -13f),
        Size(80f, 13f), CornerRadius(5f))
    drawRoundRect(Color(0xFFAB7967), Offset(-7f, -79f),
        Size(15f, 67f), CornerRadius(5f))
    drawLine(Color(0xFFD9B18D), Offset(-34f, -77f),
        Offset(38f, -77f), 9f, cap = StrokeCap.Round)
    // Tail feathers extend from the lower back of the body.
    for (i in 0..2) {
        val tipX = -20f + i * 12f
        drawLine(if(i == 1) Color(0xFF9CCB77) else dark,
            Offset(-7f, -123f),
            Offset(tipX, -65f + (i % 2) * 14f),
            12f, cap = StrokeCap.Round)
    }
    drawOval(Brush.verticalGradient(
        listOf(Color(0xFFA8DAC2), teal, dark),
        startY = -167f, endY = -85f),
        Offset(-40f, -171f), Size(80f, 91f))
    drawOval(cream, Offset(-8f, -143f), Size(32f, 42f))
    // Wing gently flexes while perched.
    drawOval(Color(0xFF4BA39D), Offset(-43f, -154f + wing),
        Size(48f, 57f))
    for (i in 0..2) {
        drawLine(Color(0xFFAEDCC3).copy(alpha = .85f),
            Offset(-36f + i * 10f, -119f + wing),
            Offset(-31f + i * 10f, -103f + wing),
            3f, cap = StrokeCap.Round)
    }
    drawCircle(teal, 39f, Offset(0f, -174f))
    drawOval(Color(0xFF9CCB79), Offset(-14f, -212f),
        Size(26f, 19f))
    val beak = Path().apply {
        moveTo(22f, -183f)
        quadraticBezierTo(55f, -178f, 32f, -159f)
        lineTo(19f, -165f)
        close()
    }
    drawPath(beak, Color(0xFFF6C981))
    drawOval(Color.White, Offset(3f, -190f), Size(21f, 22f))
    val blink = tick % 179 in 0..4
    petEye(16f, -177f, 5f, blink)
    for (xx in listOf(-13f, 12f)) {
        drawLine(Color(0xFF836B69), Offset(xx, -85f),
            Offset(xx + 3f, -77f), 3f, cap = StrokeCap.Round)
    }
}
