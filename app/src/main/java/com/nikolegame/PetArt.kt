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

/**
 * v0.12 — five completely redrawn, coordinated children's-book pets.
 * Geometry uses world-space feet as origin, so game movement and depth
 * sorting remain unchanged. All details are native Compose Canvas shapes.
 */
internal fun DrawScope.renderPet(
    type: String, x: Float, footY: Float, tick: Int, moving: Boolean
) {
    val gait = if(moving) sin(tick * .11f) else 0f
    val bob = if(moving) -abs(gait) * 2.4f else sin(tick * .045f) * .95f
    val breathe = sin(tick * .046f) * 1.1f
    val flying = type=="parrot"
    withTransform({ translate(x, footY) }) {
        val w=if(flying)57f else if(type=="turtle")134f else 113f
        drawOval(Color(0xFF64515B).copy(alpha=if(flying).065f else .14f),
            Offset(-w*.5f,-9f),Size(w,if(flying)9f else 16f))
        withTransform({
            // The little parrot hovers well above the floor and flaps in place
            // even between roaming destinations. Its small shadow stays below.
            val floatY = if(flying) -86f+sin(tick*.045f)*12f
                else 0f
            translate(0f,bob+floatY)
            val scaleFactor=if(flying) .67f else 1.08f
            scale(scaleFactor,scaleFactor,Offset.Zero)
        }) {
            when(type) {
                "cat" -> drawStoryCat(tick,gait,breathe)
                "hamster" -> drawStoryHamster(tick,gait,breathe)
                "turtle" -> drawStoryTurtle(tick,gait,breathe)
                "parrot" -> drawStoryParrot(tick,gait,breathe)
                else -> drawStoryDog(tick,gait,breathe)
            }
        }
    }
}

private val outline = Color(0xFF73636C)
private val eyeInk = Color(0xFF342F41)
private val milk = Color(0xFFFFF6EA)
private fun DrawScope.softLine(a:Offset,b:Offset,c:Color=outline,width:Float=2f) {
    drawLine(c,a,b,width,cap=StrokeCap.Round)
}
private fun DrawScope.petDot(x:Float,y:Float,r:Float,color:Color) {
    drawCircle(color,r,Offset(x,y))
}
private fun DrawScope.eye(x:Float,y:Float,r:Float,blink:Boolean=false,
    iris:Color=Color(0xFF746675)) {
    if(blink) {
        softLine(Offset(x-r*.95f,y),Offset(x+r*.95f,y),
            Color(0xFF6D5666),2.5f)
    } else {
        petDot(x,y,r+1.6f,Color.White)
        petDot(x+.8f,y+1f,r*.75f,iris)
        petDot(x+1.6f,y+.9f,r*.49f,eyeInk)
        petDot(x-r*.22f,y-r*.31f,r*.26f,Color.White)
    }
}
private fun DrawScope.paw(x:Float,y:Float,base:Color,mark:Color,shift:Float=0f) {
    drawRoundRect(base,Offset(x-12f,y-25f+shift),Size(24f,28f),
        CornerRadius(11f))
    drawOval(base,Offset(x-13f,y-10f+shift),Size(26f,13f))
    for(i in -1..1)petDot(x+i*6.5f,y-5.5f+shift,1.6f,mark)
}
private fun DrawScope.cheek(x:Float,y:Float,r:Float=7f) {
    petDot(x,y,r,Color(0xFFE89EAA).copy(alpha=.40f))
}
private fun DrawScope.smile(x:Float,y:Float,c:Color=Color(0xFF956875)) {
    val p=Path().apply {
        moveTo(x-8f,y-2f)
        quadraticBezierTo(x,y+6.5f,x+8f,y-2f)
    }
    drawPath(p,c,style=Stroke(width=2.1f,cap=StrokeCap.Round))
}

