package com.nikolegame

import android.content.Context
import android.os.Bundle
import android.view.View
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.min
import kotlin.math.max
import kotlin.random.Random

private const val WORLD = 2700f
private val Ivory = Color(0xFFFFFBF5)
private val Violet = Color(0xFF7C599B)
private val Pink = Color(0xFFFFC3D5)

private data class WalkPoint(val x: Float, val y: Float)

// Coordinates describe where Nicole's feet are. Furniture is solid, floor is walkable.
private fun kitchenWalkable(x:Float,y:Float):Boolean {
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
private fun walkable(
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
private fun closestWalkable(
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
private fun clearPath(
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
private fun roomRoute(
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

class MainActivity : ComponentActivity() {
    @Suppress("DEPRECATION")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
        setContent {
            MaterialTheme { NicoleGame() }
        }
    }
}

@Composable
private fun NicoleGame() {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("nicole_save", Context.MODE_PRIVATE) }
    // Explicitly configured for debug builds; release coins still apply.
    val freeTesting = BuildConfig.FREE_SHOP_TESTING
    var locale by remember { mutableStateOf(prefs.getString("locale", "ru") ?: "ru") }
    var pet by remember { mutableStateOf(prefs.getString("pet", "") ?: "") }
    var isNight by remember { mutableStateOf(false) }
    var season by remember { mutableIntStateOf(prefs.getInt("season", 1).coerceIn(0, 3)) }
    var coins by remember { mutableIntStateOf(prefs.getInt("coins", 0).coerceAtLeast(0)) }
    var ownedStyles by remember {
        mutableStateOf(prefs.getStringSet("renovation_owned", emptySet())?.toSet()
            ?: emptySet<String>())
    }
    var wallStyle by remember { mutableIntStateOf(prefs.getInt("room_wall", 0).coerceIn(0, MAX_ITEM_STYLE)) }
    var floorStyle by remember { mutableIntStateOf(prefs.getInt("room_floor", 0).coerceIn(0, MAX_ITEM_STYLE)) }
    var furnitureStyle by remember {
        mutableIntStateOf(prefs.getInt("room_furniture", 0).coerceIn(0, 2))
    }
    var selectedStyles by remember {
        mutableStateOf(ROOM_CATEGORIES.associate { cat ->
            val old = if(cat.id in listOf("bed","wardrobe","table","chair"))
                prefs.getInt("room_furniture",0) else 0
            cat.id to prefs.getInt("room_"+cat.id,old).coerceIn(0,MAX_ITEM_STYLE)
        })
    }
    var shopFeedback by remember { mutableStateOf<String?>(null) }
    var petShopFeedback by remember { mutableStateOf<String?>(null) }
    var petSelections by remember {
        mutableStateOf(PET_SHOP_ITEMS.map{it.category}.distinct().associateWith { category ->
            prefs.getInt("room_"+category,0).coerceIn(0,3)
        })
    }
    var designCategory by remember {
        mutableStateOf(prefs.getString("design_tab","bed")?.takeIf { tab ->
            ROOM_CATEGORIES.any{it.id==tab}
        } ?: "bed")
    }
    var countingQuestion by remember { mutableIntStateOf(Random.nextInt(2, 9)) }
    var countingCorrect by remember { mutableIntStateOf(0) }
    var countingMistake by remember { mutableStateOf(false) }
    var leftDoor by remember { mutableStateOf(false) }
    var rightDoor by remember { mutableStateOf(false) }
    var currentRoom by remember { mutableStateOf("bedroom") }
    var fridgeOpen by remember { mutableStateOf(false) }
    var girlX by remember { mutableFloatStateOf(1350f) }
    var girlY by remember { mutableFloatStateOf(810f) }
    var girlFacing by remember { mutableIntStateOf(0) } // 0 front, 1 left, 2 right, 3 back
    var targetX by remember { mutableFloatStateOf(1350f) }
    var targetY by remember { mutableFloatStateOf(810f) }
    val walkPath = remember { mutableStateListOf<WalkPoint>() }
    var routeRecoveryUsed by remember { mutableStateOf(false) }
    var petX by remember { mutableFloatStateOf(1185f) }
    var petY by remember { mutableFloatStateOf(820f) }
    var petTargetX by remember { mutableFloatStateOf(1185f) }
    var petTargetY by remember { mutableFloatStateOf(820f) }
    var pendingPetAction by remember { mutableStateOf("") }
    var petAction by remember { mutableStateOf("") }
    var petActionStartFrame by remember { mutableIntStateOf(0) }
    // go -> inside -> normal roaming; pet returns to the same clear walkway.
    var petHomeMode by remember { mutableStateOf("") }
    val petHomeRoute=remember { mutableStateListOf<WalkPoint>() }
    var petHomeStartFrame by remember { mutableIntStateOf(0) }
    var viewWidth by remember { mutableFloatStateOf(1600f) }
    var camera by remember { mutableFloatStateOf(550f) }
    var manualCamera by remember { mutableStateOf(false) }
    var frames by remember { mutableIntStateOf(0) }
    var uiVisible by remember { mutableStateOf(true) }
    var lastTouch by remember { mutableIntStateOf(0) }
    var dialog by remember { mutableStateOf<String?>(null) }
    var message by remember { mutableStateOf<String?>(null) }
    val cameraNow = rememberUpdatedState(camera)
    val modelsNow = rememberUpdatedState(selectedStyles)
    val roomNow = rememberUpdatedState(currentRoom)
    val petNow = rememberUpdatedState(pet)
    val petXNow = rememberUpdatedState(petX)
    val petYNow = rememberUpdatedState(petY)
    val fridgeOpenNow = rememberUpdatedState(fridgeOpen)
    val widthNow = rememberUpdatedState(viewWidth)
    fun walkTo(x: Float, y: Float) {
        // Any new walk command resumes automatic camera tracking after a
        // manual swipe. Otherwise Nicole can walk off-screen and appear stuck.
        manualCamera = false
        val start = WalkPoint(girlX, girlY)
        // Tapping the tabletop should approach it from the SAME side as Nicole,
        // not snap her destination to the other side of a solid obstacle.
        val aimedY = if (roomNow.value=="kitchen" &&
            x in 1290f..1810f && y in 675f..810f) {
            if(girlY>=735f) 840f else 640f
        } else y
        val destination = closestWalkable(x, aimedY, modelsNow.value, roomNow.value)
        targetX = destination.x
        targetY = destination.y
        routeRecoveryUsed = false
        walkPath.clear()
        val route=roomRoute(start,destination,modelsNow.value,roomNow.value)
        walkPath.addAll(route)
        if(route.isEmpty() && hypot(destination.x-girlX,destination.y-girlY)>12f) {
            message = if(locale=="ru") "Здесь проход закрыт" else "Hier ist der Weg versperrt"
        }
    }

    fun planPetHomeRoute():Boolean {
        val goal=WalkPoint(1140f,795f)
        val steps=roomRoute(WalkPoint(petX,petY),goal,selectedStyles,"bedroom")
        if(steps.isEmpty() && hypot(petX-goal.x,petY-goal.y)>12f)return false
        petHomeRoute.clear()
        petHomeRoute.addAll(steps)
        val first=petHomeRoute.firstOrNull()?:goal
        petHomeMode="go"
        petHomeStartFrame=frames
        petTargetX=first.x;petTargetY=first.y
        return true
    }
    fun sendPetHome() {
        if(pet.isEmpty() || currentRoom!="bedroom")return
        if((petSelections["pet_home_"+pet]?:0)<=0){
            message=if(locale=="ru")"Сначала купи домик в магазине 🐾"
                else "Kaufe zuerst ein Häuschen 🐾"
            dialog=null
            return
        }
        petAction=""
        pendingPetAction=""
        dialog=null
        if(planPetHomeRoute()){
            message=if(locale=="ru")"🏠 Питомец идёт в домик!"
                else "🏠 Dein Tier geht nach Hause!"
        }else{
            message=if(locale=="ru")"Питомец не может найти проход к домику"
                else "Dein Tier findet keinen Weg zum Häuschen"
        }
    }
    fun beginPetInteraction(action:String) {
        if(pet.isEmpty() || currentRoom!="bedroom")return
        if(action=="home"){sendPetHome();return}
        if(petHomeMode.isNotEmpty()){
            // Leave the habitat at its front, not through a wall or cage.
            petX=1140f
            petY=795f
            petHomeMode=""
            petHomeRoute.clear()
        }
        petTargetX=petX;petTargetY=petY
        petAction=""
        pendingPetAction=action
        dialog=null
        val approachX=(petX + if(girlX<=petX)-125f else 125f)
            .coerceIn(80f,WORLD-80f)
        walkTo(approachX,petY.coerceIn(795f,846f))
    }
    fun tr(ru: String, de: String) = if (locale == "ru") ru else de
    fun interact() { uiVisible = true; lastTouch++ }
    fun toast(ru: String, de: String) { message = tr(ru, de) }
    fun returnToBedroom() {
        currentRoom = "bedroom"
        petHomeMode=""
        petHomeRoute.clear()
        petAction=""
        pendingPetAction=""
        fridgeOpen = false
        girlX = 2240f; girlY = 810f
        targetX = girlX; targetY = girlY
        girlFacing = 0
        walkPath.clear()
        manualCamera = false
        camera = (girlX - widthNow.value / 2f)
            .coerceIn(0f,max(0f,WORLD-widthNow.value))
        toast("Снова в спальне! 🏡", "Zurück im Schlafzimmer! 🏡")
    }
    // Canvas gesture handlers are long-lived; use the LATEST Compose state and
    // current lambdas instead of values captured at the first composition.
    val touchWalk = rememberUpdatedState<(Float,Float)->Unit>({ x,y -> walkTo(x,y) })
    val touchInteract = rememberUpdatedState<()->Unit>({ interact() })
    val touchToast = rememberUpdatedState<(String,String)->Unit>({ ru,de -> toast(ru,de) })
    val touchReturn = rememberUpdatedState<()->Unit>({ returnToBedroom() })
    val touchPet = rememberUpdatedState<()->Unit>({ dialog="pet_actions" })
    val touchHome = rememberUpdatedState<()->Unit>({ sendPetHome() })
    val petHomesNow=rememberUpdatedState(petSelections)

    LaunchedEffect(viewWidth) {
        camera = (girlX - viewWidth / 2f).coerceIn(0f, max(0f, WORLD - viewWidth))
    }
    LaunchedEffect(lastTouch, dialog) {
        if (dialog == null) {
            delay(10_000)
            uiVisible = false
        }
    }
    LaunchedEffect(message) {
        if (message != null) {
            delay(2300)
            message = null
        }
    }
    // A pet lives in world space. Walking with Nicole is never forced.
    LaunchedEffect(pet, selectedStyles, currentRoom, petSelections) {
        while (pet.isNotEmpty()) {
            if (currentRoom != "bedroom") {
                delay(1800)
                continue
            }
            delay(Random.nextLong(2200L, 4400L))
            if(pendingPetAction.isNotEmpty() || petAction.isNotEmpty() ||
                petHomeMode.isNotEmpty())continue
            // House visits are autonomous as well as manually triggerable.
            if((petSelections["pet_home_"+pet]?:0)>0 &&
                Random.nextInt(4)==0 && planPetHomeRoute())continue
            if (pet == "dog" || pet == "cat" || pet == "hamster") {
                // Hamsters explore only a small patch; dogs and cats wander farther.
                val range = if (pet == "hamster") 85 else 240
                val yRange = if (pet == "hamster") 30 else 75
                val destination = closestWalkable(
                    petX + Random.nextInt(-range, range + 1),
                    petY + Random.nextInt(-yRange, yRange + 1), selectedStyles
                )
                if (clearPath(WalkPoint(petX, petY), destination, selectedStyles)) {
                    petTargetX = destination.x
                    petTargetY = destination.y
                }
            } else if (pet == "turtle") {
                petTargetX = (petX + Random.nextInt(-28, 29)).coerceIn(1135f, 1235f)
                petTargetY = (petY + Random.nextInt(-12, 13)).coerceIn(795f, 850f)
            } else if (pet == "parrot") {
                // A small bird makes short autonomous flights around the
                // bedroom instead of standing at one place on the floor.
                // Flying ignores floor furniture collisions below it.
                petTargetX = (petX + Random.nextInt(-280,281))
                    .coerceIn(260f,WORLD-260f)
                petTargetY = (petY + Random.nextInt(-80,81))
                    .coerceIn(695f,825f)
            }
        }
    }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameNanos { }
            frames++
            if(petHomeMode=="inside" && frames-petHomeStartFrame>=235){
                petHomeMode=""
                petX=1140f
                petY=795f
                petTargetX=petX;petTargetY=petY
            }
            if(petHomeMode=="go" &&
                hypot(petTargetX-petX,petTargetY-petY)<9f){
                if(petHomeRoute.isNotEmpty())petHomeRoute.removeAt(0)
                if(petHomeRoute.isEmpty()){
                    petX=1140f;petY=795f
                    petTargetX=petX;petTargetY=petY
                    petHomeMode="inside"
                    petHomeStartFrame=frames
                }else{
                    petTargetX=petHomeRoute.first().x
                    petTargetY=petHomeRoute.first().y
                }
            }
            if(petAction.isNotEmpty() && frames-petActionStartFrame>=155){
                petAction=""
            }
            if(pendingPetAction.isNotEmpty() && walkPath.isEmpty()){
                val dist=hypot(petX-girlX,petY-girlY)
                if(dist<220f){
                    petAction=pendingPetAction
                    petActionStartFrame=frames
                    pendingPetAction=""
                    petTargetX=petX;petTargetY=petY
                    message=when(petAction){
                        "pet"->if(locale=="ru")"💗 Питомцу приятно!" else "💗 Wie schön!"
                        "play"->if(locale=="ru")"🎾 Весёлая игра!" else "🎾 Viel Spaß!"
                        else->if(locale=="ru")"🥣 Вкусный обед!" else "🥣 Guten Appetit!"
                    }
                } else {
                    pendingPetAction=""
                    message=if(locale=="ru")"Не удалось подойти к питомцу"
                        else "Der Weg zum Tier ist versperrt"
                }
            }
            // Stop autonomous wandering while Nicole approaches and interacts.
            if(petAction.isNotEmpty() || pendingPetAction.isNotEmpty() ||
                petHomeMode=="inside"){
                petTargetX=petX;petTargetY=petY
            }
            if (pet.isNotEmpty() && roomNow.value == "bedroom") {
                val dx = petTargetX - petX
                val dy = petTargetY - petY
                val dist = hypot(dx, dy)
                if (dist > 1.5f) {
                    val speed = when {
                        petHomeMode=="go" -> if(pet=="turtle")1.9f else 3.1f
                        pet=="turtle" -> 0.3f
                        pet=="hamster" -> 0.85f
                        pet=="parrot" -> 2.0f
                        else -> 1.45f
                    }
                    val step = min(speed, dist)
                    val nx = petX + dx / dist * step
                    val ny = petY + dy / dist * step
                    if (pet == "parrot" ||
                        walkable(nx, ny, modelsNow.value, roomNow.value)) {
                        petX = nx
                        petY = ny
                    } else if(petHomeMode=="go"){
                        val retry=roomRoute(
                            WalkPoint(petX,petY),WalkPoint(1140f,795f),
                            modelsNow.value,"bedroom")
                        petHomeRoute.clear()
                        petHomeRoute.addAll(retry)
                        if(retry.isNotEmpty()){
                            petTargetX=retry.first().x
                            petTargetY=retry.first().y
                        }else{
                            petHomeMode=""
                            petTargetX=petX
                            petTargetY=petY
                        }
                    } else {
                        petTargetX = petX
                        petTargetY = petY
                    }
                }
            }
            if (walkPath.isNotEmpty()) {
                val next = walkPath.first()
                val dx = next.x - girlX
                val dy = next.y - girlY
                val distance = hypot(dx, dy)
                if (distance > 2f) {
                    // Face the actual walking direction; no teleporting or camera coupling.
                    girlFacing = if (abs(dx) >= abs(dy) * 1.3f) {
                        if (dx < 0f) 1 else 2
                    } else {
                        if (dy < 0f) 3 else 0
                    }
                }
                if (distance <= 5.6f) {
                    girlX = next.x
                    girlY = next.y
                    walkPath.removeAt(0)
                } else {
                    val nx = girlX + dx / distance * 5.6f
                    val ny = girlY + dy / distance * 5.6f
                    if (walkable(nx, ny, modelsNow.value, roomNow.value)) {
                        girlX = nx
                        girlY = ny
                    } else if(!routeRecoveryUsed) {
                        // Recover from a missed corner rather than freezing.
                        routeRecoveryUsed = true
                        val retry=roomRoute(
                            WalkPoint(girlX,girlY),WalkPoint(targetX,targetY),
                            modelsNow.value,roomNow.value
                        )
                        walkPath.clear()
                        walkPath.addAll(retry)
                    } else {
                        walkPath.clear()
                    }
                }
                if (!manualCamera) {
                    val desired = (girlX - viewWidth / 2f)
                        .coerceIn(0f, max(0f, WORLD - viewWidth))
                    camera += (desired - camera) * 0.08f
                }
            }
        }
    }

    Box(Modifier.fillMaxSize().background(Ivory)) {
        Canvas(
            Modifier.fillMaxSize()
                .onSizeChanged {
                    val scale = it.height / 900f
                    if (scale > 0f) viewWidth = it.width / scale
                }
                .pointerInput(Unit) {
                    detectTapGestures { touch ->
                        touchInteract.value()
                        val scale = size.height / 900f
                        val worldX = touch.x / scale + cameraNow.value
                        val worldY = touch.y / scale
                        when {
                            roomNow.value=="bedroom" &&
                                petNow.value in PET_SPECIES &&
                                (petHomesNow.value["pet_home_"+petNow.value]?:0)>0 &&
                                worldX in 1002f..1282f &&
                                worldY in 390f..752f -> {
                                touchHome.value()
                            }
                            roomNow.value=="bedroom" && petNow.value.isNotEmpty() &&
                                kotlin.math.abs(worldX-petXNow.value)<115f &&
                                worldY in (petYNow.value-
                                    if(petNow.value=="parrot")260f else 163f)..
                                    (petYNow.value+28f) -> {
                                touchPet.value()
                            }
                            // Kitchen: tap the left doorway to return to the bedroom.
                            roomNow.value == "kitchen" &&
                                worldY in 160f..615f && worldX in 115f..335f -> {
                                touchReturn.value()
                            }
                            roomNow.value == "kitchen" &&
                                worldY in 160f..615f && worldX in 2345f..2570f -> {
                                touchToast.value("Здесь скоро будет новая комната!",
                                    "Hier kommt später ein weiteres Zimmer!")
                            }
                            roomNow.value == "kitchen" &&
                                worldX in 374f..779f && worldY in 263f..676f -> {
                                val opening = !fridgeOpenNow.value
                                fridgeOpen = opening
                                touchToast.value(
                                    if(opening) "Холодильник открыт! 🥕"
                                    else "Холодильник закрыт!",
                                    if(opening) "Kühlschrank geöffnet! 🥕"
                                    else "Kühlschrank geschlossen!"
                                )
                            }
                            roomNow.value == "kitchen" &&
                                worldX in 1328f..1660f && worldY in 110f..463f -> {
                                // Glass is on the wall; walking target is on the
                                // actual floor directly below the window.
                                touchWalk.value(1489f, 630f)
                                touchToast.value("К окошку! 🌳", "Zum Fenster! 🌳")
                            }
                            roomNow.value == "kitchen" -> {
                                if(worldY >= 590f) touchWalk.value(worldX,worldY)
                            }
                            worldY in 160f..610f && worldX in 115f..325f -> {
                                leftDoor = !leftDoor
                                touchToast.value("Дверь открыта!", "Tür geöffnet!")
                            }
                            worldY in 160f..610f && worldX in 2345f..2570f -> {
                                rightDoor = true
                                currentRoom = "kitchen"
                                girlX = 388f; girlY = 807f
                                targetX = girlX; targetY = girlY
                                girlFacing = 0
                                walkPath.clear()
                                manualCamera = false
                                camera = 0f
                                touchToast.value("Мы на кухне! 🍎", "Willkommen in der Küche! 🍎")
                            }
                            roomNow.value == "bedroom" &&
                                worldX in 486f..827f && worldY in 110f..452f -> {
                                // Walk THROUGH the side aisle to the floor
                                // directly beneath this window.
                                touchWalk.value(652f,642f)
                                touchToast.value("Подойдём к окну! 🌸",
                                    "Gehen wir zum Fenster! 🌸")
                            }
                            roomNow.value == "bedroom" &&
                                worldX in 1834f..2197f && worldY in 110f..452f -> {
                                // Rear aisle behind the desk; pathfinder routes
                                // around furniture rather than cutting through it.
                                touchWalk.value(2025f,639f)
                                touchToast.value("Подойдём к окну! 🌳",
                                    "Gehen wir zum Fenster! 🌳")
                            }
                            worldX in 340f..860f && worldY in 360f..740f -> {
                                touchWalk.value(870f, 775f)
                                touchToast.value("Уютная кроватка!", "Ein gemütliches Bett!")
                            }
                            worldX in 1510f..1840f && worldY in 280f..635f -> {
                                touchWalk.value(1860f, 760f)
                                touchToast.value("Здесь мой шкаф!", "Das ist mein Schrank!")
                            }
                            worldX in 1870f..2280f && worldY in 355f..710f -> {
                                touchWalk.value(2335f, 760f)
                                touchToast.value("Будем рисовать!", "Lass uns malen!")
                            }
                            else -> {
                                if (worldY >= 580f) {
                                    touchWalk.value(worldX, worldY)
                                }
                            }
                        }
                    }
                }
                .pointerInput(Unit) {
                    detectDragGestures { change, dragAmount ->
                        change.consume()
                        touchInteract.value()
                        manualCamera = true
                        val scale = size.height / 900f
                        camera = (cameraNow.value - dragAmount.x / scale)
                            .coerceIn(0f, max(0f, WORLD - widthNow.value))
                    }
                }
        ) {
            val s = size.height / 900f
            withTransform({
                scale(s, s, Offset.Zero)
                translate(-camera, 0f)
            }) {
                if (currentRoom == "kitchen") {
                    renderKitchen(isNight, season, frames, camera,
                        selectedStyles["fridge"] ?: 0, fridgeOpen)
                } else {
                    drawRoom(isNight, season, frames, leftDoor, rightDoor, camera,
                        wallStyle, floorStyle, furnitureStyle, selectedStyles)
                    if(pet.isNotEmpty()){
                        val homeStyle=petSelections["pet_home_"+pet]?:0
                        renderPetHabitat(pet,homeStyle)
                        if(petHomeMode=="inside"){
                            renderPetInHabitat(pet,homeStyle,frames-petHomeStartFrame)
                            renderPetHabitatFront(pet,homeStyle)
                        }
                        renderPetBowl(pet,petSelections["pet_bowl_"+pet]?:0)
                    }
                }
                val depth = (0.82f + (girlY - 680f) / 800f).coerceIn(0.80f, 1.05f)
                // The pet stays safely in the bedroom while Nicole visits the kitchen.
                if (currentRoom == "bedroom" && pet.isNotEmpty() &&
                    petHomeMode!="inside" && petY <= girlY) {
                    renderPet(pet, petX, petY, frames,
                        hypot(petTargetX - petX, petTargetY - petY) > 1.5f,
                        petAction,(frames-petActionStartFrame).coerceAtLeast(0))
                }
                // In the kitchen the dining table changes depth order as Nicole
                // moves: behind her near the front, IN FRONT of her by the window.
                if(currentRoom == "kitchen" && girlY >= 811f) {
                    renderKitchenDiningTable()
                }
                renderNicole(girlX, girlY, depth, frames, walkPath.isNotEmpty(), girlFacing)
                if(currentRoom == "kitchen" && girlY < 811f) {
                    renderKitchenDiningTable()
                }
                // Bed and desk occlude Nicole correctly in the walkable
                // rear corridor, without moving the approved furniture.
                if(currentRoom == "bedroom") {
                    renderBedroomForeground(selectedStyles,furnitureStyle,girlX,girlY)
                }
                if (currentRoom == "bedroom" && pet.isNotEmpty() &&
                    petHomeMode!="inside" && petY > girlY) {
                    renderPet(pet, petX, petY, frames,
                        hypot(petTargetX - petX, petTargetY - petY) > 1.5f,
                        petAction,(frames-petActionStartFrame).coerceAtLeast(0))
                }
                // One uniform night tint over the whole scene including
                // Nicole and depth-ordered furniture in both rooms.
                if(isNight) {
                    drawRect(Color(0xFF30345B).copy(alpha=.25f),
                        size=Size(WORLD,900f))
                }
            }
        }

        if (uiVisible && dialog == null) {
            Row(
                Modifier.align(Alignment.TopStart)
                    .padding(start = 11.dp, top = 8.dp)
                    .clip(RoundedCornerShape(22.dp))
                    .background(Ivory.copy(alpha = 0.95f))
                    .padding(horizontal = 15.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("🪙 $coins", fontSize = 17.sp, color = Violet, fontWeight = FontWeight.Bold)
            }
            Box(Modifier.align(Alignment.TopCenter).padding(top = 6.dp)) {
                MenuKey(
                    if(currentRoom=="kitchen") "🚪" else "🎯",
                    if(currentRoom=="kitchen") tr("В спальню", "Zum Schlafzimmer")
                    else tr("К Николь", "Zu Nicole")
                ) {
                    interact()
                    if(currentRoom=="kitchen") returnToBedroom()
                    else {
                        manualCamera = false
                        camera = (girlX - viewWidth / 2f)
                            .coerceIn(0f, max(0f, WORLD - viewWidth))
                    }
                }
            }
            Column(
                Modifier.align(Alignment.CenterStart).padding(start = 8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                MenuKey("🛍️", tr("Магазин", "Laden")) {
                    interact(); shopFeedback = null; dialog = "shop"
                }
                MenuKey("👗", tr("Гардероб", "Kleidung")) { interact(); dialog = "wardrobe" }
                MenuKey("🐾", tr("Питомцы", "Tiere")) { interact(); dialog = "pets" }
                if(pet.isNotEmpty() && currentRoom=="bedroom"){
                    MenuKey("💗", tr("Играть", "Spielen")) {
                        interact(); dialog="pet_actions"
                    }
                }
                MenuKey("🎮", tr("Игры", "Spiele")) {
                    interact()
                    countingQuestion = Random.nextInt(2, 9)
                    countingCorrect = 0
                    countingMistake = false
                    dialog = "games"
                }
            }
            Column(
                Modifier.align(Alignment.CenterEnd).padding(end = 8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                MenuKey("🎨", tr("Оформление", "Gestalten")) {
                    interact(); shopFeedback = null; dialog = "design"
                }
                MenuKey(if (isNight) "🌙" else "☀️", tr("День/ночь", "Tag/Nacht")) {
                    interact(); isNight = !isNight
                }
                MenuKey(arrayOf("🌸", "☀️", "🍂", "❄️")[season], tr("Сезон", "Jahreszeit")) {
                    interact()
                    season = (season + 1) % 4
                    prefs.edit().putInt("season", season).apply()
                    val ru = arrayOf("Весна 🌸", "Лето ☀️", "Осень 🍂", "Зима ❄️")
                    val de = arrayOf("Frühling 🌸", "Sommer ☀️", "Herbst 🍂", "Winter ❄️")
                    toast(ru[season], de[season])
                }
            }
            Box(Modifier.align(Alignment.TopEnd).padding(top = 8.dp, end = 10.dp)) {
                MenuKey("⚙️", tr("Настройки", "Optionen")) { interact(); dialog = "settings" }
            }
        }
        if (message != null && dialog == null) {
            Box(
                Modifier.align(Alignment.BottomCenter).padding(bottom = 16.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(Ivory.copy(alpha = 0.95f))
                    .padding(horizontal = 18.dp, vertical = 10.dp)
            ) {
                Text(message ?: "", color = Violet, fontWeight = FontWeight.SemiBold)
            }
        }
    }

    if (dialog == "design" || dialog == "shop") {
        RenovationShop(
            locale=locale, coins=coins, category=designCategory,
            freeTesting=freeTesting,
            selections=selectedStyles, owned=ownedStyles,
            feedback=shopFeedback,
            onCategory={ id ->
                shopFeedback = null
                designCategory=id
                prefs.edit().putString("design_tab",id).apply()
            },
            onPetShop={ shopFeedback=null;petShopFeedback=null;dialog="pet_shop" },
            onPick={ item ->
                val purchase = purchaseRenovation(
                    item, coins, ownedStyles, selectedStyles, freeTesting
                )
                if(purchase.success) {
                    // Apply one atomic preference edit, including the selection,
                    // so the piece stays installed after restarting the game.
                    coins = purchase.coins
                    ownedStyles = purchase.owned
                    selectedStyles = purchase.selections
                    prefs.edit()
                        .putInt("coins", purchase.coins)
                        .putStringSet("renovation_owned", purchase.owned.toSet())
                        .putInt("room_"+item.category, item.style)
                        .apply()
                    if(item.category=="wall")wallStyle=item.style
                    if(item.category=="floor")floorStyle=item.style
                    shopFeedback = if(locale=="ru")
                        "✓ Установлено: ${item.nameRu}"
                    else "✓ Aufgestellt: ${item.nameDe}"
                } else {
                    shopFeedback = if(locale=="ru")
                        "Не хватает монет" else "Nicht genug Münzen"
                }
            },
            onClose={dialog=null}
        )
    } else if(dialog=="pet_shop") {
        PetShop(
            locale=locale,activePet=pet,coins=coins,freeTesting=freeTesting,
            selections=petSelections,owned=ownedStyles,feedback=petShopFeedback,
            onPick={ item ->
                val purchase=purchaseRenovation(
                    item,coins,ownedStyles,petSelections,freeTesting
                )
                if(purchase.success){
                    coins=purchase.coins
                    ownedStyles=purchase.owned
                    petSelections=purchase.selections
                    prefs.edit().putInt("coins",purchase.coins)
                        .putStringSet("renovation_owned",purchase.owned.toSet())
                        .putInt("room_"+item.category,item.style)
                        .apply()
                    petShopFeedback=if(locale=="ru")
                        "✓ Установлено: ${item.nameRu}"
                    else "✓ Aufgestellt: ${item.nameDe}"
                }else{
                    petShopFeedback=if(locale=="ru")"Не хватает монет"
                        else "Nicht genug Münzen"
                }
            },
            onBack={petShopFeedback=null;dialog="shop"},
            onChoosePet={petShopFeedback=null;dialog="pets"},
            onClose={dialog=null}
        )
    } else if(dialog=="pet_actions" && pet.isNotEmpty()){
        PetActionsDialog(
            locale=locale,pet=pet,
            hasHome=(petSelections["pet_home_"+pet]?:0)>0,
            onAction={ action->beginPetInteraction(action) },
            onClose={dialog=null}
        )
    } else if (dialog == "pets") {
        // Choosing a pet is optional and available only through the paw button.
        PetChooser(
            locale=locale, chosen=pet,
            onChoose={ kind ->
                pet=kind
                petHomeMode=""
                petHomeRoute.clear()
                petAction=""
                pendingPetAction=""
                prefs.edit().putString("pet",kind).apply()
                if(kind.isNotEmpty()) {
                    petX=1185f; petY=820f
                    petTargetX=petX; petTargetY=petY
                }
                dialog=null
            },
            onClose={ dialog=null }
        )
    } else if (dialog != null) {
        AlertDialog(
            onDismissRequest = { dialog = null },
            title = {
                Text(when (dialog) {
                    "design" -> tr("Оформление комнаты", "Zimmer gestalten")
                    "shop" -> tr("Магазин ремонта", "Renovierungsladen")
                    "games" -> tr("Считаем яблоки", "Äpfel zählen")
                    "wardrobe" -> tr("Гардероб", "Kleidung")
                    else -> tr("Настройки", "Einstellungen")
                })
            },
            text = {
                when (dialog) {
                    "settings" -> {
                        TextButton(onClick = {
                            locale = if (locale == "ru") "de" else "ru"
                            prefs.edit().putString("locale", locale).apply()
                        }) {
                            Text(tr("Язык: Русский → Deutsch",
                                "Sprache: Deutsch → Русский"))
                        }
                    }
                    "games" -> {
                        Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
                            Text(tr("Посчитай яблоки. Три правильных ответа " +
                                "принесут 20 🪙!", "Zähle die Äpfel. Drei richtige " +
                                "Antworten bringen 20 🪙!"), fontSize = 13.sp)
                            Text(tr("Правильно: $countingCorrect из 3",
                                "Richtig: $countingCorrect von 3"),
                                fontSize = 12.sp, color = Violet)
                            Text("🍎 ".repeat(countingQuestion), fontSize = 22.sp)
                            Text(tr("Сколько яблок?", "Wie viele Äpfel?"))
                            Row(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                                listOf((countingQuestion - 1).coerceAtLeast(1),
                                    countingQuestion, (countingQuestion + 1).coerceAtMost(9))
                                    .distinct().sorted().forEach { answer ->
                                        TextButton(onClick = {
                                            if (answer == countingQuestion) {
                                                countingCorrect++
                                                countingMistake = false
                                                if (countingCorrect >= 3) {
                                                    coins += 20
                                                    prefs.edit().putInt("coins", coins).apply()
                                                    dialog = null
                                                    toast("Молодец! +20 монет 🪙",
                                                        "Super! +20 Münzen 🪙")
                                                } else {
                                                    countingQuestion = Random.nextInt(2, 9)
                                                }
                                            } else {
                                                countingMistake = true
                                            }
                                        }) {
                                            Text("$answer", fontSize = 22.sp,
                                                fontWeight = FontWeight.Bold)
                                        }
                                    }
                            }
                            if (countingMistake) {
                                Text(tr("Попробуй ещё! 🌷", "Versuch es nochmal! 🌷"),
                                    color = Violet, fontSize = 12.sp)
                            }
                        }
                    }
                    else -> {
                        Text(tr("Этот раздел появится в следующих версиях.",
                            "Dieser Bereich wird später ergänzt."))
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { dialog = null }) {
                    Text(tr("Закрыть", "Schließen"))
                }
            }
        )
    }
}

@Composable
private fun MenuKey(symbol: String, label: String, onClick: () -> Unit) {
    Column(
        Modifier.width(88.dp).clip(RoundedCornerShape(19.dp))
            .background(Ivory.copy(alpha = 0.92f)).clickable(onClick = onClick)
            .padding(horizontal = 3.dp, vertical = 5.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(symbol, fontSize = 23.sp, lineHeight = 25.sp)
        Text(label, fontSize = 9.sp, lineHeight = 11.sp, color = Color(0xFF443183),
            textAlign = TextAlign.Center, fontWeight = FontWeight.Bold, maxLines = 2)
    }
}

private fun DrawScope.drawRoom(
    night: Boolean, season: Int, tick: Int,
    lOpen: Boolean, rOpen: Boolean, camera: Float,
    wallStyle: Int, floorStyle: Int, furnitureStyle: Int,
    selections: Map<String,Int>
) {
    renderRoomArt(night, season, tick, lOpen, rOpen, camera,
        wallStyle, floorStyle, furnitureStyle, selections)
}

private fun DrawScope.drawDoor(x: Float, open: Boolean) {
    drawRoundRect(Color(0xFFF0DCC9), Offset(x - 18f, 157f), Size(236f, 445f),
        CornerRadius(100f, 90f))
    drawRoundRect(Color(0xFF684334), Offset(x, 175f), Size(199f, 424f),
        CornerRadius(80f, 80f))
    if (!open) {
        drawRoundRect(Color(0xFF965D44), Offset(x + 13f, 188f), Size(173f, 398f),
            CornerRadius(76f, 65f))
        drawRoundRect(Color(0xFFAB7155), Offset(x + 42f, 268f), Size(106f, 217f),
            CornerRadius(25f))
    } else {
        drawRect(Color(0xFF624D75), Offset(x + 22f, 241f), Size(165f, 344f))
        drawRoundRect(Color(0xFFA36C55), Offset(x + 5f, 178f), Size(65f, 413f),
            CornerRadius(28f))
    }
    drawCircle(Color(0xFFFFCB71), 10f, Offset(x + (if (open) 56f else 166f), 435f))
}

internal fun DrawScope.drawWindow(x: Float, night: Boolean, season: Int, tick: Int, camera: Float) {
    // Scene behind glass gets its own small offset; the frame stays anchored.
    val sky = when (season) {
        0 -> Color(0xFFC9EAF5) // spring
        1 -> Color(0xFF9BDEFC) // summer
        2 -> Color(0xFFD4DFEA) // autumn
        else -> Color(0xFFC2D8EA) // winter
    }
    val leaf = when (season) {
        0 -> Color(0xFF9DCB91)
        1 -> Color(0xFF68A95E)
        2 -> Color(0xFFD38A3F)
        else -> Color(0xFFE4F0F4)
    }
    val leafShadow = when (season) {
        0 -> Color(0xFF72B47B)
        1 -> Color(0xFF428351)
        2 -> Color(0xFFAA593D)
        else -> Color(0xFFB5CFD9)
    }
    val dx = camera - 550f
    val far = (dx * 0.07f).coerceIn(-37f, 37f)
    val middle = (dx * 0.16f).coerceIn(-80f, 80f)
    val near = (dx * 0.25f).coerceIn(-90f, 90f)
    drawRoundRect(Color(0xFF8B5A41), Offset(x - 11f, 120f), Size(342f, 325f),
        CornerRadius(14f))
    clipRect(left = x + 8f, top = 137f, right = x + 310f, bottom = 422f) {
        drawRect(sky, Offset(x + 8f, 137f), Size(302f, 285f))
        if (!night) drawCircle(
            if (season == 3) Color(0xFFFFF6DB) else Color(0xFFFFE79A),
            if (season == 3) 21f else 28f, Offset(x + 258f + far * 0.3f, 180f)
        )
        for (i in 0..3) {
            val px = x - 65f + i * 130f + far
            drawOval(Color.White.copy(alpha = .72f), Offset(px, 197f + (i % 2) * 12f), Size(90f, 20f))
            drawCircle(Color.White.copy(alpha = .72f), 17f, Offset(px + 30f, 197f + (i % 2) * 12f))
        }
        // The distant hills shift least, then trees, then the nearby fence.
        for (i in -2..6) {
            val xx = x + i * 118f + far
            drawOval(
                if (season == 3) Color(0xFFEAF5FA) else Color(0xFF92B9A1),
                Offset(xx - 78f, 274f + i % 3 * 7f), Size(210f, 95f)
            )
        }
        for (i in -2..5) {
            val xx = x + 36f + i * 118f + middle
            drawLine(Color(0xFF8E7869), Offset(xx, 318f), Offset(xx, 372f), 13f)
            drawCircle(leafShadow, 32f, Offset(xx - 9f, 285f))
            drawCircle(leaf, 42f, Offset(xx + 17f, 294f))
            if (season == 0) {
                for (j in 0..6) {
                    val bx = xx + ((j * 37) % 61) - 18f
                    val by = 271f + ((j * 19) % 38)
                    drawCircle(Color(0xFFF8BACA), 7f, Offset(bx, by))
                    drawCircle(Color(0xFFFFEDF2), 3f, Offset(bx + 2f, by - 2f))
                }
            } else if (season == 2) {
                for (j in 0..6) {
                    drawCircle(Color(0xFFFFD46D), 6f,
                        Offset(xx - 18f + ((j * 33) % 70), 267f + (j * 24) % 70))
                }
            } else if (season == 3) {
                for (j in 0..4) {
                    drawOval(Color.White, Offset(xx - 35f + j * 12f, 260f + (j % 2) * 12f), Size(33f, 12f))
                }
            }
        }
        val ground = when (season) {
            0 -> Color(0xFFA9D79D)
            1 -> Color(0xFF84C477)
            2 -> Color(0xFFCDA165)
            else -> Color(0xFFEBF5FA)
        }
        drawRect(ground, Offset(x + 8f, 341f), Size(302f, 81f))
        for (i in -3..12) {
            val fx = x + 15f + i * 39f + near
            drawRoundRect(Color(0xFFFDF2E6), Offset(fx, 320f), Size(9f, 74f), CornerRadius(5f))
        }
        drawRect(Color(0xFFFFF6EE), Offset(x - 150f, 345f), Size(650f, 7f))
        for (i in -3..6) {
            val px = x + i * 75f + near
            drawCircle(leaf, 24f, Offset(px + 15f, 374f))
            drawCircle(leafShadow, 17f, Offset(px + 32f, 383f))
            if (season == 0 || season == 1) {
                for (j in 0..2) drawCircle(
                    if (season == 0) Color(0xFFFFD2E1) else Color(0xFFFFDA7B),
                    6f, Offset(px + 6f + j * 13f, 370f + (j % 2) * 9f)
                )
            } else if (season == 2) {
                drawOval(Color(0xFFC67941), Offset(px + 12f, 394f), Size(36f, 8f))
            }
        }
        if (season == 3) {
            // A real winter yard: snowbanks, snowman, snowy trees and falling flakes.
            drawOval(Color.White, Offset(x - 130f + near, 391f), Size(260f, 72f))
            drawOval(Color(0xFFF5FCFF), Offset(x + 80f + near, 385f), Size(260f, 73f))
            val snowX = x + 87f + near * .24f
            drawCircle(Color(0xFFFDFEFF), 23f, Offset(snowX, 375f))
            drawCircle(Color.White, 16f, Offset(snowX, 343f))
            drawCircle(Color(0xFF343C4C), 2.6f, Offset(snowX - 6f, 339f))
            drawCircle(Color(0xFF343C4C), 2.6f, Offset(snowX + 6f, 339f))
            drawLine(Color(0xFFE3925C), Offset(snowX, 345f), Offset(snowX + 12f, 348f), 4f)
            drawLine(Color(0xFF9C5940), Offset(snowX - 17f, 364f), Offset(snowX - 32f, 354f), 3f)
            drawLine(Color(0xFF9C5940), Offset(snowX + 17f, 364f), Offset(snowX + 31f, 351f), 3f)
            drawRect(Color(0xFF935F80), Offset(snowX - 15f, 323f), Size(30f, 6f))
            drawRect(Color(0xFF935F80), Offset(snowX - 10f, 307f), Size(20f, 18f))
            for (i in 0..18) {
                val sx = x + 12f + ((i * 79) % 288)
                val sy = 142f + ((i * 47 + tick * 2) % 272)
                drawCircle(Color.White.copy(alpha = .92f), 3.2f, Offset(sx, sy))
            }
        }
    }
    // Frames and curtains draw last and never follow parallax offsets.
    drawRect(Color(0xFFA7745E), Offset(x + 153f, 130f), Size(13f, 300f))
    drawRect(Color(0xFFA7745E), Offset(x + 8f, 285f), Size(303f, 13f))
    drawRect(Color(0xFFD9AE97), Offset(x - 20f, 429f), Size(362f, 22f))
    drawRoundRect(Color(0xFFD19AAE), Offset(x - 34f, 108f), Size(63f, 260f), CornerRadius(18f))
    drawRoundRect(Color(0xFFD19AAE), Offset(x + 284f, 108f), Size(63f, 260f), CornerRadius(18f))
    drawLine(Color(0xFFF1C1D0), Offset(x - 18f, 120f), Offset(x - 2f, 350f), 5f)
    drawLine(Color(0xFFF1C1D0), Offset(x + 325f, 120f), Offset(x + 308f, 350f), 5f)
}

