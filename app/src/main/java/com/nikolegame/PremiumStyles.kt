package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke

// Premium decoration is drawn INSIDE the existing furniture footprint.
// Never move, enlarge or reposition colliders when introducing new shop styles.
private fun premiumMetal(style:Int)=when(style) {
    3->Color(0xFFB7A6BD) // pearl silver
    4->Color(0xFFCEA04F) // polished gold
    else->Color(0xFF8CACC9) // diamond / platinum
}
private fun premiumGem(style:Int)=when(style){
    3->Color(0xFFFFF9F5)
    4->Color(0xFFFFE0A1)
    else->Color(0xFFEBFCFF)
}
private fun premiumVelvet(style:Int)=when(style){
    3->Color(0xFFF6DFE8)
    4->Color(0xFFE9BDD1)
    else->Color(0xFFBFC9EC)
}
private fun DrawScope.jewel(x:Float,y:Float,r:Float,style:Int){
    val metal=premiumMetal(style)
    drawCircle(metal,r+3f,Offset(x,y))
    drawCircle(premiumGem(style),r,Offset(x,y))
    drawLine(Color.White.copy(alpha=.9f),Offset(x-r*.45f,y),Offset(x+r*.45f,y),1.5f)
    if(style>=5) {
        drawLine(Color.White.copy(alpha=.9f),
            Offset(x,y-r*.55f),Offset(x,y+r*.55f),1.5f)
    }
}

