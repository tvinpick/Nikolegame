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
import kotlin.math.sin

// Nicole v0.5.1: slimmer, softer proportions matching the approved reference.
// Separate figure renderer so the outfit, hair and facial features can
// eventually be replaced independently in the dressing-room system.
// Facing: 0 front, 1 left, 2 right, 3 back. Feet remain the depth anchor.
private val skinLight = Color(0xFFFFDEC8)
private val skinShadow = Color(0xFFE6B79E)
private val honeyHair = Color(0xFFF1CF88)
private val hairShade = Color(0xFFCAA36D)
private val flowerRose = Color(0xFFD7A4B7)
private val iris = Color(0xFF6B7C65)
private val outline = Color(0xFF80666A)

internal fun DrawScope.renderNicole(
    x: Float,
    footY: Float,
    depth: Float,
    tick: Int,
    walking: Boolean,
    facing: Int
) {
    // The shadow is glued to the floor and does not bob.
    withTransform({ translate(x, footY); scale(depth, depth, Offset.Zero) }) {
        drawOval(Color(0xFF493B44).copy(alpha = 0.19f),
            Offset(-54f, -12f), Size(110f, 24f))
        val phase = tick.toFloat() * 0.23f
        val legSwing = if (walking) sin(phase) * 10f else 0f
        val armSwing = if (walking) sin(phase) * 7f else 0f
        val bounce = if (walking) -kotlin.math.abs(sin(phase)) * 2.5f else 0f

        withTransform({ translate(0f, bounce) }) {
            // Right-facing art mirrors consistently to the left.
            if (facing == 1) {
                withTransform({ scale(-1f, 1f, Offset.Zero) }) {
                    paintNicoleFigure(walking, legSwing, armSwing, side = true, back = false, tick = tick)
                }
            } else {
                paintNicoleFigure(walking, legSwing, armSwing, side = facing == 2,
                    back = facing == 3, tick = tick)
            }
        }
    }
}

// Separate scale transforms keep the feet/depth anchor fixed.
// 0.80-0.83x body width eliminates the barrel-shaped torso;
// 1.08x height improves the leg-to-body ratio; the head is 13% smaller.
private fun DrawScope.paintNicoleFigure(
    walking: Boolean, legSwing: Float, armSwing: Float,
    side: Boolean, back: Boolean, tick: Int
) {
    withTransform({ scale(if (side) 0.79f else 0.83f, 1.08f, Offset.Zero) }) {
        paintNicoleBody(walking, legSwing, armSwing, side, back)
    }
    withTransform({
        translate(0f, -9f)
        scale(0.87f, 0.87f, Offset(0f, -207f))
    }) {
        paintNicoleHead(side, back, tick)
    }
}

