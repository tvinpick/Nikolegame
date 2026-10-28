package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import kotlin.math.abs
import kotlin.math.sin

/**
 * v0.12 — five completely redrawn, coordinated children's-book pets.
 * Geometry uses world-space feet as origin, so game movement and depth
 * sorting remain unchanged. All details are native Compose Canvas shapes.
 */
internal fun DrawScope.renderPet(
    type: String, x: Float, footY: Float, tick: Int, moving: Boolean,
    action: String = "", actionTick: Int = 0
) {
    drawPosedPet(type,x,footY,tick*.11f,tick/60f,1f,moving,action,actionTick/60f)
}
