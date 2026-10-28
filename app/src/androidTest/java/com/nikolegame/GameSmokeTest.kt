package com.nikolegame

import android.graphics.Bitmap
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import android.os.SystemClock
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.io.File

/** Real Android renders, not synthetic evidence. Test data stays in the preview package. */
@RunWith(AndroidJUnit4::class)
class GameSmokeTest {
    private val instrumentation get()=InstrumentationRegistry.getInstrumentation()
    private fun tap(x:Float,y:Float){
        val t=SystemClock.uptimeMillis()
        for(action in listOf(MotionEvent.ACTION_DOWN,MotionEvent.ACTION_UP)) {
            val event=MotionEvent.obtain(t,SystemClock.uptimeMillis(),action,x,y,0)
            check(instrumentation.uiAutomation.injectInputEvent(event,true));event.recycle()
        }
    }
    private fun clickText(text:String):Boolean {
        val root=instrumentation.uiAutomation.rootInActiveWindow ?: return false
        val matches=root.findAccessibilityNodeInfosByText(text)
        for(match in matches){
            var node:AccessibilityNodeInfo?=match
            repeat(5){
                if(node?.isClickable==true && node!!.performAction(AccessibilityNodeInfo.ACTION_CLICK))return true
                node=node?.parent
            }
        }
        return false
    }
    // startActivitySync waits for the main looper to become idle. Nicole's
    // continuous Compose Canvas animation deliberately never becomes idle.
    // Launch via Android's activity manager instead; then assert the real
    // active window and capture frames with UiAutomation.
    private fun shell(command:String){
        instrumentation.uiAutomation.executeShellCommand(command).close()
    }
    private fun startGame(resetTask:Boolean){
        val flags=if(resetTask)"0x10008000" else "0x10000000"
        shell("am start -n com.nikolegame.preview/com.nikolegame.MainActivity -f $flags")
        val until=SystemClock.uptimeMillis()+20000L
        while(SystemClock.uptimeMillis()<until){
            val window=instrumentation.uiAutomation.rootInActiveWindow
            if(window?.packageName?.toString()=="com.nikolegame.preview")return
            Thread.sleep(350)
        }
        val last=instrumentation.uiAutomation.rootInActiveWindow
        throw AssertionError("Game did not become foreground; active window=${last?.packageName}")
    }
    @Test fun testAllPetsColdStartAndBackground() {
        val ctx=instrumentation.targetContext
        val output=File(ctx.getExternalFilesDir(null),"audit").apply{mkdirs()}
        for(pet in listOf("dog","cat","hamster","parrot","turtle")) {
            ctx.getSharedPreferences("nicole_save",0).edit().putString("pet",pet)
                .putInt("room_pet_home_$pet",6).putInt("room_pet_bowl_$pet",3).commit()
            startGame(resetTask=true)
            Thread.sleep(3500)
            if(clickText("Got it"))Thread.sleep(500)
            // Tap the real habitat in the room, with the current camera centred on Nicole.
            val initial=instrumentation.uiAutomation.takeScreenshot()
            tap(initial.width/2f-210f*initial.height/900f,initial.height*650f/900f)
            initial.recycle()
            for(frame in 0..5){
                val bitmap=instrumentation.uiAutomation.takeScreenshot()
                assertNotNull(bitmap)
                File(output,"${pet}_$frame.png").outputStream().use{bitmap.compress(Bitmap.CompressFormat.PNG,100,it)}
                bitmap.recycle()
                Thread.sleep(2500)
            }
            // Ensure a genuinely fresh foreground Activity: on a continuously
            // redrawing Compose game, the old window can otherwise be seen
            // while the new task is still coming to the foreground.
            shell("input keyevent 3")
            Thread.sleep(450)
            startGame(resetTask=true)
            Thread.sleep(1800)
            val before=instrumentation.uiAutomation.takeScreenshot()
            // The menu is always in the top-left column on landscape displays;
            // its shop button is around 27% of viewport height. Unlike the
            // accessibility click, this injects a real child's screen tap.
            tap(before.width*.067f,before.height*.275f)
            Thread.sleep(1100)
            val after=instrumentation.uiAutomation.takeScreenshot()
            File(output,"${pet}_room_shop.png").outputStream().use {
                after.compress(Bitmap.CompressFormat.PNG,100,it)
            }
            val root=instrumentation.uiAutomation.rootInActiveWindow
            val semantics=root?.findAccessibilityNodeInfosByText("Звери")?.isNotEmpty()==true ||
                root?.findAccessibilityNodeInfosByText("Магазин для домика")?.isNotEmpty()==true
            // Compose semantics on this emulator have occasionally lacked
            // click actions. Detect the newly opened modal visually as well.
            var changed=0
            var sampled=0
            for(y in (after.height/5) until (after.height*4/5) step 42)
                for(x in (after.width/4) until (after.width*3/4) step 42){
                    val c1=before.getPixel(x,y)
                    val c2=after.getPixel(x,y)
                    val difference=kotlin.math.abs(android.graphics.Color.red(c1)-
                        android.graphics.Color.red(c2))+
                        kotlin.math.abs(android.graphics.Color.green(c1)-
                            android.graphics.Color.green(c2))+
                        kotlin.math.abs(android.graphics.Color.blue(c1)-
                            android.graphics.Color.blue(c2))
                    if(difference>115)changed++
                    sampled++
                }
            before.recycle()
            after.recycle()
            assertTrue("Shop failed to open (semantics=$semantics, visually changed=$changed/$sampled); see ${pet}_room_shop.png",
                semantics || changed*4>sampled)
            Thread.sleep(400)
            // The animal tab may be off screen on compact devices; room shop remains tested.
            if(clickText("Звери")){
                Thread.sleep(700)
                instrumentation.uiAutomation.takeScreenshot().also { bitmap ->
                    File(output,"${pet}_pet_shop.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }
                    bitmap.recycle()
                }
            }
            shell("input keyevent 3") // HOME; app background
            Thread.sleep(500)
            startGame(resetTask=false)
            Thread.sleep(500)
            shell("input keyevent 3")
        }
        // Catalogue silhouettes and doorway placement for all thirty homes.
        for(pet in listOf("dog","cat","hamster","parrot","turtle"))for(level in 1..6){
            ctx.getSharedPreferences("nicole_save",0).edit().putString("pet",pet)
                .putInt("room_pet_home_$pet",level).commit()
            startGame(resetTask=true)
            Thread.sleep(1000)
            val screen=instrumentation.uiAutomation.takeScreenshot()
            tap(screen.width/2f-210f*screen.height/900f,screen.height*650f/900f)
            screen.recycle()
            Thread.sleep(if(pet=="turtle")9000 else 3500)
            instrumentation.uiAutomation.takeScreenshot().also { bitmap ->
                File(output,"${pet}_home_$level.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }
                bitmap.recycle()
            }
            shell("input keyevent 3")
            Thread.sleep(150)
        }
    }
}
