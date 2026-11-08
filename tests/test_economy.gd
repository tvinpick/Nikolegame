extends RefCounted
## Wallet, purchases (atomic + idempotent), rewards, daily chest, inventory ledger.

var runner: Object


func _e() -> Node:
	return runner.root.get_node("Economy")


func _gs() -> Node:
	return runner.root.get_node("GameState")


func before_each() -> void:
	_e().new_game()


func test_new_game_has_starters_and_coins() -> void:
	var gs := _gs()
	runner.eq(gs.coins(), int(runner.root.get_node("Content").econ("start_coins")), "start coins")
	runner.check(gs.owned_count("bed_rose") == 1, "starter bed owned")
	runner.check(gs.placed_count("bed_rose") == 1, "starter bed placed")


func test_purchase_debits_and_grants_once() -> void:
	var gs := _gs()
	gs.data["coins"] = 100
	var r: int = _e().purchase("ball_star", "tx-1")
	runner.eq(r, 0, "purchase ok")
	runner.eq(gs.coins(), 85, "coins debited")
	runner.eq(gs.owned_count("ball_star"), 1, "item granted")
	var r2: int = _e().purchase("ball_star", "tx-1")
	runner.eq(r2, 5, "same tx is a duplicate")  # Result.DUPLICATE
	runner.eq(gs.coins(), 85, "no double debit")
	runner.eq(gs.owned_count("ball_star"), 1, "no double grant")


func test_not_enough_coins() -> void:
	var gs := _gs()
	gs.data["coins"] = 3
	runner.eq(_e().purchase("bed_star"), 1, "rejected")
	runner.eq(gs.coins(), 3, "coins untouched")
	runner.eq(gs.owned_count("bed_star"), 0, "not granted")


func test_unique_ownership_categories() -> void:
	var gs := _gs()
	gs.data["coins"] = 1000
	runner.eq(_e().purchase("dress_sun"), 0, "buy dress")
	runner.eq(_e().purchase("dress_sun"), 3, "cannot buy same dress twice")
	runner.eq(_e().purchase("cat_tuxedo"), 0, "buy breed")
	runner.eq(_e().purchase("cat_tuxedo"), 3, "breed once")
	runner.eq(_e().purchase("window_main"), 4, "fixed window not for sale")


func test_purchase_persists_after_reload() -> void:
	var gs := _gs()
	var save: Node = runner.root.get_node("Save")
	gs.data["coins"] = 200
	_e().purchase("sofa_peach")
	var coins: int = gs.coins()
	gs.data = gs.default_state()
	save.load_game()
	runner.eq(gs.coins(), coins, "coins after reload")
	runner.eq(gs.owned_count("sofa_peach"), 1, "item after reload")


func test_reward_idempotent() -> void:
	var gs := _gs()
	var c0: int = gs.coins()
	runner.eq(_e().grant_reward("learn-x-1", 12, "test"), 12, "first grant")
	runner.eq(_e().grant_reward("learn-x-1", 12, "test"), 0, "second grant ignored")
	runner.eq(gs.coins(), c0 + 12, "paid once")


func test_daily_chest_once_per_day_and_rollback_guard() -> void:
	var gs := _gs()
	var day1 := 1_800_000_000  # fixed unix time
	var got: int = _e().claim_daily(day1, 1)
	runner.check(got > 0, "first chest pays")
	runner.eq(_e().claim_daily(day1 + 60, 1), 0, "same day: nothing")
	# clock rolled back by a day -> no chest, no negative effects
	var c: int = gs.coins()
	runner.eq(_e().claim_daily(day1 - 86400, 1), 0, "rollback: nothing")
	runner.eq(gs.coins(), c, "rollback didn't change coins")
	runner.check(_e().claim_daily(day1 + 86400 + 10, 1) > 0, "next day pays again")


func test_store_and_place_keep_counts() -> void:
	var gs := _gs()
	var e := _e()
	var uid := -1
	for inst in gs.data["instances"]:
		if inst["item_id"] == "sofa_mint":
			uid = int(inst["uid"])
	runner.check(e.store_instance(uid), "stored")
	runner.eq(gs.owned_count("sofa_mint"), 1, "still owned")
	runner.eq(gs.stored_count("sofa_mint"), 1, "in inventory")
	var nu: int = e.place_from_inventory("sofa_mint", Vector2(3000, 900))
	runner.check(nu > 0, "placed back")
	runner.eq(gs.stored_count("sofa_mint"), 0, "not in inventory")
	runner.eq(e.place_from_inventory("sofa_mint", Vector2(3000, 900)), -1, "cannot place what isn't stored")


func test_unique_group_replacement_returns_old_item() -> void:
	var gs := _gs()
	var e := _e()
	gs.data["coins"] = 500
	runner.eq(e.purchase("bed_star"), 0, "buy second bed")
	runner.eq(gs.stored_count("bed_star"), 1, "new bed in inventory")
	e.place_from_inventory("bed_star", Vector2(700, 830))
	runner.eq(gs.placed_count("bed_star"), 1, "new bed placed")
	runner.eq(gs.placed_count("bed_rose"), 0, "old bed removed from room")
	runner.eq(gs.owned_count("bed_rose"), 1, "old bed still owned")
	runner.eq(gs.stored_count("bed_rose"), 1, "old bed returned to inventory")


func test_consumables() -> void:
	var gs := _gs()
	gs.data["coins"] = 100
	runner.eq(_e().purchase("treat_fish"), 0, "buy treat")
	runner.eq(_e().purchase("treat_fish"), 0, "buy treat again")
	runner.eq(_e().consumable_count("treat"), 2, "two treats")
	runner.eq(_e().consume("treat"), "treat_fish", "consume")
	runner.eq(_e().consumable_count("treat"), 1, "one left")
