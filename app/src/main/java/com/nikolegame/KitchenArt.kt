package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import kotlin.math.sin

// v1.0: a SECOND room, intentionally distinct from Nicole's bedroom.
// Uses the same 2700 x 900 world, controls and season/parallax window layers.
internal fun DrawScope.renderKitchen(
    night:Boolean, season:Int, tick:Int, camera:Float,
    fridgeStyle:Int, fridgeOpen:Boolean
) {
    val wall = listOf(Color(0xFFFFF4DB), Color(0xFFF9EDDA), Color(0xFFE9DED0))
    drawRect(Brush.verticalGradient(wall, startY=0f, endY=600f),
        Offset.Zero, Size(2700f,600f))
    // Warm painted stripes and petite tiles along the splashback.
    for(i in 0..26) {
        val x=i*103f+27f
        drawLine(Color.White.copy(alpha=.49f),
            Offset(x,50f),Offset(x,575f),3f)
    }
    drawRect(Color(0xFFFFFAF1),Offset(0f,38f),Size(2700f,20f))
    drawRect(Color(0xFFB8B9A6),Offset(0f,569f),Size(2700f,10f))
    drawRect(Color(0xFFF8F5E8),Offset(0f,578f),Size(2700f,21f))
    for(r in 0..5)for(c in 0..39){
        val x=c*70f;val y=599f+r*52f
        val color=if((r+c)%2==0)Color(0xFFF8F3E6)else Color(0xFFD7E5DC)
        drawRect(color,Offset(x,y),Size(68f,50f))
    }

    // Two arches. Only the left door is currently a room transition.
    kitchenDoor(136f,false)
    kitchenDoor(2370f,true)

    // Different window from the bedroom. The outdoor scene moves in parallax.
    renderSeasonalWindow(1338f,night,season,tick,camera,0)

    // Vivid upper cupboards above counter, with open shelving.
    for(x in listOf(800f,1006f,1830f,2030f)) {
        drawRoundRect(Color(0xFFC3D7C5),Offset(x,270f),Size(183f,156f),CornerRadius(13f))
        drawRoundRect(Color(0xFFFFF8EE),Offset(x+11f,282f),Size(161f,130f),CornerRadius(11f))
        drawRoundRect(Color(0xFFC2D6C5),Offset(x+17f,290f),Size(148f,112f),
            CornerRadius(11f),style=Stroke(width=4f))
        drawCircle(Color(0xFFE3B985),5f,Offset(x+153f,353f))
    }

    // The large independent fridge on the left.
    drawKitchenFridge(fridgeStyle,fridgeOpen)
    // Sink, counter, stove — an understandable first kitchen, not yet shop items.
    counter(790f,510f,431f)
    counter(1790f,510f,467f)
    drawRoundRect(Color(0xFFDDE7E1),Offset(838f,488f),Size(284f,47f),CornerRadius(17f))
    drawRoundRect(Color(0xFF9CABB0),Offset(854f,491f),Size(252f,29f),CornerRadius(14f))
    drawRoundRect(Color(0xFFD4E4E5),Offset(864f,495f),Size(232f,19f),CornerRadius(12f))
    val faucet=Path().apply{
        moveTo(975f,484f);lineTo(975f,442f)
        quadraticBezierTo(975f,412f,1002f,416f)
        quadraticBezierTo(1037f,415f,1037f,452f)
    }
    drawPath(faucet,Color(0xFFC1B3B0),style=Stroke(width=11f))
    drawCircle(Color(0xFFE5C8BF),8f,Offset(1042f,452f))
    // Four cooktop rings and oven door.
    for(x in listOf(1919f,2044f)) for(y in listOf(494f,532f)){
        drawOval(Color(0xFF6B666B),Offset(x,y),Size(52f,19f))
        drawOval(Color(0xFF9A9294),Offset(x+8f,y+4f),Size(36f,10f))
    }
    drawRoundRect(Color(0xFFEEE0D4),Offset(1865f,570f),Size(330f,117f),CornerRadius(12f))
    drawRoundRect(Color(0xFF83999A),Offset(1890f,586f),Size(276f,82f),CornerRadius(9f))
    drawLine(Color(0xFFFFF7E6),Offset(1899f,598f),Offset(2162f,598f),5f)
    for(x in listOf(1900f,1985f,2070f,2155f))drawCircle(Color(0xFFA98D86),8f,Offset(x,555f))

    // A compact round dining table with two visible chairs.
    drawOval(Color.Black.copy(alpha=.11f),Offset(1290f,782f),Size(530f,46f))
    for(x in listOf(1330f,1710f)){
        drawRoundRect(Color(0xFFAD9589),Offset(x,667f),Size(26f,139f),CornerRadius(8f))
        drawRoundRect(Color(0xFFCFC0A7),Offset(x-19f,585f),Size(90f,111f),CornerRadius(19f))
        drawRoundRect(Color(0xFFE7C9B7),Offset(x-26f,680f),Size(110f,29f),CornerRadius(12f))
    }
    drawRoundRect(Color(0xFFB79E8A),Offset(1527f,697f),Size(27f,110f),CornerRadius(7f))
    drawOval(Color(0xFFBDA38F),Offset(1347f,642f),Size(374f,98f))
    drawOval(Color(0xFFFFE1C3),Offset(1355f,632f),Size(357f,84f))
    drawOval(Color(0xFFF7F5E9),Offset(1480f,651f),Size(101f,45f))
    drawCircle(Color(0xFFEA9E92),13f,Offset(1521f,659f))
    drawCircle(Color(0xFFE3C37E),10f,Offset(1546f,672f))
    drawCircle(Color(0xFFA5BE92),9f,Offset(1509f,680f))

    // Pendant lights and wall decor.
    for(x in listOf(1046f,1920f)) {
        drawLine(Color(0xFF988A80),Offset(x,45f),Offset(x,159f),5f)
        val shade=Path().apply{
            moveTo(x-53f,179f);lineTo(x-31f,146f);lineTo(x+33f,146f)
            lineTo(x+54f,179f);close()
        }
        drawPath(shade,Color(0xFFD2BBB7))
        drawOval(Color(0xFFFFECCC),Offset(x-47f,176f),Size(96f,22f))
    }
    drawRoundRect(Color(0xFFBD9B84),Offset(1655f,212f),Size(116f,117f),CornerRadius(50f))
    drawCircle(Color(0xFFFFFCF4),50f,Offset(1713f,270f))
    for(i in 0..11){
        val a=i*0.5235988f
        drawCircle(Color(0xFFA88480),2f,
            Offset(1713f+kotlin.math.sin(a)*40f,270f-kotlin.math.cos(a)*40f))
    }
    drawLine(Color(0xFF9C8386),Offset(1713f,270f),Offset(1713f,241f),4f)
    drawLine(Color(0xFF9C8386),Offset(1713f,270f),Offset(1734f,279f),3f)

    // A clear soft night tint, no hard light circles.
    if(night)drawRect(Color(0xFF30345B).copy(alpha=.25f),size=Size(2700f,900f))
}

