package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

// Full replacement models, never a recolor overlay on the original object.
internal fun DrawScope.drawSpecialBed(style:Int) {
    val white=Color(0xFFFFF5E9)
    val pink=Color(0xFFE8B5CF)
    val lavender=Color(0xFFB6A2D4)
    if(style==1) {
        // House-shaped bed: smaller mattress with a pitched roof and open rails.
        drawOval(Color.Black.copy(alpha=.12f),Offset(408f,701f),Size(439f,44f))
        for(x in listOf(407f,829f)) {
            drawRoundRect(Color(0xFFC7A894),Offset(x,485f),Size(21f,239f),CornerRadius(7f))
            drawCircle(Color(0xFFFFE8C6),10f,Offset(x+10f,485f))
        }
        val roof=Path().apply{
            moveTo(401f,488f);lineTo(616f,353f);lineTo(839f,487f)
        }
        drawPath(roof,Color(0xFFAC8E80),style=Stroke(width=18f))
        drawPath(roof,white,style=Stroke(width=11f))
        drawRoundRect(Color(0xFFBE987F),Offset(427f,569f),Size(383f,125f),CornerRadius(18f))
        drawRoundRect(white,Offset(430f,553f),Size(375f,125f),CornerRadius(22f))
        drawRoundRect(pink,Offset(568f,583f),Size(231f,89f),CornerRadius(19f))
        drawRoundRect(Color.White,Offset(455f,561f),Size(110f,66f),CornerRadius(24f))
        drawLine(Color(0xFFEED7DB),Offset(455f,629f),Offset(781f,629f),3f)
        for(x in listOf(435f,791f))drawRoundRect(Color(0xFFD5B8A6),
            Offset(x,670f),Size(22f,57f),CornerRadius(8f))
    }else{
        // Four-poster canopy bed with four distinct posts, soft curtains and a tall head.
        drawOval(Color.Black.copy(alpha=.13f),Offset(387f,708f),Size(481f,44f))
        for(x in listOf(402f,828f)) {
            drawRoundRect(Color(0xFFBA94AD),Offset(x,437f),Size(24f,284f),CornerRadius(10f))
            drawCircle(white,13f,Offset(x+12f,436f))
        }
        drawLine(lavender,Offset(414f,436f),Offset(842f,436f),13f)
        drawRoundRect(Color(0xFFD5BDDF),Offset(418f,450f),Size(422f,21f),CornerRadius(8f))
        for(x in listOf(430f,777f)) {
            val curtain=Path().apply{
                moveTo(x,465f);quadraticBezierTo(x+39f,509f,x+13f,556f)
                lineTo(x+7f,637f);lineTo(x-9f,637f);close()
            }
            drawPath(curtain,Color(0xFFEBD9ED).copy(alpha=.84f))
            drawCircle(Color(0xFFE1B0C5),9f,Offset(x+8f,561f))
        }
        drawRoundRect(Color(0xFFAC8EAB),Offset(429f,569f),Size(388f,128f),CornerRadius(22f))
        drawRoundRect(white,Offset(434f,556f),Size(380f,124f),CornerRadius(24f))
        drawRoundRect(lavender,Offset(568f,589f),Size(239f,85f),CornerRadius(17f))
        drawRoundRect(Color.White,Offset(460f,560f),Size(107f,64f),CornerRadius(21f))
        drawLine(Color(0xFFEBD2EA),Offset(586f,606f),Offset(789f,606f),4f)
    }
}

