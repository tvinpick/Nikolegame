package com.nikolegame

import android.content.Intent
import android.graphics.Bitmap
import android.test.InstrumentationTestCase
import java.io.File

/** Real Android renders, not synthetic evidence. Test data stays in the preview package. */
@Suppress("DEPRECATION")
class GameSmokeTest: InstrumentationTestCase() {
    fun testAllPetsColdStartAndBackground() {
        val ctx=instrumentation.targetContext
        val output=File(ctx.getExternalFilesDir(null),"audit").apply{mkdirs()}
        for(pet in listOf("dog","cat","hamster","parrot","turtle")) {
            ctx.getSharedPreferences("nicole_save",0).edit().putString("pet",pet)
                .putInt("room_pet_home_$pet",6).putInt("room_pet_bowl_$pet",3).commit()
            val intent=Intent(ctx,MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val activity=instrumentation.startActivitySync(intent)
            Thread.sleep(3500)
            assertFalse(activity.isFinishing)
            for(frame in 0..3){
                val bitmap=instrumentation.uiAutomation.takeScreenshot()
                assertNotNull(bitmap)
                File(output,"${pet}_$frame.png").outputStream().use{bitmap.compress(Bitmap.CompressFormat.PNG,100,it)}
                Thread.sleep(2500)
            }
            instrumentation.runOnMainSync { activity.moveTaskToBack(true) }
            Thread.sleep(300)
            ctx.startActivity(intent)
            Thread.sleep(500)
            assertFalse(activity.isFinishing)
            instrumentation.runOnMainSync { activity.finish() }
        }
    }
}
