package com.nikolegame

// Every furnishing has its OWN model, size, local ownership and saved selection.
internal data class RenovationItem(
    val category: String,
    val style: Int,
    val icon: String,
    val nameRu: String,
    val nameDe: String,
    val price: Int
) { val key: String get() = "$category:$style" }

internal data class RoomCategory(val id:String,val emoji:String,val ru:String,val de:String)
internal val ROOM_CATEGORIES=listOf(
    RoomCategory("bed","🛏️","Кровать","Bett"),
    RoomCategory("wardrobe","🚪","Шкаф","Schrank"),
    RoomCategory("table","🖍️","Стол","Tisch"),
    RoomCategory("chair","🪑","Стул","Stuhl"),
    RoomCategory("rug","🌺","Ковёр","Teppich"),
    RoomCategory("painting","🖼️","Картины","Bilder"),
    RoomCategory("ceiling","💡","Люстра","Deckenlampe"),
    RoomCategory("lamp","🕯️","Лампа","Lampe"),
    RoomCategory("tv","📺","Телевизор","Fernseher"),
    RoomCategory("fridge","🧊","Холодильник","Kühlschrank"),
    RoomCategory("wall","🌸","Обои","Tapete"),
    RoomCategory("floor","🟫","Пол","Boden")
)

internal const val MAX_ITEM_STYLE = 5