private fun DrawScope.kitchenDoor(x:Float,locked:Boolean) {
    drawRoundRect(Color(0xFFF8EADA),Offset(x-18f,154f),Size(237f,450f),CornerRadius(92f))
    drawRoundRect(Color(0xFF725C51),Offset(x,171f),Size(199f,421f),CornerRadius(79f))
    drawRoundRect(if(locked)Color(0xFFA8AE9B)else Color(0xFFC29C84),
        Offset(x+12f,180f),Size(175f,397f),CornerRadius(72f))
    drawRoundRect(if(locked)Color(0xFFCBD3C4)else Color(0xFFE8CBB0),
        Offset(x+43f,260f),Size(105f,220f),CornerRadius(24f))
    drawCircle(Color(0xFFFFDEA9),10f,Offset(x+164f,439f))
    if(locked){
        drawRoundRect(Color(0xFFF9F0E8),Offset(x+40f,505f),Size(112f,48f),CornerRadius(13f))
        // Visual sign for future room. A child needn't read it.
        drawCircle(Color(0xFFD6B4CB),15f,Offset(x+95f,525f))
        drawLine(Color(0xFF816580),Offset(x+88f,525f),Offset(x+103f,525f),4f)
    }
}
private fun DrawScope.counter(x:Float,y:Float,w:Float) {
    drawRoundRect(Color(0xFFB4C7B7),Offset(x+13f,y+14f),Size(w-26f,172f),CornerRadius(13f))
    drawRoundRect(Color(0xFFD6E4D8),Offset(x+22f,y+24f),Size(w-44f,158f),CornerRadius(12f))
    for(i in 0..2) {
        val dx=x+34f+i*(w-68f)/3f
        drawRoundRect(Color(0xFFF8F7EC),Offset(dx,y+45f),
            Size((w-68f)/3f-7f,119f),CornerRadius(10f))
        drawCircle(Color(0xFFE8BD91),5f,Offset(dx+16f,y+102f))
    }
    drawRoundRect(Color(0xFFFDF6E6),Offset(x,y),Size(w,33f),CornerRadius(9f))
    drawLine(Color(0xFFD4BFAE),Offset(x+7f,y+29f),Offset(x+w-7f,y+29f),3f)
}

