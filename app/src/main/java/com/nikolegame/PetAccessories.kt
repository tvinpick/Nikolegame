package com.nikolegame

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform

internal val PET_SPECIES=listOf("dog","cat","hamster","parrot","turtle")
internal fun petSpeciesName(id:String,ru:Boolean)=when(id){
 "dog"->if(ru)"Собака" else "Hund"
 "cat"->if(ru)"Кошка" else "Katze"
 "hamster"->if(ru)"Хомяк" else "Hamster"
 "parrot"->if(ru)"Попугай" else "Papagei"
 else->if(ru)"Черепаха" else "Schildkröte"
}
internal fun petSpeciesIcon(id:String)=when(id){
 "dog"->"🐶";"cat"->"🐱";"hamster"->"🐹";"parrot"->"🦜";else->"🐢"
}
// Each species owns separate furniture and feeding slots. 0 = empty,
// 1 = simple, 2 = decorated, 3 = premium. Preview purchases are free.
internal val PET_SHOP_ITEMS:List<RenovationItem> = PET_SPECIES.flatMap { animal ->
 listOf("home","bowl").flatMap { kind ->
  val namesRu=if(kind=="home")when(animal){
   "dog"->listOf("Без домика","Простой вольер","Клетка с лежанкой","Просторный вольер","Деревянная будка","Будка с двориком","Дворец VIP")
   "cat"->listOf("Без домика","Клетка с лежанкой","Клетка с гамаком","Кошачий комплекс","Двухэтажный домик","Дворец с полочками","Кошачий замок")
   "hamster"->listOf("Без клетки","Клетка с колесом","Клетка с домиком","Клетка с тоннелями","Двухэтажный комплекс","Деревянный дворец","Замок с башнями")
   "parrot"->listOf("Без клетки","Круглая клетка","Клетка с качелями","Деревянная клетка","Арочный вольер","Большой вольер","Клетка-замок")
   else->listOf("Без жилища","Лоток с укрытием","Простой террариум","Террариум с домиком","Террариум с прудом","Большой эко-террариум","Королевский террариум")
  }else when(animal){
   "dog"->listOf("Без миски","Миска с кормом","Двойная миска","Золотая миска")
   "cat"->listOf("Без миски","Миска с рыбкой","Двойная миска","Жемчужная миска")
   "hamster"->listOf("Без миски","Зёрнышки","Миска с семенами","Золотая кормушка")
   "parrot"->listOf("Без миски","Зёрна для птицы","Фруктовая миска","Жемчужная кормушка")
   else->listOf("Без миски","Листья салата","Овощная миска","Драгоценная кормушка")
  }
  val namesDe=if(kind=="home")when(animal){
   "dog"->listOf("Ohne Haus","Einfacher Zwinger","Käfig mit Körbchen","Großes Gehege","Holzhütte","Hütte mit Garten","VIP-Palast")
   "cat"->listOf("Ohne Haus","Käfig mit Bett","Käfig mit Hängematte","Katzenparadies","Zweistöckiges Haus","Luxusregale","Katzenschloss")
   "hamster"->listOf("Ohne Käfig","Radkäfig","Käfig mit Haus","Tunnelkäfig","Zwei Etagen","Holzpalast","Hamsterschloss")
   "parrot"->listOf("Ohne Käfig","Rundkäfig","Käfig mit Schaukel","Holzvoliere","Bogenvoliere","Große Voliere","Vogelburg")
   else->listOf("Ohne Haus","Becken mit Versteck","Kleines Terrarium","Terrarium mit Haus","Terrarium mit Teich","Öko-Terrarium","Königliches Terrarium")
  }else when(animal){
   "dog"->listOf("Ohne Napf","Futternapf","Doppelnapf","Goldnapf")
   "cat"->listOf("Ohne Napf","Fischfutter","Doppelnapf","Perlennapf")
   "hamster"->listOf("Ohne Napf","Körner","Saatennapf","Goldnapf")
   "parrot"->listOf("Ohne Napf","Vogelkörner","Obstnapf","Perlennapf")
   else->listOf("Ohne Napf","Salatnapf","Gemüsenapf","Edelnapf")
  }
  (if(kind=="home")0..6 else 0..3).map { style -> RenovationItem(
    "pet_"+kind+"_"+animal,style,if(kind=="home")petSpeciesIcon(animal) else "🥣",
    namesRu[style],namesDe[style],
    if(style==0)0 else if(kind=="home")listOf(0,10,20,35,55,80,120)[style]
    else listOf(0,5,15,30)[style]
  ) }
 }
}
internal val PET_CATALOG_VALID = PET_SPECIES.all { animal ->
 listOf("home","bowl").all { kind ->
  val a=PET_SHOP_ITEMS.filter { it.category=="pet_"+kind+"_"+animal }
  a.map{it.style}==(if(kind=="home")(0..6).toList() else (0..3).toList())&&
   a.zipWithNext().all{(x,y)->y.price>x.price}
 }
}
private fun petFill(style:Int)=when(style){
 1->Color(0xFFD5B596);2->Color(0xFFF1CBD9);else->Color(0xFFD8BEEB)
}
private fun petTrim(style:Int)=when(style){
 1->Color(0xFF94725D);2->Color(0xFFB987A3);else->Color(0xFFC3A05C)
}
private fun DrawScope.petGem(x:Float,y:Float,style:Int){
 if(style==3){
  drawCircle(Color(0xFFFFE8AD),7f,Offset(x,y))
  drawCircle(Color.White,3.5f,Offset(x-1f,y-1f))
 }
}
// All art is near the wall, ending before the main walking lane y>=800.
// Furniture does not alter bed, desk, kitchen, or doorway collision zones.
internal fun DrawScope.renderPetHabitat(animal:String,style:Int, tick:Int=0){
    // Readable scale next to the roaming pet, but the home's feet remain in the
    // wall-side dressing niche. There are no new navigation colliders.
    withTransform({
        translate(1140f,730f)
        scale(PET_HOME_ART_SCALE,PET_HOME_ART_SCALE,Offset.Zero)
        translate(-1140f,-730f)
    }){
        renderDetailedPetHabitat(animal,style,tick)
    }
}
internal fun DrawScope.renderPetBowl(animal:String,style:Int){
 if(style<=0||animal !in PET_SPECIES)return
 val edge=petTrim(style)
 withTransform({translate(1335f,730f)}){
  drawOval(Color.Black.copy(alpha=.13f),Offset(7f,53f),Size(131f,13f))
  drawOval(edge,Offset(6f,20f),Size(132f,44f))
  drawOval(petFill(style),Offset(14f,22f),Size(116f,32f))
  drawOval(Color(0xFFFFE8B9),Offset(24f,26f),Size(96f,24f))
  when(animal){
   "dog","cat"->{
    for(i in 0..5)drawCircle(if(animal=="dog")Color(0xFFB88F67)
      else Color(0xFFE4A19E),4.1f,
      Offset(34f+i*15f,34f+(i%2)*5f))
   }
   "hamster","parrot"->{
    for(i in 0..7)drawOval(Color(0xFFD2A568),
     Offset(32f+i*11f,32f+(i%3)*4f),Size(9f,5f))
   }
   else->{
    for(i in 0..3)drawOval(Color(0xFF82B88B),
     Offset(29f+i*19f,29f+i%2*3f),Size(25f,15f))
   }
  }
  if(style>=2)drawLine(Color.White.copy(alpha=.84f),
   Offset(22f,55f),Offset(125f,55f),2f)
  if(style==3)for(x in listOf(24f,122f))petGem(x,44f,style)
 }
}

/** Validate saved IDs against the actual catalog, including homes 4..6. */
internal fun restoredPetStyle(category:String, saved:Int):Int =
    saved.coerceIn(0, PET_SHOP_ITEMS.filter { it.category==category }.maxOfOrNull { it.style } ?: 0)
internal fun petShopItems(species:String, kind:String):List<RenovationItem> =
    if(species !in PET_SPECIES || kind !in listOf("home","bowl")) emptyList()
    else PET_SHOP_ITEMS.filter { it.category=="pet_${kind}_${species}" }.sortedBy { it.price }