// Golden, soft-eared puppy with a round, coherent face and short sturdy paws.
private fun DrawScope.drawStoryDog(tick:Int,gait:Float,breath:Float) {
    val coat=Color(0xFFE5B38D)
    val shade=Color(0xFFC78D6B)
    val warm=Color(0xFFF6CCA5)
    val blink=tick%182 in 0..5
    val wag=sin(tick*.15f)*9f

    // Tail and rear legs behind the torso.
    val tail=Path().apply {
        moveTo(-48f,-39f)
        quadraticBezierTo(-80f,-53f+wag,-76f,-76f+wag)
    }
    drawPath(tail,shade,style=Stroke(width=12f,cap=StrokeCap.Round))
    paw(-33f,-1f,shade,Color(0xFFAA7765),gait*3f)
    paw(13f,-1f,shade,Color(0xFFAA7765),-gait*3f)
    drawOval(shade,Offset(-58f,-86f+breath*.4f),Size(111f,76f))
    drawOval(Brush.verticalGradient(listOf(warm,coat,shade),
        startY=-83f,endY=-17f),Offset(-55f,-87f+breath*.4f),Size(107f,70f))
    // Large clean cream chest and only a few accent hairs.
    drawOval(milk,Offset(1f,-65f),Size(40f,42f))
    softLine(Offset(15f,-39f),Offset(19f,-33f),
        Color(0xFFE7C7AE),2f)

    // Draw the head FIRST. The floppy ears must be in the FOREGROUND
    // and outside the cheek contour, otherwise the circular head hides them.
    drawCircle(Color(0xFFD09D7A),41f,Offset(44f,-80f))
    drawCircle(coat,39f,Offset(44f,-84f))
    val leftEar=Path().apply {
        moveTo(15f,-116f)
        quadraticBezierTo(-8f,-125f,-13f,-100f)
        quadraticBezierTo(-21f,-74f,-8f,-57f)
        quadraticBezierTo(8f,-49f,15f,-71f)
        quadraticBezierTo(19f,-96f,15f,-116f)
        close()
    }
    drawPath(leftEar,shade)
    val leftInside=Path().apply {
        moveTo(6f,-105f)
        quadraticBezierTo(-10f,-101f,-7f,-78f)
        quadraticBezierTo(-4f,-66f,1f,-70f)
    }
    drawPath(leftInside,Color(0xFFF0C09E),
        style=Stroke(width=5f,cap=StrokeCap.Round))
    val rightEar=Path().apply {
        moveTo(73f,-116f)
        quadraticBezierTo(97f,-124f,102f,-96f)
        quadraticBezierTo(108f,-72f,95f,-57f)
        quadraticBezierTo(79f,-51f,75f,-75f)
        quadraticBezierTo(72f,-101f,73f,-116f)
        close()
    }
    drawPath(rightEar,Color(0xFFB98064))
    val rightInside=Path().apply {
        moveTo(86f,-103f)
        quadraticBezierTo(100f,-94f,93f,-70f)
    }
    drawPath(rightInside,Color(0xFFE5AB89),
        style=Stroke(width=5f,cap=StrokeCap.Round))
    // Two distinct patches and a single connected ivory muzzle.
    drawOval(warm,Offset(16f,-93f),Size(33f,34f))
    drawOval(milk,Offset(24f,-68f),Size(50f,34f))
    drawOval(Color(0xFFFFE3C8),Offset(40f,-66f),Size(37f,23f))
    eye(27f,-91f,6f,blink,Color(0xFF8C665A))
    eye(61f,-91f,6f,blink,Color(0xFF8C665A))
    softLine(Offset(21f,-105f),Offset(31f,-107f),shade,2.3f)
    softLine(Offset(56f,-107f),Offset(65f,-105f),shade,2.3f)
    drawOval(Color(0xFF76545C),Offset(42f,-68f),Size(16f,12f))
    petDot(46f,-65f,2.3f,Color(0xFFEAC5BB))
    smile(51f,-53f)
    cheek(73f,-71f,6f)
    // Two freckles and one soft collar bow, not a scribbled muzzle.
    petDot(35f,-61f,1.7f,shade)
    petDot(39f,-59f,1.6f,shade)
    softLine(Offset(8f,-51f),Offset(57f,-44f),
        Color(0xFFC887A6),5f)
    petDot(40f,-43f,6f,Color(0xFFF1C76E))
    petDot(38f,-45f,2f,Color.White)
}

