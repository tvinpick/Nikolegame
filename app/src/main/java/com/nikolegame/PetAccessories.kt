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
internal fun DrawScope.renderPetHabitat(animal:String,style:Int){
 if(style<=0||animal !in PET_SPECIES)return
 renderDetailedPetHabitat(animal,style)
 return
 val fill=petFill(style);val border=petTrim(style)
 withTransform({translate(1003f,560f)}){
  when(animal){
   "dog"->{
    drawOval(Color.Black.copy(alpha=.12f),Offset(3f,158f),Size(272f,20f))
    drawRoundRect(border,Offset(25f,56f),Size(224f,107f),CornerRadius(16f))
    drawRoundRect(fill,Offset(35f,65f),Size(204f,89f),CornerRadius(12f))
    val roof=Path().apply{
     moveTo(7f,63f);lineTo(137f,0f);lineTo(269f,63f);close()
    }
    drawPath(roof,border)
    drawLine(fill,Offset(31f,58f),Offset(137f,7f),8f)
    drawLine(fill,Offset(137f,7f),Offset(247f,58f),8f)
    drawRoundRect(Color(0xFF62566C),Offset(100f,105f),Size(75f,51f),
     CornerRadius(32f))
    if(style>=2)drawRoundRect(Color(0xFFFFF0DE),Offset(95f,67f),
     Size(85f,24f),CornerRadius(11f))
    petGem(137f,29f,style)
   }
   "cat"->{
    drawOval(border,Offset(10f,87f),Size(259f,79f))
    drawOval(fill,Offset(21f,93f),Size(238f,64f))
    drawOval(Color(0xFFFFF2EA),Offset(43f,111f),Size(192f,40f))
    drawOval(Color(0xFFEAB9CA),Offset(93f,112f),Size(77f,28f))
    if(style>=2){
     drawRoundRect(border,Offset(46f,73f),Size(176f,51f),CornerRadius(19f))
     drawRoundRect(fill,Offset(55f,80f),Size(156f,35f),CornerRadius(15f))
    }
    petGem(136f,89f,style)
   }
   "hamster"->{
    drawRoundRect(border,Offset(20f,27f),Size(238f,146f),CornerRadius(14f))
    drawRoundRect(Color(0xFFFFF8E9),Offset(29f,35f),Size(220f,122f),
     CornerRadius(10f))
    drawRoundRect(fill,Offset(30f,137f),Size(218f,26f),CornerRadius(8f))
    for(i in 0..12){
     val x=38f+i*16f
     drawLine(border.copy(alpha=.72f),Offset(x,39f),Offset(x,135f),2.5f)
    }
    drawCircle(border,43f,Offset(176f,99f))
    drawCircle(Color(0xFFFDF1DE),35f,Offset(176f,99f))
    drawCircle(border,6f,Offset(176f,99f))
    for(i in 0..5){
     val a=i*1.0471976f
     drawLine(border,Offset(176f,99f),
      Offset(176f+kotlin.math.cos(a)*31f,99f+kotlin.math.sin(a)*31f),2.4f)
    }
    drawRoundRect(Color(0xFFD3A57A),Offset(52f,118f),Size(70f,29f),
     CornerRadius(17f))
    if(style>=2)drawCircle(Color(0xFFAFD19F),15f,Offset(79f,65f))
    petGem(133f,28f,style)
   }
   "parrot"->{
    drawRoundRect(border,Offset(35f,29f),Size(205f,143f),CornerRadius(68f))
    drawRoundRect(Color(0xFFFAF9EE),Offset(44f,38f),Size(187f,125f),
     CornerRadius(60f))
    for(i in 0..10){
     val x=54f+i*17f
     drawLine(border.copy(alpha=.77f),Offset(x,84f),Offset(x,150f),2.5f)
    }
    drawLine(border,Offset(58f,122f),Offset(221f,122f),6f)
    drawLine(fill,Offset(58f,143f),Offset(218f,143f),10f)
    drawCircle(Color(0xFF85BEA7),15f,Offset(116f,106f))
    if(style>=2){
     drawLine(border,Offset(178f,66f),Offset(178f,98f),2.7f)
     drawCircle(Color(0xFFEFBDD0),12f,Offset(178f,103f))
    }
    petGem(139f,24f,style)
   }
   else->{
    drawOval(border,Offset(8f,120f),Size(267f,53f))
    drawOval(Color(0xFFA9D6C5),Offset(20f,125f),Size(239f,41f))
    drawOval(fill,Offset(53f,76f),Size(172f,80f))
    drawOval(border,Offset(79f,68f),Size(125f,81f))
    drawOval(fill,Offset(87f,78f),Size(108f,63f))
    drawOval(Color(0xFF6B605C),Offset(101f,122f),Size(80f,22f))
    for(i in 0..2)drawOval(Color(0xFF81B88A),
     Offset(40f+i*87f,102f),Size(26f,45f))
    if(style>=2)drawCircle(Color(0xFFE6CEAD),13f,Offset(241f,140f))
    petGem(139f,75f,style)
   }
  }
  if(style>=3)for(x in listOf(29f,244f))petGem(x,153f,style)
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
