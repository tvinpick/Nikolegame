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
            // Menu auto-hides after ten seconds of idle pet observation.
            // Reopen the real game to give the shop its normal visible state
            // instead of trying to click an intentionally hidden button.
            startGame(resetTask=true)
            Thread.sleep(900)
            var opened=clickText("Магазин")
            if(!opened){
                // Fallback for Compose canvas semantics on the emulator:
                // the shop is the left-column top button in landscape.
                val screen=instrumentation.uiAutomation.takeScreenshot()
                tap(screen.width*.07f,screen.height*.235f)
                screen.recycle()
                Thread.sleep(600)
                opened=clickText("Звери") || clickText("🏡 Магазин для домика")
                // The tab probe may enter the animal shop; leave it as a
                // legitimate successful shop open instead of clicking twice.
            }
            assertTrue("Shop did not open after a fresh game launch",opened)
            Thread.sleep(700)
            instrumentation.uiAutomation.takeScreenshot().also { bitmap ->
                File(output,"${pet}_room_shop.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG,100,it) }
                bitmap.recycle()
            }
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