// Silver tabby kitten: clean whiskers, expressive sage-green eyes and stripes.
private fun DrawScope.drawStoryCat(tick:Int,gait:Float,breath:Float) {
    val silver=Color(0xFFBDC9D8)
    val dark=Color(0xFF8392A7)
    val pale=Color(0xFFEAF0F4)
    val rose=Color(0xFFD599A9)
    val blink=tick%175 in 0..5
    val sway=sin(tick*.065f)*11f
    val tail=Path().apply {
        moveTo(-49f,-35f)
        quadraticBezierTo(-86f,-48f+sway,-76f,-96f+sway)
        quadraticBezierTo(-63f,-122f+sway,-44f,-98f+sway)
    }
    drawPath(tail,dark,style=Stroke(width=12f,cap=StrokeCap.Round))
    // Two tasteful tail bands.
    softLine(Offset(-79f,-82f+sway),Offset(-72f,-88f+sway),
        pale.copy(alpha=.7f),3f)
    paw(-33f,-1f,silver,dark,gait*3f)
    paw(16f,-1f,silver,dark,-gait*3f)
    drawOval(dark,Offset(-58f,-88f+breath*.4f),Size(112f,79f))
    drawOval(Brush.verticalGradient(listOf(pale,silver,dark),
        startY=-91f,endY=-14f),Offset(-56f,-88f+breath*.4f),Size(108f,74f))
    drawOval(pale,Offset(8f,-61f),Size(37f,42f))
    // Restrained tabby markings follow the curve of the back.
    for(i in 0..2) {
        val px=-37f+i*25f
        val stripe=Path().apply {
            moveTo(px,-77f)
            quadraticBezierTo(px+5f,-65f,px+13f,-63f)
        }
        drawPath(stripe,dark.copy(alpha=.52f),
            style=Stroke(width=4f,cap=StrokeCap.Round))
    }

    // Solid pointed ears with visible pink interiors.
    for(ex in listOf(14f,61f)) {
        val ear=Path().apply {
            moveTo(ex-17f,-96f)
            lineTo(ex-8f,-137f)
            quadraticBezierTo(ex+5f,-131f,ex+20f,-98f)
            close()
        }
        drawPath(ear,dark)
        val inner=Path().apply {
            moveTo(ex-6f,-106f)
            lineTo(ex-5f,-126f)
            lineTo(ex+10f,-107f)
            close()
        }
        drawPath(inner,Color(0xFFF0BECB))
    }
    petDot(38f,-86f,38f,dark)
    petDot(38f,-88f,35f,silver)
    for(i in -1..1) {
        softLine(Offset(38f+i*7f,-117f),
            Offset(38f+i*5f,-110f),dark.copy(alpha=.67f),2.6f)
    }
    drawOval(pale,Offset(14f,-79f),Size(49f,27f))
    // Green irises are prominent, not surrounded by many black lines.
    eye(20f,-91f,7f,blink,Color(0xFF95AC83))
    eye(56f,-91f,7f,blink,Color(0xFF95AC83))
    val nose=Path().apply {
        moveTo(33f,-74f);lineTo(43f,-74f);lineTo(38f,-67f);close()
    }
    drawPath(nose,rose)
    softLine(Offset(38f,-67f),Offset(38f,-62f),dark,1.8f)
    smile(38f,-63f,Color(0xFF8E7182))
    cheek(15f,-72f,5f)
    cheek(62f,-72f,5f)
    // Exactly two smoothly spaced whiskers on each side.
    for(side in listOf(-1f,1f))for(i in 0..1){
        val y=-70f+i*8f
        softLine(Offset(38f+side*20f,y),
            Offset(38f+side*51f,y-5f+i*9f),
            dark.copy(alpha=.75f),1.7f)
    }
    softLine(Offset(3f,-47f),Offset(47f,-44f),rose,4.2f)
    petDot(23f,-40f,5.4f,Color(0xFFEFCB7F))
    petDot(21f,-42f,1.7f,Color.White)
}

