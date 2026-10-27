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
import kotlin.math.sin

// Fine vector details layered over the original five approved animal
// silhouettes. No bitmaps, internet access, accounts or external assets.
internal fun DrawScope.drawPetDetails(kind:String,tick:Int,walk:Float) {
    when(kind){
        "cat" -> detailKitten(tick,walk)
        "parrot" -> detailParrot(tick)
        "hamster" -> detailHamster(tick,walk)
        "turtle" -> detailTurtle(tick,walk)
        else -> detailPuppy(tick,walk)
    }
}
private fun DrawScope.fineStroke(a:Offset,b:Offset,color:Color,width:Float=2f){
    drawLine(color,a,b,width,cap=StrokeCap.Round)
}
private fun DrawScope.fineCurve(
    x:Float,y:Float,cx:Float,cy:Float,tx:Float,ty:Float,
    color:Color,width:Float=2f
){
    val path=Path().apply{
        moveTo(x,y);quadraticBezierTo(cx,cy,tx,ty)
    }
    drawPath(path,color,style=Stroke(width=width,cap=StrokeCap.Round))
}

private fun DrawScope.detailPuppy(tick:Int,walk:Float) {
    val sable=Color(0xFFAB755D)
    val umber=Color(0xFF8B615B)
    val highlights=Color(0xFFFFE4C4)
    // Uneven coat patches are inside the torso and don't change its shape.
    drawOval(Color(0xFFC89072).copy(alpha=.64f),
        Offset(-46f,-68f),Size(36f,30f))
    drawOval(highlights.copy(alpha=.68f),Offset(-31f,-75f),Size(32f,18f))
    drawOval(Color(0xFFF9DBC1).copy(alpha=.64f),
        Offset(-18f,-53f),Size(23f,29f))
    // Little hand-drawn tufts along the back and legs.
    for(i in 0..3){
        val x=-38f+i*17f
        fineCurve(x,-76f,x+7f,-86f,x+13f,-74f,
            highlights.copy(alpha=.72f),2.6f)
    }
    for(xx in listOf(-31f,21f)){
        val offset=if(xx<0)walk*3f else -walk*3f
        for(i in 0..2){
            val tx=xx-6f+offset+i*7f
            fineStroke(Offset(tx,-6f),Offset(tx+1f,-11f),umber.copy(alpha=.68f),1.65f)
        }
        drawOval(Color.White.copy(alpha=.33f),Offset(xx-2f+offset,-23f),
            Size(11f,13f))
    }
    // An embroidered-looking, light brown patch surrounding the left eye.
    val eyePatch=Path().apply{
        moveTo(14f,-94f);quadraticBezierTo(7f,-106f,23f,-110f)
        quadraticBezierTo(35f,-103f,33f,-87f)
        quadraticBezierTo(23f,-82f,14f,-94f);close()
    }
    drawPath(eyePatch,sable.copy(alpha=.42f))
    // Keep the original eyes visible on top.
    val blink=tick%183 in 0..5
    if(!blink){
        for(ex in listOf(27f,62f)){
            drawCircle(Color(0xFF332E39),5.9f,Offset(ex,-89f))
            drawCircle(Color.White,2.1f,Offset(ex-1.7f,-91f))
            drawCircle(Color.White.copy(alpha=.70f),.9f,Offset(ex+1.6f,-86f))
        }
    }
    fineCurve(20f,-102f,26f,-106f,34f,-100f,umber.copy(alpha=.55f),2f)
    fineCurve(53f,-101f,61f,-104f,69f,-97f,umber.copy(alpha=.55f),2f)
    // Velvety ears have pink-brown inner surfaces and a lifted highlight.
    drawOval(Color(0xFFB4776C),Offset(13f,-110f),Size(13f,37f))
    drawOval(Color(0xFFC88B79),Offset(66f,-107f),Size(10f,33f))
    fineCurve(11f,-109f,14f,-121f,26f,-112f,highlights.copy(alpha=.67f),2.3f)
    // More expressive muzzle, tiny lip, freckles and an upside-down smile.
    drawOval(Color(0xFF654C53),Offset(44f,-65f),Size(11f,8f))
    drawCircle(Color.White.copy(alpha=.58f),1.8f,Offset(47f,-65f))
    fineCurve(51f,-58f,47f,-51f,41f,-53f,umber,1.9f)
    fineCurve(52f,-58f,57f,-50f,65f,-53f,umber,1.9f)
    for(cx in listOf(32f,37f,68f,72f)){
        drawCircle(umber.copy(alpha=.60f),1.35f,
            Offset(cx,-58f+(cx.toInt()%3)))
    }
    // Tiny bow-shaped ornament around the already present collar.
    val center=Offset(42f,-42f)
    val leftBow=Path().apply{
        moveTo(center.x,center.y)
        quadraticBezierTo(26f,-53f,28f,-39f)
        quadraticBezierTo(28f,-33f,center.x,center.y);close()
    }
    val rightBow=Path().apply{
        moveTo(center.x,center.y)
        quadraticBezierTo(58f,-53f,58f,-42f)
        quadraticBezierTo(59f,-34f,center.x,center.y);close()
    }
    drawPath(leftBow,Color(0xFFEAAAC3))
    drawPath(rightBow,Color(0xFFF5C8D7))
    drawCircle(Color(0xFFFFF1C0),3.3f,center)
    // A soft tail-tip accent follows the existing wag.
    val wag=sin(tick*.21f)*13f
    drawCircle(highlights.copy(alpha=.8f),5f,Offset(-77f,-89f+wag))
}