internal fun DrawScope.drawSpecialWardrobe(style:Int) {
    if(style==1) {
        // Rounded mirrored wardrobe, slightly shorter than the original.
        drawOval(Color.Black.copy(alpha=.13f),Offset(1538f,620f),Size(295f,35f))
        drawRoundRect(Color(0xFFD0AF9F),Offset(1552f,328f),Size(268f,304f),CornerRadius(36f))
        drawRoundRect(Color(0xFFFFEDE1),Offset(1562f,335f),Size(249f,281f),CornerRadius(32f))
        drawRoundRect(Color(0xFFC6DCE1),Offset(1595f,364f),Size(123f,221f),CornerRadius(54f))
        drawRoundRect(Color(0xFFE7F5F3).copy(alpha=.57f),
            Offset(1608f,371f),Size(31f,198f),CornerRadius(13f))
        drawRoundRect(Color(0xFFF3D7C9),Offset(1735f,368f),Size(57f,218f),CornerRadius(18f))
        for(y in listOf(454f,478f))drawCircle(Color(0xFFC69677),5f,Offset(1741f,y))
        for(x in listOf(1570f,1786f))drawRoundRect(Color(0xFFB9907C),
            Offset(x,614f),Size(21f,31f),CornerRadius(6f))
    }else{
        // Taller three-door wardrobe with a pitched crown, not the same cabinet.
        drawOval(Color.Black.copy(alpha=.14f),Offset(1522f,630f),Size(320f,38f))
        val crown=Path().apply{
            moveTo(1525f,341f);lineTo(1548f,303f);lineTo(1692f,283f)
            lineTo(1830f,303f);lineTo(1850f,341f);close()
        }
        drawPath(crown,Color(0xFFB898C4))
        drawRoundRect(Color(0xFFD2BAE5),Offset(1537f,341f),
            Size(304f,290f),CornerRadius(13f))
        for(i in 0..2){
            val x=1548f+i*99f
            drawRoundRect(Color(0xFFF1E6F5),Offset(x,350f),
                Size(91f,264f),CornerRadius(13f))
            drawRoundRect(Color(0xFFBB9BCB),Offset(x+10f,369f),
                Size(71f,209f),CornerRadius(17f),style=Stroke(width=3.2f))
            drawCircle(Color(0xFFD6AE78),5f,Offset(x+79f,477f))
        }
        for(x in listOf(1563f,1795f))drawRoundRect(Color(0xFF9D7EB0),
            Offset(x,624f),Size(25f,29f),CornerRadius(5f))
    }
}

internal fun DrawScope.drawSpecialTable(style:Int) {
    if(style==1) {
        // Small round tea/art table with a single pedestal and curved feet.
        drawOval(Color.Black.copy(alpha=.11f),Offset(1930f,690f),Size(360f,38f))
        drawOval(Color(0xFFAF8A74),Offset(1939f,448f),Size(355f,81f))
        drawOval(Color(0xFFF0D2BB),Offset(1945f,440f),Size(343f,68f))
        drawRoundRect(Color(0xFFD1AF99),Offset(2100f,496f),Size(33f,208f),CornerRadius(10f))
        drawLine(Color(0xFFA87E68),Offset(2117f,690f),Offset(2034f,703f),18f)
        drawLine(Color(0xFFA87E68),Offset(2117f,690f),Offset(2197f,703f),18f)
    } else {
        // Long angled drawing desk with raised tilted paper surface.
        drawOval(Color.Black.copy(alpha=.12f),Offset(1909f,693f),Size(423f,37f))
        for(x in listOf(1950f,2260f))
            drawRoundRect(Color(0xFF9474B0),Offset(x,500f),Size(25f,212f),CornerRadius(6f))
        val top=Path().apply{
            moveTo(1905f,472f);lineTo(2255f,419f);lineTo(2343f,480f)
            lineTo(2309f,504f);lineTo(1905f,504f);close()
        }
        drawPath(top,Color(0xFFB99BD5))
        drawLine(Color(0xFFF5EAFB),Offset(1930f,472f),Offset(2250f,429f),6f)
        drawRoundRect(Color(0xFFF6F0E4),Offset(2032f,450f),Size(166f,18f),CornerRadius(4f))
        for(i in 0..4)drawLine(Color(0xFFCAACD5),Offset(2053f+i*29f,452f),
            Offset(2053f+i*29f,465f),2f)
        drawRoundRect(Color(0xFFDCCAE6),Offset(2000f,525f),Size(243f,68f),CornerRadius(6f))
        for(x in listOf(2061f,2177f))drawCircle(Color(0xFFB595C6),6f,Offset(x,553f))
    }
}

