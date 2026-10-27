package com.nikolegame

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalDensity
import kotlin.math.roundToInt
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

// Wide image-led gallery sized for a six-year-old: big touch targets,
// few words, price/ownership visually obvious. Last tab is controlled by parent.
@Composable
internal fun RenovationShop(
    locale:String,
    coins:Int,
    category:String,
    selections:Map<String,Int>,
    owned:Set<String>,
    onCategory:(String)->Unit,
    onPick:(RenovationItem)->Unit,
    onClose:()->Unit
) {
    val ru=locale=="ru"
    val accent=Color(0xFF795A90)
    val tabsScroll=rememberScrollState()
    val density=LocalDensity.current.density
    LaunchedEffect(category) {
        val index=ROOM_CATEGORIES.indexOfFirst{it.id==category}.coerceAtLeast(0)
        tabsScroll.animateScrollTo((index*89*density).roundToInt())
    }
    val active=ROOM_CATEGORIES.firstOrNull{it.id==category}?:ROOM_CATEGORIES.first()
    Dialog(onDismissRequest=onClose,
        properties=DialogProperties(usePlatformDefaultWidth=false)
    ) {
        Column(
            Modifier.fillMaxWidth(.94f).fillMaxHeight(.90f)
                .clip(RoundedCornerShape(25.dp))
                .background(Color(0xFFFFF8F5))
                .padding(horizontal=15.dp,vertical=9.dp),
            verticalArrangement=Arrangement.spacedBy(7.dp)
        ) {
            Row(Modifier.fillMaxWidth(),
                verticalAlignment=Alignment.CenterVertically,
                horizontalArrangement=Arrangement.SpaceBetween) {
                Text(if(ru)"🏡 Украшаем домик" else "🏡 Haus dekorieren",
                    color=accent, fontSize=19.sp,fontWeight=FontWeight.Bold)
                Text("🪙 $coins",color=accent,fontSize=18.sp,fontWeight=FontWeight.Bold)
                TextButton(onClick=onClose) {
                    Text("✕",fontSize=23.sp,color=accent,fontWeight=FontWeight.Bold)
                }
            }
            // The scrollable carousel remembers the exact category, including
            // after exit, re-opening and restarting the app.
            Row(
                Modifier.fillMaxWidth().horizontalScroll(tabsScroll),
                horizontalArrangement=Arrangement.spacedBy(7.dp)
            ) {
                ROOM_CATEGORIES.forEach{tab->
                    val isActive=tab.id==category
                    Column(
                        Modifier.width(82.dp)
                            .clip(RoundedCornerShape(15.dp))
                            .background(if(isActive) Color(0xFFE6CCE6)
                                else Color(0xFFF4EBE9))
                            .clickable { onCategory(tab.id) }
                            .padding(vertical=6.dp,horizontal=2.dp),
                        horizontalAlignment=Alignment.CenterHorizontally
                    ) {
                        Text(tab.emoji,fontSize=27.sp)
                        Text(if(ru)tab.ru else tab.de,
                            fontSize=11.sp,fontWeight=FontWeight.SemiBold,
                            color=accent,maxLines=1,textAlign=TextAlign.Center)
                    }
                }
            }
            Text(active.emoji+"  "+if(ru) active.ru else active.de,
                color=accent,fontSize=17.sp,fontWeight=FontWeight.Bold)
            Row(
                Modifier.fillMaxWidth().weight(1f)
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement=Arrangement.spacedBy(12.dp),
                verticalAlignment=Alignment.CenterVertically
            ) {
                RENOVATION_ITEMS.filter { it.category==category }.forEach{item->
                    val selected=(selections[category]?:0)==item.style
                    val legacy=item.category in listOf("bed","wardrobe","table","chair")
                        && "furniture:${item.style}" in owned
                    val unlocked=item.price==0 || item.key in owned || legacy
                    val canClick=!selected && (unlocked || coins>=item.price)
                    Column(
                        Modifier.width(175.dp).fillMaxHeight()
                            .clip(RoundedCornerShape(20.dp))
                            .background(if(selected) Color(0xFFE4F2E7)
                                else if(unlocked) Color(0xFFF9E9E6)
                                else Color(0xFFF0E9F3))
                            .clickable(enabled=canClick){ onPick(item) }
                            .padding(horizontal=9.dp,vertical=8.dp),
                        horizontalAlignment=Alignment.CenterHorizontally,
                        verticalArrangement=Arrangement.SpaceEvenly
                    ) {
                        // A recognizable, large visual anchor is usable
                        // before the child is fluent at reading.
                        Text(item.icon,fontSize=52.sp,textAlign=TextAlign.Center)
                        Text(if(ru)item.nameRu else item.nameDe,
                            fontSize=13.sp,fontWeight=FontWeight.Bold,
                            color=Color(0xFF654D68),textAlign=TextAlign.Center,
                            maxLines=2)
                        Box(
                            Modifier.clip(RoundedCornerShape(17.dp))
                                .background(if(selected) Color(0xFFB6D6B9)
                                    else if(unlocked) Color(0xFFE6CCD9)
                                    else Color(0xFFE4D8EC))
                                .padding(horizontal=12.dp,vertical=7.dp)
                        ) {
                            Text(when {
                                selected->if(ru)"✓ Стоит" else "✓ Im Haus"
                                unlocked->if(ru)"✓ Моё" else "✓ Meins"
                                else->"🪙 ${item.price}"
                            },fontSize=14.sp,color=Color(0xFF59436C),
                                fontWeight=FontWeight.Bold)
                        }
                    }
                }
            }
            Text(if(ru)"👆 Нажми на картинку, чтобы поставить предмет. " +
                "🔒 Купленные вещи остаются твоими."
            else "👆 Bild antippen zum Aufstellen. " +
                "🔒 Gekaufte Dinge bleiben dir.",
                fontSize=11.sp,color=Color(0xFF846F82),
                textAlign=TextAlign.Center,modifier=Modifier.fillMaxWidth(),
                maxLines=2)
        }
    }
}
