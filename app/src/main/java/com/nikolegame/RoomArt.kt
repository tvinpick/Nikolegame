package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import kotlin.math.sin

// v0.4: independent vector layers. The world uses the same 2700 x 900
// coordinates as v0.3, so no interaction, collision, window or parallax
// coordinates need to be changed when swapping the illustration.
private const val ROOM_W = 2700f
private val warmInk = Color(0xFF886D73)
private val woodShade = Color(0xFF765345)
private val cream = Color(0xFFFFF5EA)
private val blush = Color(0xFFE5B4C8)

internal fun DrawScope.renderRoomArt(
    night: Boolean,
    season: Int,
    tick: Int,
    leftDoorOpen: Boolean,
    rightDoorOpen: Boolean,
    camera: Float,
    wallStyle: Int,
    floorStyle: Int,
    furnitureStyle: Int,
    choices: Map<String, Int>
) {
    paintWallpaper()
    renderRenovatedWallpaper(wallStyle)
    paintFloor()
    renderRenovatedFloor(floorStyle)
    paintWallDecor(choices["painting"] ?: 0, choices["tv"] ?: 0)

    // Window scenes come from the separate season-and-parallax renderer.
    renderSeasonalWindow(500f, night, season, tick, camera, 0)
    renderSeasonalWindow(1850f, night, season, tick, camera, 1)
    decorateWindow(500f)
    decorateWindow(1850f)

    paintDoor(135f, leftDoorOpen)
    paintDoor(2370f, rightDoorOpen)
    paintRugsAndTrinkets(choices["rug"] ?: 0)
    val bedStyle = choices["bed"] ?: furnitureStyle
    val wardrobeStyle = choices["wardrobe"] ?: furnitureStyle
    val tableStyle = choices["table"] ?: furnitureStyle
    val chairStyle = choices["chair"] ?: furnitureStyle
    if(bedStyle == 0) paintOldBed() else drawSpecialBed(bedStyle)
    if(wardrobeStyle == 0) paintOldWardrobe() else drawSpecialWardrobe(wardrobeStyle)
    paintOldDesk(tableStyle, chairStyle, choices["lamp"] ?: 0)
    drawRoomTelevision(choices["tv"] ?: 0)
    drawCeilingLight(choices["ceiling"] ?: 0)

    // No painted "sunlight puddles" on the floor.
    // Night is a uniform scene tint without hard-edged elliptical spots.
    if (night) {
        drawRect(Color(0xFF30345B).copy(alpha = 0.26f), size = Size(ROOM_W, 900f))
    }
}

private fun DrawScope.paintWallpaper() {
    drawRect(
        brush = Brush.verticalGradient(
            colors = listOf(Color(0xFFF9EAEA), Color(0xFFF2DCE0), Color(0xFFE7D0DA)),
            startY = 0f, endY = 600f
        ),
        size = Size(ROOM_W, 600f)
    )
    // Pale vertical wallpaper panels: hand-painted rather than distressed.
    for (i in 0..24) {
        val x = i * 112f
        drawLine(Color(0xFFFFF4F2).copy(alpha = .68f),
            Offset(x + 22f, 43f), Offset(x + 22f, 558f), 2f)
        drawLine(Color(0xFFDABBC5).copy(alpha = .34f),
            Offset(x + 28f, 43f), Offset(x + 28f, 558f), 1.4f)
    }
    // Very subtle printed flowers on the old wallpaper.
    for (ix in 0..20) {
        for (iy in 0..4) {
            val fx = 95f + ix * 133f + if (iy % 2 == 0) 0f else 35f
            val fy = 106f + iy * 103f
            drawLine(Color(0xFFAAB69E).copy(alpha = .45f),
                Offset(fx, fy + 13f), Offset(fx + 5f, fy + 39f), 2.2f)
            for (petal in 0..3) {
                val ang = petal * 1.5708f
                val px = fx + kotlin.math.cos(ang) * 9f
                val py = fy + kotlin.math.sin(ang) * 9f
                drawCircle(Color(0xFFD7A5B7).copy(alpha = .46f),
                    6.3f, Offset(px, py))
            }
            drawCircle(Color(0xFFEDCA87).copy(alpha = .7f), 4.3f, Offset(fx, fy))
        }
    }

    // A few carefully placed faded wallpaper strips, not a ruined room.
    for (x in listOf(970f, 1360f, 2630f)) {
        drawRoundRect(Color(0xFFFFF3EB).copy(alpha = .22f),
            topLeft = Offset(x, 490f), size = Size(50f, 55f),
            cornerRadius = CornerRadius(16f))
    }

    // Cornice, picture rail and warm painted skirting.
    drawRect(Color(0xFFBDA7B6), Offset(0f, 25f), Size(ROOM_W, 22f))
    drawRect(Color(0xFFFFF7EE), Offset(0f, 37f), Size(ROOM_W, 12f))
    drawRect(Color(0xFFDFC4C8), Offset(0f, 52f), Size(ROOM_W, 5f))
    drawRect(Color(0xFFD3B2B8), Offset(0f, 568f), Size(ROOM_W, 9f))
    drawRect(Color(0xFFFFF2E5), Offset(0f, 574f), Size(ROOM_W, 22f))
    drawLine(Color(0xFFBA9094).copy(alpha = .6f),
        Offset(0f, 597f), Offset(ROOM_W, 597f), 3f)
}