internal fun DrawScope.drawSpecialChair(style:Int) {
    if(style==1){
        // Butterfly-back chair, different back contour.
        drawOval(Color.Black.copy(alpha=.13f),Offset(2049f,723f),Size(166f,29f))
        for(x in listOf(2070f,2175f))
            drawRoundRect(Color(0xFFAC8D7E),Offset(x,619f),Size(17f,119f),CornerRadius(5f))
        val wing=Path().apply{
            moveTo(2131f,582f);quadraticBezierTo(2038f,520f,2070f,488f)
            quadraticBezierTo(2117f,468f,2131f,532f)
            quadraticBezierTo(2162f,468f,2198f,490f)
            quadraticBezierTo(2235f,527f,2131f,582f);close()
        }
        drawPath(wing,Color(0xFFE8C5B9))
        drawPath(wing,Color(0xFFC698A6),style=Stroke(width=5f))
        drawRoundRect(Color(0xFFDAB1B5),Offset(2046f,603f),Size(173f,31f),CornerRadius(12f))
    }else{
        // Compact upholstered armchair, wider and lower than wooden chairs.
        drawOval(Color.Black.copy(alpha=.15f),Offset(2022f,724f),Size(220f,30f))
        for(x in listOf(2045f,2205f))drawRoundRect(Color(0xFF9D7EB5),
            Offset(x,685f),Size(21f,54f),CornerRadius(6f))
        drawRoundRect(Color(0xFFB99DD5),Offset(2042f,506f),Size(184f,189f),CornerRadius(57f))
        drawRoundRect(Color(0xFFECDFF2),Offset(2058f,526f),Size(153f,133f),CornerRadius(37f))
        drawRoundRect(Color(0xFFAF91CB),Offset(2019f,613f),Size(228f,78f),CornerRadius(25f))
        drawRoundRect(Color(0xFFDCC9EC),Offset(2051f,622f),Size(168f,55f),CornerRadius(23f))
        for(x in listOf(2034f,2229f))drawRoundRect(Color(0xFFB598D0),
            Offset(x,590f),Size(24f,89f),CornerRadius(12f))
    }
}

internal fun DrawScope.drawSpecialRug(style:Int) {
    if(style==1){
        // Distinct five-point star silhouette, not an oval recolor.
        val cx=1203f; val cy=816f
        val star=Path()
        for(i in 0..9){
            val a=-Math.PI/2 + i*Math.PI/5
            val radius=if(i%2==0) 210f else 98f
            val x=cx+cos(a).toFloat()*radius*1.54f
            val y=cy+sin(a).toFloat()*radius*.31f
            if(i==0)star.moveTo(x,y) else star.lineTo(x,y)
        }
        star.close()
        drawPath(star,Color(0xFFF4D7A2))
        drawPath(star,Color(0xFFD6A7C2),style=Stroke(width=13f))
        drawCircle(Color(0xFFFFF5DB),25f,Offset(cx,cy))
    }else{
        // Six-petalled flower carpet with scalloped edge and round middle.
        for(i in 0..5){
            val a=i*Math.PI/3
            drawOval(Color(0xFFD6B2D9),Offset(
                1200f+cos(a).toFloat()*171f-133f,
                808f+sin(a).toFloat()*37f-35f),Size(266f,70f))
        }
        drawOval(Color(0xFFFFEAD5),Offset(1013f,774f),Size(382f,75f))
        drawOval(Color(0xFFF4D7A0),Offset(1092f,789f),Size(220f,43f))
        for(i in 0..5){
            val a=i*Math.PI/3
            drawCircle(Color.White.copy(alpha=.74f),8f,
                Offset(1200f+cos(a).toFloat()*166f,
                    813f+sin(a).toFloat()*38f))
        }
    }
}

internal fun DrawScope.drawSpecialPaintings(style:Int) {
    if(style==1) {
        // One large panorama instead of three matching rectangles.
        drawRoundRect(Color(0xFFAF9079),Offset(1011f,184f),Size(447f,190f),CornerRadius(15f))
        drawRoundRect(Color(0xFFFFF3E6),Offset(1024f,197f),Size(421f,164f),CornerRadius(9f))
        drawRect(Color(0xFFB7D6DA),Offset(1033f,207f),Size(403f,143f))
        val hills=Path().apply{
            moveTo(1033f,317f);quadraticBezierTo(1115f,244f,1198f,310f)
            quadraticBezierTo(1290f,247f,1436f,306f)
            lineTo(1436f,350f);lineTo(1033f,350f);close()
        }
        drawPath(hills,Color(0xFF92B69B))
        drawCircle(Color(0xFFFFE8B6),25f,Offset(1345f,238f))
    }else {
        // Six tiny butterfly portraits of differing dimensions.
        for(i in 0..5) {
            val x=1015f+(i%3)*143f
            val y=190f+(i/3)*119f
            val w=if(i%2==0) 102f else 84f
            val h=if(i%2==0) 92f else 104f
            drawRoundRect(Color(0xFFB69DB8),Offset(x,y),Size(w,h),CornerRadius(14f))
            drawRoundRect(Color(0xFFFFF1E8),Offset(x+8f,y+8f),Size(w-16f,h-16f),CornerRadius(11f))
            val cx=x+w/2; val cy=y+h/2
            drawOval(Color(0xFFE1BDD6),Offset(cx-27f,cy-19f),Size(25f,25f))
            drawOval(Color(0xFFE7C98C),Offset(cx+2f,cy-19f),Size(25f,25f))
            drawOval(Color(0xFFD5AEC4),Offset(cx-21f,cy+3f),Size(19f,18f))
            drawOval(Color(0xFFE1BFA0),Offset(cx+2f,cy+3f),Size(19f,18f))
            drawLine(Color(0xFF846D7A),Offset(cx,cy-17f),Offset(cx,cy+20f),3f)
        }
    }
}

