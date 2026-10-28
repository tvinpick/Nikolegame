package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke

// The television is wall-mounted over the old toy chest, without taking floor space.
// The pictures are rearranged to its left in a smaller dedicated gallery.
internal fun DrawScope.drawRoomTelevision(style: Int) {
    if(style >= 3) {
        drawRoomTelevision(2)
        drawPremiumFurnishing("tv",style)
        return
    }
    if (style == 0) return
    val bx = 1218f
    val by = 238f
    val w = if (style == 1) 290f else 278f
    val h = if (style == 1) 166f else 179f
    drawRoundRect(Color(0xFF6B5563).copy(alpha = .17f),
        Offset(bx + 12f, by + 13f), Size(w, h), CornerRadius(16f))
    drawRoundRect(if (style == 1) Color(0xFF514758) else Color(0xFFC5A487),
        Offset(bx, by), Size(w, h), CornerRadius(if (style == 1) 15f else 27f))
    drawRoundRect(if (style == 1) Color(0xFF3F5265) else Color(0xFF7D685F),
        Offset(bx + 11f, by + 12f), Size(w - 22f, h - 27f),
        CornerRadius(if (style == 1) 9f else 22f))
    val xx=bx+21f; val yy=by+23f
    drawRoundRect(Brush.verticalGradient(
        listOf(Color(0xFFB1DDEA), Color(0xFFE1EDE6)),
        startY=yy,endY=yy+h-54f
    ), Offset(xx,yy),Size(w-42f,h-60f),CornerRadius(9f))
    val hills=Path().apply {
        moveTo(xx,yy+h-103f)
        quadraticBezierTo(xx+74f,yy+h-160f,xx+157f,yy+h-112f)
        quadraticBezierTo(xx+206f,yy+h-144f,xx+w-42f,yy+h-118f)
        lineTo(xx+w-42f,yy+h-60f);lineTo(xx,yy+h-60f);close()
    }
    drawPath(hills,Color(0xFF9FC5AA))
    drawCircle(Color(0xFFFFECB0),14f,Offset(xx+w-89f,yy+36f))
    // A tiny playful butterfly silhouette on the screen.
    drawOval(Color(0xFFF0B9D1),Offset(xx+65f,yy+48f),Size(20f,18f))
    drawOval(Color(0xFFF9D5AD),Offset(xx+87f,yy+48f),Size(20f,18f))
    drawLine(Color(0xFF98798F),Offset(xx+86f,yy+47f),
        Offset(xx+86f,yy+72f),2.5f)
    drawRoundRect(if(style==1) Color(0xFF625B67) else Color(0xFFA17B68),
        Offset(bx+w*.5f-41f,by+h-5f),Size(82f,12f),CornerRadius(6f))
    if(style==2) {
        for(i in 0..3){
            drawCircle(Color(0xFFF9E5CF),3f,
                Offset(bx+18f+i*12f,by+h-10f))
        }
    }
}

internal fun DrawScope.drawCompactPaintings(style:Int) {
    // All picture styles fit to the left of the television with no overlap.
    val frames=if(style==1) listOf(Triple(890f,214f,200f))
        else if(style==2)listOf(
            Triple(873f,199f,80f),
            Triple(975f,194f,91f),
            Triple(1081f,211f,77f)
        )
        else listOf(
            Triple(887f,216f,94f),
            Triple(1002f,201f,118f),
            Triple(1135f,222f,71f)
        )
    for((i,frame)in frames.withIndex()){
        val (x,y,w)=frame
        val h=if(style==1)129f else if(i%2==0)96f else 123f
        drawRoundRect(Color(0xFF937581).copy(alpha=.14f),
            Offset(x+6f,y+7f),Size(w,h),CornerRadius(9f))
        drawRoundRect(if(style>=3)premiumGalleryFrame(style)
            else if(style==2)Color(0xFFBCA0BE) else Color(0xFFBA927A),
            Offset(x,y),Size(w,h),CornerRadius(8f))
        drawRoundRect(Color(0xFFFFF5EE),
            Offset(x+8f,y+8f),Size(w-16f,h-16f),CornerRadius(6f))
        drawRect(Color(0xFFBDD9D7),Offset(x+15f,y+16f),Size(w-30f,h-33f))
        val landscape=Path().apply{
            moveTo(x+15f,y+h-40f)
            quadraticBezierTo(x+w*.38f,y+h-100f,x+w*.61f,y+h-45f)
            quadraticBezierTo(x+w*.83f,y+h-75f,x+w-15f,y+h-44f)
            lineTo(x+w-15f,y+h-17f)
            lineTo(x+15f,y+h-17f)
            close()
        }
        drawPath(landscape,Color(0xFF9BBBA0))
        drawCircle(Color(0xFFFFE6B0),if(style==1)12f else 8f,
            Offset(x+w*.76f,y+30f))
        if(style>=3) {
            drawRoundRect(premiumGalleryFrame(style),Offset(x+3f,y+3f),
                Size(w-6f,h-6f),CornerRadius(7f),
                style=androidx.compose.ui.graphics.drawscope.Stroke(width=2.3f))
            if(style>=4)drawCircle(Color(0xFFFFF5D7),5f,Offset(x+w*.5f,y+5f))
            if(style>=5)drawLine(Color.White,Offset(x+17f,y+22f),
                Offset(x+w-17f,y+22f),2f)
        }
    }
}

private fun premiumGalleryFrame(style:Int)=when(style){
    3->Color(0xFFAEA0BD)
    4->Color(0xFFC79B4B)
    else->Color(0xFF91B7D1)
}