private fun DrawScope.detailKitten(tick:Int,walk:Float) {
    val slate=Color(0xFF758397)
    val smoke=Color(0xFF8998AE)
    val light=Color(0xFFF3F4F3)
    // Tabby stripes on back: curved markings, not repeated geometric bars.
    for(i in 0..3){
        val x=-43f+i*17f
        fineCurve(x,-65f,x+5f,-52f,x-3f,-46f,
            slate.copy(alpha=.58f),3.5f)
    }
    fineCurve(-33f,-32f,-19f,-22f,-8f,-36f,
        smoke.copy(alpha=.45f),2.5f)
    // Long ringed tail, including its flexible tip.
    val sway=sin(tick*.065f)*10f
    for(i in 0..2){
        fineStroke(
            Offset(-80f+i*5f,-66f+sway+i*11f),
            Offset(-68f+i*4f,-61f+sway+i*11f),
            light.copy(alpha=.82f),4f)
    }
    // Classic M-shape tabby marking between the ears.
    val m=Path().apply{
        moveTo(15f,-108f);lineTo(22f,-101f)
        lineTo(29f,-109f);lineTo(38f,-102f)
        lineTo(47f,-108f)
    }
    drawPath(m,slate.copy(alpha=.75f),style=Stroke(width=2.6f,cap=StrokeCap.Round))
    for(side in listOf(-1f,1f)){
        val x=38f+side*23f
        fineCurve(x,-112f,x-side*3f,-105f,x-side*7f,-100f,
            slate.copy(alpha=.7f),2.2f)
        fineCurve(x,-76f,x+side*8f,-72f,x+side*12f,-79f,
            smoke.copy(alpha=.55f),2.2f)
    }
    // Rounded muzzle puffs and a tiny divided mouth.
    drawOval(light.copy(alpha=.80f),Offset(23f,-77f),Size(17f,15f))
    drawOval(light.copy(alpha=.80f),Offset(39f,-77f),Size(17f,15f))
    val nose=Path().apply{
        moveTo(33f,-75f);lineTo(46f,-75f)
        lineTo(39f,-68f);close()
    }
    drawPath(nose,Color(0xFFD28EA5))
    fineStroke(Offset(39f,-68f),Offset(39f,-62f),slate,1.7f)
    fineCurve(39f,-62f,34f,-57f,30f,-63f,slate,1.6f)
    fineCurve(39f,-62f,44f,-57f,48f,-63f,slate,1.6f)
    for(side in listOf(-1f,1f)){
        for(i in 0..2){
            val x=39f+side*17f
            fineCurve(x,-70f+i*4f,x+side*18f,-73f+i*3f,
                x+side*38f,-74f+i*5f,
                slate.copy(alpha=.74f),1.65f)
        }
    }
    // Fine ear hair and front paw toes.
    for(x in listOf(13f,64f)){
        fineCurve(x-9f,-111f,x-3f,-119f,x+4f,-111f,
            light.copy(alpha=.82f),1.5f)
    }
    for(px in listOf(-29f,24f)){
        val swayFoot=if(px<0)walk*3f else -walk*3f
        for(i in 0..2){
            fineStroke(Offset(px-2f+i*7f+swayFoot,-6f),
                Offset(px-2f+i*7f+swayFoot,-12f),
                slate.copy(alpha=.55f),1.4f)
        }
    }
    for(x in listOf(12f,20f,57f,65f))
        drawCircle(Color(0xFFD6B5C1).copy(alpha=.46f),2f,
            Offset(x,-80f))
}