private fun DrawScope.paintFloor() {
    drawRect(
        brush = Brush.verticalGradient(
            listOf(Color(0xFFC79576), Color(0xFFA9795D), Color(0xFF8F614D)),
            startY = 598f, endY = 900f
        ),
        topLeft = Offset(0f, 598f), size = Size(ROOM_W, 302f)
    )
    for (row in 0..11) {
        val y = 600f + row * 27f
        drawLine(Color(0xFF6E4D43).copy(alpha = .40f),
            Offset(0f, y), Offset(ROOM_W, y), 2.1f)
        drawLine(Color(0xFFFFD7AE).copy(alpha = .18f),
            Offset(0f, y + 3.5f), Offset(ROOM_W, y + 3.5f), 2.4f)
        for (col in 0..9) {
            val x = col * 315f + if (row % 2 == 0) 38f else 190f
            drawLine(Color(0xFF815B49).copy(alpha = .32f),
                Offset(x, y), Offset(x, y + 27f), 1.5f)
        }
    }
    // Old but well kept: tiny knots and delicate grain marks.
    for (i in 0..55) {
        val x = 45f + ((i * 189) % 2580)
        val y = 616f + ((i * 71) % 275)
        drawOval(Color(0xFF734E41).copy(alpha = .15f),
            Offset(x, y), Size(29f + (i % 4) * 4f, 3f))
    }
}

private fun DrawScope.paintWallDecor(paintingStyle: Int, televisionStyle: Int) {
    if(televisionStyle != 0) {
        drawCompactPaintings(paintingStyle)
    } else {
    // Old pictures are fully REMOVED when a different arrangement is selected.
    if(paintingStyle == 0) {
    for ((x, y) in listOf(1015f to 210f, 1194f to 248f, 1400f to 176f)) {
        drawRoundRect(Color(0xFF8D6A55).copy(alpha = .20f), Offset(x + 9f, y + 11f),
            Size(141f, 124f), CornerRadius(8f))
        drawRoundRect(Color(0xFFA77F64), Offset(x, y), Size(138f, 122f), CornerRadius(7f))
        drawRoundRect(Color(0xFFFFEBD7), Offset(x + 9f, y + 9f), Size(120f, 104f), CornerRadius(3f))
        drawRoundRect(Color(0xFFC9D9CB), Offset(x + 16f, y + 16f), Size(106f, 90f), CornerRadius(3f))
        val landscape = Path().apply {
            moveTo(x + 16f, y + 98f)
            quadraticBezierTo(x + 55f, y + 55f, x + 77f, y + 86f)
            quadraticBezierTo(x + 101f, y + 56f, x + 122f, y + 80f)
            lineTo(x + 122f, y + 106f)
            lineTo(x + 16f, y + 106f)
            close()
        }
        drawPath(landscape, Color(0xFF9CB89C))
        drawCircle(Color(0xFFF8E5AE), 12f, Offset(x + 92f, y + 44f))
    }
    } else {
        drawSpecialPaintings(paintingStyle)
    }
    }
    // A wall shelf and a friendly ceramic flower vase.
    drawRoundRect(Color(0xFFAF806E), Offset(1024f, 447f), Size(315f, 14f), CornerRadius(6f))
    drawRoundRect(Color(0xFFD0A4B2), Offset(1163f, 393f), Size(51f, 58f), CornerRadius(21f))
    for (i in 0..3) {
        val xx = 1185f + (i - 1) * 16f
        drawLine(Color(0xFF73966E), Offset(1186f, 404f), Offset(xx, 359f), 3f)
        drawCircle(if (i % 2 == 0) Color(0xFFEAB7CA) else Color(0xFFFFE1B4),
            11f, Offset(xx, 355f))
    }
    // Simple warm, old wall sconces.
    for (x in if (televisionStyle == 0) listOf(925f, 1468f) else listOf(925f)) {
        drawCircle(Color(0xFFC49C79), 16f, Offset(x, 330f))
        drawRoundRect(Color(0xFFF8DEBD), Offset(x - 31f, 301f),
            Size(62f, 35f), CornerRadius(14f))
        drawCircle(Color(0xFFFFE6C7).copy(alpha = .40f), 40f, Offset(x, 310f))
    }
}

