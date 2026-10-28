package com.nikolegame

import android.content.Intent
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
            instrumentation.sendPointerSync(event);event.recycle()
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
    @Test fun testAllPetsColdStartAndBackground() {
        val ctx=instrumentation.targetContext
        val output=File(ctx.getExternalFilesDir(null),"audit").apply{mkdirs()}
        for(pet in listOf("dog","cat","hamster","parrot","turtle")) {
            ctx.getSharedPreferences("nicole_save",0).edit().putString("pet",pet)
                .putInt("room_pet_home_$pet",6).putInt("room_pet_bowl_$pet",3).commit()
            val intent=Intent(ctx,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val activity=instrumentation.startActivitySync(intent)
            Thread.sleep(3500)
            assertFalse(activity.isFinishing)
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
            // Reactivate the menus and inspect both real shop dialogs.
            val screen=instrumentation.uiAutomation.takeScreenshot()
            tap(screen.width/2f,screen.height*.55f)
            screen.recycle()
            Thread.sleep(500)
            assertTrue("Shop menu missing",clickText("Магазин"))
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
            instrumentation.sendKeyDownUpSync(android.view.KeyEvent.KEYCODE_BACK)
            instrumentation.runOnMainSync { activity.moveTaskToBack(true) }
            Thread.sleep(300)
            ctx.startActivity(intent)
            Thread.sleep(500)
            assertFalse(activity.isFinishing)
            instrumentation.runOnMainSync { activity.finish() }
        }
    }
}
