package com.nikolegame
import org.junit.Assert.*
import org.junit.Test
class RoomNavigationTest {
    private fun check(a:WalkPoint,b:WalkPoint,models:Map<String,Int>,room:String) {
        val route=roomRoute(a,b,models,room)
        assertTrue("No route $room $a -> $b ($models)",route.isNotEmpty())
        var here=a
        for(next in route){assertTrue("Collision $here -> $next",clearPath(here,next,models,room));here=next}
        assertEquals(b,route.last())
    }
    @Test fun kitchenBothSidesAndWindowStayReachable() {
        val points=listOf(WalkPoint(1250f,840f),WalkPoint(1900f,840f),WalkPoint(1489f,630f))
        for(a in points)for(b in points)check(a,b,emptyMap(),"kitchen")
        assertFalse(clearPath(WalkPoint(1250f,740f),WalkPoint(1900f,740f),emptyMap(),"kitchen"))
    }
    @Test fun furnitureVariantsPreservePetAndDoorCorridors() {
        for(category in listOf("bed","wardrobe","table","chair"))for(style in 0..5){
            val models=mapOf(category to style)
            for(start in listOf(WalkPoint(250f,820f),WalkPoint(1185f,820f),WalkPoint(2400f,820f))){
                check(start,WalkPoint(1140f,795f),models,"bedroom")
                check(start,WalkPoint(1370f,815f),models,"bedroom")
            }
        }
    }
}