private fun DrawScope.decorateWindow(x: Float) {
    // Soft trim around each original functional season window.
    drawLine(Color(0xFFFFF5EA), Offset(x - 16f, 109f), Offset(x + 327f, 109f), 8f)
    drawLine(Color(0xFFC49DA6), Offset(x - 12f, 120f), Offset(x + 324f, 120f), 3f)
    drawOval(Color(0xFFAC8274).copy(alpha = .17f), Offset(x - 21f, 437f), Size(368f, 12f))
    // Small curtain bow; does not hide the winter garden.
    for (side in listOf(x - 22f, x + 320f)) {
        drawCircle(Color(0xFFF7D7D9), 10f, Offset(side, 292f))
        drawLine(Color(0xFFD38EA9), Offset(side, 298f), Offset(side - 6f, 321f), 4f)
    }
}

private fun DrawScope.paintDoor(x: Float, open: Boolean) {
    // Muted arched doors; full walk-up clearance at the far ends.
    drawRoundRect(Color(0xFFAB8580).copy(alpha = .24f),
        Offset(x - 13f, 169f), Size(240f, 437f), CornerRadius(93f, 94f))
    drawRoundRect(Color(0xFFFFF3E9),
        Offset(x - 21f, 150f), Size(240f, 443f), CornerRadius(100f))
    drawRoundRect(Color(0xFFAC846C),
        Offset(x - 7f, 163f), Size(209f, 427f), CornerRadius(92f))
    if (!open) {
        drawRoundRect(brush = Brush.horizontalGradient(
                listOf(Color(0xFFD8AF8D), Color(0xFFB98469), Color(0xFFD0A087)),
                startX = x, endX = x + 197f),
            topLeft = Offset(x + 2f, 176f), size = Size(190f, 408f),
            cornerRadius = CornerRadius(85f))
        for (top in listOf(278f, 433f)) {
            drawRoundRect(Color(0xFF9E715F).copy(alpha = .63f),
                Offset(x + 32f, top), Size(126f, 123f), CornerRadius(16f))
            drawRoundRect(Color(0xFFE0BA96),
                Offset(x + 39f, top + 7f), Size(112f, 109f), CornerRadius(12f))
            drawLine(Color.White.copy(alpha = .25f),
                Offset(x + 46f, top + 14f), Offset(x + 143f, top + 14f), 3f)
        }
    } else {
        drawRect(Color(0xFF78637A), Offset(x + 10f, 243f), Size(182f, 338f))
        drawRoundRect(Brush.horizontalGradient(listOf(Color(0xFFD4A686), Color(0xFFAF755D))),
            Offset(x + 7f, 179f), Size(74f, 407f), CornerRadius(28f))
        drawRoundRect(Color(0xFFE5BC9C), Offset(x + 17f, 275f), Size(46f, 113f), CornerRadius(8f))
    }
    val knobX = x + (if (open) 61f else 164f)
    drawCircle(Color(0xFF8F6945), 11f, Offset(knobX, 445f))
    drawCircle(Color(0xFFFFE3A6), 7.7f, Offset(knobX, 442f))
    drawCircle(Color.White.copy(alpha = .68f), 2.3f, Offset(knobX - 2f, 439f))
}

