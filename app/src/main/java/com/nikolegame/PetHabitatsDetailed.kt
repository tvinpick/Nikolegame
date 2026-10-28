package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import kotlin.math.cos
import kotlin.math.sin

internal const val PET_HOME_ART_SCALE = 1.16f

// Detailed miniature habitats. One 280 x 184 world-space display niche against
// the bedroom wall for EVERY tier; footprint and navigation never change.
private val line=Color(0xFF675D62)
private val oak=Color(0xFFCAA47E)
private val blush=Color(0xFFF3C8DA)
private val lilac=Color(0xFFCCB6DF)
private val sky=Color(0xFFAED8E9)
private val foliage=Color(0xFF9FBF95)
private val ivory=Color(0xFFFFF2DF)
private val gold=Color(0xFFD5AD6C)

private fun DrawScope.panel(x:Float,y:Float,w:Float,h:Float,color:Color,round:Float=5f){
    drawRoundRect(color,Offset(x,y),Size(w,h),CornerRadius(round))
    drawRoundRect(line.copy(alpha=.75f),Offset(x,y),Size(w,h),
        CornerRadius(round),style=Stroke(width=2.5f))
}
private fun DrawScope.stick(x1:Float,y1:Float,x2:Float,y2:Float,color:Color=line,w:Float=3f){
    drawLine(color,Offset(x1,y1),Offset(x2,y2),w)
}
private fun DrawScope.star(x:Float,y:Float,c:Color=gold,r:Float=6f){
    drawCircle(c,r,Offset(x,y))
    drawCircle(Color.White.copy(alpha=.8f),r*.35f,Offset(x-1.3f,y-1.2f))
}
private fun DrawScope.woodGrain(x:Float,y:Float,w:Float,h:Float,n:Int=5){
    for(i in 1..n) {
        val xx=x+w*i/(n+1)
        stick(xx,y+7f,xx+3f,y+h-7f,Color(0xFF926F5A).copy(alpha=.55f),1.5f)
    }
}
private fun DrawScope.gable(x:Float,y:Float,w:Float,h:Float,c:Color=oak){
    val roof=Path().apply{
        moveTo(x-5f,y+h);lineTo(x+w*.5f,y);lineTo(x+w+5f,y+h);close()
    }
    drawPath(roof,c)
    drawPath(roof,line,style=Stroke(width=3f))
    stick(x+13f,y+h-9f,x+w*.5f,y+11f,ivory.copy(alpha=.7f),2f)
}
private fun DrawScope.door(x:Float,y:Float,w:Float,h:Float,c:Color=Color(0xFF6B5866)){
    drawRoundRect(c,Offset(x,y),Size(w,h),CornerRadius(w*.48f,w*.48f))
    drawOval(Color(0xFF423E4D),Offset(x+5f,y+h*.55f),Size(w-10f,h*.41f))
}
private fun DrawScope.bars(x:Float,y:Float,w:Float,h:Float,spacing:Float=16f,metal:Color=line){
    panel(x,y,w,h,Color(0xFFEAF1F0).copy(alpha=.25f))
    val n=(w/spacing).toInt()
    for(i in 1 until n){
        val xx=x+i*w/n
        stick(xx,y+4f,xx,y+h-4f,metal.copy(alpha=.72f),1.7f)
    }
    for(f in listOf(.30f,.62f)){
        stick(x+3f,y+h*f,x+w-3f,y+h*f,metal.copy(alpha=.57f),1.7f)
    }
}
private fun DrawScope.wheel(cx:Float,cy:Float,r:Float,color:Color,phase:Float=0f){
    drawCircle(line,r+4f,Offset(cx,cy))
    drawCircle(color,r,Offset(cx,cy))
    drawCircle(ivory,r-8f,Offset(cx,cy))
    for(i in 0..7){
        val a=i*.785398f+phase
        stick(cx,cy,cx+cos(a)*(r-9f),cy+sin(a)*(r-9f),line.copy(alpha=.65f),2f)
    }
    drawCircle(line,6f,Offset(cx,cy))
    star(cx,cy,Color.White,3f)
}
private fun DrawScope.bed(x:Float,y:Float,w:Float,c:Color=blush){
    drawOval(line.copy(alpha=.2f),Offset(x-5f,y+18f),Size(w+10f,19f))
    drawRoundRect(line,Offset(x,y),Size(w,33f),CornerRadius(16f))
    drawRoundRect(c,Offset(x+5f,y+4f),Size(w-10f,24f),CornerRadius(12f))
    drawOval(ivory,Offset(x+12f,y+6f),Size(w*.32f,17f))
    drawLine(Color.White.copy(alpha=.78f),
        Offset(x+w*.57f,y+11f),Offset(x+w-15f,y+11f),2f)
}
private fun DrawScope.bowl(x:Float,y:Float,c:Color=sky){
    drawOval(line,Offset(x,y),Size(33f,17f))
    drawOval(c,Offset(x+2f,y+1f),Size(29f,12f))
    for(i in 0..2)drawCircle(Color(0xFFB99060),2.5f,
        Offset(x+8f+i*8f,y+6f))
}
private fun DrawScope.ladder(x:Float,y:Float,x2:Float,y2:Float,n:Int=5){
    stick(x,y,x2,y2,oak,5f)
    stick(x+17f,y,x2+17f,y2,oak,5f)
    for(i in 1..n){
        val t=i.toFloat()/(n+1)
        stick(x+(x2-x)*t,y+(y2-y)*t,
            x+17f+(x2-x)*t,y2* t+y*(1f-t),
            Color(0xFF976E55),3f)
    }
}
private fun DrawScope.fence(x:Float,y:Float,w:Float,h:Float){
    stick(x,y+h-2f,x+w,y+h-2f,oak,5f)
    stick(x,y+h*.55f,x+w,y+h*.55f,oak,4f)
    for(i in 0..(w/19f).toInt()){
        val xx=x+i*18f
        panel(xx,y,9f,h,Color(0xFFDEC09A),3f)
    }
}
private fun DrawScope.castle(x:Float,y:Float,w:Float,color:Color){
    panel(x+18f,y+28f,w-36f,88f,color)
    for(i in 0..2){
        val xx=x+6f+i*(w-35f)/2f
        panel(xx,y+4f,43f,111f,color)
        gable(xx-3f,y-31f,49f,36f,blush)
        star(xx+20f,y+20f,ivory,5f)
    }
    door(x+w*.5f-26f,y+69f,52f,47f)
    for(i in 0..4)star(x+32f+i*(w-64f)/4f,y+35f,ivory,3f)
}
private fun DrawScope.plant(x:Float,y:Float){
    for(i in -2..2){
        stick(x,y,x+i*7f,y-27f+ kotlin.math.abs(i)*4f,
            Color(0xFF679D72),2.6f)
        drawOval(if(i%2==0)foliage else Color(0xFFB2D39D),
            Offset(x+i*7f-6f,y-31f+kotlin.math.abs(i)*4f),Size(13f,15f))
    }
}
private fun DrawScope.ball(x:Float,y:Float,c:Color=blush){
    drawCircle(line,8f,Offset(x,y));drawCircle(c,6f,Offset(x,y))
    stick(x-3f,y-3f,x+4f,y+4f,Color.White.copy(alpha=.8f),2f)
}
private fun DrawScope.shelf(x:Float,y:Float,w:Float){
    panel(x,y,w,8f,oak,2f)
    for(xx in listOf(x+14f,x+w-19f))
        stick(xx,y+6f,xx-2f,y+30f,line.copy(alpha=.6f),2f)
}

