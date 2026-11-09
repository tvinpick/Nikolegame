extends Node
## Single shared game progress (one child profile). Pure data + signals.
## Mutations that matter (coins, ownership) must go through Economy/Inventory.

signal coins_changed(coins: int)
signal inventory_changed()
signal appearance_changed()
signal pets_changed()
signal world_changed()
signal settings_changed()

const SCHEMA_VERSION := 4

var data: Dictionary = {}
var is_test_build: bool = false


func _ready() -> void:
	is_test_build = OS.has_feature("test_build")
	data = default_state()


static func default_state() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"created_unix": int(Time.get_unix_time_from_system()),
		"saved_unix": 0,
		"last_seen_unix": 0,
		"coins": 0,
		"owned": {},              # item_id -> count
		"consumables": {},        # item_id -> count (treats)
		"instances": [],          # placed item instances
		"next_uid": 1,
		"surfaces": {"wall": "wall_pink_dots", "floor": "floor_oak", "landscape": "theme_mountains"},
		"girl": {"appearance": {}, "pos": [2880, 900]},
		"pets": {
			"cat": {"breed": "", "needs": {"satiety": 80.0, "energy": 80.0, "mood": 80.0, "cleanliness": 80.0}, "accessory": "none", "pos": [2000, 950]},
			"dog": {"breed": "", "needs": {"satiety": 80.0, "energy": 80.0, "mood": 80.0, "cleanliness": 80.0}, "accessory": "collar_red", "pos": [2500, 980]},
		},
		"world": {"auto": true, "season": "autumn", "time_of_day": "day", "weather": "sun", "auto_clock": 0.35},
		"settings": {"ui_lang": "ru", "learn_lang": "ru", "vol_music": 0.6, "vol_sfx": 0.8, "vol_voice": 0.9, "dev_mode": false, "onboarding_done": false, "tutorial_done": false, "voice_enabled": true},
		"learning": {
			"levels": {"math": 1, "letters": 1, "shapes": 1, "colors": 1, "logic": 1},
			"limits": {"math": [1, 3], "letters": [1, 3], "shapes": [1, 3], "colors": [1, 3], "logic": [1, 3]},
			"stats": {},              # category -> {sessions, exercises, first_try, attempts}
			"recent": {},             # category -> array of last results (bool) for adaptivity
			"rewarded_sessions": [],
			"session_counter": 0,
		},
		"daily": {"last_claim_day": "", "max_seen_unix": 0, "claims": 0},
		"tx_log": [],             # last purchase transactions (for audit/idempotency)
	}


func read(path: String, default: Variant = null) -> Variant:
	var cur: Variant = data
	for part in path.split("/"):
		if typeof(cur) != TYPE_DICTIONARY or not cur.has(part):
			return default
		cur = cur[part]
	return cur


func write(path: String, value: Variant) -> void:
	var parts := path.split("/")
	var cur: Dictionary = data
	for i in parts.size() - 1:
		if not cur.has(parts[i]) or typeof(cur[parts[i]]) != TYPE_DICTIONARY:
			cur[parts[i]] = {}
		cur = cur[parts[i]]
	cur[parts[parts.size() - 1]] = value


func setting(key: String, default: Variant = null) -> Variant:
	return data.get("settings", {}).get(key, default)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	settings_changed.emit()


func coins() -> int:
	return int(data.get("coins", 0))


func owned_count(item_id: String) -> int:
	return int(data.get("owned", {}).get(item_id, 0))


func placed_count(item_id: String) -> int:
	var n := 0
	for inst in data.get("instances", []):
		if inst.get("item_id") == item_id:
			n += 1
	return n


func stored_count(item_id: String) -> int:
	return max(0, owned_count(item_id) - placed_count(item_id))


func new_uid() -> int:
	var u: int = int(data.get("next_uid", 1))
	data["next_uid"] = u + 1
	return u


func instance_by_uid(uid: int) -> Dictionary:
	for inst in data.get("instances", []):
		if int(inst.get("uid", -1)) == uid:
			return inst
	return {}


func appearance() -> Dictionary:
	return data["girl"]["appearance"]


func pet(kind: String) -> Dictionary:
	return data["pets"][kind]