private fun DrawScope.paintRugsAndTrinkets(style: Int) {
    if(style == 0) {
    // This rug is decorative floor paint: never creates invisible collision.
    drawOval(Color(0xFF704D45).copy(alpha = .15f), Offset(910f, 772f), Size(632f, 111f))
    drawOval(Color(0xFFDDAABE), Offset(904f, 757f), Size(630f, 119f))
    drawOval(Color(0xFFFFE9DE), Offset(943f, 772f), Size(556f, 91f))
    drawOval(Color(0xFFD0AEC8), Offset(990f, 784f), Size(457f, 72f))
    drawOval(Color(0xFFEAD5E3), Offset(1015f, 791f), Size(410f, 57f))
    for (i in 0..20) {
        val px = 941f + i * 26f
        drawLine(Color(0xFFE3A1BA), Offset(px, 814f), Offset(px - 7f, 824f), 2f)
    }
    } else drawSpecialRug(style)
    // A modest wooden toy box behind the rug.
    drawRoundRect(Color(0xFF86634F).copy(alpha = .24f),
        Offset(988f, 631f), Size(236f, 30f), CornerRadius(9f))
    drawRoundRect(Brush.verticalGradient(listOf(Color(0xFFE1BD9A), Color(0xFFC09279))),
        Offset(1011f, 557f), Size(209f, 91f), CornerRadius(10f))
    drawRoundRect(Color(0xFFA87662), Offset(1001f, 545f), Size(224f, 20f), CornerRadius(9f))
    drawCircle(Color(0xFFE8CC9D), 11f, Offset(1114f, 599f))
}

private fun DrawScope.paintOldBed() {
    // Clearly readable single bed, seen slightly from above.
    // An arched headboard on the left, mattress, separate pillow, quilt
    // and substantial footboard on the right form a familiar silhouette.
    // Keep all geometry inside the existing bed collision bounds.
    drawOval(Color(0xFF503A3B).copy(alpha = .22f),
        Offset(380f, 709f), Size(460f, 44f))

    // Back legs are visible beneath the bed body.
    for (px in listOf(404f, 787f)) {
        drawRoundRect(Color(0xFF8D6049), Offset(px, 640f), Size(25f, 100f),
            CornerRadius(8f))
        drawLine(Color(0xFFCF9F76).copy(alpha = .55f),
            Offset(px + 5f, 649f), Offset(px + 5f, 732f), 3f)
    }

    // A high curved wooden headboard gives the object a bed silhouette.
    val headboard = Path().apply {
        moveTo(391f, 645f)
        lineTo(391f, 478f)
        quadraticBezierTo(393f, 432f, 435f, 430f)
        quadraticBezierTo(492f, 435f, 497f, 483f)
        lineTo(497f, 650f)
        close()
    }
    drawPath(headboard, Brush.horizontalGradient(
        listOf(Color(0xFFA87659), Color(0xFFE3B28A), Color(0xFFAC785D)),
        startX = 386f, endX = 500f))
    drawPath(headboard, Color(0xFF805647), style = Stroke(6f))
    val inset = Path().apply {
        moveTo(411f, 615f)
        lineTo(411f, 489f)
        quadraticBezierTo(445f, 448f, 476f, 489f)
        lineTo(476f, 615f)
        close()
    }
    drawPath(inset, Color(0xFFF2CFAE).copy(alpha = .8f))
    drawPath(inset, Color(0xFF9F735D), style = Stroke(3f))
    drawCircle(Color(0xFFFFE5BC), 11f, Offset(444f, 449f))

    // Mattress and its white upholstered rim.
    drawRoundRect(Color(0xFF8A5C4E), Offset(454f, 570f),
        Size(357f, 118f), CornerRadius(18f))
    drawRoundRect(Brush.verticalGradient(
        listOf(Color(0xFFFFFAF3), Color(0xFFE9D9D3)),
        startY = 551f, endY = 668f),
        Offset(453f, 549f), Size(349f, 123f), CornerRadius(22f))
    drawLine(Color(0xFFE1C9C6), Offset(468f, 657f), Offset(778f, 657f), 4f)

    // Distinct pillow near the HEAD of the bed.
    drawRoundRect(Color(0xFFD0B0B9).copy(alpha = .42f),
        Offset(464f, 554f), Size(113f, 65f), CornerRadius(24f))
    drawRoundRect(Brush.verticalGradient(
        listOf(Color.White, Color(0xFFFFE9E6)),
        startY = 546f, endY = 606f),
        Offset(459f, 540f), Size(112f, 65f), CornerRadius(24f))
    drawLine(Color(0xFFE3C8CD), Offset(470f, 582f), Offset(553f, 582f), 2.4f)

    // Pink duvet lies OVER the mattress; a folded corner makes it legible.
    drawRoundRect(Color(0xFFE7B6CA), Offset(567f, 548f),
        Size(232f, 115f), CornerRadius(20f))
    drawRoundRect(Brush.verticalGradient(
        listOf(Color(0xFFF4D6DE), Color(0xFFC78CAA)),
        startY = 578f, endY = 680f),
        Offset(560f, 581f), Size(238f, 94f), CornerRadius(15f))
    drawRoundRect(Color(0xFFFFE9E7), Offset(559f, 574f),
        Size(239f, 23f), CornerRadius(8f))
    drawLine(Color(0xFFB47A99).copy(alpha = .6f),
        Offset(565f, 603f), Offset(787f, 603f), 2f)
    for (i in 0..4) {
        val cx = 605f + i * 37f
        drawCircle(Color(0xFFFFF0E5), 6f, Offset(cx, 627f))
        drawCircle(Color(0xFFE3A5B4), 2f, Offset(cx, 628f))
    }

    // A low but unmistakable wooden FOOTBOARD on the far end.
    drawRoundRect(Brush.horizontalGradient(
        listOf(Color(0xFFA06F54), Color(0xFFDCAD84), Color(0xFFA27155)),
        startX = 770f, endX = 824f),
        Offset(777f, 539f), Size(53f, 142f), CornerRadius(14f))
    drawRoundRect(Color(0xFFEBCAA8), Offset(787f, 558f),
        Size(27f, 98f), CornerRadius(8f))
    drawRoundRect(Color(0xFF9B6D56), Offset(778f, 648f),
        Size(24f, 95f), CornerRadius(8f))
    drawCircle(Color(0xFFF0CBA7), 13f, Offset(804f, 539f))
}