// Rounded little hamster with velvety gold fur, soft cheeks and visible toes.
private fun DrawScope.drawStoryHamster(tick:Int,gait:Float,breath:Float) {
    val honey=Color(0xFFF2C18E)
    val shade=Color(0xFFD69C76)
    val light=Color(0xFFFFEBDD)
    val blink=tick%180 in 0..5
    // Tiny feet visible below a truly round body.
    for(px in listOf(-30f,23f)) {
        drawOval(shade,Offset(px-8f+gait*2f,-12f),
            Size(20f,13f))
        for(i in 0..2)petDot(px-3f+i*5f+gait*2f,
            -4f,1.3f,light)
    }
    for(ex in listOf(-31f,31f)) {
        petDot(ex,-78f,19f,shade)
        petDot(ex,-79f,12f,Color(0xFFF2B6B9))
        petDot(ex-3f,-82f,4f,Color(0xFFFFE0D1))
    }
    drawOval(shade,Offset(-56f,-82f+breath*.2f),Size(112f,78f))
    drawOval(Brush.verticalGradient(
        listOf(Color(0xFFFFD9A8),honey,shade),
        startY=-86f,endY=-6f),Offset(-54f,-85f+breath*.2f),
        Size(108f,78f))
    // A center forehead blaze and two big fluffy cream cheek pads.
    drawOval(Color(0xFFFFDDAE),Offset(-14f,-79f),Size(28f,39f))
    drawOval(light,Offset(-42f,-53f),Size(45f,36f))
    drawOval(light,Offset(-3f,-53f),Size(45f,36f))
    drawOval(Color(0xFFFFF5E7),Offset(-20f,-44f),Size(40f,33f))
    eye(-23f,-62f,6f,blink,Color(0xFF644D49))
    eye(23f,-62f,6f,blink,Color(0xFF644D49))
    cheek(-34f,-43f,6f)
    cheek(34f,-43f,6f)
    // Small pink heart-like nose, open calm smile and few whiskers.
    petDot(0f,-43f,5.2f,Color(0xFFC98491))
    petDot(-1f,-45f,1.6f,Color(0xFFFFE6E4))
    softLine(Offset(0f,-39f),Offset(0f,-35f),shade,1.7f)
    smile(0f,-33f,Color(0xFFA67B7F))
    for(sign in listOf(-1f,1f))for(i in 0..1) {
        val y=-40f+i*8f
        softLine(Offset(sign*15f,y),
            Offset(sign*48f,y-3f+i*7f),
            Color(0xFFBB907F).copy(alpha=.78f),1.45f)
    }
    // Two broad velvety shoulder patches instead of distracting micro-lines.
    drawOval(Color(0xFFE3AB83).copy(alpha=.47f),
        Offset(-45f,-73f),Size(15f,15f))
    drawOval(Color(0xFFE3AB83).copy(alpha=.47f),
        Offset(30f,-73f),Size(15f,15f))
}