/** Called over the existing highest regular style (2), keeping physical dimensions. */
internal fun DrawScope.drawPremiumFurnishing(category:String,style:Int){
    if(style<3)return
    val metal=premiumMetal(style)
    val gem=premiumGem(style)
    val velvet=premiumVelvet(style)
    val detail=style-2
    when(category){
        "bed"->{
            drawRoundRect(velvet.copy(alpha=.94f),Offset(571f,602f),
                Size(230f,65f),CornerRadius(16f))
            drawLine(metal,Offset(417f,435f),Offset(840f,435f),5f)
            for(i in 0 until (detail*3+2)) {
                val x=432f+i*395f/(detail*3+1)
                jewel(x,451f,3.3f+detail*.65f,style)
            }
            drawLine(metal.copy(alpha=.85f),Offset(584f,623f),Offset(788f,623f),3f)
            if(style>=4){
                for(x in listOf(433f,795f))
                    drawRoundRect(metal.copy(alpha=.66f),Offset(x,472f),
                        Size(13f,132f),CornerRadius(6f))
                jewel(633f,436f,10f,style)
            }
            if(style>=5){
                for(i in 0..6)jewel(594f+i*28f,655f,3.8f,style)
                drawOval(Color.White.copy(alpha=.32f),Offset(472f,550f),
                    Size(292f,41f))
            }
        }
        "wardrobe"->{
            for(i in 0..2) {
                val x=1549f+i*99f
                drawRoundRect(metal.copy(alpha=.85f),
                    Offset(x+9f,353f),Size(70f,244f),CornerRadius(12f),
                    style=Stroke(width=2.5f+detail*.7f))
                jewel(x+76f,472f,3.8f+detail,style)
                if(style>=4) {
                    drawRoundRect(velvet.copy(alpha=.46f),Offset(x+20f,372f),
                        Size(48f,43f),CornerRadius(19f))
                }
                if(style>=5){
                    for(y in listOf(383f,548f))jewel(x+43f,y,5f,style)
                }
            }
            drawLine(metal,Offset(1548f,343f),Offset(1830f,343f),6f)
            for(i in 0 until detail+2)jewel(1565f+i*238f/(detail+1),331f,4.3f,style)
        }
        "table"->{
            drawLine(metal,Offset(1926f,495f),Offset(2290f,495f),5f)
            drawRoundRect(metal.copy(alpha=.6f),Offset(2018f,537f),
                Size(205f,45f),CornerRadius(9f),style=Stroke(width=2.5f))
            for(i in 0 until detail*3+3) {
                val x=1933f+i*345f/(detail*3+2)
                jewel(x,474f,3f+detail*.7f,style)
            }
            if(style>=4){
                drawRoundRect(velvet,Offset(2066f,453f),Size(83f,20f),CornerRadius(8f))
                jewel(2108f,461f,5f,style)
            }
            if(style>=5){
                for(x in listOf(1958f,2269f))jewel(x,663f,5f,style)
            }
        }
        "chair"->{
            drawRoundRect(velvet.copy(alpha=.88f),Offset(2065f,538f),
                Size(136f,87f),CornerRadius(31f))
            drawRoundRect(metal,Offset(2059f,529f),Size(149f,117f),
                CornerRadius(39f),style=Stroke(width=3f+detail*.5f))
            for(i in 0 until detail+3)
                jewel(2078f+i*108f/(detail+2),565f,3.5f,style)
            if(style>=4){
                drawLine(metal,Offset(2053f,666f),Offset(2215f,666f),5f)
                jewel(2133f,533f,10f,style)
            }
            if(style>=5){
                for(x in listOf(2049f,2232f))jewel(x,632f,5f,style)
            }
        }
        "rug"->{
            drawOval(metal.copy(alpha=.7f),Offset(1039f,777f),
                Size(330f,77f),style=Stroke(width=4f+detail))
            drawOval(velvet.copy(alpha=.85f),Offset(1105f,790f),
                Size(194f,42f))
            for(i in 0 until detail*4+4){
                val a=i*6.2831853f/(detail*4+4)
                val x=1203f+kotlin.math.cos(a)*157f
                val y=814f+kotlin.math.sin(a)*29f
                jewel(x,y,2.8f+detail*.6f,style)
            }
            if(style>=5)jewel(1203f,812f,11f,style)
        }
        "painting"->{
            for(i in 0..5){
                val x=1015f+(i%3)*143f
                val y=190f+(i/3)*119f
                val w=if(i%2==0)102f else 84f
                val h=if(i%2==0)92f else 104f
                drawRoundRect(metal,Offset(x+2f,y+2f),
                    Size(w-4f,h-4f),CornerRadius(10f),
                    style=Stroke(width=2f+detail))
                if(style>=4)jewel(x+w*.5f,y+5f,3f+detail,style)
            }
        }
        "ceiling"->{
            drawLine(metal,Offset(1117f,91f),Offset(1263f,91f),6f)
            for(i in 0 until (detail*2+3)){
                val x=1121f+i*138f/(detail*2+2)
                jewel(x,133f+(i%2)*9f,4f+detail,style)
            }
            if(style>=4)jewel(1190f,91f,9f,style)
            if(style>=5){
                for(x in listOf(1130f,1250f))
                    drawLine(Color.White.copy(alpha=.8f),Offset(x,92f),Offset(x,157f),2f)
            }
        }
        "lamp"->{
            drawRoundRect(velvet,Offset(2202f,408f),
                Size(38f,36f),CornerRadius(18f))
            drawLine(metal,Offset(2204f,445f),Offset(2240f,445f),3f)
            jewel(2221f,415f,5f+detail,style)
            if(style>=4)for(x in listOf(2207f,2235f))jewel(x,403f,4f,style)
            if(style>=5)jewel(2220f,384f,5f,style)
        }
        "tv"->{
            drawRoundRect(metal,Offset(1218f,238f),Size(278f,179f),
                CornerRadius(24f),style=Stroke(width=4f+detail))
            for(i in 0 until detail*2+2) {
                val x=1236f+i*242f/(detail*2+1)
                jewel(x,247f,3.5f,style)
            }
            if(style>=4)jewel(1475f,402f,5f,style)
            if(style>=5)
                drawLine(Color.White.copy(alpha=.76f),
                    Offset(1260f,267f),Offset(1440f,267f),3f)
        }
        "fridge"->{
            // The ornament stays on the TOP door: an open fridge still
            // displays its food and the door can swing freely to the left.
            drawRoundRect(metal,Offset(466f,282f),Size(234f,121f),
                CornerRadius(28f),style=Stroke(width=3f+detail))
            jewel(580f,320f,8f+detail,style)
            for(i in 0 until detail*2+2)
                jewel(482f+i*201f/(detail*2+1),377f,3.4f,style)
            if(style>=4){
                drawLine(metal,Offset(491f,417f),Offset(677f,417f),3f)
            }
            if(style>=5){
                for(x in listOf(500f,667f))jewel(x,290f,5f,style)
            }
        }
    }
}

