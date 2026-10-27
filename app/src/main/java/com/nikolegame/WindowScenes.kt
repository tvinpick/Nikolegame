package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect

// Two different parts of ONE outdoor world.
// Left = orchard / cottage garden, with the ONE sun.
// Right = pond, footbridge and distant cottage, never a second sun.
// Parallax applies only to scenery inside the glass. Curtain and frame are fixed.
internal fun DrawScope.renderSeasonalWindow(
    x:Float, night:Boolean, season:Int, tick:Int, camera:Float, scene:Int
) {
    val sky=if(night) Color(0xFF45567D) else when(season){
        0->Color(0xFFC5E4F7)
        1->Color(0xFF91D9FA)
        2->Color(0xFFCAD9E9)
        else->Color(0xFFC0D6ED)
    }
    val foliage=when(season){
        0->Color(0xFF91C59A)
        1->Color(0xFF69A66C)
        2->Color(0xFFD39B55)
        else->Color(0xFFEAF2F4)
    }
    val darkLeaf=when(season){
        0->Color(0xFF6EAD85)
        1->Color(0xFF468C60)
        2->Color(0xFFB86F48)
        else->Color(0xFFB8D0D9)
    }
    val delta=camera-550f
    val far=(delta*.064f).coerceIn(-35f,35f)
    val mid=(delta*.145f).coerceIn(-67f,67f)
    val near=(delta*.23f).coerceIn(-90f,90f)
    drawRoundRect(Color(0xFF8B5A41),Offset(x-11f,120f),
        Size(342f,325f),CornerRadius(14f))
    clipRect(left=x+8f,top=137f,right=x+310f,bottom=422f){
        drawRect(Brush.verticalGradient(listOf(sky,
            if(night) Color(0xFF8390AD) else Color(0xFFE5F0E6)),
            startY=137f,endY=365f),
            Offset(x+8f,137f),Size(302f,285f))
        if(scene==0 && !night) {
            // Exactly one sun for the entire room.
            drawCircle(Color(0xFFFFEDB4),if(season==3) 20f else 28f,
                Offset(x+250f+far*.3f,180f))
        }
        if(night) {
            for(i in 0..11) {
                drawCircle(Color(0xFFFFFAED).copy(alpha=.87f),
                    1.7f,Offset(x+18f+((i*71)%286),152f+((i*29)%106)))
            }
        } else {
            for(i in 0..2){
                val xx=x+27f+far+i*123f
                drawOval(Color.White.copy(alpha=.66f),
                    Offset(xx,196f+(i%2)*15f),Size(69f,16f))
                drawCircle(Color.White.copy(alpha=.70f),12f,Offset(xx+24f,191f+(i%2)*15f))
            }
        }
        for(i in -1..5){
            val h=x+i*115f+far
            val hills=Path().apply{
                moveTo(h-60f,351f);quadraticBezierTo(h+21f,266f,h+118f,348f)
                lineTo(h+118f,420f);lineTo(h-60f,420f);close()
            }
            drawPath(hills,if(season==3) Color(0xFFE6F1F7)
                else if(scene==1) Color(0xFF94B8AB) else Color(0xFFACC6AA))
        }
        if(scene==0) {
            // Garden: apple trees, flowerbeds, path and a low picket fence.
            drawRect(if(season==3)Color(0xFFF4F9FB)
                else Color(0xFFADD493),Offset(x+8f,335f),Size(302f,87f))
            for(i in -1..4){
                val xx=x+38f+i*134f+mid
                drawLine(Color(0xFF937760),Offset(xx,327f),Offset(xx,385f),11f)
                drawCircle(darkLeaf,31f,Offset(xx-14f,299f))
                drawCircle(foliage,38f,Offset(xx+17f,292f))
                if(season==0){
                    for(j in 0..5)drawCircle(Color(0xFFFFE3EA),5f,
                        Offset(xx-22f+j*11f,290f+((j*13)%23)))
                }else if(season==1){
                    for(j in 0..3)drawCircle(Color(0xFFEFA86A),5f,
                        Offset(xx-15f+j*13f,287f+((j*17)%28)))
                }else if(season==2){
                    for(j in 0..4)drawOval(Color(0xFFFFC76F),
                        Offset(xx-21f+j*14f,304f+((j*9)%17)),Size(8f,6f))
                }
            }
            // The stepping-stone path and near flowers move most.
            for(i in 0..4) {
                drawOval(if(season==3)Color(0xFFD5E4E9)
                    else Color(0xFFE5D0A8),
                    Offset(x+42f+i*68f+near,388f-(i%2)*7f),Size(52f,14f))
            }
            for(i in -2..12){
                val px=x+18f+i*34f+near
                drawRoundRect(Color(0xFFFFF5ED),
                    Offset(px,326f),Size(8f,70f),CornerRadius(4f))
            }
            drawRect(Color(0xFFFFF4E7),Offset(x-90f,345f),Size(540f,6f))
            if(season==3){
                drawOval(Color.White,Offset(x-68f+near,389f),Size(210f,62f))
                drawOval(Color(0xFFF9FEFF),Offset(x+111f+near,389f),Size(240f,61f))
                val sx=x+86f+near*.32f
                drawCircle(Color.White,19f,Offset(sx,381f))
                drawCircle(Color.White,13f,Offset(sx,354f))
                drawCircle(Color(0xFF524A54),2.2f,Offset(sx-5f,351f))
                drawCircle(Color(0xFF524A54),2.2f,Offset(sx+5f,351f))
                drawLine(Color(0xFFE7A260),Offset(sx,354f),Offset(sx+11f,357f),3f)
            }else {
                for(i in 0..7){
                    val px=x+((i*53)%284)+near*.3f
                    drawCircle(if(season==2)Color(0xFFE8B36D)
                        else Color(0xFFF5C4D0),5f,
                        Offset(px,389f+(i%2)*11f))
                }
            }
        }else{
            // Different direction: lake, bridge, island and a tiny cottage.
            val water=if(season==3)Color(0xFFDCECF2)
                else if(night)Color(0xFF637E9B) else Color(0xFF8DC4CF)
            drawRect(water,Offset(x+8f,338f),Size(302f,84f))
            for(i in 0..9){
                val wx=x+((i*67)%332)+near*.56f
                drawLine(if(season==3)Color.White.copy(alpha=.82f)
                    else Color(0xFFE3FCFD).copy(alpha=.66f),
                    Offset(wx,353f+(i*17)%53),Offset(wx+34f,353f+(i*17)%53),2f)
            }
            // Near riverbank and reeds.
            drawOval(if(season==3)Color(0xFFF7FBFA) else Color(0xFF9FC7A0),
                Offset(x-100f+near,383f),Size(300f,77f))
            drawOval(if(season==3)Color(0xFFF8FCFC) else Color(0xFFA9D2A7),
                Offset(x+184f+near,388f),Size(180f,69f))
            // A little arched footbridge, its geometry distinct from the orchard.
            val bx=x-60f+mid
            val bridge=Path().apply{
                moveTo(bx,360f)
                quadraticBezierTo(bx+145f,310f,bx+304f,355f)
            }
            drawPath(bridge,Color(0xFFB89077),style=Stroke(width=13f))
            drawPath(bridge,Color(0xFFFFE0BA),style=Stroke(width=5f))
            for(i in 0..8){
                val p=bx+i*37f
                val yy=356f-29f*(1f-kotlin.math.abs(i-4)/4f)
                drawLine(Color(0xFFAD856D),
                    Offset(p,yy),Offset(p,yy+32f),4f)
            }
            // Cottage on the far bank, behind the bridge.
            val hx=x+187f+far
            drawRoundRect(Color(0xFFEBD2B4),Offset(hx,276f),Size(79f,78f),CornerRadius(7f))
            val roof=Path().apply{
                moveTo(hx-12f,283f);lineTo(hx+40f,245f)
                lineTo(hx+91f,283f);close()
            }
            drawPath(roof,if(season==3)Color(0xFFF6FAFD)else Color(0xFFA7787E))
            drawRoundRect(Color(0xFF9F7E73),Offset(hx+29f,310f),Size(21f,43f),CornerRadius(5f))
            drawRect(Color(0xFFE8F7F4),Offset(hx+10f,290f),Size(16f,19f))
            // Evergreen/willow and flowering or golden foliage.
            for(i in 0..2){
                val xx=x+20f+i*139f+mid
                drawLine(Color(0xFF866E60),Offset(xx,319f),Offset(xx,370f),10f)
                drawCircle(darkLeaf,28f,Offset(xx,303f))
                drawCircle(foliage,31f,Offset(xx+14f,296f))
                if(season==0){
                    for(j in 0..3)drawCircle(Color(0xFFFFE1E9),4f,
                        Offset(xx+j*10f-16f,292f+((j*9)%20)))
                }
            }
            if(season!=3)for(i in 0..5) {
                val rx=x+((i*59)%302)+near
                drawLine(Color(0xFF5E9779),Offset(rx,412f),
                    Offset(rx+4f,380f-(i%3)*6f),3f)
            }
        }
        if(season==3){
            // Light snowfall follows the season but is confined to the outdoors.
            for(i in 0..16){
                val px=x+17f+((i*73)%282)
                val py=148f+((i*41+tick)%268)
                drawCircle(Color.White.copy(alpha=.89f),2.5f,Offset(px,py))
            }
        }
        if(night){
            drawRect(Color(0xFF202B58).copy(alpha=.19f),
                Offset(x+8f,137f),Size(302f,285f))
        }
    }
    // Static window trim, mullions and curtains.
    drawRect(Color(0xFFA7745E),Offset(x+153f,130f),Size(13f,300f))
    drawRect(Color(0xFFA7745E),Offset(x+8f,285f),Size(303f,13f))
    drawRect(Color(0xFFD9AE97),Offset(x-20f,429f),Size(362f,22f))
    drawRoundRect(Color(0xFFD19AAE),Offset(x-34f,108f),
        Size(63f,260f),CornerRadius(18f))
    drawRoundRect(Color(0xFFD19AAE),Offset(x+284f,108f),
        Size(63f,260f),CornerRadius(18f))
    drawLine(Color(0xFFF1C1D0),Offset(x-18f,120f),Offset(x-2f,350f),5f)
    drawLine(Color(0xFFF1C1D0),Offset(x+325f,120f),Offset(x+308f,350f),5f)
}