// A lifted, three-dimensional domed tortoise: layered shell plates and smiling head.
private fun DrawScope.drawStoryTurtle(tick:Int,gait:Float,breath:Float) {
    val green=Color(0xFF9CC789)
    val belly=Color(0xFFCDE3AA)
    val shell=Color(0xFF71997A)
    val deep=Color(0xFF4F7864)
    val blink=tick%193 in 0..5
    val step=abs(gait)*2f
    // Body and tail are visible around the shell, not a flat stamp.
    val tail=Path().apply {
        moveTo(-52f,-30f);lineTo(-70f,-24f);lineTo(-54f,-17f);close()
    }
    drawPath(tail,green)
    drawOval(belly,Offset(-52f,-38f),Size(112f,33f))
    for((px,py) in listOf(-42f to -20f,5f to -18f,30f to -20f,51f to -17f)) {
        drawOval(Color(0xFF80AE7B),Offset(px,py+step),
            Size(30f,20f))
        drawOval(green,Offset(px+2f,py-3f+step),Size(25f,20f))
        for(i in 0..1)petDot(px+10f+i*7f,py+12f+step,
            1.9f,milk)
    }
    // Round smiling neck/head comes out the side of the shell.
    drawOval(green,Offset(29f,-57f+breath),Size(69f,52f))
    drawOval(belly,Offset(60f,-32f+breath),Size(30f,24f))
    eye(68f,-42f+breath,6f,blink,Color(0xFF526C53))
    cheek(81f,-27f+breath,5.4f)
    petDot(89f,-33f+breath,1.7f,deep)
    val grin=Path().apply {
        moveTo(76f,-21f+breath)
        quadraticBezierTo(84f,-14f+breath,92f,-23f+breath)
    }
    drawPath(grin,deep,style=Stroke(width=2f,cap=StrokeCap.Round))
    for((xx,yy) in listOf(49f to -27f,57f to -35f)) {
        petDot(xx,yy+breath,2.4f,Color(0xFF7FA981))
    }

    // Solid domed shell. The bottom rim is a smooth uninterrupted
    // curve; NO plates extend into or below it.
    drawOval(deep,Offset(-62f,-79f),Size(124f,67f))
    drawOval(Brush.verticalGradient(
        listOf(Color(0xFFB8D9A4),shell,deep),
        startY=-85f,endY=-14f),Offset(-59f,-85f),
        Size(118f,72f))
    // Five compact overlapping-looking hexagons arranged safely INSIDE
    // the dome; the pale outlines never cross the bottom rim.
    val plates=listOf(
        -31f to -52f, 0f to -59f, 31f to -52f,
        -17f to -36f, 17f to -36f
    )
    for((i,plate) in plates.withIndex()){
        val cx=plate.first; val cy=plate.second
        val radius=if(i>=3) 9.5f else 10.5f
        val tile=Path().apply {
            moveTo(cx-radius,cy)
            lineTo(cx-radius*.5f,cy-radius*.88f)
            lineTo(cx+radius*.5f,cy-radius*.88f)
            lineTo(cx+radius,cy)
            lineTo(cx+radius*.5f,cy+radius*.88f)
            lineTo(cx-radius*.5f,cy+radius*.88f)
            close()
        }
        drawPath(tile,Color(0xFF9FBF91).copy(alpha=.35f))
        drawPath(tile,Color(0xFFD5E8BD),
            style=Stroke(width=2.1f,cap=StrokeCap.Round))
        if(i==1 || i==3)petDot(cx-2f,cy-2f,2.3f,
            Color.White.copy(alpha=.42f))
    }
    // A single light border closes the shell, with no pale bar running
    // through the pattern or separating the legs from the body.
    val rim=Path().apply {
        moveTo(-55f,-24f)
        quadraticBezierTo(0f,-7f,55f,-24f)
    }
    drawPath(rim,Color(0xFFD7E9BA),
        style=Stroke(width=5f,cap=StrokeCap.Round))
    petDot(-31f,-73f,4f,Color.White.copy(alpha=.22f))
}

