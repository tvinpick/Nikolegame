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

// Nicole v0.5.3: balanced leg and torso lengths, same narrow silhouette and all-direction hairstyles.
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
// Slim geometric silhouette: shorter tapered top, longer narrow legs and distinct head art.
private fun DrawScope.paintNicoleFigure(
    walking: Boolean, legSwing: Float, armSwing: Float,
    side: Boolean, back: Boolean, tick: Int
) {
    // The torso is actually redrawn slimmer, not squashed from a wide sprite.
    // Both passes share the same floor anchor and remain independent of hitboxes.
    paintNicoleBody(walking, legSwing, armSwing, side, back)
    withTransform({
        translate(0f, -3f)
        scale(0.83f, 0.83f, Offset(0f, -204f))
    }) {
        paintNicoleHead(side, back, tick)
    }
}

private fun DrawScope.paintNicoleBody(
    walking: Boolean, legSwing: Float, armSwing: Float,
    side: Boolean, back: Boolean
) {
    // v0.5.3: legs are ~12% shorter (hip -132 instead of -147), and
    // the unchanged narrow shirt is ~15 units taller (hem -116 vs -131).
    // Feet and head stay at their former positions, preserving depth/scale.
    val pant = Color(0xFF729CC5)
    val pantShade = Color(0xFF4C719C)
    val legSpacing = if (side) 8f else 17f
    for (sign in listOf(-1f, 1f)) {
        val swing = (if (sign < 0) legSwing else -legSwing) * if (side) .45f else 1f
        val hipX = sign * legSpacing
        val kneeX = hipX + swing * .6f
        val ankleX = hipX + swing
        drawLine(pantShade, Offset(hipX, -132f), Offset(kneeX, -68f),
            strokeWidth = 22f, cap = StrokeCap.Round)
        drawLine(pant, Offset(kneeX, -69f), Offset(ankleX, -25f),
            strokeWidth = 19f, cap = StrokeCap.Round)
        drawLine(Color(0xFFB1D0E7).copy(alpha = .48f),
            Offset(kneeX - 4f, -66f), Offset(ankleX - 4f, -36f),
            strokeWidth = 2f, cap = StrokeCap.Round)
        val lift = if (walking && swing > 3f) -3.5f else 0f
        drawRoundRect(Color(0xFFD6CDD0), Offset(ankleX - 19f, -22f + lift),
            Size(38f, 18f), CornerRadius(9f))
        drawRoundRect(Color.White, Offset(ankleX - 19f, -26f + lift),
            Size(38f, 17f), CornerRadius(8f))
        drawLine(Color(0xFFD9C7CB), Offset(ankleX - 10f, -11f + lift),
            Offset(ankleX + 10f, -11f + lift), 2f)
    }
    // Narrow waistband under the shirt.
    drawRoundRect(pantShade, Offset(if(side) -23f else -26f, -138f),
        Size(if(side) 46f else 52f, 23f), CornerRadius(8f))
    drawLine(Color(0xFFABC9E0), Offset(-17f, -130f),
        Offset(17f, -130f), 2f)

    // Small, slim arms. Keep wrists close to the body.
    val shoulder = if(side) 22f else 31f
    for (sign in listOf(-1f, 1f)) {
        val startX = sign * shoulder
        val endX = startX + sign * 4f + (if (walking) armSwing * sign * .45f else 0f)
        val endY = -119f + (if (walking) armSwing * sign * .22f else 0f)
        drawLine(skinShadow.copy(alpha = .4f), Offset(startX + 1f, -181f),
            Offset(endX + 1f, endY), 11f, cap = StrokeCap.Round)
        drawLine(skinLight, Offset(startX, -181f),
            Offset(endX, endY), 10f, cap = StrokeCap.Round)
        drawCircle(skinLight, 5.5f, Offset(endX, endY + 3f))
    }

    // Tapered shirt: natural child's narrow shoulders and a short, neat hem.
    val shoulders = if (side) 20f else 31f
    val waist = if (side) 17f else 23f
    val shirt = Path().apply {
        moveTo(-20f, -193f)
        quadraticBezierTo(-shoulders, -189f, -shoulders, -175f)
        lineTo(-waist, -128f)
        quadraticBezierTo(-waist - 2f, -119f, -waist + 4f, -116f)
        lineTo(waist - 4f, -116f)
        quadraticBezierTo(waist + 2f, -119f, waist, -128f)
        lineTo(shoulders, -175f)
        quadraticBezierTo(shoulders, -189f, 20f, -193f)
        close()
    }
    drawPath(shirt, Brush.verticalGradient(
        listOf(Color.White, Color(0xFFFFFAF6), Color(0xFFEBDDE0)),
        startY = -193f, endY = -116f))
    drawPath(shirt, Color(0xFFCFB6C0).copy(alpha = .55f),
        style = Stroke(width = 1.7f))
    for (sign in listOf(-1f, 1f)) {
        drawRoundRect(Color(0xFFFFF7F4), Offset(sign * shoulder -
            if (sign < 0) 0f else 10f, -186f), Size(10f, 18f),
            CornerRadius(6f))
    }

    // Light floral pattern only on the front and on the visible side.
    if (!back) {
        val blooms = if(side) listOf(
            Offset(-5f, -169f), Offset(7f, -134f)
        ) else listOf(
            Offset(-15f, -172f), Offset(10f, -179f),
            Offset(3f, -152f), Offset(-10f, -126f), Offset(18f, -134f)
        )
        blooms.forEachIndexed { i, p ->
            drawLine(Color(0xFF9CB89B).copy(alpha = .75f),
                Offset(p.x, p.y + 2f), Offset(p.x + 3f, p.y + 9f), 1.2f)
            for (j in 0..3) {
                val a = j * 1.5707964f
                drawCircle(if(i%2==0) flowerRose else Color(0xFFF1C7C8),
                    2.6f, Offset(p.x + kotlin.math.cos(a) * 3.8f,
                        p.y + kotlin.math.sin(a) * 3.8f))
            }
            drawCircle(Color(0xFFF7D38F), 1.6f, p)
        }
    } else {
        drawLine(Color(0xFFE2CDD1), Offset(0f, -190f),
            Offset(0f, -141f), 1.5f)
    }
}