private fun DrawScope.detailHamster(tick:Int,walk:Float) {
    val warm=Color(0xFFBD886C)
    val amber=Color(0xFFE2AE80)
    val blush=Color(0xFFF5BCC0)
    // Soft irregular saddle and short fur strokes around the round body.
    drawOval(Color(0xFFB78365).copy(alpha=.46f),
        Offset(-11f,-75f),Size(26f,23f))
    drawOval(Color(0xFFFFE2B7).copy(alpha=.63f),
        Offset(-39f,-65f),Size(37f,16f))
    for(i in 0..5){
        val x=-41f+i*15f
        fineCurve(x,-20f,x+3f,-13f,x+8f,-15f,
            Color(0xFFFFE7C9),1.6f)
    }
    // Little ear folds and an inner-edge shine.
    for(xx in listOf(-29f,26f)){
        drawOval(Color(0xFFE89CA5).copy(alpha=.76f),
            Offset(xx-7f,-89f),Size(13f,18f))
        drawOval(Color(0xFFFFE4D7).copy(alpha=.68f),
            Offset(xx-5f,-86f),Size(7f,8f))
    }
    // Distinct puffed cheeks with little textured freckles.
    drawOval(Color(0xFFFFF9EC).copy(alpha=.87f),
        Offset(-40f,-53f),Size(36f,29f))
    drawOval(Color(0xFFFFF9EC).copy(alpha=.87f),
        Offset(3f,-53f),Size(36f,29f))
    for(sign in listOf(-1,1)){
        for(i in 0..2){
            drawCircle(warm.copy(alpha=.55f),1.5f,
                Offset(sign*(17f+i*5f),-42f+(i%2)*5f))
        }
    }
    // Make black round eyes sparkle even in the smallest pet.
    if(tick%181 !in 0..5){
        for(xx in listOf(-23f,23f)){
            drawCircle(Color(0xFF392F37),5.6f,Offset(xx,-61f))
            drawCircle(Color.White,2.1f,Offset(xx-1.8f,-63f))
        }
    }
    drawOval(blush.copy(alpha=.48f),Offset(-36f,-49f),Size(17f,11f))
    drawOval(blush.copy(alpha=.48f),Offset(20f,-49f),Size(17f,11f))
    drawCircle(Color(0xFFC78687),5f,Offset(0f,-43f))
    fineStroke(Offset(0f,-40f),Offset(0f,-35f),warm,1.5f)
    fineCurve(0f,-35f,-4f,-31f,-8f,-34f,warm,1.6f)
    fineCurve(0f,-35f,4f,-31f,8f,-34f,warm,1.6f)
    // Curved whiskers, two layers of tiny paws and individual toes.
    for(side in listOf(-1f,1f)) {
        for(j in 0..2){
            fineCurve(side*9f,-43f+j*4f,side*28f,-49f+j*6f,
                side*47f,-46f+j*7f,warm.copy(alpha=.63f),1.25f)
        }
        val px=side*24f+walk*2f
        drawOval(Color(0xFFF7C4B2),Offset(px-10f,-15f),Size(21f,11f))
        for(i in 0..2)
            fineStroke(Offset(px-5f+i*5f,-6f),
                Offset(px-5f+i*5f,-10f),amber,1.4f)
    }
}