internal fun DrawScope.drawCeilingLight(style:Int) {
    val cx=1190f; val cy=96f
    drawLine(Color(0xFFAA8C96),Offset(cx,45f),Offset(cx,78f),7f)
    if(style==0){
        drawRoundRect(Color(0xFFE1C6AE),Offset(cx-64f,78f),Size(128f,42f),CornerRadius(22f))
        drawOval(Color(0xFFFFEAD0),Offset(cx-46f,97f),Size(92f,27f))
    }else if(style==1){
        val star=Path()
        for(i in 0..9){
            val a=-Math.PI/2+i*Math.PI/5
            val r=if(i%2==0) 64f else 34f
            val x=cx+cos(a).toFloat()*r
            val y=cy+sin(a).toFloat()*r
            if(i==0)star.moveTo(x,y) else star.lineTo(x,y)
        }
        star.close();drawPath(star,Color(0xFFFFE1A6))
        drawPath(star,Color(0xFFCBA7B4),style=Stroke(width=5f))
    }else {
        drawLine(Color(0xFFBBA3BE),Offset(cx-74f,90f),Offset(cx+74f,90f),8f)
        for(i in -2..2){
            val x=cx+i*33f; val drop=abs(i)*8f
            drawLine(Color(0xFFBBA3BE),Offset(x,91f),Offset(x,134f+drop),3f)
            drawCircle(Color(0xFFFAE8D8),11f,Offset(x,141f+drop))
            drawCircle(Color(0xFFF7FAFF),5f,Offset(x,151f+drop))
        }
    }
}

internal fun DrawScope.drawDeskLight(style:Int) {
    // Lamps are independently replaceable and remain on the desktop.
    if(style==0) {
        drawRect(Color(0xFFAA876A),Offset(2210f,407f),Size(9f,45f))
        val shade=Path().apply{
            moveTo(2197f,406f);lineTo(2242f,406f)
            lineTo(2235f,376f);lineTo(2206f,376f);close()
        }
        drawPath(shade,Color(0xFFF9D5AE))
        drawCircle(Color(0xFFFFE2B1),8f,Offset(2220f,408f))
    }else if(style==1){
        drawRoundRect(Color(0xFF7BAE8F),Offset(2214f,416f),Size(12f,39f),CornerRadius(6f))
        for(i in 0..4){
            val a=i*Math.PI/2.5
            drawOval(Color(0xFFF2B9CD),Offset(
                2218f+cos(a).toFloat()*22f-13f,
                398f+sin(a).toFloat()*16f-13f),Size(26f,26f))
        }
        drawCircle(Color(0xFFFFE6AC),10f,Offset(2218f,399f))
    }else{
        drawRoundRect(Color(0xFFFFF2E7),Offset(2199f,397f),Size(45f,55f),CornerRadius(23f))
        for(x in listOf(2208f,2229f))
            drawOval(Color(0xFFFFF2E7),Offset(x,377f),Size(16f,31f))
        for(x in listOf(2212f,2230f))
            drawCircle(Color(0xFF9B7C91),2.6f,Offset(x,415f))
        drawCircle(Color(0xFFD6A4AD),4f,Offset(2221f,425f))
        drawOval(Color(0xFFFFF8BF).copy(alpha=.29f),
            Offset(2186f,366f),Size(69f,85f))
    }
}
