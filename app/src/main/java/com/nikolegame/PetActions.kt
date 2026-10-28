package com.nikolegame

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

@Composable
internal fun PetActionsDialog(
    locale:String, pet:String, hasHome:Boolean,
    onAction:(String)->Unit, onClose:()->Unit
) {
    val ru=locale=="ru"
    val ink=Color(0xFF76577F)
    Dialog(onDismissRequest=onClose,
        properties=DialogProperties(usePlatformDefaultWidth=false)
    ){
        Column(
            Modifier.fillMaxWidth(.83f)
                .clip(RoundedCornerShape(24.dp))
                .background(Color(0xFFFFF8F1))
                .padding(17.dp),
            horizontalAlignment=Alignment.CenterHorizontally,
            verticalArrangement=Arrangement.spacedBy(9.dp)
        ){
            Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween,
                verticalAlignment=Alignment.CenterVertically){
                Text(petSpeciesIcon(pet)+" "+petSpeciesName(pet,ru),
                    fontSize=18.sp,fontWeight=FontWeight.Bold,color=ink)
                TextButton(onClick=onClose,contentPadding=PaddingValues(0.dp)){
                    Text("✕",color=ink,fontSize=23.sp)
                }
            }
            Text(if(ru)"Что будем делать?" else "Was machen wir?",
                color=ink,fontSize=13.sp)
            for(action in if(hasHome)listOf("pet","play","feed","home")
                else listOf("pet","play","feed")) {
                val label=when(action) {
                    "pet"->if(ru)"💗 Погладить" else "💗 Streicheln"
                    "play"->if(ru)"🎾 Поиграть" else "🎾 Spielen"
                    "feed"->if(ru)"🥣 Покормить" else "🥣 Füttern"
                    else->if(ru)"🏠 В домик" else "🏠 Ins Häuschen"
                }
                Button(
                    onClick={onAction(action)},
                    modifier=Modifier.fillMaxWidth().height(44.dp),
                    colors=ButtonDefaults.buttonColors(
                        containerColor=when(action){
                            "pet"->Color(0xFFF1D2E2)
                            "play"->Color(0xFFDDE7F5)
                            "feed"->Color(0xFFDDEED9)
                            else->Color(0xFFE7D9F6)
                        },
                        contentColor=ink),
                    shape=RoundedCornerShape(16.dp)
                ){
                    Text(label,fontSize=16.sp,fontWeight=FontWeight.Bold)
                }
            }
            Text(if(ru)"Питомец сможет отдыхать и играть в своём домике 🐾"
                else "Dein Tier kann im Häuschen spielen und ruhen 🐾",
                fontSize=11.sp,color=ink)
        }
    }
}
