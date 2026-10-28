package com.nikolegame

// Shared transition timing for all pet species. Smooth interpolation prevents
// an abrupt change from full-size roaming sprite to the smaller habitat sprite.
internal const val PET_HOME_TRANSITION_FRAMES = 48
internal const val PET_HOME_REST_FRAMES = 205

internal fun petHomeProgress(mode:String,elapsedFrames:Int):Float {
    val t=(elapsedFrames.toFloat()/PET_HOME_TRANSITION_FRAMES).coerceIn(0f,1f)
    val eased=t*t*(3f-2f*t)
    return when(mode){
        "enter"->eased
        "inside"->1f
        "exit"->1f-eased
        else->0f
    }
}
