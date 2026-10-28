package com.nikolegame

import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import kotlin.math.*

internal fun DrawScope.renderLivingPet(p:PetLife,tick:Int) {
    val exercising=p.state==PetState.PLAY_HOME
    val swing=if(exercising && p.species=="parrot")sin(p.age*3f)*8f else 0f
    drawPosedPet(p.species,p.x+swing,p.y,
        if(exercising && p.species=="hamster")p.age*18f else p.gait,
        p.age,p.facing,p.moving || (exercising && p.species=="hamster"),
        p.action,p.elapsed,p.atHome)
}

/** Joint animation: four independently phased legs, a hinged head and tail.
 * Species scale is constant on the floor, through the door, and inside. */
internal fun DrawScope.drawPosedPet(
    species:String,x:Float,y:Float,gait:Float,time:Float,facing:Float,
    moving:Boolean,action:String,elapsed:Float,inside:Boolean=false
) {
    val asleep=action=="sleep"
    val resting=asleep || action=="rest"
    val eating=action=="feed"
    val playing=action=="play"
    val happy=action=="pet"
    val stretch=action=="stretch"
    val grooming=action=="groom"
    val sniffing=action=="sniff"
    // Distinct horizontal sleeping silhouettes, not compressed walking sprites.
    if(resting){
        drawRestingPet(species,x,y,time,facing,asleep,inside)
        return
    }
    val blink=asleep || (time%3.4f<.10f) || happy
    val breath=sin(time*if(asleep)1.5f else 2.3f)
    val coat=when(species){"cat"->Color(0xFFBCC9DA);"hamster"->Color(0xFFF1C28F)
        "turtle"->Color(0xFF9CC789);"parrot"->Color(0xFF79C8B2);else->Color(0xFFE6B38B)}
    val shade=when(species){"cat"->Color(0xFF8193AC);"hamster"->Color(0xFFD29C78)
        "turtle"->Color(0xFF537F66);"parrot"->Color(0xFF438F8C);else->Color(0xFFB98263)}
    val cream=Color(0xFFFFF3DF)
    val ink=Color(0xFF514444)
    fun DrawScope.line(a:Offset,b:Offset,c:Color,w:Float)=drawLine(c,a,b,w,StrokeCap.Round)
    fun DrawScope.eyeAt(x:Float,y:Float){
        if(blink)line(Offset(x-3,y),Offset(x+3,y),ink,1.5f)
        else {drawCircle(Color.White,5f,Offset(x,y));drawCircle(ink,3.4f,Offset(x+1,y));drawCircle(Color.White,1.2f,Offset(x,y-1.5f))}
    }
    val small=when(species){"hamster"->.62f;"turtle"->.76f;"parrot"->.72f;else->1f}
    withTransform({translate(x,y)}){
        drawOval(Color(0x2264515B),Offset(-49f*small,-5f),Size(98f*small,10f))
        withTransform({scale(small*facing,small,Offset.Zero)}){
            if(species=="parrot"){
                val fly=moving && !inside
                val flap=fly || playing
                // The bird flaps on a perch without constantly hovering.
                val lift=if(fly)-22f-abs(sin(time*8f))*4f
                    else if(playing) -abs(sin(time*7f))*5f else 0f
                withTransform({translate(0f,lift)}){
                    // Feet grasp the perch at rest; wings fold against the breast.
                    for(dx in listOf(-9f,9f)){
                        line(Offset(dx,-13f),Offset(dx,0f),Color(0xFFAB8266),3f)
                        for(i in -1..1)line(Offset(dx,0f),Offset(dx+i*4f,2f),ink,1.5f)
                    }
                    withTransform({rotate(if(flap)sin(time*18f)*48f else 12f,Offset(-8f,-55f))}){
                        drawOval(shade,Offset(-51f,-64f),Size(47f,19f))
                    }
                    for(i in -1..1)line(Offset(-6f+i*5,-27f),Offset(-25f+i*8,-3f),shade,6f)
                    drawOval(shade,Offset(-26f,-76f+breath*.5f),Size(48f,62f))
                    drawOval(coat,Offset(-24f,-77f+breath*.5f),Size(45f,58f))
                    drawOval(cream,Offset(-3f,-60f),Size(23f,33f))
                    withTransform({rotate(if(flap)sin(time*18f+1)*55f else -15f,Offset(-8f,-57f))}){
                        drawOval(shade,Offset(-47f,-62f),Size(44f,19f))
                        for(i in 0..2)line(Offset(-39f+i*8,-57f),Offset(-33f+i*8,-48f),coat,2f)
                    }
                    withTransform({rotate(if(eating)18f+sin(time*11f)*12f else if(asleep)-22f else sin(time)*3f,Offset(4f,-73f))}){
                        drawCircle(shade,24f,Offset(3f,-87f));drawCircle(coat,22f,Offset(3f,-88f))
                        for(i in 0..2)line(Offset(-9f+i*7,-106f),Offset(-13f+i*7,-117f-i%2*5f),Color(0xFFB5D68A),4f)
                        eyeAt(12f,-92f)
                        val beak=Path().apply{moveTo(22f,-88f);quadraticBezierTo(41f,-87f,26f,-74f);close()}
                        drawPath(beak,Color(0xFFF3BF70))
                    }
                }
            } else if(species=="turtle"){
                for(i in 0..3){
                    val phase=gait+i%2*PI.toFloat()
                    val dx=if(moving)sin(phase)*7f else 0f
                    val px=if(i<2)-27f else 23f
                    drawOval(coat,Offset(px+dx,-12f-(i%2)*6),Size(21f,13f))
                }
                val neck=if(asleep)-10f else if(eating)sin(time*8)*5f else breath*1.5f
                drawOval(coat,Offset(25f+neck,if(eating)-20f else -29f),Size(35f,25f))
                eyeAt(48f+neck,if(eating)-13f else -22f)
                drawOval(shade,Offset(-45f,-54f+breath*.3f),Size(88f,45f))
                drawOval(Color(0xFF9FC294),Offset(-40f,-55f+breath*.3f),Size(77f,38f))
                for(i in -1..1){
                    val cx=i*23f;val cy=if(i==0)-41f else -33f
                    val tile=Path().apply{for(k in 0..5){val a=k*PI/3;val px=cx+13*cos(a).toFloat();val py=cy+10*sin(a).toFloat();if(k==0)moveTo(px,py) else lineTo(px,py)};close()}
                    drawPath(tile,shade,style=Stroke(2f))
                }
                if(eating){drawOval(Color(0xFF66A366),Offset(48f,-5f),Size(23f,8f))}
            } else {
                val hamster=species=="hamster"
                val cat=species=="cat"
                val bodyY=if(stretch)-29f else -43f +
                    if(moving)abs(sin(gait*2f))*2.5f else sin(time*2f)*.8f
                // Far legs first; front legs last. Lift only the swing half of the stride.
                fun DrawScope.leg(i:Int,front:Boolean){
                    val phase=gait+if(i==0||i==3)0f else PI.toFloat()
                    val hipX=if(i<2)-24f else 25f
                    val hipY=bodyY+13f
                    var footX=hipX+if(moving)sin(phase)*18f else 0f
                    var footY=if(moving)-max(0f,cos(phase))*13f else -2f
                    if(resting){footX+=12f;footY=-3f}
                    if(stretch && i>=2)footX+=16f
                    if(playing && i==3){footX+=12f+sin(time*6)*9f;footY-=10f+abs(sin(time*6))*9f}
                    val knee=Offset((hipX+footX)*.5f-3f,(hipY+footY)*.5f)
                    val c=if(front)coat else shade
                    line(Offset(hipX,hipY),knee,c,11f);line(knee,Offset(footX,footY),c,9f)
                    drawOval(c,Offset(footX-6f,footY-4f),Size(16f,8f))
                    line(Offset(footX+4,footY),Offset(footX+4,footY+2),shade,1f)
                }
                leg(0,false);leg(2,false)
                val tail=Path().apply{moveTo(-35f,bodyY+12f);quadraticBezierTo(-62f,bodyY-4f,-52f,bodyY-24f+sin(time*if(happy || playing)10f else 3f)*12f)}
                if(!hamster)drawPath(tail,shade,style=Stroke(if(cat)7f else 9f,cap=StrokeCap.Round))
                drawOval(shade,Offset(-44f,bodyY-20f+breath*.5f),Size(85f,if(resting)34f else 49f))
                drawOval(Brush.verticalGradient(listOf(cream,coat,shade),bodyY-20f,bodyY+30f),Offset(-43f,bodyY-22f+breath*.5f),Size(83f,if(resting)34f else 49f))
                if(cat)for(i in 0..2)line(Offset(-30f+i*15,bodyY-16f),Offset(-25f+i*15,bodyY-4f),shade,3f)
                // Collar is under the head, never over the muzzle.
                // A collar drawn diagonally across the head caused the
                // recurring violet muzzle stripe. Fur only: no floating line.
                // Collar ornaments belong behind the muzzle, not above it.
                val headY=if(eating)-30f+sin(time*9f)*6f
                    else if(sniffing)-41f+sin(time*6f)*4f
                    else if(grooming)-51f+sin(time*8f)*2f
                    else bodyY-14f
                val headX=if(cat && asleep)9f else 33f
                withTransform({rotate(if(happy)-12f else if(eating)27f else if(stretch)-12f
                    else if(sniffing)9f else sin(time*.9f)*3f,Offset(headX,headY))}){
                    if(cat){
                        for(dx in listOf(-18f,15f)){
                            val ear=Path().apply{moveTo(headX+dx-8,headY-12);lineTo(headX+dx-5,headY-35);lineTo(headX+dx+11,headY-14);close()}
                            drawPath(ear,shade);drawCircle(Color(0xFFE8B7C3),5f,Offset(headX+dx,headY-22))
                        }
                    }else if(hamster){for(dx in listOf(-18f,18f)){drawCircle(shade,10f,Offset(headX+dx,headY-19));drawCircle(Color(0xFFF0B8B8),6f,Offset(headX+dx,headY-20))}}
                    drawCircle(shade,25f,Offset(headX,headY+1));drawCircle(coat,24f,Offset(headX,headY-1))
                    if(!cat && !hamster){
                        drawOval(shade,Offset(headX-30f,headY-18f),Size(14f,32f))
                        drawOval(shade,Offset(headX+17f,headY-18f),Size(14f,32f))
                    }
                    drawOval(cream,Offset(headX-14f,headY+1f),Size(37f,22f))
                    if(eating && !hamster){
                        drawOval(Color(0xFFF0A8AB),Offset(headX+17f,headY+15f),
                            Size(10f,6f))
                    }
                    eyeAt(headX-8,headY-7);eyeAt(headX+12,headY-7)
                    drawOval(if(cat||hamster)Color(0xFFCE8F9B) else ink,Offset(headX+1,headY+3),Size(9f,6f))
                    val smile=Path().apply{moveTo(headX,headY+14);quadraticBezierTo(headX+6,headY+18,headX+13,headY+12)}
                    drawPath(smile,ink,style=Stroke(1.3f))
                    if(cat||hamster)for(side in listOf(-1f,1f))for(i in 0..1)line(Offset(headX+side*14,headY+8+i*4),Offset(headX+side*30,headY+5+i*8),shade,1.1f)
                }
                leg(1,true);leg(3,true)
                if(cat && asleep){
                    val curl=Path().apply{moveTo(-32f,-23f);cubicTo(-64f,2f,12f,12f,31f,-5f)}
                    drawPath(curl,shade,style=Stroke(10f,cap=StrokeCap.Round))
                }
                if(hamster && eating){
                    drawOval(Color(0xFFCB945C),Offset(42f,-19f),Size(12f,18f))
                    for(dx in listOf(39f,55f))drawCircle(coat,5f,Offset(dx,-12f+sin(time*9f)))
                }
            }
            if(asleep && elapsed>1f){
                val yy=-83f-(time%2f)*7f
                line(Offset(-15f,yy),Offset(-8f,yy),shade,1.5f)
                line(Offset(-8f,yy),Offset(-15f,yy+7),shade,1.5f)
                line(Offset(-15f,yy+7),Offset(-8f,yy+7),shade,1.5f)
            }
        }
    }
    // The hamster's home animation IS the spinning wheel: no second toy.
    if(!(inside && species=="hamster" && playing))
        drawPetActivityDetail(species,x,y,time,action,facing)
}
