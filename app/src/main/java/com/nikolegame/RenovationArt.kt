package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import kotlin.math.cos
import kotlin.math.sin

// Repaintable layers over the original room. Positions and collision geometry
// never change; this keeps Nicole's established navigation intact.
internal fun DrawScope.renderRenovatedWallpaper(style: Int) {
    if (style == 0) return
    val palette = if (style == 1)
        listOf(Color(0xFFF3F9ED), Color(0xFFDDECE0), Color(0xFFC5DCD3))
    else listOf(Color(0xFFF6EEF9), Color(0xFFE9D9F3), Color(0xFFD8C5E9))
    drawRect(Brush.verticalGradient(palette, startY = 0f, endY = 575f),
        Offset.Zero, Size(2700f, 575f))
    for (i in 0..26) {
        val x = 36f + i * 104f
        drawLine(Color.White.copy(alpha = .65f),
            Offset(x, 58f), Offset(x, 557f), 2f)
        drawLine(palette[2].copy(alpha = .55f),
            Offset(x + 9f, 58f), Offset(x + 9f, 557f), 1.2f)
    }
    if (style == 1) {
        // Small mint leaves; deliberately subdued behind the furniture.
        for (i in 0..19) for (j in 0..3) {
            val x = i * 137f + 75f
            val y = 126f + j * 113f
            drawLine(Color(0xFF8DB7A0).copy(alpha = .48f),
                Offset(x, y + 15f), Offset(x + 7f, y - 8f), 2f)
            drawOval(Color(0xFF8DB7A0).copy(alpha = .42f),
                Offset(x - 5f, y - 1f), Size(17f, 8f))
            drawOval(Color(0xFFB2CDAF).copy(alpha = .65f),
                Offset(x + 5f, y - 11f), Size(18f, 8f))
        }
    } else {
        // Lavender medallions and soft pearl details.
        for (i in 0..17) for (j in 0..3) {
            val x = 95f + i * 150f
            val y = 124f + j * 116f
            for (k in 0..3) {
                val a = k * 1.5707964f
                drawCircle(Color(0xFFC5A4DC).copy(alpha = .49f), 6.2f,
                    Offset(x + cos(a) * 10f, y + sin(a) * 10f))
            }
            drawCircle(Color(0xFFFFEAC0), 4f, Offset(x, y))
        }
    }
    drawRect(Color(0xFFBDA7B6), Offset(0f,25f), Size(2700f,22f))
    drawRect(Color(0xFFFFF7EE), Offset(0f,37f), Size(2700f,12f))
    drawRect(Color(0xFFD3B2B8), Offset(0f,568f), Size(2700f,9f))
    drawRect(Color(0xFFFFF2E5), Offset(0f,574f), Size(2700f,22f))
}

internal fun DrawScope.renderRenovatedFloor(style: Int) {
    if (style == 0) return
    if (style == 1) {
        drawRect(Brush.verticalGradient(
            listOf(Color(0xFFEAD6B8), Color(0xFFDCC19D), Color(0xFFC5A27C)),
            startY = 596f, endY = 900f),
            Offset(0f,596f), Size(2700f,304f))
        for (r in 0..10) {
            val y = 598f + r*30f
            drawLine(Color(0xFFB08D72).copy(alpha=.63f),Offset(0f,y),
                Offset(2700f,y),2f)
            for (c in 0..11) {
                val x = c * 250f + if(r%2==0) 0f else 125f
                drawLine(Color(0xFFAE8A68).copy(alpha=.55f),
                    Offset(x,y), Offset(x,y+30f),1.4f)
            }
        }
    } else {
        drawRect(Color(0xFFEADCE6),Offset(0f,596f),Size(2700f,304f))
        for(r in 0..6) for(c in 0..33) {
            val color = if((r+c)%2==0) Color(0xFFFFF8F1) else Color(0xFFE5D4E9)
            val x = c * 81f
            val y = 599f + r * 48f
            drawRect(color,Offset(x,y),Size(79f,46f))
            drawLine(Color.White.copy(alpha=.54f),
                Offset(x+6f,y+5f),Offset(x+73f,y+5f),1.8f)
        }
    }
}

internal fun DrawScope.renderRenovatedFurniture(style: Int) {
    if(style == 0) return
    val paint = if(style == 1) Color(0xFFF5E1D5) else Color(0xFFD7BCE9)
    val trim = if(style == 1) Color(0xFFBC9C90) else Color(0xFF9D7BB8)
    val quilt = if(style == 1) Color(0xFFE5D5BD) else Color(0xFFB99AD7)
    val shine = Color.White.copy(alpha=.46f)

    // Bed: repaint headboard, duvet and footboard while leaving pillow/mattress distinct.
    drawRoundRect(paint.copy(alpha=.79f),Offset(398f,455f),
        Size(93f,188f),CornerRadius(35f))
    drawRoundRect(trim.copy(alpha=.48f),Offset(405f,469f),
        Size(78f,153f),CornerRadius(25f),style=Stroke(width=4f))
    drawRoundRect(quilt.copy(alpha=.86f),Offset(569f,597f),
        Size(220f,70f),CornerRadius(14f))
    for(i in 0..4) drawCircle(shine,5f,Offset(599f+i*43f,633f))
    drawRoundRect(paint.copy(alpha=.8f),Offset(781f,546f),
        Size(44f,127f),CornerRadius(14f))
    drawLine(trim,Offset(795f,570f),Offset(795f,654f),3f)

    // Wardrobe panels: keep both doors, handles and the same physical footprint.
    for(i in 0..1) {
        val x=1566f+i*130f
        drawRoundRect(paint.copy(alpha=.81f),Offset(x,320f),
            Size(122f,274f),CornerRadius(11f))
        for(y in listOf(352f,490f)) {
            drawRoundRect(trim.copy(alpha=.70f),Offset(x+13f,y),
                Size(94f,100f),CornerRadius(11f),style=Stroke(width=4f))
            drawLine(shine,Offset(x+27f,y+11f),
                Offset(x+91f,y+11f),2f)
        }
    }
    for(x in listOf(1680f,1704f)) {
        drawCircle(Color(0xFF95715F),8f,Offset(x,453f))
        drawCircle(Color(0xFFFFE8AD),4.5f,Offset(x,452f))
    }

    // Desk and chair remain at their approved dimensions and locations.
    drawRoundRect(paint.copy(alpha=.85f),Offset(1913f,458f),
        Size(394f,47f),CornerRadius(10f))
    drawLine(trim.copy(alpha=.83f),Offset(1917f,509f),
        Offset(2304f,509f),4f)
    drawRoundRect(paint.copy(alpha=.84f),Offset(2022f,522f),
        Size(131f,33f),CornerRadius(9f))
    drawCircle(trim,5f,Offset(2086f,541f))
    drawRoundRect(paint.copy(alpha=.88f),Offset(2079f,490f),
        Size(102f,125f),CornerRadius(28f))
    drawRoundRect(trim.copy(alpha=.45f),Offset(2091f,501f),
        Size(79f,104f),CornerRadius(24f),style=Stroke(width=3f))
    drawRoundRect(quilt.copy(alpha=.92f),Offset(2048f,599f),
        Size(159f,29f),CornerRadius(10f))
    drawLine(shine,Offset(2063f,606f),Offset(2193f,606f),3f)
}
