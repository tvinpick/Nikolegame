package com.nikolegame

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlin.math.min

/** A section of the ordinary shop. Every species has two independent slots. */
@Composable
internal fun PetShop(
    locale:String, activePet:String, coins:Int, freeTesting:Boolean,
    selections:Map<String,Int>, owned:Set<String>, feedback:String?,
    onPick:(RenovationItem)->Unit, onClose:()->Unit, onBack:()->Unit,
    onChoosePet:()->Unit, initialKind:String="home"
){
    val ru=locale=="ru"
    // The shop is LOCKED to the currently adopted animal. Other species'
    // purchases persist but their items never appear in this shop.
    val species=activePet
    var kind by remember(initialKind) { mutableStateOf(initialKind) }
    val ink=Color(0xFF493A51)
    val cards=petShopItems(species,kind)
    Dialog(onDismissRequest=onClose,
        properties=DialogProperties(usePlatformDefaultWidth=false)
    ){
        Column(
            Modifier.fillMaxWidth(.97f).fillMaxHeight(.94f).semantics { contentDescription="nikole-pet-shop-open" }
                .clip(RoundedCornerShape(22.dp))
                .background(Color(0xFFFFF8F4))
                .padding(horizontal=11.dp,vertical=7.dp),
            verticalArrangement=Arrangement.spacedBy(5.dp)
        ){
            Row(Modifier.fillMaxWidth().height(48.dp),
                verticalAlignment=Alignment.CenterVertically,
                horizontalArrangement=Arrangement.SpaceBetween){
                TextButton(onClick=onBack,contentPadding=PaddingValues(0.dp)){
                    Text("‹ "+if(ru)"Магазин" else "Laden",fontSize=13.sp,color=ink)
                }
                Text(if(species in PET_SPECIES)
                    petSpeciesIcon(species)+" "+petSpeciesName(species,ru)
                    else if(ru)"🐾 Выбери питомца" else "🐾 Tier wählen",
                    fontSize=16.sp,fontWeight=FontWeight.Bold,color=ink)
                TextButton(onClick=onClose,contentPadding=PaddingValues(0.dp)){
                    Text("✕",fontSize=22.sp,color=ink)
                }
            }
            if(species !in PET_SPECIES){
                Button(
                    onClick=onChoosePet,
                    modifier=Modifier.fillMaxWidth().height(48.dp),
                    colors=ButtonDefaults.buttonColors(
                        containerColor=Color(0xFFEAD8EB),contentColor=ink)
                ){
                    Text(if(ru)"🐾 Сначала выбери питомца"
                        else "🐾 Wähle zuerst ein Tier",
                        fontWeight=FontWeight.Bold)
                }
            } else {
                Text(
                    if(ru)"В магазине только товары для: "+petSpeciesName(species,true)
                    else "Nur Zubehör für: "+petSpeciesName(species,false),
                    color=ink,fontWeight=FontWeight.Bold,fontSize=12.sp,
                    modifier=Modifier.fillMaxWidth()
                )
            }
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.spacedBy(8.dp)){
                for(slot in listOf("home","bowl")){
                    val sel=kind==slot
                    val label=if(slot=="home"){
                        if(ru)"🏠 Домики и лежанки" else "🏠 Häuser und Betten"
                    }else{if(ru)"🥣 Миски с кормом" else "🥣 Futternäpfe"}
                    Text((if(sel)"✓ " else "")+label,Modifier.weight(1f)
                        .heightIn(min=48.dp).clip(RoundedCornerShape(12.dp))
                        .background(if(slot=="home")Color(0xFFFFD9AB) else Color(0xFFD0EAF7))
                        .border(if(sel)2.dp else 0.dp,ink,RoundedCornerShape(12.dp))
                        .clickable{kind=slot}
                        .padding(vertical=9.dp,horizontal=3.dp),
                        textAlign=TextAlign.Center,color=ink,fontSize=12.sp,
                        fontWeight=FontWeight.Bold,maxLines=1)
                }
            }
            Text(
                feedback ?: if(species !in PET_SPECIES){
                    if(ru)"Сначала посели питомца в домике 🐾"
                    else "Wähle zuerst ein Tier 🐾"
                } else if(ru)"🪙 $coins  •  Листай товары →"
                  else "🪙 $coins  •  Weitere Artikel →",
                color=if(feedback!=null)Color(0xFF408262) else Color(0xFF927A91),
                fontSize=11.sp,maxLines=1
            )
            Row(
                Modifier.fillMaxWidth().weight(1f)
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement=Arrangement.spacedBy(8.dp),
                verticalAlignment=Alignment.CenterVertically
            ){
                cards.forEach { item ->
                    val selected=selections[item.category]==item.style ||
                        (selections[item.category]==null && item.style==0)
                    val unlocked=item.price==0 || item.key in owned
                    Column(
                        Modifier.width(173.dp).fillMaxHeight()
                            .clip(RoundedCornerShape(16.dp))
                            .background(if(selected)Color(0xFFE7F4E7)
                                else Color.White)
                            .border(if(selected)2.dp else 1.dp,
                                if(selected)Color(0xFF7EB08B) else Color(0xFFE9CBD8),
                                RoundedCornerShape(16.dp))
                            .padding(7.dp),
                        verticalArrangement=Arrangement.SpaceEvenly,
                        horizontalAlignment=Alignment.CenterHorizontally
                    ){
                        Canvas(Modifier.fillMaxWidth().weight(1f)){
                            if(item.style==0){
                                drawCircle(Color(0xFFF1EAE8),
                                    min(size.width,size.height)*.30f,
                                    Offset(size.width/2f,size.height/2f))
                                drawLine(Color(0xFFBCABB5),Offset(size.width*.33f,size.height*.67f),
                                    Offset(size.width*.67f,size.height*.33f),5f)
                            }else{
                                val home=kind=="home"
                                val factor=min(size.width/(if(home)310f else 156f),
                                    size.height/(if(home)205f else 95f))*.9f
                                withTransform({
                                    translate(size.width*.5f,size.height*.50f)
                                    scale(factor,factor,Offset.Zero)
                                    translate(if(home)-1145f else -1406f,
                                        if(home)-648f else -770f)
                                }){
                                    if(home)renderPetHabitat(species,item.style)
                                    else renderPetBowl(species,item.style)
                                }
                            }
                        }
                        Text(if(ru)item.nameRu else item.nameDe,
                            fontSize=12.sp,fontWeight=FontWeight.Bold,
                            textAlign=TextAlign.Center,color=ink,maxLines=2)
                        Text("🪙 ${item.price}",fontSize=11.sp,color=Color(0xFF8C7959))
                        Button(onClick={onPick(item)},
                            enabled=freeTesting || unlocked || coins>=item.price,
                            modifier=Modifier.fillMaxWidth().height(48.dp),
                            shape=RoundedCornerShape(11.dp),
                            contentPadding=PaddingValues(horizontal=3.dp,vertical=0.dp),
                            colors=ButtonDefaults.buttonColors(
                                containerColor=if(selected)Color(0xFFC6E5CF)
                                    else if(unlocked)Color(0xFFCDE4FF) else Color(0xFFFFE4A1),contentColor=ink)
                        ){
                            Text(if(selected) {
                                if(ru)"✓ Установлено" else "✓ Aufgestellt"
                            }else if(unlocked){
                                if(ru)"Поставить" else "Aufstellen"
                            }else if(freeTesting) {
                                if(ru)"Бесплатно" else "Kostenlos"
                            }else if(unlocked){
                                if(ru)"Установить" else "Aufstellen"
                            }else if(ru)"Купить" else "Kaufen",
                                fontSize=11.sp,fontWeight=FontWeight.Bold,maxLines=1)
                        }
                    }
                }
            }
            Text(if(freeTesting){
                if(ru)"🧪 Тестовая версия: все предметы бесплатно, цены показаны для будущей игры."
                else "🧪 Testversion: alles kostenlos, Preise nur zur Orientierung."
            }else if(ru)"Купленные вещи сохраняются отдельно для каждого питомца."
            else "Gekaufte Sachen bleiben für jedes Tier gespeichert.",
                fontSize=10.sp,textAlign=TextAlign.Center,
                modifier=Modifier.fillMaxWidth(),color=Color(0xFF907D88),maxLines=1)
        }
    }
}
