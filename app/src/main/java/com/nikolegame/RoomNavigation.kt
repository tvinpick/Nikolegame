package com.nikolegame

import kotlin.math.*

private const val WORLD = 2700f

internal data class WalkPoint(val x: Float, val y: Float)

// Coordinates describe where Nicole's feet are. Furniture is solid, floor is walkable.
internal fun kitchenWalkable(x:Float,y:Float):Boolean {
    if(x !in 75f..(WORLD-75f) || y !in 603f..865f) return false
    if(x in 436f..763f && y <= 706f) return false
    if(x in 775f..1235f && y <= 711f) return false
    if(x in 1776f..2275f && y <= 715f) return false
    // One continuous obstacle for the dining table and its chairs. Keep
    // the aisle behind it (y <= 674) AND a generous lane in front (y >= 811).
    // Splitting the furniture into small colliders previously led to paths
    // skimming chair legs or walking through the tabletop.
    if(x in 1290f..1810f && y in 675f..810f) return false
    return true
}
internal fun walkable(
    x:Float,y:Float,models:Map<String,Int> = emptyMap(),room:String="bedroom"
):Boolean {
    if(room=="kitchen")return kitchenWalkable(x,y)
    if(x !in 75f..(WORLD-75f) || y !in 603f..865f) return false
    val bed=models["bed"]?:0
    val bedLeft=if(bed==1)395f else if(bed>=2)385f else 355f
    val bedRight=if(bed==1)847f else if(bed>=2)857f else 840f
    val bedFront=if(bed==1)729f else if(bed>=2)742f else 748f
    // The headboard sits in front of a narrow walkable rear aisle.
    // Nicole can go around the bed and approach the glass from behind.
    if(x in bedLeft..bedRight && y in 676f..bedFront) return false
    val wardrobe=models["wardrobe"]?:0
    if(x in (if(wardrobe>=2)1540f else 1558f)..(if(wardrobe>=2)1843f else 1820f)
        && y <= (if(wardrobe>=2)651f else 638f))return false
    val table=models["table"]?:0
    if(x in (if(table==1)1935f else 1900f)..(if(table>=2)2340f else 2315f)
        && y in 678f..(if(table==1)711f else 716f))return false
    val chair=models["chair"]?:0
    if(x in (if(chair>=2)2019f else 2040f)..(if(chair>=2)2247f else 2218f)
        && y in 670f..742f)return false
    return true
}
internal fun closestWalkable(
    x:Float,y:Float,models:Map<String,Int> = emptyMap(),room:String="bedroom"
):WalkPoint {
    val px=x.coerceIn(75f,WORLD-75f); val py=y.coerceIn(603f,865f)
    if(walkable(px,py,models,room))return WalkPoint(px,py)
    var best=WalkPoint(1350f,810f); var bestD=Float.MAX_VALUE
    for(dx in -270..270 step 15)for(dy in -210..210 step 15){
        val nx=(px+dx).coerceIn(75f,WORLD-75f)
        val ny=(py+dy).coerceIn(603f,865f)
        val d=(nx-px)*(nx-px)+(ny-py)*(ny-py)
        if(d<bestD && walkable(nx,ny,models,room)){bestD=d;best=WalkPoint(nx,ny)}
    }
    return best
}
internal fun clearPath(
    a:WalkPoint,b:WalkPoint,models:Map<String,Int> = emptyMap(),room:String="bedroom"
):Boolean {
    // Use a collision sampling interval shorter than Nicole's 5.6px step.
    // The old 12px check could miss the edge of a chair on a diagonal.
    val steps=max(1,kotlin.math.ceil(hypot(b.x-a.x,b.y-a.y)/2.5f).toInt())
    for(i in 0..steps){
        val t=i.toFloat()/steps
        if(!walkable(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,models,room))return false
    }
    return true
}

// A* pathfinding for BOTH rooms. Unlike the old fixed two-lane bedroom route,
// this handles obstacles, furniture variations and reaching either window.
internal fun roomRoute(
    start:WalkPoint, target:WalkPoint, models:Map<String,Int>, room:String
):List<WalkPoint> {
    // Prefer the wide foreground corridor for horizontal kitchen crossings.
    // It avoids cutting diagonally into the table, while A* below still
    // handles destinations behind the table and in the rest of the rooms.
    if(room=="kitchen" && start.y>=811f && target.y>=811f &&
        abs(target.x-start.x)>100f &&
        min(start.x,target.x)<1820f && max(start.x,target.x)>1280f) {
        val entry=WalkPoint(start.x,840f)
        val exit=WalkPoint(target.x,840f)
        if(clearPath(start,entry,models,room) &&
            clearPath(entry,exit,models,room) &&
            clearPath(exit,target,models,room)) {
            return listOf(entry,exit,target)
        }
    }
    if(clearPath(start,target,models,room))return listOf(target)
    val dx=25f; val dy=25f
    val cols=103; val rows=11
    val count=cols*rows
    fun node(id:Int)=WalkPoint(75f+(id%cols)*dx,615f+(id/cols)*dy)
    val valid=BooleanArray(count){ i->
        val p=node(i); walkable(p.x,p.y,models,room)
    }
    fun closest(p:WalkPoint):Int {
        var best=-1
        var distance=Float.POSITIVE_INFINITY
        for(i in 0 until count){
            if(!valid[i])continue
            val q=node(i)
            val d=(p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y)
            if(d<distance && clearPath(p,q,models,room)){
                best=i; distance=d
            }
        }
        return best
    }
    val source=closest(start)
    val dest=closest(target)
    if(source<0||dest<0)return emptyList()
    val cost=FloatArray(count){ Float.POSITIVE_INFINITY }
    val previous=IntArray(count){-1}
    val closed=BooleanArray(count)
    val queue=java.util.PriorityQueue<Pair<Float,Int>>(compareBy{it.first})
    cost[source]=0f
    queue.add(0f to source)
    while(queue.isNotEmpty()){
        val id=queue.poll().second
        if(closed[id])continue
        if(id==dest)break
        closed[id]=true
        val c=id%cols; val r=id/cols
        val a=node(id)
        for(stepY in -1..1)for(stepX in -1..1){
            if(stepX==0&&stepY==0)continue
            val nx=c+stepX; val ny=r+stepY
            if(nx !in 0 until cols || ny !in 0 until rows)continue
            val next=ny*cols+nx
            if(!valid[next]||closed[next])continue
            val b=node(next)
            // No corner cutting: inspect the entire diagonal segment.
            if(!clearPath(a,b,models,room))continue
            val length=if(stepX!=0&&stepY!=0)35.35534f else 25f
            val nextCost=cost[id]+length
            if(nextCost<cost[next]){
                previous[next]=id; cost[next]=nextCost
                val estimate=hypot(b.x-node(dest).x,b.y-node(dest).y)
                queue.add((nextCost+estimate) to next)
            }
        }
    }
    if(!cost[dest].isFinite())return emptyList()
    val backwards=mutableListOf<WalkPoint>()
    var id=dest
    while(id>=0&&id!=source){
        backwards.add(node(id))
        id=previous[id]
    }
    if(id!=source)return emptyList()
    backwards.reverse()
    backwards.add(target)
    // Keep only corners: fewer unnecessary turns and nicer walking.
    val simplified=mutableListOf<WalkPoint>()
    var here=start
    var index=0
    while(index<backwards.size){
        var furthest=index
        for(k in backwards.lastIndex downTo index){
            if(clearPath(here,backwards[k],models,room)){
                furthest=k
                break
            }
        }
        simplified.add(backwards[furthest])
        here=backwards[furthest]
        index=furthest+1
    }
    return simplified
}

