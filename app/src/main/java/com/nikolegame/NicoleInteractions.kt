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

/**
 * Nicole performs visible animation poses rather than standing motionless
 * while a pet receives an off-screen state change.
 *
 * All coordinates are world-space. No collision geometry changes.
 */
internal fun DrawScope.renderNicoleActivity(
    x:Float, y:Float, depth:Float, tick:Int, pose:String,
    elapsed:Float, facing:Int
) {
    val skin=Color(0xFFFFDEC8)
    val hair=Color(0xFFF1CF88)
    val hairShade=Color(0xFFCAA36D)
    val shirt=Color(0xFFFFFAF6)
    val jeans=Color(0xFF729CC5)
    val ink=Color(0xFF80666A)
    val phase=sin(elapsed*8f)
    if(pose=="sleep"){
        val arrive=(elapsed/.9f).coerceIn(0f,1f)
        val u=arrive*arrive*(3f-2f*arrive)
        if(arrive<.99f) {
            // Nicole climbs onto the bed before lying down.
            renderNicole(x+(625f-x)*u,y+(616f-y)*u,depth,tick,false,1)
            return
        }
        withTransform({translate(620f,595f)}){
            // Side-lying body across a pillow with closed eyes and tucked legs.
            drawOval(Color(0x668E678B),Offset(-142f,-41f),Size(310f,76f))
            drawOval(Color(0xFFFFFAF7),Offset(-156f,-63f),Size(101f,79f))
            drawLine(jeans,Offset(39f,-12f),Offset(143f,7f),24f)
            drawLine(jeans,Offset(42f,2f),Offset(133f,28f),24f)
            drawOval(Color.White,Offset(119f,6f),Size(36f,18f))
            drawOval(Color.White,Offset(118f,22f),Size(36f,15f))
            drawRoundRect(shirt,Offset(-66f,-42f),Size(132f,60f),CornerRadius(28f))
            drawLine(skin,Offset(-40f,-4f),Offset(28f,16f),13f)
            drawCircle(hairShade,43f,Offset(-97f,-15f))
            drawCircle(hair,40f,Offset(-100f,-22f))
            drawOval(skin,Offset(-118f,-33f),Size(62f,48f))
            drawLine(ink,Offset(-103f,-10f),Offset(-90f,-11f),2.4f)
            drawOval(Color(0xFFF3C1CB),Offset(-78f,-2f),Size(10f,6f))
            for(i in 0..2)drawCircle(Color.White.copy(alpha=.7f),
                4.5f,Offset(1f+i*17f,-69f-(elapsed%3f)*7f-i*10f))
        }
        return
    }
    if(pose=="sit"){
        withTransform({translate(x,y);scale(depth,depth,Offset.Zero)}){
            drawOval(Color(0x335A5057),Offset(-44f,-10f),Size(88f,16f))
            // Seated bent knees and shoes rather than the ordinary standing legs.
            drawLine(jeans,Offset(-18f,-90f),Offset(-35f,-43f),25f)
            drawLine(jeans,Offset(18f,-90f),Offset(42f,-45f),25f)
            drawLine(jeans,Offset(-35f,-42f),Offset(-34f,-6f),21f)
            drawLine(jeans,Offset(42f,-44f),Offset(52f,-7f),21f)
            drawOval(Color.White,Offset(-52f,-15f),Size(39f,17f))
            drawOval(Color.White,Offset(35f,-15f),Size(39f,17f))
            drawRoundRect(shirt,Offset(-37f,-192f),Size(75f,111f),CornerRadius(20f))
            drawLine(skin,Offset(-34f,-167f),Offset(-23f,-108f+phase*5f),13f)
            drawLine(skin,Offset(34f,-167f),Offset(30f,-101f-phase*5f),13f)
            drawCircle(hairShade,38f,Offset(0f,-225f))
            drawCircle(hair,34f,Offset(0f,-230f))
            drawOval(skin,Offset(-26f,-244f),Size(54f,51f))
            drawCircle(ink,2.7f,Offset(-10f,-221f))
            drawCircle(ink,2.7f,Offset(12f,-221f))
        }
        return
    }
    if(pose=="window"){
        // Window watching: turn to the glass and raise a hand to the sill.
        renderNicole(x,y,depth,tick,false,3)
        withTransform({translate(x,y);scale(depth,depth,Offset.Zero)}){
            drawLine(skin,Offset(29f,-175f),Offset(51f+phase*2f,-235f),12f)
            drawCircle(skin,7f,Offset(51f+phase*2f,-236f))
            drawCircle(Color(0xFFFFE7AE).copy(alpha=.55f),4f,
                Offset(81f,-265f+sin(elapsed*2f)*8f))
        }
        return
    }
    // Throwing, stroking and feeding all have distinct coordinated arm motion.
    renderNicole(x,y,depth,tick,false,if(facing==3)2 else facing)
    withTransform({translate(x,y);scale(depth,depth,Offset.Zero)}){
        when(pose){
            "throw"->{
                val arm=if(elapsed<.7f)-.6f else if(elapsed<1.1f)1f else .3f
                drawLine(skin,Offset(29f,-172f),Offset(44f+arm*42f,-225f+arm*95f),13f)
                drawCircle(skin,8f,Offset(44f+arm*42f,-225f+arm*95f))
                if(elapsed<.7f)drawCircle(Color(0xFFECA4BD),11f,
                    Offset(44f+arm*42f,-224f+arm*95f))
            }
            "pet"->{
                val wave=abs(sin(elapsed*7f))*18f
                drawLine(skin,Offset(28f,-166f),Offset(86f,-108f-wave),12f)
                drawCircle(skin,8f,Offset(86f,-108f-wave))
                if(elapsed>1f && (tick/14)%2==0)
                    drawCircle(Color(0xFFF0B8C9),9f,Offset(99f,-141f))
            }
            "feed"->{
                val lift=sin(elapsed*5f)*9f
                drawLine(skin,Offset(30f,-169f),Offset(80f,-98f+lift),12f)
                drawCircle(skin,7f,Offset(80f,-98f+lift))
                drawOval(Color(0xFF94CCE2),Offset(67f,-96f+lift),Size(32f,16f))
                for(i in 0..2)drawCircle(Color(0xFFD5A274),3f,
                    Offset(73f+i*9f,-94f+lift))
            }
        }
    }
}

/** Visible ball with a flight arc and a ground target shared with PetLife chase. */
internal fun DrawScope.renderThrownBall(
    startX:Float, startY:Float, target:WalkPoint, elapsed:Float
) {
    if(elapsed !in .65f..6.2f)return
    val u=((elapsed-.65f)/.85f).coerceIn(0f,1f)
    val bx=startX+(target.x-startX)*u
    val by=startY+(target.y-startY)*u
    val bounce=if(u<1f)sin(u*3.14159f)*105f else abs(sin((elapsed-1.5f)*7f))*9f*exp(-(elapsed-1.5f).coerceAtLeast(0f))
    drawOval(Color(0x334F3544),Offset(bx-14f,target.y-8f),Size(28f,8f))
    drawCircle(Color(0xFFE9A3BB),15f,Offset(bx,by-17f-bounce))
    drawCircle(Color(0xFFFFE7F2),6f,Offset(bx-6f,by-23f-bounce))
    drawArc(Color(0xFFBD729B),55f,140f,false,
        Offset(bx-12f,by-29f-bounce),Size(24f,24f),
        style=Stroke(2f))
}