private fun DrawScope.paintNicoleHead(side: Boolean, back: Boolean, tick: Int) {
    // These are THREE independently drawn head-and-hair silhouettes.
    // Horizontal left is the mirror of the complete right-facing profile.
    // A shared front-facing wig must never appear under another face.
    if (back) {
        paintNicoleBackHair(tick)
    } else if (side) {
        paintNicoleSideHead(tick)
    } else {
        paintNicoleFrontHead(tick)
    }
}

private fun DrawScope.paintNicoleFrontHead(tick: Int) {
    val sway = sin(tick * .045f) * 1.4f
    // Neck shows through just above the tapered shirt.
    drawRoundRect(skinLight, Offset(-10f, -210f),
        Size(20f, 29f), CornerRadius(8f))
    // Behind-cheek hair, kept narrow so the shoulders remain visible.
    val backHair = Path().apply {
        moveTo(-52f, -268f)
        quadraticBezierTo(-63f, -329f, -5f, -334f)
        quadraticBezierTo(61f, -332f, 54f, -263f)
        lineTo(57f, -215f)
        quadraticBezierTo(48f, -187f, 38f, -207f)
        quadraticBezierTo(21f, -196f, 16f, -211f)
        quadraticBezierTo(-18f, -198f, -25f, -212f)
        quadraticBezierTo(-45f, -197f, -56f, -216f)
        close()
    }
    drawPath(backHair, Brush.verticalGradient(
        listOf(Color(0xFFFFE7AC), honeyHair, hairShade),
        startY = -335f, endY = -190f))
    drawPath(backHair, hairShade.copy(alpha=.58f),
        style=Stroke(width=2f))

    // Smaller soft cheeks; eyes dominate but do not pop out of the head.
    drawOval(skinShadow, Offset(-49f, -309f), Size(98f, 112f))
    drawOval(skinLight, Offset(-48f, -311f), Size(96f, 112f))
    for (ear in listOf(-47f, 47f)) {
        drawCircle(skinLight, 9f, Offset(ear, -246f))
    }
    for (eye in listOf(-22f, 22f)) {
        drawLine(Color(0xFFAB877C), Offset(eye - 10f, -277f),
            Offset(eye + 11f, -277f), 2f, cap=StrokeCap.Round)
        drawOval(Color.White, Offset(eye - 11f, -271f), Size(23f, 28f))
        drawCircle(iris, 8.2f, Offset(eye, -257f))
        drawCircle(Color(0xFF303846), 4.1f, Offset(eye, -258f))
        drawCircle(Color.White, 3f, Offset(eye+2f, -263f))
        drawCircle(Color(0xFF987B90), 19f, Offset(eye, -258f),
            style=Stroke(width=3f))
    }
    drawLine(Color(0xFF987B90), Offset(-3f,-258f),
        Offset(3f,-258f),3f, cap=StrokeCap.Round)
    drawOval(Color(0xFFF5B7A8).copy(alpha=.42f),
        Offset(-42f,-238f),Size(19f,12f))
    drawOval(Color(0xFFF5B7A8).copy(alpha=.42f),
        Offset(23f,-238f),Size(19f,12f))
    val smile = Path().apply {
        moveTo(-9f, -218f)
        quadraticBezierTo(0f,-212f,9f,-218f)
    }
    drawPath(smile, Color(0xFFB36A77),
        style=Stroke(width=2.7f,cap=StrokeCap.Round))

    // Blond side-parted fringe belongs ONLY to the front-facing haircut.
    val bangs = Path().apply {
        moveTo(-54f, -266f)
        quadraticBezierTo(-65f,-325f,-5f,-336f)
        quadraticBezierTo(53f,-334f,55f,-279f)
        quadraticBezierTo(30f,-299f,12f,-305f)
        quadraticBezierTo(-9f,-283f,-26f,-298f)
        quadraticBezierTo(-37f,-279f,-54f,-266f)
        close()
    }
    drawPath(bangs, Brush.verticalGradient(
        listOf(Color(0xFFFFE9B5),honeyHair,Color(0xFFD9B579)),
        startY=-335f,endY=-266f))
    drawPath(bangs,hairShade.copy(alpha=.6f),
        style=Stroke(width=1.8f))
    for (xx in listOf(-50f,50f)) {
        drawCircle(Color(0xFFEBC581),11f,Offset(xx,-209f+sway))
        drawCircle(Color(0xFFFFE7B2).copy(alpha=.6f),
            4f,Offset(xx-3f,-214f+sway))
    }
}