/** Complete and independently purchasable refrigerator models. */
internal fun DrawScope.drawKitchenFridge(style:Int,open:Boolean) {
    val x=458f;val top=273f
    drawOval(Color.Black.copy(alpha=.14f),Offset(x-10f,649f),Size(303f,45f))
    val base = when(style) {
        1->Color(0xFFB7D6CD)
        2->Color(0xFFF0BFCB)
        else->Color(0xFFFCF5E8)
    }
    val shade=when(style) {
        1->Color(0xFF86B6AD)
        2->Color(0xFFC58FA5)
        else->Color(0xFFD7C7BA)
    }
    val width=if(style==1)282f else if(style==2)250f else 266f
    val height=if(style==2)365f else 373f
    drawRoundRect(shade,Offset(x,top),Size(width,height),CornerRadius(if(style==2)42f else 21f))
    drawRoundRect(base,Offset(x+8f,top+8f),Size(width-16f,height-16f),
        CornerRadius(if(style==2)37f else 17f))
    drawRoundRect(Color.White.copy(alpha=.45f),Offset(x+20f,top+14f),
        Size(18f,height-39f),CornerRadius(8f))
    drawLine(shade,Offset(x+10f,top+131f),Offset(x+width-10f,top+131f),4f)
    if(style==1){
        drawLine(shade,Offset(x+width*.5f,top+138f),
            Offset(x+width*.5f,top+height-10f),4f)
    }
    if(open) {
        // Visible food only when the child taps the refrigerator.
        drawRoundRect(Color(0xFFFAFBF6),Offset(x+45f,top+151f),
            Size(width-81f,height-175f),CornerRadius(12f))
        for(i in 0..2){
            val yy=top+193f+i*68f
            drawLine(shade.copy(alpha=.6f),Offset(x+50f,yy),
                Offset(x+width-43f,yy),3f)
        }
        drawCircle(Color(0xFFEA9784),17f,Offset(x+94f,top+179f))
        drawCircle(Color(0xFFE0C76E),14f,Offset(x+145f,top+178f))
        drawRoundRect(Color(0xFFB9D6A0),Offset(x+94f,top+211f),
            Size(55f,68f),CornerRadius(9f))
        drawRoundRect(Color(0xFFF1D9B0),Offset(x+160f,top+230f),
            Size(36f,51f),CornerRadius(9f))
        val door = Path().apply{
            moveTo(x+44f,top+141f);lineTo(x+width-16f,top+151f)
            lineTo(x+width+43f,top+height-14f)
            lineTo(x+47f,top+height-3f);close()
        }
        drawPath(door,base.copy(alpha=.88f))
        drawPath(door,shade,style=Stroke(width=6f))
        drawLine(Color(0xFFB9AB9F),
            Offset(x+width+16f,top+203f),
            Offset(x+width+16f,top+276f),7f)
    } else {
        if(style==2){
            drawLine(Color(0xFF9F8D91),Offset(x+width-39f,top+163f),
                Offset(x+width-39f,top+277f),9f)
            drawOval(Color(0xFFEBC6D0),Offset(x+width-89f,top+40f),Size(62f,28f))
        }else{
            for(yy in listOf(top+59f,top+198f)){
                drawRoundRect(Color(0xFFB5ABA1),
                    Offset(x+width-43f,yy),Size(12f,75f),CornerRadius(6f))
            }
        }
        drawCircle(Color(0xFFFFE7A6),7f,Offset(x+width*.48f,top+45f))
    }
    for(dx in listOf(33f,width-55f)){
        drawRoundRect(Color(0xFF8D8C89),Offset(x+dx,top+height-1f),
            Size(18f,27f),CornerRadius(6f))
    }
}
