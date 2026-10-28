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

    @Test fun allPetItemsCanBePurchasedForFreeInPreview() {
        assertTrue(PET_CATALOG_VALID)
        assertEquals(40, PET_SHOP_ITEMS.size)
        for(item in PET_SHOP_ITEMS) {
            val p=purchaseRenovation(item,0,emptySet(),emptyMap(),true)
            assertTrue("Cannot buy ${item.key}",p.success)
            assertEquals(0,p.coins)
            assertTrue(item.key in p.owned)
            assertEquals(item.style,p.selections[item.category])
        }
    }

    @Test fun petHabitatAndBowlAreIndependentlySavedForEachSpecies() {
        var owned=emptySet<String>()
        var chosen=emptyMap<String,Int>()
        PET_SPECIES.forEach { animal ->
            val home=PET_SHOP_ITEMS.first {
                it.category=="pet_home_"+animal && it.style==3
            }
            val bowl=PET_SHOP_ITEMS.first {
                it.category=="pet_bowl_"+animal && it.style==2
            }
            val a=purchaseRenovation(home,0,owned,chosen,true)
            val b=purchaseRenovation(bowl,0,a.owned,a.selections,true)
            owned=b.owned
            chosen=b.selections
        }
        assertEquals(10,chosen.size)
        assertEquals(10,owned.size)
        PET_SPECIES.forEach {animal ->
            assertEquals(3,chosen["pet_home_"+animal])
            assertEquals(2,chosen["pet_bowl_"+animal])
        }
    }

    @Test fun petAccessoryPricingRemainsEnforcedInRelease() {
        val home=PET_SHOP_ITEMS.first{it.category=="pet_home_dog" && it.style==3}
        val p=purchaseRenovation(home,0,emptySet(),emptyMap(),false)
        assertFalse(p.success)
        assertTrue(p.owned.isEmpty())
        val paid=purchaseRenovation(home,home.price,emptySet(),emptyMap(),false)
        assertTrue(paid.success)
        assertEquals(0,paid.coins)
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
