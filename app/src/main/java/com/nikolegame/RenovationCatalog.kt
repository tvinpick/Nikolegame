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
    RoomCategory("wall","🌸","Обои","Tapete"),
    RoomCategory("floor","🟫","Пол","Boden")
)

internal val RENOVATION_ITEMS=listOf(
    RenovationItem("bed",0,"🛏️","Деревянная","Holzbett",0),
    RenovationItem("bed",1,"🏰","Кровать-домик","Hausbett",0),
    RenovationItem("bed",2,"👑","Кровать с балдахином","Himmelbett",35),
    RenovationItem("wardrobe",0,"🚪","Старый шкаф","Alter Schrank",0),
    RenovationItem("wardrobe",1,"🪞","Шкаф с зеркалом","Spiegelschrank",0),
    RenovationItem("wardrobe",2,"🎀","Высокий шкаф","Großer Schrank",30),
    RenovationItem("table",0,"🎨","Старый стол","Alter Tisch",0),
    RenovationItem("table",1,"🌳","Круглый стол","Runder Tisch",0),
    RenovationItem("table",2,"🎨","Стол для рисования","Maltisch",25),
    RenovationItem("chair",0,"🪑","Старый стул","Alter Stuhl",0),
    RenovationItem("chair",1,"🦋","Стул-бабочка","Schmetterlingsstuhl",0),
    RenovationItem("chair",2,"💜","Мягкое кресло","Polsterstuhl",20),
    RenovationItem("rug",0,"🥚","Овальный ковёр","Ovaler Teppich",0),
    RenovationItem("rug",1,"⭐","Звёздочка","Sternenteppich",0),
    RenovationItem("rug",2,"🌸","Цветок","Blumenteppich",20),
    RenovationItem("painting",0,"🖼️","Три пейзажа","Drei Landschaften",0),
    RenovationItem("painting",1,"🌻","Большая картина","Großes Bild",0),
    RenovationItem("painting",2,"🦋","Маленькие бабочки","Kleine Schmetterlinge",20),
    RenovationItem("ceiling",0,"💡","Простая люстра","Einfache Deckenlampe",0),
    RenovationItem("ceiling",1,"🌟","Люстра-звезда","Sternlampe",0),
    RenovationItem("ceiling",2,"👑","Хрустальная люстра","Kristallleuchter",35),
    RenovationItem("lamp",0,"🕯️","Настольная лампа","Tischlampe",0),
    RenovationItem("lamp",1,"🌷","Лампа-цветок","Blumenlampe",0),
    RenovationItem("lamp",2,"🐰","Лампа-зайчик","Hasenlampe",20),
    RenovationItem("tv",0,"🚫","Без телевизора","Ohne Fernseher",0),
    RenovationItem("tv",1,"📺","Настенный экран","Wandfernseher",0),
    RenovationItem("tv",2,"📺","Ретро-телевизор","Retro-Fernseher",35),
    RenovationItem("wall",0,"🌸","Цветочные обои","Blumentapete",0),
    RenovationItem("wall",1,"🌿","Мятные обои","Minztapete",0),
    RenovationItem("wall",2,"💜","Лавандовые обои","Lavendeltapete",20),
    RenovationItem("floor",0,"🪵","Тёплые доски","Holzdielen",0),
    RenovationItem("floor",1,"🌾","Светлый дуб","Helle Eiche",0),
    RenovationItem("floor",2,"🤍","Узорная плитка","Musterfliesen",30)
)