private fun DrawScope.paintOldWardrobe() {
    drawOval(Color(0xFF583C3A).copy(alpha = .20f), Offset(1550f, 619f), Size(285f, 43f))
    drawRoundRect(Brush.horizontalGradient(listOf(Color(0xFFCFAB95), Color(0xFFFFEBDB), Color(0xFFCBA18A))),
        Offset(1544f, 289f), Size(291f, 346f), CornerRadius(23f))
    drawRoundRect(Color(0xFFAD7F71), Offset(1558f, 306f), Size(264f, 299f), CornerRadius(12f))
    for (i in 0..1) {
        val xx = 1567f + i * 130f
        drawRoundRect(Brush.verticalGradient(listOf(Color(0xFFEBD8C8), Color(0xFFD4B19E))),
            Offset(xx, 318f), Size(121f, 276f), CornerRadius(10f))
        for (top in listOf(352f, 490f)) {
            drawRoundRect(Color(0xFFB58C7D).copy(alpha = .68f),
                Offset(xx + 13f, top), Size(94f, 100f), CornerRadius(10f))
            drawRoundRect(Color(0xFFEBD8C8), Offset(xx + 19f, top + 5f),
                Size(82f, 90f), CornerRadius(9f))
        }
        drawLine(Color(0xFFFFF4E9).copy(alpha = .63f),
            Offset(xx + 5f, 322f), Offset(xx + 5f, 585f), 3f)
    }
    drawCircle(Color(0xFF8C6354), 9f, Offset(1680f, 453f))
    drawCircle(Color(0xFF8C6354), 9f, Offset(1704f, 453f))
    drawCircle(Color(0xFFE8C58D), 5.5f, Offset(1680f, 450f))
    drawCircle(Color(0xFFE8C58D), 5.5f, Offset(1704f, 450f))
    drawRoundRect(Color(0xFFB48970), Offset(1575f, 624f), Size(35f, 25f), CornerRadius(5f))
    drawRoundRect(Color(0xFFB48970), Offset(1765f, 624f), Size(35f, 25f), CornerRadius(5f))
}

