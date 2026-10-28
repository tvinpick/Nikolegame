package com.nikolegame

import org.junit.Assert.*
import org.junit.Test
import kotlin.random.Random
import kotlin.math.hypot

class PetLifeTest {
    @Test fun ballThrowMakesDogRunTowardVisibleLandingPoint() {
        val dog=PetLife("dog",Random(16))
        val startingX=dog.x
        assertTrue(dog.chaseBall(WalkPoint(1460f,823f),emptyMap()))
        assertEquals(PetState.CHASE_BALL,dog.state)
        var chased=false
        var playingAfterCatch=false
        repeat(60*12){
            dog.update(1f/60f,6,1,emptyMap(),1350f,810f)
            if(dog.state==PetState.CHASE_BALL)chased=true
            if(chased && dog.state==PetState.PLAY)playingAfterCatch=true
        }
        assertTrue("Pet never chased the ball",chased)
        assertTrue("Pet never played with the caught ball",playingAfterCatch)
        assertTrue("Dog did not move toward the ball",dog.x>startingX+80f)
    }

    @Test fun parrotFliesUpAndPerchesThenReturnsToFloorOnCommand(){
        val bird=PetLife("parrot",Random(2))
        assertTrue(bird.chaseBall(WalkPoint(1120f,430f),emptyMap()))
        assertEquals(PetState.FLY_ROOM,bird.state)
        var perched=false
        repeat(60*6){
            bird.update(1f/60f,6,1,emptyMap(),1350f,810f)
            perched=perched || bird.perched
        }
        assertTrue("Parrot never landed on an elevated perch",perched)
        bird.request("pet")
        var landed=false
        repeat(60*12){
            bird.update(1f/60f,6,1,emptyMap(),1350f,810f)
            if(bird.y>=770f)landed=true
        }
        assertTrue("Parrot didn't return to the ground when called",landed)
    }

    @Test fun everyPetHasBowlToChooseInItsOwnShop(){
        for(pet in PET_SPECIES){
            val bowls=petShopItems(pet,"bowl")
            assertEquals(4,bowls.size)
            assertEquals("pet_bowl_"+pet,bowls[1].category)
            assertEquals(1,bowls[1].style)
        }
    }

    @Test fun restoreAllPurchasedHomesAcrossRestart() {
        for(pet in PET_SPECIES)for(level in 0..6)
            assertEquals(level,restoredPetStyle("pet_home_$pet",level))
        assertEquals(3,restoredPetStyle("pet_bowl_dog",99))
        assertEquals(0,restoredPetStyle("pet_home_dog",-1))
    }
    @Test fun shopOnlyOffersSelectedSpecies() {
        for(pet in PET_SPECIES)for(kind in listOf("home","bowl")) {
            val items=petShopItems(pet,kind)
            assertTrue(items.isNotEmpty())
            assertTrue(items.all { it.category=="pet_${kind}_$pet" })
        }
        assertTrue(petShopItems("","home").isEmpty())
    }
    @Test fun allThirtyHomesHaveContinuousEntryRestAndExit() {
        for(pet in PET_SPECIES)for(level in 1..6){
            val p=PetLife(pet,Random(12));p.request("home")
            val seen=mutableSetOf<PetState>()
            repeat(60*32){
                val x=p.x;val y=p.y
                p.update(1f/60,level,3,emptyMap(),1350f,810f)
                assertTrue("Teleport $pet $level",hypot(p.x-x,p.y-y)<2.2f)
                seen+=p.state
            }
            for(s in listOf(PetState.APPROACH_HOME,PetState.ENTER_HOME,PetState.EXIT_HOME,PetState.STRETCH))
                assertTrue("$pet/$level missing $s",s in seen)
            assertTrue(PetState.SLEEP in seen || PetState.PLAY_HOME in seen)
        }
    }
    @Test fun interruptedHomeVisitExitsBeforePlaying() {
        val p=PetLife("dog",Random(8));p.request("home")
        repeat(180){p.update(1f/60,6,3,emptyMap(),1350f,810f)}
        assertTrue(p.atHome)
        p.request("play")
        val seen=mutableListOf<PetState>()
        repeat(300){p.update(1f/60,6,3,emptyMap(),1350f,810f);seen+=p.state}
        assertTrue(seen.indexOf(PetState.EXIT_HOME)>=0)
        assertTrue(seen.indexOf(PetState.PLAY)>seen.indexOf(PetState.EXIT_HOME))
    }
    @Test fun missingFurnitureNeverStartsEntryOrFeeding() {
        for(pet in PET_SPECIES){
            val p=PetLife(pet,Random(12))
            repeat(3600){
                if(it==0)p.request("home")
                if(it==50)p.request("feed")
                p.update(1f/60,0,0,emptyMap(),1350f,810f)
                assertFalse(p.atHome)
                assertNotEquals(PetState.EAT,p.state)
            }
        }
    }
    @Test fun parrotOnlySleepsOrRestsInsideItsCage() {
        val bird=PetLife("parrot",Random(7))
        repeat(60*100){
            bird.update(1f/60f,6,3,emptyMap(),1350f,810f)
            if(bird.state==PetState.SLEEP || bird.state==PetState.REST)
                assertTrue("Bird resting on the floor at step $it",bird.atHome)
        }
    }

    @Test fun autonomousPetRoutineIncludesGroomingAndEnvironmentalAwareness() {
        val p=PetLife("cat",Random(47))
        val seen=mutableSetOf<PetState>()
        repeat(60*175){
            p.update(1f/60f,6,3,emptyMap(),1350f,810f)
            seen+=p.state
        }
        assertTrue("Autonomous grooming never occurred",PetState.GROOM in seen)
        assertTrue("Missing environmental interaction",
            PetState.SNIFF in seen || PetState.LOOK in seen)
        assertTrue("No visible rest pose",PetState.REST in seen || PetState.SLEEP in seen)
        assertTrue("No autonomous movement",
            PetState.WALK in seen || PetState.APPROACH_BOWL in seen ||
                PetState.APPROACH_HOME in seen)
    }

    @Test fun movementAgreesAtDifferentUpdateRates() {
        fun sample(hz:Int):PetLife {
            val p=PetLife("dog",Random(1));p.request("home")
            repeat(hz){p.update(1f/hz,1,1,emptyMap(),1350f,810f)}
            return p
        }
        val a=sample(60);val b=sample(120)
        assertEquals(a.x,b.x,1.5f);assertEquals(a.y,b.y,1.5f)
        assertEquals(a.state,b.state)
    }
}