internal fun DrawScope.renderDetailedPetHabitat(animal:String,style:Int,animTick:Int=0){
    if(style !in 1..6)return
    withTransform({translate(1003f,560f)}){
        // Ground shadow: all variants end at the same safe back-wall position.
        drawOval(Color(0xFF655A64).copy(alpha=.13f),
            Offset(5f,167f),Size(271f,17f))
        when(animal){
            "dog"->detailedDogHouse(style,animTick)
            "cat"->detailedCatHouse(style,animTick)
            "hamster"->detailedHamsterHouse(style,animTick)
            "parrot"->detailedBirdHouse(style,animTick)
            "turtle"->detailedTurtleHouse(style,animTick)
        }
    }
}
private fun DrawScope.detailedDogHouse(s:Int,tick:Int){
    when(s){
        1->{
            panel(10f,50f,259f,118f,Color(0xFFD3D6D5))
            bed(42f,131f,132f,Color(0xFFE8D4BE))
            bars(10f,50f,259f,118f,16f,Color(0xFF7B858A))
            stick(206f,50f,206f,168f,Color(0xFF7B858A),4f)
            bowl(214f,148f)
        }
        2,3->{
            panel(9f,32f,263f,139f,Color(0xFFE3E8E6))
            panel(18f,137f,246f,29f,if(s==2)blush else ivory)
            bed(39f,117f,128f,blush)
            bowl(207f,150f)
            if(s>=3){
                ball(208f,115f);ball(251f,137f,sky)
                shelf(35f,74f,120f)
            }
            bars(9f,32f,263f,139f,19f,Color(0xFF84929E))
            if(s>=3)stick(187f,32f,187f,171f,Color(0xFF777E82),4f)
        }
        4,5->{
            panel(17f,64f,246f,104f,oak)
            woodGrain(25f,64f,229f,102f,9)
            gable(4f,5f,270f,70f,if(s==4)Color(0xFFBA927C)
                else Color(0xFF9F7969))
            door(89f,98f,95f,69f)
            panel(90f,83f,94f,18f,ivory,7f)
            if(s==5){
                bed(91f,143f,98f,Color(0xFFF4C4C4))
                fence(3f,140f,70f,34f)
                fence(208f,140f,67f,34f)
                bowl(211f,149f)
                star(135f,45f,gold,8f)
            }else bowl(202f,145f)
        }
        else->{
            panel(10f,51f,256f,118f,Color(0xFFA37E66))
            panel(20f,61f,236f,101f,ivory)
            panel(22f,10f,232f,40f,oak)
            gable(36f,-9f,209f,24f,gold)
            for(i in 0..6)star(38f+i*33f,40f,gold,6f)
            drawRoundRect(Color(0xFFAF8C70),Offset(41f,94f),
                Size(191f,54f),CornerRadius(23f))
            bed(48f,105f,179f,blush)
            fence(6f,140f,44f,34f)
            fence(225f,140f,49f,34f)
            bowl(217f,145f)
            star(135f,20f,ivory,11f)
        }
    }
}
private fun DrawScope.detailedCatHouse(s:Int,tick:Int){
    when(s){
        1,2,3,4->{
            panel(10f,29f,258f,143f,Color(0xFFF2EDE8))
            if(s==1){
                bed(37f,132f,141f,Color(0xFFDCC5B5))
                panel(212f,93f,19f,64f,oak)
                bowl(192f,148f)
            }
            if(s>=2){
                shelf(19f,76f,240f)
                bed(32f,127f,105f,blush)
                ladder(166f,146f,196f,87f,5)
                if(s>=3){
                    shelf(33f,110f,94f)
                    panel(170f,126f,67f,32f,oak)
                    door(180f,134f,45f,24f)
                }
                if(s==4){
                    shelf(28f,40f,205f)
                    bed(104f,20f,110f,lilac)
                    drawOval(blush,Offset(114f,79f),Size(93f,12f))
                    stick(114f,69f,136f,91f,gold,3f)
                }
            }
            bars(10f,29f,258f,143f,18f,Color(0xFF877A7D))
            if(s>=3){
                ball(58f,85f)
                star(225f,53f)
            }
        }
        5->{
            panel(8f,16f,264f,154f,Color(0xFFE1C7AE))
            panel(18f,27f,244f,132f,ivory)
            gable(13f,-9f,254f,41f,oak)
            shelf(31f,77f,211f)
            bed(30f,125f,101f,blush)
            bed(150f,47f,91f,lilac)
            ladder(129f,144f,157f,84f)
            panel(164f,112f,70f,43f,oak)
            door(172f,125f,53f,30f)
            panel(139f,23f,3f,126f,oak)
            star(134f,19f,gold,9f)
        }
        else->{
            castle(9f,9f,262f,oak)
            shelf(27f,84f,224f)
            bed(32f,127f,103f,blush)
            bed(155f,80f,87f,lilac)
            ladder(134f,151f,156f,91f,4)
            fence(6f,143f,70f,27f)
            fence(208f,143f,65f,27f)
            ball(222f,132f,sky)
            star(137f,10f,gold,11f)
        }
    }
}
private fun DrawScope.detailedHamsterHouse(s:Int,tick:Int){
    when(s){
        1,2,3->{
            panel(10f,53f,258f,112f,if(s==1)sky else if(s==2)blush else foliage)
            panel(17f,70f,244f,79f,ivory)
            panel(13f,137f,252f,25f,if(s==1)sky else if(s==2)blush else foliage)
            wheel(95f,110f,34f,if(s==1)sky else if(s==2)blush else gold,
                if(tick>0)tick*.15f else 0f)
            bowl(196f,140f)
            if(s>=2){
                panel(183f,108f,57f,34f,oak)
                door(191f,120f,36f,22f)
                ladder(127f,145f,156f,103f,4)
                shelf(157f,91f,90f)
            }
            if(s==3){
                panel(181f,44f,71f,32f,foliage)
                door(195f,53f,43f,24f)
                drawOval(lilac,Offset(216f,72f),Size(43f,29f))
                drawOval(sky,Offset(247f,86f),Size(32f,23f))
            }
            bars(10f,53f,258f,112f,17f,Color(0xFF8D8585))
        }
        4,5->{
            panel(5f,31f,268f,136f,if(s==4)lilac else oak)
            panel(15f,40f,248f,114f,ivory)
            shelf(26f,90f,225f)
            wheel(74f,126f,35f,lilac,if(tick>0)tick*.15f else 0f)
            wheel(188f,66f,25f,sky,if(tick>0)tick*.1f else 0f)
            panel(151f,121f,77f,36f,oak)
            door(168f,131f,47f,26f)
            ladder(113f,147f,142f,96f,5)
            bowl(234f,143f)
            drawOval(sky,Offset(15f,52f),Size(49f,30f))
            drawOval(blush,Offset(217f,53f),Size(49f,30f))
            if(s==4)bars(5f,31f,268f,136f,20f,Color(0xFF8B7E93))
            else{
                panel(5f,17f,268f,19f,oak)
                woodGrain(11f,31f,258f,134f,11)
                star(136f,22f,gold,8f)
            }
        }
        else->{
            panel(8f,68f,262f,100f,Color(0xFFF3E8E8))
            panel(14f,81f,251f,76f,ivory)
            castle(45f,3f,191f,Color(0xFFF0D4B7))
            wheel(64f,127f,28f,sky,if(tick>0)tick*.16f else 0f)
            wheel(210f,129f,27f,blush,if(tick>0)tick*.10f else 0f)
            door(113f,107f,54f,48f)
            ladder(79f,149f,100f,94f,4)
            ladder(187f,151f,181f,94f,4)
            shelf(25f,156f,228f)
            star(139f,-5f,gold,9f)
        }
    }
}
private fun DrawScope.detailedBirdHouse(s:Int,tick:Int){
    when(s){
        1->{
            drawOval(sky,Offset(50f,121f),Size(176f,45f))
            drawRoundRect(sky,Offset(53f,35f),Size(169f,107f),CornerRadius(75f))
            for(i in 0..11){
                val xx=62f+i*14f
                stick(xx,93f,xx,141f,line.copy(alpha=.65f),1.6f)
            }
            stick(69f,111f,207f,111f,oak,7f)
            bowl(165f,134f,sky)
            drawCircle(line,9f,Offset(139f,28f))
        }
        2,3->{
            panel(14f,43f,252f,125f,if(s==2)blush else oak)
            panel(19f,47f,241f,113f,Color(0xFFFFF7F0))
            stick(34f,105f,244f,105f,oak,6f)
            stick(92f,128f,205f,82f,oak,6f)
            if(s==2){
                stick(152f,61f,152f,102f,line,2.6f)
                stick(133f,102f,174f,102f,line,4f)
                bowl(213f,139f)
            }else{
                gable(11f,4f,257f,42f,Color(0xFFD3A791))
                ladder(81f,149f,130f,105f,6)
                drawCircle(line,22f,Offset(216f,91f))
                drawCircle(Color(0xFFE4F6FF),17f,Offset(216f,91f))
                bowl(201f,148f)
            }
            bars(14f,43f,252f,125f,16f,Color(0xFF887B85))
        }
        4->{
            panel(10f,48f,260f,117f,lilac)
            gable(10f,4f,260f,48f,lilac)
            panel(21f,55f,238f,98f,Color(0xFFFAF7F5))
            stick(32f,112f,244f,112f,oak,7f)
            ladder(65f,149f,104f,106f,5)
            drawCircle(line,25f,Offset(185f,99f))
            drawCircle(ivory,18f,Offset(185f,99f))
            drawOval(blush,Offset(220f,126f),Size(40f,22f))
            bars(10f,48f,260f,117f,18f,Color(0xFF9683A4))
        }
        5->{
            panel(13f,10f,254f,154f,Color(0xFF858D95))
            panel(22f,19f,236f,135f,Color(0xFFEEF5EF))
            shelf(28f,52f,220f)
            stick(26f,89f,250f,89f,oak,7f)
            ladder(52f,150f,105f,96f,6)
            drawCircle(line,23f,Offset(174f,110f))
            drawCircle(lilac,18f,Offset(174f,110f))
            for(i in 0..3)ball(79f+i*39f,72f,
                if(i%2==0)foliage else blush)
            bowl(217f,138f,sky)
            bars(13f,10f,254f,154f,18f,Color(0xFF7C7F8B))
            panel(20f,164f,240f,11f,Color(0xFF8E7972))
        }
        else->{
            // Fairytale castle with turrets, bridges and play structures.
            castle(7f,4f,266f,Color(0xFFECD3AF))
            for(i in 0..2){
                stick(33f+i*93f,88f,55f+i*82f,143f,oak,6f)
            }
            ladder(47f,150f,93f,110f,5)
            drawCircle(line,24f,Offset(189f,122f))
            drawCircle(lilac,19f,Offset(189f,122f))
            panel(28f,139f,224f,14f,gold)
            bowl(226f,148f,sky)
            for(i in 0..3)star(48f+i*65f,39f,ivory,6f)
        }
    }
}
private fun DrawScope.detailedTurtleHouse(s:Int,tick:Int){
    when(s){
        1->{
            panel(9f,111f,262f,57f,Color(0xFFD3DFE5))
            panel(16f,117f,249f,42f,Color(0xFFEBD2A8))
            panel(165f,114f,69f,40f,oak)
            door(181f,128f,38f,25f)
            drawOval(sky,Offset(44f,133f),Size(55f,18f))
        }
        2,3->{
            panel(8f,65f,263f,103f,Color(0xFFE1ECEF))
            panel(16f,77f,247f,80f,Color(0xFFC9AE96))
            if(s==2) {
                drawOval(Color(0xFF99948E),Offset(29f,131f),Size(75f,24f))
                drawOval(oak,Offset(143f,119f),Size(97f,38f))
                door(158f,129f,57f,27f)
            }else{
                panel(26f,118f,97f,35f,oak)
                gable(23f,91f,101f,30f,Color(0xFFAF8969))
                door(54f,127f,45f,28f)
                drawOval(sky,Offset(175f,126f),Size(65f,28f))
                plant(237f,120f)
            }
            stick(14f,65f,263f,65f,line,2f)
            stick(80f,65f,80f,159f,line.copy(alpha=.4f),2f)
            stick(195f,65f,195f,159f,line.copy(alpha=.4f),2f)
        }
        4->{
            panel(5f,65f,268f,105f,oak)
            panel(13f,74f,250f,87f,Color(0xFFB8A08A))
            panel(30f,102f,103f,40f,Color(0xFFE6C4A8))
            door(62f,112f,45f,31f)
            drawOval(sky,Offset(173f,125f),Size(82f,26f))
            plant(223f,117f);plant(145f,125f)
            shelf(52f,86f,96f)
            ladder(129f,141f,164f,88f,5)
            for(i in 0..4)star(33f+i*50f,69f,ivory,3.5f)
        }
        5->{
            panel(7f,33f,264f,138f,Color(0xFFAC8467))
            panel(15f,40f,247f,117f,Color(0xFFD3E9DF))
            shelf(27f,103f,110f)
            panel(30f,78f,101f,29f,oak)
            gable(27f,51f,107f,30f,oak)
            door(58f,86f,53f,32f)
            ladder(138f,126f,164f,81f,4)
            drawOval(sky,Offset(173f,111f),Size(84f,42f))
            plant(216f,118f);plant(162f,113f)
            for(i in 0..4)drawOval(Color(0xFFB5B7A7),
                Offset(25f+i*30f,133f+(i%2)*5f),Size(23f,12f))
            panel(7f,18f,264f,18f,oak)
            star(137f,26f,gold,8f)
        }
        else->{
            panel(7f,21f,264f,151f,Color(0xFF95745E))
            panel(14f,29f,250f,129f,Color(0xFFE9F3E9))
            castle(11f,33f,129f,Color(0xFFF0D5BB))
            drawOval(sky,Offset(154f,111f),Size(103f,43f))
            drawOval(Color(0xFFB0E3EC),Offset(164f,117f),Size(80f,28f))
            plant(148f,117f);plant(245f,109f)
            stick(135f,149f,188f,124f,oak,11f)
            for(i in 0..3)drawCircle(Color(0xFFB9B1A3),11f,
                Offset(151f+i*23f,154f))
            for(i in 0..6)star(32f+i*35f,32f,ivory,4f)
            panel(7f,12f,264f,15f,gold)
            star(137f,20f,ivory,9f)
        }
    }
}

