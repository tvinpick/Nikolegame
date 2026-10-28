package com.nikolegame

import kotlin.math.*
import kotlin.random.Random

internal enum class PetState {
    IDLE, WALK, APPROACH_HOME, ENTER_HOME, SLEEP, REST, PLAY_HOME,
    EXIT_HOME, STRETCH, APPROACH_BOWL, EAT, PLAY, WAIT_OWNER, PETTED, HAPPY
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
    val atHome get()=indoors
    val moving get()=speed>.1f
    val action get()=when(state){
        PetState.SLEEP->"sleep"; PetState.REST->"rest"; PetState.EAT->"feed"
        PetState.PLAY,PetState.PLAY_HOME->"play";PetState.PETTED,PetState.HAPPY->"pet"
        PetState.STRETCH->"stretch";else->""
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
                }
            }
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
                else->Unit
            }
            return
        }
        when(state){
            PetState.IDLE->if(elapsed>2.8f){
                var choice=random.nextInt(5)
                if(choice==lastChoice)choice=(choice+1)%5
                lastChoice=choice
                when {
                    choice==0 && home>0->travel(entrance(),PetState.APPROACH_HOME,models)
                    choice==1 && bowl>0->travel(WalkPoint(1370f,815f),PetState.APPROACH_BOWL,models)
                    choice==2->change(PetState.PLAY)
                    choice==3->change(PetState.REST)
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
            PetState.PETTED->if(elapsed>3f)change(PetState.HAPPY)
            PetState.EAT,PetState.PLAY->if(elapsed>5f)change(PetState.HAPPY)
            PetState.STRETCH,PetState.HAPPY->if(elapsed>1.4f)change(PetState.IDLE)
            else->Unit
        }
    }
}
