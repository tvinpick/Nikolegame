extends Node
## The ONLY place that changes coins and ownership. UI asks; Economy decides.
## Every purchase = check -> debit -> grant -> atomic save, in one call.
## Rewards are idempotent by reward_id (double signals / taps never pay twice).

signal purchase_done(item_id: String)
signal reward_granted(amount: int, reason: String)

enum Result { OK, NOT_ENOUGH_COINS, UNKNOWN_ITEM, ALREADY_OWNED, NOT_FOR_SALE, DUPLICATE }

const UNIQUE_OWN_CATEGORIES := ["breeds", "clothes_girl", "clothes_pet", "wallfloor", "themes"]


func new_game() -> void:
	var d: Dictionary = GameState.default_state()
	GameState.data = d
	d["coins"] = int(Content.econ("start_coins", 50))
	for id in Content.starter_items():
		d["owned"][id] = 1
	# starter layout
	for e in Content.default_layout:
		var inst := {"uid": GameState.new_uid(), "item_id": e["item_id"], "x": float(e["x"]), "y": float(e["y"]), "flip": false, "state": default_instance_state(e["item_id"])}
		d["instances"].append(inst)
	var app: Dictionary = Content.wardrobe.get("default_appearance", {}).duplicate(true)
	d["girl"]["appearance"] = app
	d["pets"]["cat"]["accessory"] = app.get("pet_accessory", {}).get("cat", "none")
	d["pets"]["dog"]["accessory"] = app.get("pet_accessory", {}).get("dog", "none")
	Diag.event("new_game", {"coins": d["coins"]})


func default_instance_state(item_id: String) -> Dictionary:
	var it := Content.item(item_id)
	var s := {}
	match it.get("interaction_profile", ""):
		"bowl_food":
			s["food"] = 0
			s["treat"] = 0
		"bowl_water":
			s["water"] = 0
	if it.has("device"):
		s["on"] = it["device"] == "clock"
	return s


func can_buy(item_id: String) -> int:
	if not Content.has_item(item_id):
		return Result.UNKNOWN_ITEM
	var it := Content.item(item_id)
	if it.get("category") == "fixed":
		return Result.NOT_FOR_SALE
	if it.get("category") in UNIQUE_OWN_CATEGORIES and GameState.owned_count(item_id) > 0:
		return Result.ALREADY_OWNED
	if GameState.coins() < Content.price(item_id):
		return Result.NOT_ENOUGH_COINS
	return Result.OK


## Atomic purchase. tx_id makes repeated taps idempotent (same tx_id -> DUPLICATE).
func purchase(item_id: String, tx_id: String = "") -> int:
	if tx_id == "":
		tx_id = "%s-%d-%d" % [item_id, Time.get_ticks_usec(), randi()]
	for t in GameState.data.get("tx_log", []):
		if t.get("tx") == tx_id:
			return Result.DUPLICATE
	var r := can_buy(item_id)
	if r != Result.OK:
		Diag.event("purchase_rejected", {"item": item_id, "reason": r})
		return r
	var price := Content.price(item_id)
	var d: Dictionary = GameState.data
	var before := int(d["coins"])
	d["coins"] = before - price
	var it := Content.item(item_id)
	if it.get("consumable", false):
		d["consumables"][item_id] = int(d["consumables"].get(item_id, 0)) + 1
	else:
		d["owned"][item_id] = GameState.owned_count(item_id) + 1
	var log: Array = d.get("tx_log", [])
	log.append({"tx": tx_id, "item": item_id, "price": price, "t": int(Time.get_unix_time_from_system())})
	while log.size() > 50:
		log.pop_front()
	d["tx_log"] = log
	var ok := Save.save_now()
	if not ok:
		# disk failed: roll back memory so UI never shows a phantom item
		d["coins"] = before
		if it.get("consumable", false):
			d["consumables"][item_id] = int(d["consumables"][item_id]) - 1
		else:
			d["owned"][item_id] = GameState.owned_count(item_id) - 1
		log.pop_back()
		Diag.event("purchase_failed_save", {"item": item_id})
		return Result.NOT_FOR_SALE
	Diag.event("purchase", {"item": item_id, "price": price})
	GameState.coins_changed.emit(GameState.coins())
	GameState.inventory_changed.emit()
	purchase_done.emit(item_id)
	AudioSvc.sfx("coin")
	return Result.OK


## Idempotent reward. Returns granted amount (0 if reward_id already paid).
func grant_reward(reward_id: String, amount: int, reason: String) -> int:
	var l: Dictionary = GameState.data["learning"]
	var paid: Array = l.get("rewarded_sessions", [])
	if reward_id in paid or amount <= 0:
		return 0
	paid.append(reward_id)
	var limit := int(Content.econ("rewarded_history_limit", 200))
	while paid.size() > limit:
		paid.pop_front()
	l["rewarded_sessions"] = paid
	GameState.data["coins"] = GameState.coins() + amount
	Save.save_now()
	Diag.event("reward", {"amount": amount, "reason": reason})
	GameState.coins_changed.emit(GameState.coins())
	reward_granted.emit(amount, reason)
	return amount


