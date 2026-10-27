package com.nikolegame

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlin.math.min

private data class PetTileInfo(
    val id:String,val ru:String,val de:String,val tint:Color
)
private val PET_CHOICES=listOf(
    PetTileInfo("dog","Собачка","Hund",Color(0xFFFFE4D2)),
    PetTileInfo("cat","Кошечка","Katze",Color(0xFFE5EAF5)),
    PetTileInfo("parrot","Попугай","Papagei",Color(0xFFDCF1E5)),
    PetTileInfo("hamster","Хомячок","Hamster",Color(0xFFFFE8D7)),
    PetTileInfo("turtle","Черепаха","Schildkröte",Color(0xFFE1EEDB))
)

@Composable
internal fun PetChooser(
    locale:String, chosen:String, onChoose:(String)->Unit, onClose:()->Unit
) {
    val ru=locale=="ru"
    val ink=Color(0xFF6D4C7C)
    Dialog(onDismissRequest=onClose,
        properties=DialogProperties(usePlatformDefaultWidth=false)
    ){
        Column(
            Modifier.fillMaxWidth(.92f).fillMaxHeight(.90f)
                .clip(RoundedCornerShape(24.dp))
                .background(Color(0xFFFFF8F3))
                .padding(horizontal=14.dp,vertical=9.dp),
            horizontalAlignment=Alignment.CenterHorizontally,
            verticalArrangement=Arrangement.spacedBy(7.dp)
        ){
            Row(Modifier.fillMaxWidth().height(34.dp),
                horizontalArrangement=Arrangement.SpaceBetween,
                verticalAlignment=Alignment.CenterVertically){
                Text(if(ru)"🐾 Мои питомцы" else "🐾 Meine Tiere",
                    color=ink,fontSize=20.sp,fontWeight=FontWeight.Bold)
                TextButton(onClick=onClose,contentPadding=PaddingValues(0.dp)){
                    Text("✕",color=ink,fontSize=24.sp)
                }
            }
            // Larger illustrated, clickable pet cards in two simple rows.
            for(rowIndex in 0..1){
                Row(Modifier.fillMaxWidth().weight(1f),
                    horizontalArrangement=Arrangement.spacedBy(9.dp)
                ){
                    val pets=if(rowIndex==0)PET_CHOICES.take(3)
                        else PET_CHOICES.drop(3)
                    pets.forEach{p->
                        val selected=chosen==p.id
                        val shape=RoundedCornerShape(17.dp)
                        Column(
                            Modifier.weight(1f).fillMaxHeight()
                                .clip(shape)
                                .background(if(selected)Color(0xFFE3F0E5)else p.tint)
                                .border(if(selected)2.dp else 1.dp,
                                    if(selected)Color(0xFF76AE86)else Color(0xFFE6CCD9),
                                    shape)
                                .clickable{onChoose(p.id)}
                                .padding(5.dp),
                            horizontalAlignment=Alignment.CenterHorizontally,
                            verticalArrangement=Arrangement.SpaceEvenly
                        ){
                            Canvas(Modifier.fillMaxWidth().weight(1f)){
                                val h=if(p.id=="parrot")255f else if(p.id=="cat")165f
                                    else if(p.id=="dog")148f else 120f
                                val factor=min(size.width/160f,
                                    size.height/h)*.92f
                                withTransform({
                                    translate(size.width*.5f,size.height*.90f)
                                    scale(factor,factor,Offset.Zero)
                                }){
                                    renderPet(p.id,0f,0f,36,false)
                                }
                            }
                            Text((if(ru)p.ru else p.de)+if(selected)" ✓" else "",
                                fontSize=12.sp,fontWeight=FontWeight.Bold,color=ink,
                                maxLines=1,textAlign=TextAlign.Center)
                        }
                    }
                    if(rowIndex==1){
                        val shape=RoundedCornerShape(17.dp)
                        Column(
                            Modifier.weight(1f).fillMaxHeight()
                                .clip(shape)
                                .background(Color(0xFFF0EAE9))
                                .border(1.dp,Color(0xFFE2D4D7),shape)
                                .clickable{onChoose("")}.padding(6.dp),
                            horizontalAlignment=Alignment.CenterHorizontally,
                            verticalArrangement=Arrangement.SpaceEvenly
                        ){
                            Text("🏡",fontSize=39.sp)
                            Text(if(ru)"Пока без питомца"
                                else "Ohne Tier",fontSize=11.sp,
                                color=ink,fontWeight=FontWeight.Bold,
                                maxLines=2,textAlign=TextAlign.Center)
                        }
                    }
                }
            }
            Text(
                if(ru)"👆 Нажми на картинку — питомец поселится в спальне."
                else "👆 Tippe auf ein Tierbild — es wohnt dann im Schlafzimmer.",
                fontSize=11.sp,color=ink,textAlign=TextAlign.Center,
                maxLines=1
            )
        }
    }
}
