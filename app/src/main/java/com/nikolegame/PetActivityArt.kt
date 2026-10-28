package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import kotlin.math.*

/** Full-size dedicated reclining/sleeping frames, not a scaled walking sprite.
 * The feet remain at the same world-space position while the torso settles.
 */
internal fun DrawScope.drawRestingPet(
    species:String, x:Float, footY:Float, seconds:Float, facing:Float, asleep:Boolean, inside:Boolean
) {
    val breath=sin(seconds*if(asleep)1.8f else 2.7f)
    val coat=when(species){
        "dog"->Color(0xFFE6B38B)
        "cat"->Color(0xFFBCC9DA)
        "hamster"->Color(0xFFF1C28F)
        "parrot"->Color(0xFF79C8B2)
        else->Color(0xFF9CC789)
    }
    val shade=when(species){
        "dog"->Color(0xFFB98263)
        "cat"->Color(0xFF8193AC)
        "hamster"->Color(0xFFD29C78)
        "parrot"->Color(0xFF438F8C)
        else->Color(0xFF537F66)
    }
    val ink=Color(0xFF514444)
    val cream=Color(0xFFFFF3DF)
    val small=when(species){
        "hamster"->.62f; "turtle"->.76f; "parrot"->.72f;else->1f
    }
    withTransform({
        translate(x,footY)
        scale(small*facing,small,Offset.Zero)
    }) {
        // Stable low cast shadow and slow rhythmic breathing at rest.
        if(species=="parrot" && inside){
            drawLine(Color(0xFFAC845E),Offset(-55f,2f),Offset(55f,2f),6f)
        }else{
            drawOval(Color(0x2764515B),Offset(-58f,-6f),Size(116f,10f))
        }
        when(species) {
            "dog"->{
                // Side-lying silhouette with bent forelegs and visible head on paws.
                drawOval(shade,Offset(-49f,-34f+breath),Size(102f,34f))
                drawOval(coat,Offset(-46f,-37f+breath),Size(98f,33f))
                drawOval(cream,Offset(-17f,-20f),Size(51f,16f))
                for(i in 0..2){
                    val xx=4f+i*16f
                    drawRoundRect(coat,Offset(xx,-12f+i%2*3f),Size(31f,11f),CornerRadius(7f))
                    drawLine(shade,Offset(xx+22f,-3f),Offset(xx+27f,-3f),1.8f)
                }
                val tail=Path().apply{
                    moveTo(-45f,-17f);quadraticBezierTo(-68f,-37f,-70f,-16f+sin(seconds*2f)*3f)
                }
                drawPath(tail,shade,style=Stroke(8f))
                drawOval(shade,Offset(22f,-44f+breath),Size(48f,36f))
                drawOval(coat,Offset(24f,-44f+breath),Size(44f,33f))
                drawOval(cream,Offset(43f,-23f),Size(33f,17f))
                drawOval(shade,Offset(27f,-49f+breath),Size(14f,28f))
                drawLine(ink,Offset(57f,-28f),Offset(67f,-29f),2.7f)
                drawCircle(ink,3f,Offset(70f,-13f))
                drawLine(ink,Offset(57f,-9f),Offset(63f,-7f),1.6f)
            }
            "cat"->{
                // Tight circle: head nestles against flank, tail loops across back.
                drawOval(shade,Offset(-52f,-50f+breath),Size(106f,49f))
                drawOval(coat,Offset(-47f,-50f+breath),Size(98f,44f))
                drawOval(cream,Offset(-8f,-27f),Size(51f,22f))
                val curl=Path().apply{
                    moveTo(-36f,-18f);cubicTo(-69f,-5f,-57f,-56f,-14f,-39f)
                }
                drawPath(curl,shade,style=Stroke(10f))
                val ears=listOf(11f,44f)
                for(ex in ears){
                    val ear=Path().apply{
                        moveTo(ex-10f,-48f);lineTo(ex,-71f);lineTo(ex+10f,-46f);close()
                    }
                    drawPath(ear,shade)
                    drawCircle(Color(0xFFEABCCB),4f,Offset(ex,-53f))
                }
                drawCircle(shade,27f,Offset(27f,-33f))
                drawCircle(coat,25f,Offset(27f,-33f))
                drawOval(cream,Offset(24f,-27f),Size(30f,16f))
                drawLine(ink,Offset(15f,-34f),Offset(23f,-34f),2f)
                drawLine(ink,Offset(39f,-34f),Offset(47f,-34f),2f)
                drawCircle(Color(0xFFD48F9B),3f,Offset(33f,-24f))
                for(i in 0..1){
                    drawLine(shade,Offset(49f,-21f+i*4),Offset(66f,-25f+i*8f),1.6f)
                }
            }
            "hamster"->{
                // Curled, round sleeping hamster; never a flattened floor oval.
                // Height is comparable to width, paws are tucked underneath.
                drawOval(shade,Offset(-45f,-78f+breath),Size(91f,73f))
                drawOval(coat,Offset(-41f,-76f+breath),Size(86f,70f))
                drawOval(cream,Offset(-3f,-52f),Size(48f,40f))
                for(ex in listOf(-27f,29f)){
                    drawCircle(shade,11f,Offset(ex,-73f))
                    drawCircle(Color(0xFFF3BBC2),6f,Offset(ex,-74f))
                }
                drawLine(ink,Offset(10f,-41f),Offset(21f,-43f),2f)
                drawLine(ink,Offset(28f,-40f),Offset(39f,-41f),2f)
                drawCircle(Color(0xFFD6939C),3.5f,Offset(27f,-32f))
                for(ex in listOf(-18f,15f))
                    drawOval(shade,Offset(ex,-10f),Size(18f,7f))
                drawOval(cream.copy(alpha=.65f),Offset(-32f,-36f),
                    Size(23f,18f))
            }
            "parrot"->{
                // One raised leg, rounded perched body, head TUCKED INTO wing.
                drawLine(Color(0xFFA88061),Offset(-14f,-7f),Offset(-14f,0f),3f)
                drawLine(Color(0xFFA88061),Offset(16f,-7f),Offset(16f,0f),3f)
                drawOval(shade,Offset(-38f,-69f+breath),Size(78f,65f))
                drawOval(coat,Offset(-34f,-70f+breath),Size(69f,62f))
                drawOval(cream,Offset(-11f,-49f),Size(37f,32f))
                drawOval(shade,Offset(-31f,-62f),Size(39f,36f))
                drawCircle(coat,23f,Offset(8f,-64f))
                drawLine(ink,Offset(13f,-67f),Offset(22f,-65f),2.2f)
                val beak=Path().apply{
                    moveTo(23f,-60f);lineTo(38f,-56f);lineTo(25f,-46f);close()
                }
                drawPath(beak,Color(0xFFF3BF70))
                for(i in 0..2)drawLine(shade,Offset(-30f+i*7f,-28f),
                    Offset(-50f+i*6f,-4f),5f)
            }
            else->{
                // Tortoise retracts its neck and legs under the breathing shell.
                for(ex in listOf(-34f,20f))
                    drawOval(coat,Offset(ex,-9f),Size(20f,11f))
                drawOval(shade,Offset(-49f,-48f+breath),Size(100f,49f))
                drawOval(coat,Offset(-43f,-45f+breath),Size(87f,40f))
                for(i in -1..1)drawOval(shade.copy(alpha=.45f),
                    Offset(i*27f-8f,-35f),Size(22f,15f),style=Stroke(2f))
                drawOval(coat,Offset(41f,-25f),Size(19f,18f))
                drawLine(ink,Offset(51f,-20f),Offset(58f,-19f),2f)
            }
        }
        // Floating sleepy symbols: restrained, no jerky shaking.
        if(asleep){
            val yy=-100f-(seconds%2.5f)*6f
            val alpha=(.45f+.25f*sin(seconds*2f)).coerceIn(.2f,.85f)
            for(i in 0..1){
                val px=-10f+i*15f
                val py=yy-i*14f
                drawLine(shade.copy(alpha=alpha),Offset(px,py),Offset(px+9f,py),2f)
                drawLine(shade.copy(alpha=alpha),Offset(px+9f,py),Offset(px,py+10f),2f)
                drawLine(shade.copy(alpha=alpha),Offset(px,py+10f),Offset(px+9f,py+10f),2f)
            }
        }
    }
}

