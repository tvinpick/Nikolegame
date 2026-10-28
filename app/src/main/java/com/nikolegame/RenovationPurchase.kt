package com.nikolegame

/**
 * Single source of truth for the shop transaction.
 * The independent preview and all debug APKs use freeTesting=true.
 * Release builds require coins for items that are not already owned.
 */
internal data class RenovationPurchase(
    val success: Boolean,
    val coins: Int,
    val owned: Set<String>,
    val selections: Map<String, Int>
)

internal fun purchaseRenovation(
    item: RenovationItem,
    coins: Int,
    owned: Set<String>,
    selections: Map<String, Int>,
    freeTesting: Boolean
): RenovationPurchase {
    val legacy = item.category in listOf("bed", "wardrobe", "table", "chair") &&
        "furniture:${item.style}" in owned
    val unlocked = item.price == 0 || item.key in owned || legacy
    if (!freeTesting && !unlocked && coins < item.price) {
        return RenovationPurchase(false, coins, owned, selections)
    }
    val newCoins = if (freeTesting || unlocked) coins else coins - item.price
    val newOwned = owned + item.key
    return RenovationPurchase(
        success = true,
        coins = newCoins,
        owned = newOwned,
        selections = selections + (item.category to item.style)
    )
}
