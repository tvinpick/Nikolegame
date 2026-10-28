package com.nikolegame

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

// Big real-object pictures, category families, no reading required to navigate.
// The active item category belongs to saved state in MainActivity.
private data class ShopFamily(
    val ru:String,val de:String,val icon:String,val categories:List<String>
)
private val FAMILIES=listOf(
    ShopFamily("Мебель","Möbel","🛏️",listOf("bed","wardrobe","table","chair")),
    ShopFamily("Украшения","Deko","🖼️",listOf("rug","painting","ceiling","lamp")),
    ShopFamily("Ремонт","Renovieren","🎨",listOf("wall","floor")),
    ShopFamily("Техника","Technik","📺",listOf("tv","fridge"))
)
@Composable
internal fun RenovationShop(
    locale:String,
    coins:Int,
    freeTesting:Boolean,
    category:String,
    selections:Map<String,Int>,
    owned:Set<String>,
    onCategory:(String)->Unit,
    onPick:(RenovationItem)->Unit,
    onClose:()->Unit
) {
    val ru=locale=="ru"
    val ink=Color(0xFF735678)
    val pale=Color(0xFFFFF7F3)
    val family=FAMILIES.firstOrNull{category in it.categories}?:FAMILIES.first()
    val active=ROOM_CATEGORIES.firstOrNull{it.id==category}?:ROOM_CATEGORIES.first()
    Dialog(
        onDismissRequest=onClose,
        properties=DialogProperties(usePlatformDefaultWidth=false)
    ) {
        Column(
            Modifier.fillMaxWidth(.96f).fillMaxHeight(.94f)
                .clip(RoundedCornerShape(23.dp))
                .background(Brush.verticalGradient(
                    listOf(Color(0xFFFFF5EF),Color(0xFFFFFAF7),Color(0xFFF8EDF4))))
                .padding(horizontal=12.dp,vertical=8.dp),
            verticalArrangement=Arrangement.spacedBy(5.dp)
        ) {
            Row(
                Modifier.fillMaxWidth().height(35.dp),
                horizontalArrangement=Arrangement.SpaceBetween,
                verticalAlignment=Alignment.CenterVertically
            ){
                Column {
                    Text(if(ru)"🏡 Магазин для домика" else "🏡 Hausladen",
                        color=ink,fontSize=17.sp,fontWeight=FontWeight.Bold,
                        maxLines=1)
                    if(freeTesting) Text(if(ru)"🧪 Тест: все вещи бесплатно"
                        else "🧪 Test: alles kostenlos",
                        color=Color(0xFF488468),fontSize=10.sp,fontWeight=FontWeight.Bold)
                }
                Box(
                    Modifier.clip(RoundedCornerShape(18.dp))
                        .background(Color(0xFFFFE6B3))
                        .padding(horizontal=12.dp,vertical=5.dp)
                ) {
                    Text("🪙 $coins",fontSize=16.sp,
                        color=Color(0xFF83602D),fontWeight=FontWeight.Bold)
                }
                TextButton(onClick=onClose,contentPadding=PaddingValues(0.dp)) {
                    Text("✕",color=ink,fontSize=24.sp,fontWeight=FontWeight.Bold)
                }
            }
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement=Arrangement.spacedBy(7.dp)
            ){
                FAMILIES.forEach{group ->
                    val chosen=group==family
                    val shape=RoundedCornerShape(13.dp)
                    Row(
                        Modifier.weight(1f).height(43.dp).clip(shape)
                            .background(if(chosen)Color(0xFFE9D5EB)
                                else Color(0xFFF1E6E6))
                            .border(if(chosen)BorderStroke(2.dp,Color(0xFFAB85B6))
                                else BorderStroke(1.dp,Color(0xFFE8D4DD)),shape)
                            .clickable { if(!chosen)onCategory(group.categories.first()) },
                        verticalAlignment=Alignment.CenterVertically,
                        horizontalArrangement=Arrangement.Center
                    ){
                        Text(group.icon,fontSize=19.sp)
                        Spacer(Modifier.width(4.dp))
                        Text(if(ru)group.ru else group.de,fontSize=12.sp,
                            fontWeight=FontWeight.Bold,color=ink,maxLines=1)
                    }
                }
            }
            // Within the family the category thumbnails are real miniature
            // in-game models, not unclear chair/paintbrush emojis.
            Row(
                Modifier.fillMaxWidth().height(87.dp),
                horizontalArrangement=Arrangement.spacedBy(8.dp),
                verticalAlignment=Alignment.CenterVertically
            ) {
                family.categories.forEach { id ->
                    val model=ROOM_CATEGORIES.first{it.id==id}
                    val item=RENOVATION_ITEMS.first{it.category==id}
                    val selected=id==category
                    val shape=RoundedCornerShape(14.dp)
                    Column(
                        Modifier.weight(1f).fillMaxHeight().clip(shape)
                            .background(if(selected)Color(0xFFFFE5E6)
                                else Color.White.copy(alpha=.78f))
                            .border(if(selected)BorderStroke(2.dp,Color(0xFFCA9DAD))
                                else BorderStroke(1.dp,Color(0xFFECDDDD)),shape)
                            .clickable { if(!selected)onCategory(id) }
                            .padding(4.dp),
                        horizontalAlignment=Alignment.CenterHorizontally,
                        verticalArrangement=Arrangement.Center
                    ) {
                        RenovationThumbnail(item,Modifier.fillMaxWidth().height(54.dp))
                        Text(if(ru)model.ru else model.de,color=ink,
                            fontSize=11.sp,maxLines=1,fontWeight=FontWeight.Bold)
                    }
                }
            }
            Row(Modifier.fillMaxWidth(),
                verticalAlignment=Alignment.CenterVertically,
                horizontalArrangement=Arrangement.SpaceBetween
            ){
                Text((if(ru)active.ru else active.de),
                    color=ink,fontSize=15.sp,fontWeight=FontWeight.Bold)
                Text(if(ru)"Выбери картинку 👆" else "Bild wählen 👆",
                    color=Color(0xFFA18B9C),fontSize=11.sp)
            }
            Row(
                Modifier.fillMaxWidth().weight(1f)
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement=Arrangement.spacedBy(11.dp),
                verticalAlignment=Alignment.CenterVertically
            ) {
                RENOVATION_ITEMS.filter{it.category==category}.forEach { item ->
                    val selected=(selections[category]?:0)==item.style
                    val legacy=item.category in listOf("bed","wardrobe","table","chair")
                        && "furniture:${item.style}" in owned
                    val unlocked=item.price==0 || item.key in owned || legacy
                    val canSelect=!selected && (freeTesting || unlocked || coins>=item.price)
                    val shape=RoundedCornerShape(19.dp)
                    Column(
                        Modifier.width(183.dp).fillMaxHeight().clip(shape)
                            .background(if(selected)Color(0xFFE5F3E9)
                                else Color(0xFFFFFCFA))
                            .border(
                                if(selected)BorderStroke(3.dp,Color(0xFF91BBA2))
                                else BorderStroke(1.dp,Color(0xFFE8CBD7)),shape)
                            .clickable(enabled=canSelect){onPick(item)}
                            .padding(8.dp),
                        horizontalAlignment=Alignment.CenterHorizontally,
                        verticalArrangement=Arrangement.SpaceEvenly
                    ) {
                        RenovationThumbnail(item,
                            Modifier.fillMaxWidth().weight(1f))
                        Text(if(ru)item.nameRu else item.nameDe,
                            fontSize=12.sp,fontWeight=FontWeight.SemiBold,
                            color=ink,maxLines=2,textAlign=TextAlign.Center)
                        Text("🪙 ${item.price}",fontSize=12.sp,
                            color=Color(0xFF967142),fontWeight=FontWeight.Bold)
                        Box(
                            Modifier.clip(RoundedCornerShape(13.dp))
                                .background(if(selected)Color(0xFFBFDCC4)
                                    else if(unlocked)Color(0xFFF2DBE3)
                                    else Color(0xFFFFE6BD))
                                .padding(horizontal=10.dp,vertical=5.dp)
                        ){
                            Text(
                                when{
                                    selected->if(ru)"✓ Уже дома" else "✓ Im Haus"
                                    unlocked->if(ru)"✓ Поставить" else "✓ Aufstellen"
                                    freeTesting->if(ru)"🧪 Взять бесплатно" else "🧪 Kostenlos nehmen"
                                    else->if(ru)"Купить" else "Kaufen"
                                },
                                fontSize=12.sp,color=ink,
                                fontWeight=FontWeight.Bold
                            )
                        }
                    }
                }
            }
            Text(
                if(freeTesting) {
                    if(ru)"🧪 Бесплатные покупки только в тестовой версии • цены для сравнения"
                    else "🧪 Kostenlos nur in der Testversion • Preise zum Vergleich"
                } else if(ru)"✓ Купленные вещи остаются твоими • 🪙 Монеты в играх"
                else "✓ Gekaufte Dinge bleiben • 🪙 Münzen aus Spielen",
                modifier=Modifier.fillMaxWidth(),fontSize=10.sp,
                textAlign=TextAlign.Center,color=Color(0xFF987F90),maxLines=1
            )
        }
    }
}