private fun DrawScope.paintNicoleSideHead(tick:Int) {
    val sway=sin(tick*.045f)*1.2f
    drawRoundRect(skinLight,Offset(-8f,-207f),
        Size(18f,26f),CornerRadius(7f))
    // Hair volume is BEHIND the ear, not a copy of the frontal hairstyle.
    val rearLock=Path().apply {
        moveTo(-56f,-273f)
        quadraticBezierTo(-74f,-323f,-17f,-332f)
        quadraticBezierTo(19f,-332f,30f,-305f)
        quadraticBezierTo(-5f,-275f,-25f,-260f)
        quadraticBezierTo(-31f,-237f,-22f,-214f)
        quadraticBezierTo(-34f,-191f,-53f,-197f)
        quadraticBezierTo(-69f,-218f,-56f,-273f)
        close()
    }
    drawPath(rearLock,Brush.verticalGradient(
        listOf(Color(0xFFFFE9B5),honeyHair,hairShade),
        startY=-334f,endY=-194f))
    drawPath(rearLock,Color(0xFFC7A16B),
        style=Stroke(width=2f))

    // True narrow side-profile from eyebrow to small nose and chin.
    val face=Path().apply {
        moveTo(-31f,-302f)
        quadraticBezierTo(6f,-320f,35f,-299f)
        quadraticBezierTo(44f,-280f,44f,-264f)
        lineTo(53f,-252f)
        quadraticBezierTo(56f,-246f,48f,-241f)
        quadraticBezierTo(48f,-219f,28f,-207f)
        quadraticBezierTo(5f,-194f,-17f,-211f)
        quadraticBezierTo(-40f,-233f,-31f,-302f)
        close()
    }
    drawPath(face,skinLight)
    drawPath(face,skinShadow.copy(alpha=.38f),
        style=Stroke(width=1.8f))
    drawCircle(skinShadow,9f,Offset(-34f,-248f))
    drawCircle(skinLight,8f,Offset(-34f,-250f))
    drawOval(Color.White,Offset(16f,-269f),Size(19f,23f))
    drawCircle(iris,7.8f,Offset(27f,-258f))
    drawCircle(Color(0xFF303846),3.9f,Offset(28f,-258f))
    drawCircle(Color.White,2.2f,Offset(30f,-263f))
    drawCircle(Color(0xFF987B90),17f,Offset(25f,-257f),
        style=Stroke(width=2.7f))
    drawLine(Color(0xFF987B90),Offset(8f,-261f),
        Offset(-35f,-257f),2.6f,cap=StrokeCap.Round)
    drawOval(Color(0xFFF1B7A9).copy(alpha=.38f),
        Offset(25f,-238f),Size(15f,10f))
    drawLine(Color(0xFFAD6E79),Offset(33f,-220f),
        Offset(43f,-223f),2.1f,cap=StrokeCap.Round)

    // Side-specific sweep: forehead bangs + fine back strand,
    // no frontal twin-curls or fixed oval wig.
    val sweep=Path().apply {
        moveTo(-45f,-289f)
        quadraticBezierTo(-51f,-322f,-9f,-333f)
        quadraticBezierTo(32f,-333f,42f,-291f)
        quadraticBezierTo(24f,-298f,14f,-314f)
        quadraticBezierTo(-9f,-282f,-45f,-276f)
        close()
    }
    drawPath(sweep,Color(0xFFF2CF88))
    drawPath(sweep,hairShade.copy(alpha=.63f),
        style=Stroke(width=1.7f))
    drawLine(Color(0xFFFFE7B1).copy(alpha=.7f),
        Offset(-38f,-292f),Offset(-18f,-315f),3.2f,
        cap=StrokeCap.Round)
    drawCircle(Color(0xFFE9C17B),12f,Offset(-51f,-212f+sway))
}