/** Surface finishes never modify furniture locations or walkable ground. */
internal fun DrawScope.drawPremiumWallpaper(style:Int){
    val bg=when(style){
        3->listOf(Color(0xFFFFF9F2),Color(0xFFF3DFE2))
        4->listOf(Color(0xFFFFF2D7),Color(0xFFEED4AE))
        else->listOf(Color(0xFFF9FCFF),Color(0xFFDEDFF3))
    }
    drawRect(Brush.verticalGradient(bg,startY=0f,endY=575f),
        Offset.Zero,Size(2700f,575f))
    val metal=premiumMetal(style)
    val detail=style-2
    for(c in 0..26){
        val x=48f+c*101f
        drawLine(metal.copy(alpha=.3f),Offset(x,55f),Offset(x,563f),
            if(style>=5)3f else 2f)
        for(row in 0..3){
            val y=113f+row*125f
            drawCircle(metal.copy(alpha=.40f),9f+detail,Offset(x+50f,y))
            drawCircle(premiumGem(style),4.5f+detail*.7f,Offset(x+50f,y))
            if(style>=4){
                for(dx in listOf(-17f,17f)){
                    drawCircle(metal.copy(alpha=.36f),5f,Offset(x+50f+dx,y))
                }
            }
            if(style>=5){
                drawLine(metal.copy(alpha=.5f),
                    Offset(x+50f,y-22f),Offset(x+50f,y+22f),2f)
            }
        }
    }
    drawRect(metal.copy(alpha=.75f),Offset(0f,568f),Size(2700f,9f))
    drawRect(Color(0xFFFFF8EF),Offset(0f,577f),Size(2700f,17f))
}
internal fun DrawScope.drawPremiumFloor(style:Int){
    val base=when(style){
        3->Color(0xFFE8D5C3)
        4->Color(0xFFD7B789)
        else->Color(0xFFE7E8F1)
    }
    val line=premiumMetal(style)
    drawRect(base,Offset(0f,596f),Size(2700f,304f))
    if(style<5){
        // Inlaid parquet grows progressively more elaborate.
        for(row in 0..9)for(col in 0..26){
            val x=col*104f+(if(row%2==0)0f else 52f)
            val y=599f+row*31f
            drawRoundRect(if((row+col)%2==0)base else
                base.copy(alpha=.77f),Offset(x,y),Size(100f,28f),CornerRadius(2f),
                style=Stroke(width=1.6f))
            drawLine(line.copy(alpha=.5f),Offset(x+12f,y+6f),
                Offset(x+89f,y+23f),1.2f)
            if(style>=4 && col%3==0)jewel(x+50f,y+15f,3f,style)
        }
    } else {
        // Veined marble with framed diamond mosaics.
        for(row in 0..5)for(col in 0..23){
            val x=col*116f;val y=600f+row*52f
            drawRect(if((row+col)%2==0)Color(0xFFF7F9FF)
                else Color(0xFFDEE5F0),Offset(x,y),Size(113f,49f))
            drawLine(line.copy(alpha=.5f),Offset(x+9f,y+40f),
                Offset(x+67f,y+12f),2f)
            if(col%2==0)jewel(x+100f,y+25f,3f,style)
        }
    }
}