// The resident is drawn at the appropriate furniture surface. Physical pet
// position stays at the clear approach point: no pet or Nicole teleporting
// through furniture during entry.
internal fun DrawScope.renderPetInHabitat(
    animal:String, style:Int, tick:Int, progress:Float=1f
){
    if(style<=0||animal !in PET_SPECIES)return
    val p=progress.coerceIn(0f,1f)
    val hop=kotlin.math.abs(sin(tick*.13f))*4f*p
    val footX=when(animal) {
        "dog"->1128f
        "cat"->1130f
        "hamster"->1122f
        "parrot"->1142f
        else->1139f
    }
    val footY=when(animal) {
        "dog"->711f
        "cat"->703f
        "hamster"->715f
        "parrot"->718f
        else->718f
    }
    val homeScale=if(animal=="turtle").45f else if(animal=="hamster").36f else .46f
    // Begin at the free-walking approach point with the pet at full size.
    // Move it towards the door and scale down smoothly as it passes behind
    // the home's front opening, then reverse the same frames on exit.
    // Align the full-size dog, cat or other animal with the enlarged house.
    val indoorX=1140f+(footX-1140f)*PET_HOME_ART_SCALE
    val indoorY=730f+(footY-730f)*PET_HOME_ART_SCALE
    val displayX=1140f+(indoorX-1140f)*p
    val displayY=795f+(indoorY-795f)*p
    val displayScale=1f+(homeScale*PET_HOME_ART_SCALE-1f)*p
    withTransform({
        translate(displayX,displayY-hop)
        scale(displayScale,displayScale,Offset.Zero)
    }){
        renderPet(animal,0f,0f,tick,p<.95f)
    }
    // Indoor wheel / perch / sleep effects should not appear outside.
    if(p<.98f)return
    if(animal=="cat"){
        for(i in 0..2) {
            val dy=((tick*.75f+i*21f)%64f)
            drawCircle(Color.White.copy(alpha=.55f),5f,
                Offset(1195f+i*11f,690f-dy))
        }
    } else if(animal=="dog"){
        for(i in 0..2)star(1199f+i*9f,691f-sin(tick*.09f+i)*5f,blush,4f)
    } else if(animal=="hamster"){
        // Wheel spokes rotate visibly while the hamster is using it.
        withTransform({translate(1003f,560f)}){
            wheel(if(style<=3)95f else 74f,
                if(style<=3)110f else 126f,
                if(style<=3)34f else 29f,
                if(style<=3)sky else lilac,tick*.22f)
        }
    } else if(animal=="parrot"){
        // A little swinging perch and softly blinking hanging toy.
        withTransform({translate(1003f,560f)}){
            val angle=sin(tick*.08f)*12f
            stick(138f,57f,138f+angle,109f,line,2f)
            ball(138f+angle,117f,blush)
        }
    } else {
        drawCircle(Color(0xFFBDE0C0).copy(alpha=.40f),
            12f+sin(tick*.15f)*4f,Offset(1195f,700f))
    }
}

// Thin overlay makes the animals appear behind the front bars (not on top of
// the cage). Existing physical collision geometry is unchanged.
internal fun DrawScope.renderPetHabitatFront(animal:String,style:Int){
    if(style<=0 || animal !in PET_SPECIES)return
    if((animal=="hamster"&&style<=4) || (animal=="parrot"&&style<=5) ||
        (animal=="cat"&&style<=4) || (animal=="dog"&&style<=3)){
        withTransform({
            translate(1140f,730f)
            scale(PET_HOME_ART_SCALE,PET_HOME_ART_SCALE,Offset.Zero)
            translate(-1140f,-730f)
        }){
            withTransform({translate(1003f,560f)}){
                for(i in 1..15) {
                    val x=13f+i*16f
                    stick(x,if(animal=="hamster")82f else 91f,x,158f,
                        line.copy(alpha=.25f),1.35f)
                }
            }
        }
    }
}