private fun DrawScope.paintNicoleBackHair(tick:Int) {
    // Hair viewed from the back: continuous gently tapered flowing strands,
    // no frontal wig and no horizontal cartoon helmet.
    val sway=sin(tick*.045f)*1.4f
    val silhouette=Path().apply {
        moveTo(-10f,-334f)
        quadraticBezierTo(-59f,-333f,-57f,-275f)
        lineTo(-53f,-219f)
        quadraticBezierTo(-54f,-195f,-39f,-197f)
        quadraticBezierTo(-27f,-204f,-20f,-195f)
        quadraticBezierTo(-7f,-187f,0f,-199f)
        quadraticBezierTo(17f,-190f,24f,-200f)
        quadraticBezierTo(41f,-190f,48f,-208f)
        quadraticBezierTo(54f,-247f,56f,-273f)
        quadraticBezierTo(58f,-331f,-10f,-334f)
        close()
    }
    drawPath(silhouette,Brush.verticalGradient(
        listOf(Color(0xFFFFE3A4),honeyHair,Color(0xFFD9B16E)),
        startY=-335f,endY=-193f))
    drawPath(silhouette,Color(0xFFC19865),
        style=Stroke(width=2.1f))
    for (j in -2..2) {
        val xx=j*17f
        val delta = if(j%2==0) 3f else -2f
        val strand=Path().apply {
            moveTo(xx*.7f,-307f)
            quadraticBezierTo(xx+delta,-265f,xx+sway,-217f)
        }
        drawPath(strand,Color(0xFFFFE9B5).copy(alpha=.65f),
            style=Stroke(width=3f,cap=StrokeCap.Round))
    }
    // End curls are integrated into the hair, not a glued-on band.
    for (x in listOf(-44f,-20f,5f,30f,47f)) {
        drawCircle(Color(0xFFE8C17E),7f,
            Offset(x,-204f+sway*.5f))
    }
}