private fun DrawScope.paintOldDesk(tableStyle: Int, chairStyle: Int, lampStyle: Int) {
    if (tableStyle == 0) {
    drawOval(Color(0xFF634139).copy(alpha = .23f), Offset(1903f, 680f), Size(422f, 47f))
    drawRoundRect(Brush.verticalGradient(listOf(Color(0xFFE4C2A8), Color(0xFFC79C80))),
        Offset(1909f, 454f), Size(400f, 58f), CornerRadius(10f))
    drawLine(Color(0xFFFFE2CC).copy(alpha = .75f),
        Offset(1920f, 467f), Offset(2294f, 467f), 4f)
    drawRoundRect(Color(0xFFA47660), Offset(1922f, 510f), Size(368f, 11f), CornerRadius(4f))
    for (xx in listOf(1932f, 2261f)) {
        drawRoundRect(Brush.horizontalGradient(listOf(Color(0xFFCA9B7B), Color(0xFF9A7059))),
            Offset(xx, 515f), Size(20f, 188f), CornerRadius(5f))
    }
    drawRoundRect(Color(0xFFCAA188), Offset(2018f, 516f), Size(137f, 50f), CornerRadius(9f))
    drawRoundRect(Color(0xFFEBC8AB), Offset(2025f, 518f), Size(123f, 37f), CornerRadius(7f))
    drawCircle(Color(0xFFAA7D5F), 6f, Offset(2086f, 542f))
    } else drawSpecialTable(tableStyle)
    if(chairStyle == 0) {
    // Full-sized child's chair: taller back, broader seat, thicker legs,
    // aligned with the desk height (not a tiny toy chair).
    drawOval(Color(0xFF6F4941).copy(alpha = .18f),
        Offset(2034f, 721f), Size(183f, 32f))
    drawRoundRect(Brush.horizontalGradient(
        listOf(Color(0xFFDCB79B), Color(0xFFB9846B), Color(0xFFDBB69D))),
        Offset(2074f, 486f), Size(112f, 167f), CornerRadius(32f))
    drawRoundRect(Color(0xFFEED3BD), Offset(2085f, 501f),
        Size(90f, 131f), CornerRadius(27f))
    // Cushioned seat sits visibly beneath the desktop.
    drawRoundRect(Color(0xFF9D6E5E),
        Offset(2044f, 607f), Size(167f, 32f), CornerRadius(10f))
    drawRoundRect(Color(0xFFD1A0A8),
        Offset(2048f, 600f), Size(159f, 30f), CornerRadius(11f))
    drawLine(Color(0xFFF6DBCB).copy(alpha = .76f),
        Offset(2059f, 609f), Offset(2196f, 609f), 3f)
    for (xx in listOf(2061f, 2183f)) {
        drawRoundRect(Color(0xFFAA7961),
            Offset(xx, 631f), Size(20f, 105f), CornerRadius(6f))
        drawLine(Color(0xFFE3B595).copy(alpha = .68f),
            Offset(xx + 5f, 648f), Offset(xx + 5f, 728f), 2.5f)
    }
    } else drawSpecialChair(chairStyle)
    // Books and paper stay on the desktop; the lamp is its own object.
    drawRoundRect(Color(0xFFF3E5D5), Offset(1986f, 436f), Size(87f, 16f), CornerRadius(3f))
    drawLine(Color(0xFFBE94B0), Offset(1991f, 443f), Offset(2068f, 443f), 3f)
    drawRoundRect(Color(0xFFB2BDC1), Offset(2084f, 432f), Size(66f, 19f), CornerRadius(4f))
    drawDeskLight(lampStyle)
    // Shallow soft book shelf above table.
    drawRoundRect(Color(0xFFAD8269), Offset(1945f, 326f), Size(261f, 13f), CornerRadius(5f))
    for (i in 0..6) {
        val xx = 1971f + i * 30f
        drawRoundRect(if (i % 2 == 0) Color(0xFFC4A6BC) else Color(0xFFADC7B1),
            Offset(xx, 281f - (i % 3) * 5f), Size(24f, 44f + (i % 3) * 5f),
            CornerRadius(3f))
    }
}