func consume(item_kind: String) -> String:
	## Uses one consumable of a kind (e.g. "treat"). Returns item_id used or "".
	var cons: Dictionary = GameState.data["consumables"]
	for id in cons.keys():
		if int(cons[id]) > 0 and Content.item(id).get("consumable_kind", "") == item_kind:
			cons[id] = int(cons[id]) - 1
			Save.request_save("consume")
			GameState.inventory_changed.emit()
			return id
	return ""


func consumable_count(kind: String) -> int:
	var n := 0
	var cons: Dictionary = GameState.data["consumables"]
	for id in cons.keys():
		if Content.item(id).get("consumable_kind", "") == kind:
			n += int(cons[id])
	return n


# ------------------------------------------------------------- daily chest

static func day_key(unix: int) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(unix + _tz_offset_sec())
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


static func _tz_offset_sec() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


## Returns {available: bool, reason: String}. Guards against clock rollback:
## if system time is earlier than the latest time we've ever seen, no chest.
func daily_status(now_unix: int = -1) -> Dictionary:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())
	var daily: Dictionary = GameState.data["daily"]
	var max_seen := int(daily.get("max_seen_unix", 0))
	if max_seen > 0 and now_unix + 600 < max_seen:
		return {"available": false, "reason": "clock_rollback"}
	var today := day_key(now_unix)
	if daily.get("last_claim_day", "") == today:
		return {"available": false, "reason": "claimed"}
	if daily.get("last_claim_day", "") != "" and today < str(daily["last_claim_day"]):
		return {"available": false, "reason": "clock_rollback"}
	return {"available": true, "reason": ""}


func note_time_seen(now_unix: int = -1) -> void:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())
	var daily: Dictionary = GameState.data["daily"]
	daily["max_seen_unix"] = max(int(daily.get("max_seen_unix", 0)), now_unix)


func claim_daily(now_unix: int = -1, rng_seed: int = -1) -> int:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())
	var st := daily_status(now_unix)
	if not st["available"]:
		return 0
	var cfg: Dictionary = Content.econ("daily_chest", {"min": 5, "max": 10})
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	var amount := rng.randi_range(int(cfg["min"]), int(cfg["max"]))
	var daily: Dictionary = GameState.data["daily"]
	daily["last_claim_day"] = day_key(now_unix)
	daily["claims"] = int(daily.get("claims", 0)) + 1
	note_time_seen(now_unix)
	return grant_reward("daily-" + daily["last_claim_day"], amount, "daily_chest")


# ------------------------------------------------------------- placement ledger

## Place a stored item. Returns uid or -1 if nothing stored.
func place_from_inventory(item_id: String, pos: Vector2, host_uid: int = -1) -> int:
	if GameState.stored_count(item_id) <= 0:
		return -1
	var inst := {"uid": GameState.new_uid(), "item_id": item_id, "x": pos.x, "y": pos.y, "flip": false, "state": default_instance_state(item_id)}
	if host_uid >= 0:
		inst["host_uid"] = host_uid
	GameState.data["instances"].append(inst)
	# unique group: displaced instance goes back to inventory (stays owned)
	var group: String = Content.item(item_id).get("unique_group", "")
	if group != "":
		for other in GameState.data["instances"].duplicate():
			if int(other["uid"]) != int(inst["uid"]) and Content.item(other["item_id"]).get("unique_group", "") == group:
				store_instance(int(other["uid"]), false)
	Diag.event("place", {"item": item_id, "uid": inst["uid"]})
	Save.request_save("place")
	GameState.inventory_changed.emit()
	return int(inst["uid"])


## Move a placed instance back into the inventory (never deletes ownership).
func store_instance(uid: int, emit := true) -> bool:
	var arr: Array = GameState.data["instances"]
	for i in arr.size():
		if int(arr[i]["uid"]) == uid:
			if Content.item(arr[i]["item_id"]).get("placement") == "fixed":
				return false
			var removed: Dictionary = arr[i]
			arr.remove_at(i)
			# items standing on it go to the inventory too
			for other in arr.duplicate():
				if int(other.get("host_uid", -1)) == uid:
					store_instance(int(other["uid"]), false)
			Diag.event("store", {"item": removed["item_id"], "uid": uid})
			Save.request_save("store")
			if emit:
				GameState.inventory_changed.emit()
			return true
	return false


func stored_items() -> Array:
	var out: Array = []
	for id in GameState.data["owned"].keys():
		var n := GameState.stored_count(id)
		var it := Content.item(id)
		if n > 0 and it.get("placement", "none") not in ["none", "fixed"]:
			out.append({"item_id": id, "count": n})
	return out
