package com.nikolegame

import kotlin.math.*
import kotlin.random.Random

internal enum class PetState {
    IDLE, WALK, APPROACH_HOME, ENTER_HOME, SLEEP, REST, PLAY_HOME,
    EXIT_HOME, STRETCH, APPROACH_BOWL, EAT, PLAY, GROOM, SNIFF, LOOK,
    WAIT_OWNER, PETTED, HAPPY, CHASE_BALL, FLY_ROOM, PERCH
}

/** All positions are world-space feet. No state changes the animal's scale. */
internal class PetLife(val species:String, private val random:Random=Random.Default) {
    var x=1185f; private set
    var y=820f; private set
    var state=PetState.IDLE; private set
    var elapsed=0f; private set
    var age=0f; private set
    var gait=0f; private set
    var facing=1f; private set
    var speed=0f; private set
    private var route=mutableListOf<WalkPoint>()
    private var queued=""
    private var lastChoice=-1
    private var homeStyle=0
    private var indoors=false
    private var homeActivity=PetState.SLEEP
    private var flightGoal=WalkPoint(1150f,780f)
    private var ballGoal=WalkPoint(1300f,815f)
    private var flights=0
    val activeBall get()=state==PetState.CHASE_BALL
    val airborne get()=state==PetState.FLY_ROOM
    val perched get()=state==PetState.PERCH
    val homeDoorOpen get()=state in setOf(PetState.ENTER_HOME,PetState.EXIT_HOME)
    fun chaseBall(goal:WalkPoint,models:Map<String,Int>):Boolean {
        if(species=="parrot") {
            queued=""
            flightGoal=WalkPoint(goal.x.coerceIn(620f,2050f),goal.y.coerceIn(350f,540f))
            change(PetState.FLY_ROOM)
            return true
        }
        if(indoors){
            queued="chase"
            ballGoal=goal
            if(state !in setOf(PetState.ENTER_HOME,PetState.EXIT_HOME))exitHome()
            return true
        }
        queued=""
        ballGoal=closestWalkable(goal.x,goal.y,models,"bedroom")
        return travel(ballGoal,PetState.CHASE_BALL,models)
    }
    val atHome get()=indoors
    val moving get()=speed>.1f
    val action get()=when(state){
        PetState.SLEEP->"sleep"; PetState.REST->"rest"; PetState.EAT->"feed"
        PetState.PLAY,PetState.PLAY_HOME->"play";PetState.PETTED,PetState.HAPPY->"pet"
        PetState.STRETCH->"stretch"
        PetState.GROOM->"groom"
        PetState.SNIFF->"sniff"
        PetState.LOOK->"look"
        else->""
    }
    private fun change(next:PetState){state=next;elapsed=0f;speed=0f}
    fun request(action:String) { queued=action }
    private fun travel(goal:WalkPoint,next:PetState,models:Map<String,Int>):Boolean {
        route=roomRoute(WalkPoint(x,y),goal,models,"bedroom").toMutableList()
        if(route.isEmpty())return false
        change(next);return true
    }
    private fun entrance()=WalkPoint(1140f,795f)
    private fun inside():WalkPoint {
        if(species=="parrot")return WalkPoint(1140f,664f)
        if(species=="hamster" && homeActivity==PetState.PLAY_HOME){
            val cx=when(homeStyle){in 1..3->95f;in 4..5->74f;else->64f}
            val cy=if(homeStyle<=3)110f else 126f
            return WalkPoint(1140f+(1003f+cx-1140f)*1.16f,
                730f+(560f+cy-730f)*1.16f+24f)
        }
        return WalkPoint(1140f,720f)
    }
    private fun exitHome(){
        route=mutableListOf(WalkPoint(1140f,730f),entrance());change(PetState.EXIT_HOME)
    }
    fun update(dt:Float,home:Int,bowl:Int,models:Map<String,Int>,girlX:Float,girlY:Float) {
        if(dt<=0f || !dt.isFinite())return
        val delta=dt.coerceAtMost(.1f)
        elapsed+=delta;age+=delta;speed=0f
        if(home!=homeStyle){
            homeStyle=home
            if(atHome){exitHome()}
        }
        if(queued.isNotEmpty()){
            if(atHome){
                // Finish entry before exiting; repeated commands cannot teleport or restart exit.
                if(state !in setOf(PetState.ENTER_HOME,PetState.EXIT_HOME))exitHome()
            }else if(state!=PetState.EXIT_HOME){
                val command=queued;queued="";route.clear()
                when(command){
                    "home"->if(home>0)travel(entrance(),PetState.APPROACH_HOME,models) else change(PetState.IDLE)
                    "feed"->if(bowl>0)travel(WalkPoint(1370f,815f),PetState.APPROACH_BOWL,models) else change(PetState.IDLE)
                    "pet"->change(PetState.WAIT_OWNER)
                    "play"->change(PetState.PLAY)
                    "chase"->travel(ballGoal,PetState.CHASE_BALL,models)
                }
            }
        }
        if(state==PetState.FLY_ROOM){
            val dx=flightGoal.x-x;val dy=flightGoal.y-y
            val distance=hypot(dx,dy)
            val step=min(distance,235f*delta)
            if(distance>0f){
                x+=dx/distance*step
                y+=dy/distance*step
                speed=step/delta
                gait+=delta*19f
                if(abs(dx)>2f)facing=if(dx<0f)-1f else 1f
            }
            if(distance<=step+2f){x=flightGoal.x;y=flightGoal.y;change(PetState.PERCH)}
            return
        }
        if(state==PetState.PERCH){
            if(elapsed>4.2f){
                if(queued.isNotEmpty()){
                    flightGoal=WalkPoint(x.coerceIn(900f,1480f),815f)
                    flights=0
                    change(PetState.FLY_ROOM)
                }else if(flights++>=2){
                    flightGoal=WalkPoint(1170f,820f)
                    flights=0
                    change(PetState.FLY_ROOM)
                }else{
                    val perches=listOf(WalkPoint(660f,435f),
                        WalkPoint(1115f,345f),WalkPoint(2015f,430f))
                    flightGoal=perches[random.nextInt(perches.size)]
                    change(PetState.FLY_ROOM)
                }
            }
            return
        }
        if(state==PetState.APPROACH_HOME && home==0){route.clear();change(PetState.IDLE)}
        if(state in setOf(PetState.APPROACH_BOWL,PetState.EAT) && bowl==0){route.clear();change(PetState.IDLE)}
        if(route.isNotEmpty()){
            val goal=route.first();val dx=goal.x-x;val dy=goal.y-y;val distance=hypot(dx,dy)
            val velocity=when(species){"turtle"->22f;"hamster"->90f;"parrot"->125f;else->85f}
            val step=min(distance,velocity*delta)
            val nx=if(distance>0f)x+dx/distance*step else x
            val ny=if(distance>0f)y+dy/distance*step else y
            // The short portal segment lies in the reserved empty habitat niche.
            if(clearPath(WalkPoint(x,y),WalkPoint(nx,ny),models,"bedroom")){
                x=nx;y=ny;speed=step/delta;gait+=step*.12f
                if(abs(dx)>.5f)facing=if(dx<0)-1f else 1f
                if(distance<=step+.01f)route.removeAt(0)
            }else{
                route.clear();change(PetState.IDLE)
            }
            if(route.isEmpty())when(state){
                PetState.APPROACH_HOME->{
                    indoors=true
                    homeActivity=if(species in listOf("hamster","parrot") && random.nextBoolean())PetState.PLAY_HOME else PetState.SLEEP
                    route=mutableListOf(WalkPoint(1140f,730f),inside())
                    change(PetState.ENTER_HOME)
                }
                PetState.ENTER_HOME->{
                    facing=1f
                    change(if(queued.isNotEmpty())PetState.REST else homeActivity)
                }
                PetState.EXIT_HOME->{indoors=false;change(PetState.STRETCH)}
                PetState.APPROACH_BOWL->{facing=1f;change(PetState.EAT)}
                PetState.WALK->change(PetState.IDLE)
                PetState.CHASE_BALL->change(PetState.PLAY)
                else->Unit
            }
            return
        }
        when(state){
            PetState.IDLE->if(elapsed>2.8f){
                // Eight small autonomous routines instead of constant walking.
                // No two consecutive identical actions: the room feels alive.
                var choice=random.nextInt(if(species=="parrot")10 else 8)
                if(choice==lastChoice)choice=(choice+1)%if(species=="parrot")10 else 8
                lastChoice=choice
                when {
                    choice==0 && home>0->travel(entrance(),PetState.APPROACH_HOME,models)
                    choice==1 && bowl>0->travel(WalkPoint(1370f,815f),PetState.APPROACH_BOWL,models)
                    choice==2->change(PetState.PLAY)
                    choice==3->{
                        // Birds rest on a perch, not lying on the floor.
                        if(species=="parrot" && home>0){
                            if(!travel(entrance(),PetState.APPROACH_HOME,models))
                                change(PetState.LOOK)
                        }else if(species=="parrot")change(PetState.LOOK)
                        else change(PetState.REST)
                    }
                    choice==4->change(PetState.GROOM)
                    choice==5->change(PetState.SNIFF)
                    choice==6->change(PetState.LOOK)
                    species=="parrot" && choice>=8->{
                        val perches=listOf(WalkPoint(660f,435f),
                            WalkPoint(1115f,345f),WalkPoint(2015f,430f))
                        flightGoal=perches[random.nextInt(perches.size)]
                        flights=0
                        change(PetState.FLY_ROOM)
                    }
                    else->{
                        val goal=closestWalkable((x+random.nextInt(-250,251)).coerceIn(920f,1480f),
                            random.nextInt(770,851).toFloat(),models)
                        if(!travel(goal,PetState.WALK,models))change(PetState.IDLE)
                    }
                }
            }
            PetState.SLEEP,PetState.PLAY_HOME->if(elapsed>9f)exitHome()
            PetState.REST->if(atHome && queued.isNotEmpty())exitHome() else if(elapsed>5f){
                if(atHome)exitHome() else change(PetState.STRETCH)
            }
            PetState.WAIT_OWNER->{
                if(hypot(x-girlX,y-girlY)<145f)change(PetState.PETTED)
                else if(elapsed>8f)change(PetState.IDLE)
            }
            PetState.GROOM->if(elapsed>3.4f)change(PetState.IDLE)
            PetState.SNIFF->if(elapsed>2.5f)change(PetState.IDLE)
            PetState.LOOK->if(elapsed>2.1f)change(PetState.IDLE)
            PetState.PETTED->if(elapsed>3f)change(PetState.HAPPY)
            PetState.EAT,PetState.PLAY->if(elapsed>5f)change(PetState.HAPPY)
            PetState.STRETCH,PetState.HAPPY->if(elapsed>1.4f)change(PetState.IDLE)
            else->Unit
        }
    }
}