private fun DrawScope.paintNicoleBody(
    walking: Boolean, legSwing: Float, armSwing: Float,
    side: Boolean, back: Boolean
) {
    val leftLeg = if (walking) legSwing else 0f
    val rightLeg = -leftLeg
    val jeansLight = Color(0xFF7BA6CF)
    val jeansDark = Color(0xFF557BA8)
    // Separate soft trouser legs and moving white sneakers.
    // Narrow, proportionate jeans and a longer-legged silhouette.
    for ((sign, swing) in listOf((-1f to leftLeg), (1f to rightLeg))) {
        val sx = if (side) -1f else sign
        val hipX = if (side) -9f + sign * 11f else sign * 24f
        val kneeX = hipX + swing * .62f
        val ankleX = hipX + swing
        drawLine(jeansDark, Offset(hipX, -115f), Offset(kneeX, -64f),
            strokeWidth = 25f, cap = StrokeCap.Round)
        drawLine(jeansLight, Offset(kneeX, -64f), Offset(ankleX, -25f),
            strokeWidth = 23f, cap = StrokeCap.Round)
        drawLine(Color(0xFFB3D1E6).copy(alpha = .64f),
            Offset(kneeX - 7f, -55f), Offset(ankleX - 7f, -31f),
            strokeWidth = 2f, cap = StrokeCap.Round)
        val shoeShift = if (walking && swing > 0f) -5f else 0f
        drawRoundRect(Color(0xFFD6C8CF), Offset(ankleX - 24f + sx * 3f, -26f + shoeShift),
            Size(49f, 24f), CornerRadius(12f))
        drawRoundRect(Color.White, Offset(ankleX - 24f + sx * 3f, -30f + shoeShift),
            Size(48f, 22f), CornerRadius(11f))
        drawLine(Color(0xFFE7D7D8),
            Offset(ankleX - 9f, -18f + shoeShift),
            Offset(ankleX + 6f, -18f + shoeShift), 2f)
        drawLine(Color(0xFFC7B8C0), Offset(ankleX - 20f, -8f + shoeShift),
            Offset(ankleX + 21f, -8f + shoeShift), 2.5f)
    }

    drawRoundRect(Color(0xFF6289B6), Offset(if(side) -39f else -43f, -126f),
        Size(if(side) 76f else 86f, 34f), CornerRadius(14f))
    drawLine(Color(0xFF416B96), Offset(-31f, -107f), Offset(30f, -107f), 2.5f)
    drawCircle(Color(0xFFE7C7A7), 4f, Offset(0f, -113f))

    // Arms and warm-toned hands are behind the top.
    val shoulderX = if (side) 32f else 48f
    for (sign in listOf(-1f, 1f)) {
        val xx = if (side) sign * 25f else sign * shoulderX
        val wristX = xx + sign * (14f + armSwing * .7f)
        val wristY = -122f + sign * armSwing * .50f
        drawLine(skinShadow.copy(alpha = .55f),
            Offset(xx + 2f, -180f), Offset(wristX + 2f, wristY + 1f),
            strokeWidth = 15f, cap = StrokeCap.Round)
        drawLine(skinLight, Offset(xx, -181f), Offset(wristX, wristY),
            strokeWidth = 13.8f, cap = StrokeCap.Round)
        drawCircle(skinLight, 7.5f, Offset(wristX, wristY + 5f))
    }

    // Fitted white floral shirt with rounded sleeve caps.
    val left = if (side) -30f else -48f
    val top = -193f
    drawRoundRect(Color(0xFFD9C9CB), Offset(left + 2f, top + 5f),
        Size(if(side) 60f else 96f, 95f), CornerRadius(30f))
    drawRoundRect(Brush.verticalGradient(
        listOf(Color.White, Color(0xFFFFF9F2), Color(0xFFEEDDE0)),
        startY = top, endY = -103f),
        Offset(left, top), Size(if(side) 60f else 96f, 89f),
        CornerRadius(32f))
    if (!side) {
        for (xx in listOf(-47f, 23f)) {
            drawRoundRect(Color(0xFFFFFCF8), Offset(xx, -185f),
                Size(24f, 31f), CornerRadius(11f))
        }
    }

    // Stems, tiny roses and leaves form a genuine floral print.
    val blossomCenters = if (side) listOf(
        Offset(-11f, -167f), Offset(16f, -138f), Offset(-17f, -117f)
    ) else listOf(
        Offset(-23f, -169f), Offset(19f, -174f), Offset(30f, -134f),
        Offset(-27f, -126f), Offset(2f, -145f), Offset(12f, -112f)
    )
    for ((index, c) in blossomCenters.withIndex()) {
        drawLine(Color(0xFF8FAC94).copy(alpha = .83f),
            Offset(c.x, c.y + 7f), Offset(c.x + 4f, c.y + 18f), 1.8f)
        for (p in 0..3) {
            val angle = p.toFloat() * 1.5707964f
            drawCircle(if (index % 2 == 0) flowerRose else Color(0xFFF1C7C8),
                3.8f, Offset(c.x + kotlin.math.cos(angle) * 5.2f,
                    c.y + kotlin.math.sin(angle) * 5.2f))
        }
        drawCircle(Color(0xFFF9D38B), 2.7f, c)
        drawOval(Color(0xFFA2BF98), Offset(c.x + 1f, c.y + 11f), Size(8f, 4f))
    }
    if (!back) {
        drawLine(Color(0xFFD6C1C7), Offset(0f, -190f), Offset(0f, -183f), 2f)
    }
}

