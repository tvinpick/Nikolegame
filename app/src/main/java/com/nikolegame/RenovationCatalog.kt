package com.nikolegame

// One-time local ownership: buying a style unlocks it permanently.
// The first two choices in each category are free so children can try
// renovating before earning coins. All costs are game coins only.
internal data class RenovationItem(
    val category: String,
    val style: Int,
    val icon: String,
    val nameRu: String,
    val nameDe: String,
    val price: Int
) {
    val key: String get() = "$category:$style"
}

internal val RENOVATION_ITEMS = listOf(
    RenovationItem("wall", 0, "🌸", "Цветочные обои", "Blumentapete", 0),
    RenovationItem("wall", 1, "🌿", "Мятные обои", "Minztapete", 0),
    RenovationItem("wall", 2, "💜", "Лавандовые обои", "Lavendeltapete", 20),
    RenovationItem("floor", 0, "🪵", "Тёплые доски", "Warme Holzdielen", 0),
    RenovationItem("floor", 1, "🌾", "Светлый дуб", "Helle Eiche", 0),
    RenovationItem("floor", 2, "🤍", "Плитка с узором", "Gemusterte Fliesen", 30),
    RenovationItem("furniture", 0, "🛏️", "Старая уютная мебель", "Gemütliche alte Möbel", 0),
    RenovationItem("furniture", 1, "🕊️", "Светлая мебель", "Helle Möbel", 0),
    RenovationItem("furniture", 2, "🎀", "Сиреневый гарнитур", "Fliederfarbene Möbel", 40)
)
