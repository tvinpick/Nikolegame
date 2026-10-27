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
        withTransform({
            translate(0f, bob)
            // Larger silhouettes keep facial and feather detail readable
            // on a small landscape Android screen.
            scale(if(type=="parrot") 1.06f else 1.13f,
                if(type=="parrot") 1.06f else 1.13f,
                Offset.Zero)
        }) {
            when (type) {
                "cat" -> paintKitten(tick, walk)
                "parrot" -> paintParrot(tick)
                "hamster" -> paintHamster(tick, walk)
                "turtle" -> paintTurtle(tick, walk)
                else -> paintPuppy(tick, walk)
            }
            paintFinePetDetails(type, tick, walk)
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


// v0.11: second pass of fine, species-specific vector details.
// All marks are attached to their host animal and animate with its gait.
private fun DrawScope.fineStroke(
    from:Offset,to:Offset,color:Color,width:Float=2f
) = drawLine(color,from,to,width,cap=StrokeCap.Round)

private fun DrawScope.fineTuft(
    x:Float,y:Float,shade:Color,length:Float=10f
) {
    val tuft=Path().apply {
        moveTo(x-length*.6f,y+4f)
        quadraticBezierTo(x-2f,y-4f,x,y-length)
        quadraticBezierTo(x+4f,y-1f,x+length*.7f,y+4f)
    }
    drawPath(tuft,shade,style=Stroke(width=2.2f,cap=StrokeCap.Round))
}

private fun DrawScope.paintFinePetDetails(type:String,tick:Int,walk:Float) {
    val ivory=Color(0xFFFFF8EE)
    when(type){
        "dog" -> {
            val shade=Color(0xFFBD886B)
            // Individual fur strands on the back and down the chest.
            for(i in 0..6){
                val xx=-43f+i*13f
                val yy=-77f + (i%2)*4f
                fineStroke(Offset(xx,yy),
                    Offset(xx+5f,yy-7f),ivory.copy(alpha=.55f),2.1f)
            }
            for(i in 0..4){
                val xx=-3f+i*7f
                fineStroke(Offset(xx,-43f+(i%2)*5f),
                    Offset(xx+4f,-34f+(i%2)*5f),
                    ivory.copy(alpha=.78f),1.7f)
            }
            // Caramel patch over the floppy ear and a warm inner fold.
            drawOval(Color(0xFF9E705E).copy(alpha=.45f),
                Offset(65f,-102f),Size(13f,30f))
            drawOval(Color(0xFFF6CCA4).copy(alpha=.63f),
                Offset(14f,-110f),Size(11f,29f))
            // Blush, eyebrow expressions and warm muzzle freckles.
            drawCircle(Color(0xFFE9A8A2).copy(alpha=.38f),
                9f,Offset(72f,-69f))
            fineStroke(Offset(22f,-102f),Offset(32f,-105f),shade,2.3f)
            fineStroke(Offset(57f,-104f),Offset(65f,-101f),shade,2.3f)
            for(i in 0..2)drawCircle(shade.copy(alpha=.72f),1.9f,
                Offset(36f+i*9f,-59f+(i%2)*4f))
            val mouth=Path().apply{
                moveTo(51f,-54f)
                quadraticBezierTo(53f,-48f,59f,-50f)
                quadraticBezierTo(65f,-52f,66f,-54f)
            }
            drawPath(mouth,Color(0xFF885E62),style=Stroke(width=2f))
            drawOval(Color(0xFFFFF0DF).copy(alpha=.58f),
                Offset(-27f,-54f),Size(25f,16f))
            // Toe divisions, so the paws are not featureless capsules.
            for(px in listOf(-31f,21f)){
                for(j in 0..2)drawCircle(shade.copy(alpha=.72f),
                    1.9f,Offset(px-8f+j*8f+walk*2f,-6f))
            }
            // A tiny enamel heart on the collar.
            drawCircle(Color(0xFFFFDCA2),5.7f,Offset(43f,-42f))
            drawCircle(Color(0xFFFFF8E5),2.3f,Offset(42f,-44f))
        }
        "cat" -> {
            val stripe=Color(0xFF8293A7)
            // Delicate individually drawn coat markings and facial stripes.
            for(i in 0..3) {
                val xx=-42f+i*22f
                val mark=Path().apply{
                    moveTo(xx,-78f)
                    quadraticBezierTo(xx+4f,-65f,xx+10f,-63f)
                }
                drawPath(mark,stripe.copy(alpha=.55f),
                    style=Stroke(width=4f,cap=StrokeCap.Round))
            }
            for(sgn in listOf(-1f,1f)){
                for(i in 0..1){
                    val yy=-83f+i*12f
                    fineStroke(Offset(38f+sgn*22f,yy),
                        Offset(38f+sgn*33f,yy+6f),
                        stripe.copy(alpha=.66f),2.4f)
                }
            }
            for(i in 0..2) {
                fineStroke(Offset(-77f+i*6f,-84f),
                    Offset(-73f+i*6f,-93f),Color(0xFFA3AEBC),3f)
            }
            // Glossy nose and whisker-root freckles.
            drawCircle(Color(0xFFFFE6EF).copy(alpha=.85f),
                1.8f,Offset(36f,-76f))
            for(sign in listOf(-1f,1f)) {
                for(i in 0..2)drawCircle(stripe.copy(alpha=.7f),
                    1.4f,Offset(39f+sign*(10f+i*5f),-65f+(i%2)*4f))
            }
            fineStroke(Offset(39f,-68f),Offset(39f,-62f),stripe,1.8f)
            val smile=Path().apply{
                moveTo(29f,-62f);quadraticBezierTo(34f,-56f,39f,-61f)
                quadraticBezierTo(46f,-56f,51f,-62f)
            }
            drawPath(smile,stripe,style=Stroke(width=1.8f,cap=StrokeCap.Round))
            for(x in listOf(-28f,22f))for(i in 0..2){
                drawCircle(Color(0xFFF9F9FC).copy(alpha=.9f),
                    2.2f,Offset(x+i*6f,-5.5f))
            }
            fineTuft(-12f,-83f,Color(0xFFDDE5EB),9f)
            // Shining collar bell.
            drawCircle(Color(0xFFE6B65C),5.3f,Offset(20f,-35f))
            drawCircle(ivory,1.8f,Offset(18f,-37f))
        }
        "hamster" -> {
            val cocoa=Color(0xFFB88875)
            // Distinct silky fur parting on top, golden patches.
            for(i in 0..5){
                val xx=-39f+i*16f
                fineStroke(Offset(xx,-71f+(i%2)*5f),
                    Offset(xx+7f,-76f+(i%2)*5f),
                    Color(0xFFFFE4BF).copy(alpha=.84f),2.2f)
            }
            drawOval(Color(0xFFFFE6C1).copy(alpha=.75f),
                Offset(-10f,-81f),Size(21f,25f))
            for(side in listOf(-1f,1f)){
                drawCircle(Color(0xFFDC989B).copy(alpha=.41f),
                    11f,Offset(side*29f,-43f))
                for(j in 0..2)drawCircle(cocoa,1.65f,
                    Offset(side*(8f+j*8f),-40f+(j%2)*5f))
                // Curved ear fold shows inner shape.
                val cx=side*27f
                drawArc(cocoa.copy(alpha=.70f),180f,170f,false,
                    Offset(cx-9f,-91f),Size(19f,19f),
                    style=Stroke(width=2f))
                for(j in 0..2)fineStroke(
                    Offset(side*10f,-40f+j*6f),
                    Offset(side*(46f+j*3f),-48f+j*10f),
                    cocoa.copy(alpha=.65f),1.3f)
            }
            for(x in listOf(-25f,19f)) for(j in 0..2)
                drawCircle(Color(0xFFF7DDC8),2f,
                    Offset(x+j*7f+walk*2f,-6f))
            drawCircle(Color(0xFFFFF6EB),1.6f,Offset(-2f,-45f))
            // Animated little whiskers twitch, with no new large object.
            fineStroke(Offset(-7f,-36f),Offset(-13f,-32f),cocoa,1.5f)
            fineStroke(Offset(7f,-36f),Offset(13f,-32f),cocoa,1.5f)
        }
        "turtle" -> {
            val dark=Color(0xFF436E59)
            val shell=Color(0xFFE7E8B4)
            // Shell plate centers: individual raised hexagonal scales.
            val plateCenters=listOf(
                -29f to -55f,0f to -63f,31f to -54f,
                -16f to -31f,18f to -31f
            )
            for((i,p) in plateCenters.withIndex()){
                val (cx,cy)=p
                drawOval(Color(0xFF315F55).copy(alpha=.20f),
                    Offset(cx-7f,cy-6f),Size(17f,12f))
                drawCircle(shell.copy(alpha=.70f),3f,
                    Offset(cx-2f,cy-2f))
                if(i%2==0)fineStroke(
                    Offset(cx+6f,cy-6f),Offset(cx+10f,cy-3f),
                    shell.copy(alpha=.77f),1.7f)
            }
            for(i in 0..7){
                val xx=-48f+i*14f
                drawCircle(Color(0xFFECEDC7).copy(alpha=.88f),
                    2.2f,Offset(xx,-19f))
            }
            // Little toenails, plus cheek spots and a curved smile.
            for(xx in listOf(-40f,-3f,31f,53f)){
                for(j in 0..1)drawOval(Color(0xFFF9F6D9),
                    Offset(xx+7f+j*5f,-8f),Size(5f,4f))
            }
            for(i in 0..2)drawCircle(dark.copy(alpha=.48f),
                2f,Offset(55f+i*9f,-19f+(i%2)*4f))
            val smile=Path().apply{
                moveTo(72f,-18f)
                quadraticBezierTo(82f,-11f,89f,-20f)
            }
            drawPath(smile,dark,style=Stroke(width=2f))
            fineTuft(16f,-75f,Color(0xFFE2EECA).copy(alpha=.72f),8f)
            // Shell glint animates subtly with breathing.
            val shine=.43f+.15f*sin(tick*.04f)
            drawCircle(Color.White.copy(alpha=shine),5f,
                Offset(-18f,-65f))
        }
        "parrot" -> {
            val blue=Color(0xFF317F84)
            // Layered individual turquoise and lime feathers.
            for(i in 0..5){
                val y=-152f+i*10f
                val c=if(i%2==0)Color(0xFFC1E3BE) else Color(0xFF8DD6C3)
                val feather=Path().apply{
                    moveTo(-37f+i*2f,y)
                    quadraticBezierTo(-22f,y+13f,-5f,y+8f)
                }
                drawPath(feather,c.copy(alpha=.9f),
                    style=Stroke(width=2.5f,cap=StrokeCap.Round))
            }
            for(i in 0..2) {
                val xx=-9f+i*11f
                fineStroke(Offset(xx,-212f),
                    Offset(xx-7f+sin(tick*.07f)*2f,-227f-(i%2)*5f),
                    Color(0xFF58A48A),4.2f)
                drawCircle(Color(0xFFBDE4B4),3f,
                    Offset(xx-7f,-227f-(i%2)*5f))
            }
            // Contrasting throat collar, belly feather outlines and cheek.
            for(i in 0..5){
                drawOval(Color(0xFFFCF1D7).copy(alpha=.68f),
                    Offset(1f+(i%2)*9f,-133f+i*8f),Size(11f,5f))
            }
            drawCircle(Color(0xFFEFB4A1).copy(alpha=.55f),
                8f,Offset(25f,-168f))
            val beak=Path().apply{
                moveTo(31f,-169f)
                quadraticBezierTo(45f,-158f,26f,-153f)
            }
            drawPath(beak,Color(0xFFCB9559),
                style=Stroke(width=2f))
            drawCircle(Color.White.copy(alpha=.76f),3f,
                Offset(9f,-187f))
            // Three toes clutch the perch.
            for(x in listOf(-15f,10f)){
                for(i in -1..1)fineStroke(
                    Offset(x,-77f),Offset(x+i*7f,-70f),
                    Color(0xFF7F6860),2.1f)
            }
            // Fine horizontal strokes on tail tips.
            for(i in 0..2)fineStroke(
                Offset(-21f+i*12f,-76f),Offset(-19f+i*12f,-66f),
                blue.copy(alpha=.83f),2.4f)
        }
    }
}