// Turquoise parrot STANDING ON THE FLOOR, not attached to a permanent perch.
private fun DrawScope.drawStoryParrot(tick:Int,gait:Float,breath:Float) {
    val jade=Color(0xFF78C0AD)
    val dark=Color(0xFF458E8E)
    val pale=Color(0xFFE4F2D5)
    val lime=Color(0xFFB8D58C)
    val blink=tick%181 in 0..4
    val flap=sin(tick*.24f)
    val wingMove=flap*21f
    val crest=sin(tick*.05f)*2f
    // Three long back feathers replace the old wooden pole.
    for(i in 0..2) {
        val p=Path().apply {
            moveTo(-17f+i*8f,-92f)
            quadraticBezierTo(-41f+i*12f,-34f,-26f+i*11f,-13f)
        }
        drawPath(p,if(i==1)lime else dark,
            style=Stroke(width=9f,cap=StrokeCap.Round))
    }
    // The right wing stretches behind the torso in a flying stroke.
    // The wing tip moves up and down while the head remains steady.
    val backWing=Path().apply {
        moveTo(20f,-121f)
        quadraticBezierTo(58f,-153f-wingMove,83f,-140f-wingMove*1.6f)
        quadraticBezierTo(74f,-96f-wingMove,25f,-82f)
        close()
    }
    drawPath(backWing,Color(0xFF589F94))
    drawPath(backWing,Color(0xFFB2DBA5).copy(alpha=.78f),
        style=Stroke(width=2.1f))
    // Dangling feet, not feet planted on the floor or attached to a pole.
    for(px in emptyList<Float>()) {
        softLine(Offset(px,-28f),Offset(px+2f,-13f),
            Color(0xFF98766D),4.3f)
        for(i in -1..1) {
            softLine(Offset(px+2f,-13f),Offset(px+i*7f,-7f),
                Color(0xFFA88773),2.5f)
        }
    }
    // Plump upright breast and rounded shoulders.
    drawOval(dark,Offset(-45f,-139f+breath),Size(89f,120f))
    drawOval(Brush.verticalGradient(
        listOf(Color(0xFFA3DAC3),jade,dark),
        startY=-144f,endY=-22f),
        Offset(-43f,-143f+breath),Size(86f,118f))
    drawOval(pale,Offset(-1f,-127f),Size(40f,81f))
    // Visible left wing: wide curved feathers animated in flight.
    val frontWing=Path().apply {
        moveTo(-24f,-119f)
        quadraticBezierTo(-57f,-139f-wingMove,
            -84f,-132f-wingMove*1.7f)
        quadraticBezierTo(-85f,-100f-wingMove,
            -42f,-57f)
        quadraticBezierTo(-26f,-74f,-24f,-119f)
        close()
    }
    drawPath(frontWing,Color(0xFF4EABA8))
    for(i in 0..3){
        val yy=-105f+i*11f-wingMove*.5f
        softLine(Offset(-68f+i*3f,yy),Offset(-43f,yy+19f),
            Color(0xFFA4D9CD),2.4f)
    }
    // Connected head, broad cheek and lively soft feather crest.
    petDot(5f,-151f+breath,38f,dark)
    petDot(5f,-154f+breath,36f,jade)
    drawOval(lime,Offset(-21f,-190f),Size(28f,21f))
    for(i in 0..2) {
        val tip=-211f-(i%2)*6f+crest
        softLine(Offset(-10f+i*11f,-183f),
            Offset(-14f+i*11f,tip),
            if(i==1)lime else Color(0xFF66AE91),4.3f)
    }
    // White eye ring, dark pupil and a readable curved golden beak.
    drawOval(Color(0xFFE6FAEE),Offset(4f,-171f),
        Size(25f,26f))
    eye(18f,-159f,6f,blink,Color(0xFF557569))
    cheek(24f,-141f,5.6f)
    val beak=Path().apply {
        moveTo(28f,-157f)
        quadraticBezierTo(51f,-153f,40f,-140f)
        quadraticBezierTo(35f,-135f,28f,-138f)
        close()
    }
    drawPath(beak,Color(0xFFF2BF73))
    softLine(Offset(30f,-145f),Offset(40f,-143f),
        Color(0xFFBE965C),1.8f)
    // A few broad breast feathers, not dense thin scribbles.
    for(i in 0..2) {
        val y=-103f+i*18f
        val p=Path().apply {
            moveTo(13f,y)
            quadraticBezierTo(20f,y+7f,28f,y+1f)
        }
        drawPath(p,Color(0xFFB7D7B3).copy(alpha=.86f),
            style=Stroke(width=2f,cap=StrokeCap.Round))
    }
}
