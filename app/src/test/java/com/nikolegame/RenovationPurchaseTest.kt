package com.nikolegame

import org.junit.Assert.*
import org.junit.Test

class RenovationPurchaseTest {
    @Test fun all72PreviewItemsAreFreeAndSelectable() {
        assertTrue(CATALOG_VALID)
        assertEquals(72, RENOVATION_ITEMS.size)
        for (item in RENOVATION_ITEMS) {
            val purchase = purchaseRenovation(
                item = item, coins = 0, owned = emptySet(),
                selections = emptyMap(), freeTesting = true
            )
            assertTrue("Could not buy ${item.key}", purchase.success)
            assertEquals(0, purchase.coins)
            assertTrue("Not owned: ${item.key}", item.key in purchase.owned)
            assertEquals(item.style, purchase.selections[item.category])
        }
    }

    @Test fun eachCategoryHasIncreasingPricesAndSixUniqueStyles() {
        for(category in ROOM_CATEGORIES) {
            val group = RENOVATION_ITEMS.filter { it.category == category.id }
                .sortedBy { it.style }
            assertEquals("Wrong count in ${category.id}", 6, group.size)
            assertEquals((0..5).toList(), group.map { it.style })
            assertTrue(group.zipWithNext().all { (a,b) -> b.price > a.price })
        }
    }

    @Test fun freePreviewNeverSubtractsExistingCoins() {
        var coins=7
        var owned=emptySet<String>()
        var selections=emptyMap<String,Int>()
        for(item in RENOVATION_ITEMS) {
            val p = purchaseRenovation(item,coins,owned,selections,freeTesting=true)
            assertTrue(p.success)
            coins=p.coins
            owned=p.owned
            selections=p.selections
        }
        assertEquals(7, coins)
        assertEquals(72, owned.size)
        assertEquals(12, selections.size)
    }

    @Test fun normalBuildStillRequiresCoins() {
        val premium=RENOVATION_ITEMS.first { it.category=="bed" && it.style==5 }
        val declined=purchaseRenovation(premium,0,emptySet(),emptyMap(),freeTesting=false)
        assertFalse(declined.success)
        assertEquals(0,declined.coins)
        assertTrue(declined.owned.isEmpty())
        val paid=purchaseRenovation(premium,premium.price,emptySet(),emptyMap(),freeTesting=false)
        assertTrue(paid.success)
        assertEquals(0,paid.coins)
        val reused=purchaseRenovation(premium,0,paid.owned,paid.selections,freeTesting=false)
        assertTrue(reused.success)
        assertEquals(0,reused.coins)
    }

    @Test fun purchasesAreIndependentPerCategory() {
        val bed=RENOVATION_ITEMS.first {it.category=="bed"&&it.style==4}
        val chair=RENOVATION_ITEMS.first {it.category=="chair"&&it.style==5}
        val first=purchaseRenovation(bed,0,emptySet(),emptyMap(),true)
        val second=purchaseRenovation(chair,first.coins,first.owned,first.selections,true)
        assertEquals(4,second.selections["bed"])
        assertEquals(5,second.selections["chair"])
        assertTrue(bed.key in second.owned)
        assertTrue(chair.key in second.owned)
    }
}