private fun DrawScope.paintNicoleHead(side: Boolean, back: Boolean, tick: Int) {
    // A smaller head with softly waved blonde hair.
    // The face's proportions are consistent in all four views.
    val hairBack = Path().apply {
        moveTo(-61f, -260f)
        quadraticBezierTo(-95f, -338f, -6f, -339f)
        quadraticBezierTo(89f, -340f, 75f, -256f)
        quadraticBezierTo(93f, -220f, 73f, -183f)
        quadraticBezierTo(53f, -166f, 37f, -185f)
        quadraticBezierTo(13f, -158f, -6f, -188f)
        quadraticBezierTo(-43f, -161f, -61f, -191f)
        quadraticBezierTo(-91f, -210f, -61f, -260f)
        close()
    }
    drawPath(hairBack, Brush.verticalGradient(
        listOf(Color(0xFFF9DFA1), honeyHair, hairShade),
        startY = -341f, endY = -167f))
    drawPath(hairBack, Color(0xFFBE985F).copy(alpha = .8f),
        style = Stroke(width = 2.6f))

    // Side curls are animated very gently while walking.
    val wave = sin(tick.toFloat() * .045f) * 2f
    for (i in 0..3) {
        val cx = -65f + i * 42f
        val yy = -194f + (i % 2) * 8f + wave
        drawCircle(if (i % 2 == 0) Color(0xFFF2D28E) else Color(0xFFE4BF79),
            16f, Offset(cx, yy))
        drawCircle(Color(0xFFFFE7AF).copy(alpha = .45f),
            7f, Offset(cx - 4f, yy - 5f))
    }

    // Neck and ears remain visible under the face and hair.
    drawRoundRect(skinShadow, Offset(-14f, -203f),
        Size(28f, 36f), CornerRadius(11f))
    drawRoundRect(skinLight, Offset(-12f, -207f),
        Size(24f, 36f), CornerRadius(10f))

    if (back) {
        // Rear-facing version: back of head and flowing hair, no facial features.
        drawOval(Color(0xFFE8BD78), Offset(-63f, -316f), Size(126f, 136f))
        for (i in -2..2) {
            val hx = i * 21f
            drawLine(Color(0xFFFFE8B7).copy(alpha = .76f),
                Offset(hx, -301f), Offset(hx - 7f, -216f), 5f,
                cap = StrokeCap.Round)
        }
        drawRoundRect(Color(0xFFD2A56F), Offset(-57f, -237f),
            Size(115f, 52f), CornerRadius(23f))
        drawLine(Color(0xFFFFEAC0), Offset(-38f, -307f),
            Offset(-14f, -279f), 5f, cap = StrokeCap.Round)
        return
    }

    if (side) {
        // True drawn profile, not an enormous face oval with a stuck-on nose.
        // Face outline gently tapers toward the chin.
        val face = Path().apply {
            moveTo(-48f, -294f)
            quadraticBezierTo(-9f, -328f, 30f, -306f)
            quadraticBezierTo(51f, -289f, 51f, -263f)
            lineTo(60f, -249f) // delicate small nose
            quadraticBezierTo(65f, -245f, 57f, -241f)
            quadraticBezierTo(60f, -221f, 40f, -202f)
            quadraticBezierTo(20f, -187f, -4f, -190f)
            quadraticBezierTo(-55f, -209f, -48f, -294f)
            close()
        }
        drawPath(face, skinLight)
        drawPath(face, skinShadow.copy(alpha = .5f),
            style = Stroke(width = 2.1f, cap = StrokeCap.Round))
        drawCircle(skinShadow, 10.3f, Offset(-47f, -247f))
        drawCircle(skinLight, 8.6f, Offset(-47f, -249f))
        drawCircle(Color(0xFFD9998D).copy(alpha = .52f), 2.5f, Offset(-45f, -248f))

        // One calm, expressive eye, not a protruding cartoon globe.
        drawOval(Color.White, Offset(17f, -273f), Size(21f, 25f))
        drawCircle(iris, 8.3f, Offset(29f, -260f))
        drawCircle(Color(0xFF303846), 4.1f, Offset(30f, -260f))
        drawCircle(Color.White, 2.5f, Offset(32f, -265f))
        drawLine(Color(0xFFA78E7E), Offset(16f, -281f), Offset(36f, -280f),
            2.6f, cap = StrokeCap.Round)

        // A slim round lens, bridge and a discreet temple above the ear.
        drawCircle(Color(0xFF9C798E), 20f, Offset(26f, -261f),
            style = Stroke(width = 3f))
        drawLine(Color(0xFF9C798E), Offset(46f, -261f), Offset(54f, -259f),
            2.5f, cap = StrokeCap.Round)
        drawLine(Color(0xFF9C798E), Offset(7f, -265f), Offset(-48f, -259f),
            2.7f, cap = StrokeCap.Round)

        drawOval(Color(0xFFF2AFA6).copy(alpha = .38f),
            Offset(32f, -235f), Size(18f, 10f))
        val smile = Path().apply {
            moveTo(37f, -220f)
            quadraticBezierTo(45f, -216f, 50f, -223f)
        }
        drawPath(smile, Color(0xFFAA6575),
            style = Stroke(width = 2.4f, cap = StrokeCap.Round))

        // The fringe hugs the forehead and keeps the profile narrow.
        val fringe = Path().apply {
            moveTo(-58f, -272f)
            quadraticBezierTo(-63f, -320f, -11f, -328f)
            quadraticBezierTo(42f, -333f, 55f, -288f)
            quadraticBezierTo(30f, -294f, 9f, -304f)
            quadraticBezierTo(-17f, -283f, -58f, -272f)
            close()
        }
        drawPath(fringe, Color(0xFFF2D08A))
        drawPath(fringe, hairShade.copy(alpha = .8f),
            style = Stroke(width = 1.7f))
    } else {
        // Front face: large eyes, restrained cheeks and permanent round glasses.
        drawOval(skinShadow, Offset(-62f, -312f), Size(124f, 135f))
        drawOval(skinLight, Offset(-60f, -315f), Size(120f, 135f))
        for (ear in listOf(-59f, 59f)) {
            drawCircle(skinShadow, 13f, Offset(ear, -251f))
            drawCircle(skinLight, 11f, Offset(ear, -253f))
        }
        for (eye in listOf(-27f, 27f)) {
            drawLine(Color(0xFFAA7E72), Offset(eye - 12f, -282f),
                Offset(eye + 11f, -282f), 2.6f, cap = StrokeCap.Round)
            drawOval(Color(0xFFFDFBF9), Offset(eye - 13f, -277f),
                Size(27f, 34f))
            drawCircle(iris, 9.1f, Offset(eye, -260f))
            drawCircle(Color(0xFF343A3C), 5.3f, Offset(eye, -260f))
            drawCircle(Color.White, 3.7f, Offset(eye + 3f, -267f))
            // Transparent lenses indicated with subtle specular strokes.
            drawCircle(Color(0xFF987B90), 23f, Offset(eye, -261f),
                style = Stroke(width = 3.4f))
            drawLine(Color.White.copy(alpha = .42f),
                Offset(eye - 14f, -277f), Offset(eye - 7f, -280f),
                2.3f, cap = StrokeCap.Round)
        }
        drawLine(Color(0xFF987B90), Offset(-2f, -263f), Offset(2f, -263f),
            3.5f, cap = StrokeCap.Round)
        for (sideX in listOf(-1f, 1f)) {
            drawLine(Color(0xFF987B90),
                Offset(sideX * 51f, -264f), Offset(sideX * 66f, -261f),
                2.8f, cap = StrokeCap.Round)
        }
        drawOval(Color(0xFFF5AFA6).copy(alpha = .43f),
            Offset(-53f, -236f), Size(26f, 16f))
        drawOval(Color(0xFFF5AFA6).copy(alpha = .43f),
            Offset(27f, -236f), Size(26f, 16f))
        drawLine(skinShadow, Offset(0f, -249f), Offset(1f, -240f), 2.3f)
        val smile = Path().apply {
            moveTo(-13f, -222f)
            quadraticBezierTo(0f, -210f, 14f, -222f)
        }
        drawPath(smile, Color(0xFFB36A77), style = Stroke(
            width = 3.3f, cap = StrokeCap.Round))
        for (freckle in listOf(-45f, -38f, 35f, 42f)) {
            drawCircle(Color(0xFFDFA390).copy(alpha = .54f), 1.8f,
                Offset(freckle, -234f))
        }

        val fringe = Path().apply {
            moveTo(-66f, -261f)
            quadraticBezierTo(-86f, -336f, 0f, -339f)
            quadraticBezierTo(78f, -332f, 66f, -261f)
            quadraticBezierTo(57f, -306f, 25f, -307f)
            quadraticBezierTo(7f, -292f, -12f, -300f)
            quadraticBezierTo(-39f, -280f, -66f, -261f)
            close()
        }
        drawPath(fringe, Brush.verticalGradient(
            listOf(Color(0xFFFFE7AD), honeyHair, Color(0xFFD8B26E)),
            startY = -335f, endY = -256f))
        drawPath(fringe, hairShade.copy(alpha = .7f), style = Stroke(width = 2f))
        drawLine(Color(0xFFFFEBB7).copy(alpha = .85f),
            Offset(-25f, -323f), Offset(-3f, -304f), 4f,
            cap = StrokeCap.Round)
    }
}