// Every upgrade has a higher display price; free purchases are preview-only.
internal val RENOVATION_ITEMS=listOf(
    RenovationItem("bed",0,"🛏️","Деревянная кровать","Holzbett",0),
    RenovationItem("bed",1,"🏰","Кровать-домик","Hausbett",15),
    RenovationItem("bed",2,"👑","Кровать с балдахином","Himmelbett",35),
    RenovationItem("bed",3,"🪞","Жемчужная кровать","Perlenbett",55),
    RenovationItem("bed",4,"🏵️","Королевская кровать","Königsbett",80),
    RenovationItem("bed",5,"💎","Алмазная кровать","Diamantbett",110),
    RenovationItem("wardrobe",0,"🚪","Простой шкаф","Einfacher Schrank",0),
    RenovationItem("wardrobe",1,"🪞","Шкаф с зеркалом","Spiegelschrank",10),
    RenovationItem("wardrobe",2,"🎀","Высокий шкаф","Großer Schrank",25),
    RenovationItem("wardrobe",3,"✨","Шкаф с жемчугом","Perlenschrank",45),
    RenovationItem("wardrobe",4,"🏛️","Дворцовый шкаф","Palastschrank",60),
    RenovationItem("wardrobe",5,"💎","Шкаф с кристаллами","Kristallschrank",85),
    RenovationItem("table",0,"🎨","Простой стол","Einfacher Tisch",0),
    RenovationItem("table",1,"🌳","Круглый стол","Runder Tisch",10),
    RenovationItem("table",2,"🖍️","Стол для рисования","Maltisch",25),
    RenovationItem("table",3,"🌸","Стол с инкрустацией","Intarsientisch",45),
    RenovationItem("table",4,"🏵️","Позолоченный стол","Vergoldeter Tisch",60),
    RenovationItem("table",5,"💎","Драгоценный стол","Edelsteintisch",85),
    RenovationItem("chair",0,"🪑","Простой стул","Einfacher Stuhl",0),
    RenovationItem("chair",1,"🦋","Стул-бабочка","Schmetterlingsstuhl",10),
    RenovationItem("chair",2,"💜","Мягкое кресло","Polsterstuhl",20),
    RenovationItem("chair",3,"🌸","Жемчужное кресло","Perlensessel",35),
    RenovationItem("chair",4,"👑","Трон с золотом","Goldthron",50),
    RenovationItem("chair",5,"💎","Хрустальный трон","Kristallthron",70),
    RenovationItem("rug",0,"🥚","Овальный ковёр","Ovaler Teppich",0),
    RenovationItem("rug",1,"⭐","Звёздочка","Sternenteppich",10),
    RenovationItem("rug",2,"🌸","Цветок","Blumenteppich",20),
    RenovationItem("rug",3,"🌷","Шёлковый ковёр","Seidenteppich",35),
    RenovationItem("rug",4,"🏵️","Дворцовый ковёр","Palastteppich",50),
    RenovationItem("rug",5,"💎","Ковёр с самоцветами","Edelsteinteppich",70),
    RenovationItem("painting",0,"🖼️","Три пейзажа","Drei Landschaften",0),
    RenovationItem("painting",1,"🌻","Большая картина","Großes Bild",10),
    RenovationItem("painting",2,"🦋","Маленькие бабочки","Kleine Schmetterlinge",20),
    RenovationItem("painting",3,"🎨","Галерея в серебре","Silbergalerie",35),
    RenovationItem("painting",4,"🏛️","Золотая галерея","Goldgalerie",50),
    RenovationItem("painting",5,"💎","Хрустальная галерея","Kristallgalerie",70),
    RenovationItem("ceiling",0,"💡","Простая люстра","Einfache Deckenlampe",0),
    RenovationItem("ceiling",1,"🌟","Люстра-звезда","Sternlampe",15),
    RenovationItem("ceiling",2,"👑","Хрустальная люстра","Kristallleuchter",30),
    RenovationItem("ceiling",3,"✨","Люстра с жемчугом","Perlenleuchter",50),
    RenovationItem("ceiling",4,"🏵️","Золотая люстра","Goldleuchter",75),
    RenovationItem("ceiling",5,"💎","Люстра с бриллиантами","Diamantleuchter",100),
    RenovationItem("lamp",0,"🕯️","Настольная лампа","Tischlampe",0),
    RenovationItem("lamp",1,"🌷","Лампа-цветок","Blumenlampe",10),
    RenovationItem("lamp",2,"🐰","Лампа-зайчик","Hasenlampe",20),
    RenovationItem("lamp",3,"🪞","Фарфоровая лампа","Porzellanlampe",35),
    RenovationItem("lamp",4,"🏵️","Золотая лампа","Goldlampe",50),
    RenovationItem("lamp",5,"💎","Лампа-кристалл","Kristalllampe",70),
    RenovationItem("tv",0,"🚫","Без телевизора","Ohne Fernseher",0),
    RenovationItem("tv",1,"📺","Настенный экран","Wandfernseher",15),
    RenovationItem("tv",2,"📺","Ретро-телевизор","Retro-Fernseher",35),
    RenovationItem("tv",3,"✨","Экран с подсветкой","Leuchtfernseher",55),
    RenovationItem("tv",4,"🏵️","Золотая рамка","Goldrahmen-TV",80),
    RenovationItem("tv",5,"💎","Кристальный экран","Kristallbildschirm",110),
    RenovationItem("fridge",0,"🧊","Белый холодильник","Weißer Kühlschrank",0),
    RenovationItem("fridge",1,"🌿","Мятный двухдверный","Mint-Doppeltür",15),
    RenovationItem("fridge",2,"🎀","Розовый ретро","Rosa Retro-Kühlschrank",30),
    RenovationItem("fridge",3,"🪞","Жемчужный холодильник","Perlenkühlschrank",50),
    RenovationItem("fridge",4,"🏵️","Золотой холодильник","Goldkühlschrank",75),
    RenovationItem("fridge",5,"💎","Кристальный холодильник","Kristallkühlschrank",100),
    RenovationItem("wall",0,"🌸","Цветочные обои","Blumentapete",0),
    RenovationItem("wall",1,"🌿","Мятные обои","Minztapete",10),
    RenovationItem("wall",2,"💜","Лавандовые обои","Lavendeltapete",20),
    RenovationItem("wall",3,"✨","Шёлковые обои","Seidentapete",35),
    RenovationItem("wall",4,"🏵️","Золотые обои","Goldtapete",50),
    RenovationItem("wall",5,"💎","Жемчужные обои","Perlentapete",70),
    RenovationItem("floor",0,"🪵","Тёплые доски","Holzdielen",0),
    RenovationItem("floor",1,"🌾","Светлый дуб","Helle Eiche",10),
    RenovationItem("floor",2,"🤍","Узорная плитка","Musterfliesen",20),
    RenovationItem("floor",3,"✨","Светлый паркет","Helles Parkett",35),
    RenovationItem("floor",4,"🏵️","Дворцовый паркет","Palastparkett",50),
    RenovationItem("floor",5,"💎","Мрамор с кристаллами","Kristallmarmor",70)
)

// Verify price progression and complete families during app initialization.
internal val CATALOG_VALID = ROOM_CATEGORIES.all { category ->
    val family=RENOVATION_ITEMS.filter { it.category==category.id }.sortedBy { it.style }
    family.size==MAX_ITEM_STYLE+1 && family.map { it.style }==(0..MAX_ITEM_STYLE).toList() &&
        family.zipWithNext().all { (a,b) -> b.price>a.price }
}
