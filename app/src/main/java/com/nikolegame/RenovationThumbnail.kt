package com.nikolegame

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.Composable
import kotlin.math.min

// Real game geometry as a miniature, so a non-reading child can see what
// the shop item will look like, not just a generic emoji icon.
@Composable
internal fun RenovationThumbnail(
    item:RenovationItem,
    modifier:Modifier=Modifier.width(153.dp).height(100.dp)
) {
    Canvas(modifier
        .clip(RoundedCornerShape(12.dp))
        .background(Color(0xFFFFF9F6))) {
        if(item.category=="wall" || item.category=="floor") {
            val col=when(item.category) {
                "wall" -> when(item.style) {
                    1->Color(0xFFDAEAD8); 2->Color(0xFFE4D1EE)
                    else->Color(0xFFF1DCE6)
                }
                else -> when(item.style) {
                    1->Color(0xFFDBBEA1); 2->Color(0xFFF2E6EA)
                    else->Color(0xFFB98D70)
                }
            }
            drawRect(col,Offset.Zero,size)
            for(i in 0..5){
                val x=i*size.width/5f
                drawLine(Color.White.copy(alpha=.68f),
                    Offset(x,0f),Offset(x,size.height),2f)
            }
            if(item.category=="wall") {
                for(i in 0..8) {
                    val x=(i%3)*size.width/3f+size.width/6f
                    val y=(i/3)*size.height/3f+size.height/6f
                    drawCircle(Color.White.copy(alpha=.62f),6f,Offset(x,y))
                    drawCircle(Color(0xFFD8AFC3),2.3f,Offset(x,y))
                }
            }else{
                for(i in 0..4){
                    val y=i*size.height/4f
                    drawLine(Color(0xFF997E7A).copy(alpha=.48f),
                        Offset(0f,y),Offset(size.width,y),2f)
                }
            }
            return@Canvas
        }
        val (x,y,w,h)=when(item.category) {
            "bed" -> listOf(355f,339f,520f,432f)
            "wardrobe" -> listOf(1510f,270f,360f,420f)
            "table" -> listOf(1880f,390f,490f,350f)
            "chair" -> listOf(1985f,465f,270f,300f)
            "rug" -> listOf(873f,735f,686f,166f)
            "painting" -> listOf(995f,165f,500f,245f)
            "ceiling" -> listOf(1070f,23f,240f,170f)
            "tv" -> listOf(1197f,207f,345f,228f)
            else -> listOf(2165f,363f,115f,100f)
        }
        val scale=min(size.width/w,size.height/h)*.94f
        val ox=(size.width/scale-w)/2f
        val oy=(size.height/scale-h)/2f
        withTransform({
            scale(scale,scale,Offset.Zero)
            translate(-x+ox,-y+oy)
        }){
            if(item.style==0){
                drawDefaultPreview(item.category)
            }else{
                when(item.category){
                    "bed"->drawSpecialBed(item.style)
                    "wardrobe"->drawSpecialWardrobe(item.style)
                    "table"->drawSpecialTable(item.style)
                    "chair"->drawSpecialChair(item.style)
                    "rug"->drawSpecialRug(item.style)
                    "painting"->drawSpecialPaintings(item.style)
                    "ceiling"->drawCeilingLight(item.style)
                    "lamp"->drawDeskLight(item.style)
                    "tv"->drawRoomTelevision(item.style)
                }
            }
        }
    }
}
private fun DrawScope.drawDefaultPreview(category:String){
    val wood=Color(0xFFD5AA90)
    val trim=Color(0xFF96705E)
    when(category){
        "bed"->{
            drawRoundRect(wood,Offset(384f,451f),Size(113f,240f),CornerRadius(47f))
            drawRoundRect(Color(0xFFFFF9EF),Offset(442f,546f),Size(369f,145f),CornerRadius(21f))
            drawRoundRect(Color(0xFFE6B7CF),Offset(558f,585f),Size(253f,105f),CornerRadius(18f))
            drawRoundRect(wood,Offset(780f,538f),Size(47f,160f),CornerRadius(15f))
        }
        "wardrobe"->{
            drawRoundRect(wood,Offset(1540f,289f),Size(295f,348f),CornerRadius(22f))
            for(i in 0..1){
                val x=1560f+i*129f
                drawRoundRect(Color(0xFFF0DCD0),Offset(x,315f),Size(123f,290f),CornerRadius(11f))
                drawRoundRect(trim,Offset(x+18f,360f),Size(90f,190f),
                    CornerRadius(12f),style=androidx.compose.ui.graphics.drawscope.Stroke(width=4f))
            }
        }
        "table"->{
            for(x in listOf(1930f,2260f))drawRoundRect(wood,Offset(x,500f),Size(23f,216f),CornerRadius(6f))
            drawRoundRect(Color(0xFFF0CFB2),Offset(1905f,452f),Size(405f,56f),CornerRadius(8f))
        }
        "chair"->{
            drawRoundRect(wood,Offset(2072f,482f),Size(116f,171f),CornerRadius(30f))
            drawRoundRect(Color(0xFFE2B8A9),Offset(2042f,602f),Size(173f,34f),CornerRadius(12f))
            for(x in listOf(2062f,2188f))
                drawRoundRect(trim,Offset(x,626f),Size(19f,110f),CornerRadius(6f))
        }
        "rug"->{
            drawOval(Color(0xFFD4ADCD),Offset(903f,755f),Size(639f,116f))
            drawOval(Color(0xFFFFEDDE),Offset(937f,771f),Size(559f,83f))
        }
        "painting"->{
            for(i in 0..2){
                val x=1013f+i*147f
                drawRoundRect(wood,Offset(x,190f),Size(130f,127f),CornerRadius(7f))
                drawRoundRect(Color(0xFFD6E0D2),Offset(x+11f,203f),Size(108f,101f),CornerRadius(5f))
                drawCircle(Color(0xFFFFE4A7),12f,Offset(x+86f,239f))
            }
        }
        "ceiling"->drawCeilingLight(0)
        "lamp"->drawDeskLight(0)
        "tv"->{
            drawRoundRect(Color(0xFFDBCBD8),Offset(1218f,238f),
                Size(290f,167f),CornerRadius(16f))
            drawRoundRect(Color(0xFFF7F2F5),Offset(1231f,250f),
                Size(264f,139f),CornerRadius(11f))
            drawLine(Color(0xFFC49DAE),Offset(1253f,360f),
                Offset(1479f,267f),8f)
        }
    }
}
