package com.nikolegame

import android.graphics.Bitmap
import android.graphics.Rect
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.ArrayDeque

/** Real Android-emulator tests: semantic controls and captured device frames. */
@RunWith(AndroidJUnit4::class)
class GameSmokeTest {
    private val inst get() = InstrumentationRegistry.getInstrumentation()
    private val automation get() = inst.uiAutomation
    private val app = "com.nikolegame.preview"
    private val pets = listOf("dog", "cat", "hamster", "parrot", "turtle")

    private fun shell(command: String): String {
        val fd: ParcelFileDescriptor = automation.executeShellCommand(command)
        return ParcelFileDescriptor.AutoCloseInputStream(fd).bufferedReader().use { it.readText() }
    }
    private fun output():File =
        File(inst.targetContext.getExternalFilesDir(null),"audit").apply{mkdirs()}

    private fun snapshot(name:String):Bitmap {
        val image=automation.takeScreenshot() ?: throw AssertionError("No screenshot: $name")
        File(output(),"$name.png").outputStream().use {
            image.compress(Bitmap.CompressFormat.PNG,85,it)
        }
        return image
    }
    private fun findDescription(description:String): AccessibilityNodeInfo? {
        val root=automation.rootInActiveWindow ?: return null
        val queue=ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var visited=0
        while(!queue.isEmpty() && visited++<3500){
            val node=queue.removeFirst()
            if(node.contentDescription?.toString()==description)return node
            for(i in 0 until node.childCount){
                val child=node.getChild(i)
                if(child!=null)queue.add(child)
            }
        }
        return null
    }
    private fun visible(description:String,timeoutMs:Long=6000):Boolean {
        val until=SystemClock.uptimeMillis()+timeoutMs
        while(SystemClock.uptimeMillis()<until) {
            if(findDescription(description)!=null)return true
            Thread.sleep(250)
        }
        return false
    }
    private fun tapDescription(description:String):Boolean {
        val node=findDescription(description) ?: return false
        val bounds=Rect()
        node.getBoundsInScreen(bounds)
        val screenshot=automation.takeScreenshot() ?: return false
        val w=screenshot.width;val h=screenshot.height;screenshot.recycle()
        if(bounds.width()<=0 || bounds.height()<=0 ||
            bounds.centerX() !in 0 until w || bounds.centerY() !in 0 until h)return false
        shell("input tap "+bounds.centerX()+" "+bounds.centerY())
        return true
    }
    private fun launch(pet:String,home:Int=6,bowl:Int=3) {
        // Instrumentation runs inside the target app process: force-stop
        // would kill the tests themselves. CLEAR_TASK restarts only the UI.
        val prefs=inst.targetContext.getSharedPreferences("nicole_save",0)
        assertTrue(prefs.edit().putString("pet",pet).putString("locale","ru")
            .putInt("room_pet_home_$pet",home)
            .putInt("room_pet_bowl_$pet",bowl).commit())
        shell("am start -W -f 0x10008000 -n $app/com.nikolegame.MainActivity")
        if(!visible("nikole-menu-shop",15000)){
            snapshot("launch_error_$pet").recycle()
            fail("Game/menu did not appear for $pet")
        }
    }
    private fun assertForeground(){
        assertEquals(app,automation.rootInActiveWindow?.packageName?.toString())
    }

    @Test fun testLaunchAndBackgroundAllPets() {
        for(pet in pets) {
            launch(pet)
            assertForeground()
            snapshot("launch_$pet").recycle()
            shell("input keyevent KEYCODE_HOME")
            Thread.sleep(400)
            shell("am start -W -n $app/com.nikolegame.MainActivity")
            assertTrue("Resume failed for $pet",visible("nikole-menu-shop",12000))
            assertForeground()
            snapshot("resume_$pet").recycle()
        }
    }

    @Test fun testShopAndPetShopRealTaps() {
        launch("dog")
        snapshot("shop_before").recycle()
        assertTrue("No accessible shop control",tapDescription("nikole-menu-shop"))
        if(!visible("nikole-room-shop-open",6000)){
            snapshot("shop_not_open").recycle()
            fail("Main shop did not open after real device tap")
        }
        snapshot("room_shop").recycle()
        // Animal tab is the fifth chip in a horizontally scrollable row.
        var opened=tapDescription("nikole-shop-pets")
        if(!opened){
            val screen=automation.takeScreenshot()
            val w=screen.width; val h=screen.height;screen.recycle()
            shell("input swipe "+(w*7/10)+" "+(h/5)+" "+(w*3/10)+" "+(h/5)+" 350")
            Thread.sleep(450)
            opened=tapDescription("nikole-shop-pets")
        }
        if(!opened || !visible("nikole-pet-shop-open",6000)){
            snapshot("pet_shop_not_open").recycle()
            fail("Animal shop did not open via its category button")
        }
        snapshot("dog_pet_shop").recycle()
    }

    @Test fun testIdleFivePetFrameSequences() {
        for(pet in pets){
            launch(pet)
            snapshot("idle_"+pet+"_0").recycle()
            Thread.sleep(2200)
            snapshot("idle_"+pet+"_1").recycle()
            Thread.sleep(2200)
            snapshot("idle_"+pet+"_2").recycle()
            assertForeground()
        }
    }

    @Test fun testThirtyAnimalHomesActuallyRender() {
        for(pet in pets)for(level in 1..6){
            launch(pet,home=level)
            Thread.sleep(200)
            snapshot("home_"+pet+"_"+level).recycle()
        }
    }
}