private fun DrawScope.detailTurtle(tick:Int,walk:Float) {
    val shell=Color(0xFF477764)
    val mint=Color(0xFFDCEAC1)
    val olive=Color(0xFF82AE83)
    // Narrow edge plates, staggered in perspective around the shell rim.
    for(i in 0..8){
        val x=-48f+i*12f
        fineCurve(x,-19f,x+4f,-12f,x+9f,-18f,
            shell.copy(alpha=.72f),2.15f)
    }
    // Small mosaic marks per scute: each is slightly different.
    for((index,pos) in listOf(
        -29f to -55f,0f to -63f,31f to -54f,
        -16f to -31f,18f to -31f
    ).withIndex()) {
        val (cx,cy)=pos
        val path=Path().apply {
            moveTo(cx-11f,cy-1f);lineTo(cx-5f,cy-8f)
            lineTo(cx+7f,cy-8f);lineTo(cx+13f,cy)
            lineTo(cx+5f,cy+7f);lineTo(cx-6f,cy+7f);close()
        }
        drawPath(path,mint.copy(alpha=.73f),style=Stroke(width=1.8f))
        drawCircle(mint.copy(alpha=.55f),2.6f,
            Offset(cx+if(index%2==0)2f else -3f,cy-1f))
        fineStroke(Offset(cx-7f,cy+1f),Offset(cx-1f,cy+4f),
            shell.copy(alpha=.36f),1.25f)
    }
    // Raised shine strip on top of the hard shell.
    fineCurve(-42f,-63f,-15f,-84f,12f,-73f,
        Color(0xFFF4F8D7).copy(alpha=.62f),3f)
    // Scaly forefeet and small pale claws.
    for((i,px) in listOf(-42f,-6f,28f,49f).withIndex()){
        val wobble=if(px<0)walk*2f else -walk*2f
        for(j in 0..1){
            val x=px+8f+j*7f
            drawCircle(olive.copy(alpha=.60f),2.7f,
                Offset(x,-18f+wobble))
            fineStroke(Offset(x,-7f+wobble),
                Offset(x+1f,-4f+wobble),mint,2f)
        }
    }
    val bob=sin(tick*.05f)*1.5f
    drawCircle(Color(0xFFFFF5DF).copy(alpha=.36f),10f,
        Offset(61f,-39f+bob))
    if(tick%190 !in 0..6){
        drawCircle(Color(0xFF343E43),4.9f,Offset(65f,-39f+bob))
        drawCircle(Color.White,1.8f,Offset(63.5f,-41f+bob))
    }
    fineCurve(67f,-21f,75f,-15f,82f,-23f,shell,1.9f)
    drawCircle(Color(0xFF608A67),2f,Offset(81f,-29f+bob))
    for(i in 0..2){
        drawCircle(mint.copy(alpha=.38f),2.7f,
            Offset(45f+i*10f,-25f+bob+(i%2)*4f))
    }
}

private fun DrawScope.detailParrot(tick:Int) {
    val forest=Color(0xFF307E7B)
    val sea=Color(0xFF50ABA0)
    val pale=Color(0xFFE9F3D6)
    val citrus=Color(0xFFF4D592)
    val flex=sin(tick*.095f)*5f
    // Five feather vanes with graded texture and independent strokes.
    for(i in 0..4){
        val x=-39f+i*7f
        fineCurve(x,-145f+flex,x-3f,-126f+flex,x+11f,-106f+flex,
            if(i%2==0)pale.copy(alpha=.7f)else Color(0xFFA9D7CD),
            2.4f)
    }
    for(i in 0..2){
        val x=-21f+i*12f
        fineCurve(x,-118f,x+9f,-103f,x-5f,-79f,
            Color(0xFFACD996).copy(alpha=.65f),2.3f)
    }
    // Face feathers and a tiny raised crest.
    val topTuft=Path().apply{
        moveTo(-14f,-204f)
        quadraticBezierTo(-23f,-231f,-8f,-229f)
        quadraticBezierTo(0f,-223f,2f,-202f)
    }
    drawPath(topTuft,forest.copy(alpha=.80f),
        style=Stroke(width=5f,cap=StrokeCap.Round))
    fineCurve(-3f,-207f,7f,-235f,14f,-214f,sea,3.6f)
    fineCurve(-22f,-188f,-28f,-168f,-19f,-153f,pale.copy(alpha=.67f),2.2f)
    // Beak seam and pale upper highlight.
    fineCurve(24f,-181f,41f,-183f,43f,-171f,
        Color(0xFFFFF1C0),2.4f)
    fineCurve(28f,-166f,36f,-166f,36f,-160f,
        Color(0xFFB98C64),2.0f)
    drawCircle(Color(0xFFBA856A),1.9f,Offset(34f,-173f))
    // Real eye ring: keep blink animation from original model.
    drawCircle(Color(0xFFF6FBF4),10.9f,Offset(16f,-177f),
        style=Stroke(width=1.75f))
    if(tick%179 !in 0..4){
        drawCircle(Color(0xFF393744),4.6f,Offset(16f,-177f))
        drawCircle(Color.White,1.75f,Offset(14.3f,-179f))
    }
    // Feathered cheek with contrasting tiny dotted pattern.
    for(i in 0..3){
        drawOval(pale.copy(alpha=.59f),
            Offset(-17f+i*7f,-159f+(i%2)*5f),Size(4f,12f))
    }
    // Two curved gripping feet with separate toes on the perch.
    for(x in listOf(-13f,12f)){
        fineCurve(x,-84f,x-6f,-70f,x-18f,-77f,
            Color(0xFF84716C),2.4f)
        fineCurve(x,-84f,x+9f,-71f,x+17f,-77f,
            Color(0xFF84716C),2.4f)
    }
    drawOval(citrus.copy(alpha=.55f),
        Offset(-37f,-6f),Size(74f,5f))
}