/** Visible species-specific micro-animation for eating, playing and grooming.
 * All motions are tied to real elapsed time and feet remain anchored.
 */
internal fun DrawScope.drawPetActivityDetail(
    species:String, x:Float, footY:Float, time:Float, action:String, facing:Float
) {
    if(action !in setOf("feed","play","groom","sniff","look"))return
    val small=when(species){"hamster"->.62f;"turtle"->.76f;"parrot"->.72f;else->1f}
    val ink=Color(0xFF6D5D57)
    withTransform({translate(x,footY);scale(small*facing,small,Offset.Zero)}){
        when(action){
            "feed"->{
                val bounce=abs(sin(time*9f))
                val food=if(species=="turtle")Color(0xFF79AE6A) else Color(0xFFD2A071)
                // Ground bowl + animated chewing crumbs, rather than a floating emoji.
                drawOval(ink,Offset(53f,-7f),Size(43f,15f))
                drawOval(Color(0xFFB5DEEA),Offset(57f,-8f),Size(35f,10f))
                for(i in 0..3){
                    val px=60f+i*8f
                    drawCircle(food,3.3f,Offset(px,-9f-bounce*2f))
                }
                for(i in 0..2){
                    drawCircle(food.copy(alpha=.65f),2.6f,
                        Offset(51f+i*9f,-19f-(time*14f+i*9f)%16f))
                }
                if(species=="parrot"){
                    drawLine(Color(0xFFEFC477),Offset(38f,-91f),Offset(51f,-87f),4f)
                }
            }
            "play"->{
                val oscillation=sin(time*7f)
                if(species=="dog"){
                    drawCircle(Color(0xFFE79BBB),11f,Offset(80f+oscillation*17f,-12f-abs(oscillation)*20f))
                    drawCircle(Color.White,4f,Offset(76f+oscillation*17f,-17f-abs(oscillation)*20f))
                    for(i in 0..2)drawCircle(Color(0xFFFFE6AD),3f,
                        Offset(46f+i*10f,-42f-abs(oscillation)*9f))
                } else if(species=="cat"){
                    drawCircle(Color(0xFFD8B8EC),12f,Offset(77f+oscillation*20f,-9f))
                    for(i in 0..3)drawLine(Color(0xFFAF8CC6),
                        Offset(65f+oscillation*20f,-5f+i*2),
                        Offset(54f+oscillation*20f,-21f+i*2),1.5f)
                } else if(species=="hamster"){
                    drawCircle(Color(0xFFF6DE93),10f,Offset(77f+oscillation*15f,-18f))
                    drawOval(Color(0xFFE5AE7E),Offset(48f,-9f),Size(24f,8f))
                } else if(species=="parrot"){
                    for(i in 0..3)drawCircle(
                        if(i%2==0)Color(0xFFCCB5E9) else Color(0xFFEBC5A1),5f,
                        Offset(63f+i*11f,-38f+oscillation*7f))
                } else {
                    for(i in 0..2)drawCircle(Color(0xFFB6E0E6).copy(alpha=.6f),
                        6f+abs(oscillation)*3f,Offset(67f+i*13f,-20f-i*16f))
                }
            }
            "groom"->{
                // Paw repeatedly reaches face; bird preens a wing.
                val wave=(sin(time*8f)+1f)*.5f
                val c=when(species){"cat"->Color(0xFFBCC9DA)
                    "hamster"->Color(0xFFF1C28F)
                    "parrot"->Color(0xFF79C8B2)
                    "turtle"->Color(0xFF9CC789)
                    else->Color(0xFFE6B38B)}
                drawLine(c,Offset(15f,-5f),Offset(38f,-27f-wave*24f),11f)
                drawCircle(c,8f,Offset(38f,-27f-wave*24f))
            }
            "sniff"->{
                for(i in 0..2){
                    val dy=(time*17f+i*12f)%35f
                    drawCircle(Color(0xFFCFB6DC).copy(alpha=.75f),3.5f,
                        Offset(69f+i*8f,-43f-dy))
                }
            }
            "look"->{
                val wave=sin(time*2f)
                drawCircle(Color(0xFFFFE9B1),3f,Offset(58f+wave*8f,-96f))
                drawCircle(Color(0xFFF2CADE),2.5f,Offset(65f-wave*5f,-91f))
            }
        }
    }
}
