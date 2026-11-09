extends Node
## Loads and validates all data-driven content (catalog, interaction profiles,
## breeds, wardrobe, economy). Systems query this service — nothing hardcodes
## prices or anchors in UI or gameplay code.

const CATALOG := "res://content/items/catalog.json"
const PROFILES := "res://content/items/profiles.json"
const LAYOUT := "res://content/items/default_layout.json"
const BREEDS := "res://content/pets/breeds.json"
const WARDROBE := "res://content/girl/wardrobe.json"
const ECONOMY := "res://content/economy.json"

const VALID_PLACEMENTS := ["floor", "wall", "surface", "floor_or_surface", "flat", "fixed", "none"]
const VALID_ACTORS := ["girl", "cat", "dog", "pet"]

var items: Dictionary = {}        # item_id -> def (catalog + wardrobe items)
var profiles: Dictionary = {}     # profile_id -> profile
var breeds: Dictionary = {}       # breed_id -> breed
var wardrobe: Dictionary = {}
var economy: Dictionary = {}
var default_layout: Array = []
var zones: Array = []
var errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	reload()


func reload() -> void:
	errors.clear()
	items.clear()
	profiles.clear()
	breeds.clear()
	var cat: Dictionary = _load_json(CATALOG)
	for it in cat.get("items", []):
		items[it["item_id"]] = it
	profiles = _load_json(PROFILES).get("profiles", {})
	for b in _load_json(BREEDS).get("breeds", []):
		breeds[b["breed_id"]] = b
		# breeds are purchasable items too (category "pets_breed")
		items[b["breed_id"]] = {
			"item_id": b["breed_id"], "category": "breeds", "price": b.get("price", 0),
			"starter": b.get("starter_choice", false), "species": b["species"], "placement": "none",
			"shape": "breed", "interaction_profile": "decor", "size": {"w": 1, "d": 1, "h": 1},
		}
	wardrobe = _load_json(WARDROBE)
	for w in wardrobe.get("items", []):
		var d: Dictionary = w.duplicate(true)
		d["placement"] = "none"
		d["shape"] = "clothes"
		d["interaction_profile"] = "decor"
		d["size"] = {"w": 1, "d": 1, "h": 1}
		items[d["item_id"]] = d
	economy = _load_json(ECONOMY)
	var lay := _load_json(LAYOUT)
	default_layout = lay.get("instances", [])
	zones = lay.get("zones", [])
	validate()
	if errors.size() > 0:
		for e in errors:
			push_error("Content: " + e)


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append("missing file " + path)
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("invalid json " + path)
		return {}
	return data


func validate() -> PackedStringArray:
	for id in items.keys():
		var it: Dictionary = items[id]
		for k in ["item_id", "category", "price", "placement", "shape", "interaction_profile", "size"]:
			if not it.has(k):
				errors.append("%s: missing field %s" % [id, k])
		if int(it.get("price", 0)) < 0:
			errors.append("%s: negative price" % id)
		if it.get("placement", "") not in VALID_PLACEMENTS:
			errors.append("%s: bad placement %s" % [id, it.get("placement")])
		if not profiles.has(it.get("interaction_profile", "")):
			errors.append("%s: unknown profile %s" % [id, it.get("interaction_profile")])
		for sk in ["sprite", "sprite_worn"]:
			if it.has(sk) and not ResourceLoader.exists(it[sk]):
				errors.append("%s: missing picture %s" % [id, it[sk]])
		for a in it.get("extra_actions", []):
			var xa: String = a.get("anchor", "")
			if xa != "" and not it.get("anchors", {}).has(xa) and not profile_of(id).get("anchors", {}).has(xa):
				errors.append("%s: extra action %s refers to missing anchor %s" % [id, a.get("id"), xa])
	for pid in profiles.keys():
		var p: Dictionary = profiles[pid]
		var anchors: Dictionary = p.get("anchors", {})
		for a in p.get("actions", []):
			if a.get("actor", "") not in VALID_ACTORS:
				errors.append("profile %s: bad actor in %s" % [pid, a.get("id")])
			var an: String = a.get("anchor", "")
			if an != "" and not anchors.has(an):
				errors.append("profile %s: action %s refers to missing anchor %s" % [pid, a.get("id"), an])
			if a.has("traverse_to") and not anchors.has(a["traverse_to"]):
				errors.append("profile %s: traverse anchor missing" % pid)
	for e in default_layout:
		if not items.has(e.get("item_id", "")):
			errors.append("layout: unknown item %s" % e.get("item_id"))
	var app: Dictionary = wardrobe.get("default_appearance", {})
	for slot in ["outfit", "shoes", "hat"]:
		var v: String = app.get(slot, "none")
		if v != "none" and not items.has(v):
			errors.append("default appearance: unknown %s" % v)
	return errors


func item(id: String) -> Dictionary:
	return items.get(id, {})


func has_item(id: String) -> bool:
	return items.has(id)


func price(id: String) -> int:
	if free_shop():
		return 0
	return int(items.get(id, {}).get("price", 0))


## Real catalog price, ignoring the developer "everything free" switch.
func base_price(id: String) -> int:
	return int(items.get(id, {}).get("price", 0))


## Developer switch (dev screen): every shop item costs 0 to test each one.
func free_shop() -> bool:
	var gs := get_node_or_null("/root/GameState")
	return gs != null and bool(gs.setting("dev_free_shop", false)) and bool(gs.setting("dev_mode", false))


func profile_of(id: String) -> Dictionary:
	return profiles.get(items.get(id, {}).get("interaction_profile", "decor"), {})


func items_in_category(category: String) -> Array:
	var out: Array = []
	for id in items.keys():
		if items[id].get("category", "") == category:
			out.append(items[id])
	out.sort_custom(func(a, b): return int(a.get("price", 0)) < int(b.get("price", 0)) or (int(a.get("price", 0)) == int(b.get("price", 0)) and str(a["item_id"]) < str(b["item_id"])))
	return out


func starter_items() -> Array:
	var out: Array = []
	for id in items.keys():
		if items[id].get("starter", false) and items[id].get("category") != "breeds":
			out.append(id)
	return out


func breeds_of(species: String) -> Array:
	var out: Array = []
	for b in breeds.values():
		if b["species"] == species:
			out.append(b)
	out.sort_custom(func(a, b): return int(a.get("price", 0)) < int(b.get("price", 0)) or (int(a.get("price", 0)) == int(b.get("price", 0)) and str(a["breed_id"]) < str(b["breed_id"])))
	return out


func econ(key: String, default: Variant = null) -> Variant:
	return economy.get(key, default)


func size_of(id: String) -> Vector3:
	var s: Dictionary = items.get(id, {}).get("size", {})
	return Vector3(float(s.get("w", 1)), float(s.get("d", 1)), float(s.get("h", 1)))


## Resolve a named anchor for a concrete variant. Returns {pos: Vector2 (rel. floor), lift: float, slots: int, face: String, hidden: float}
## Variant-specific overrides in catalog "anchors" take precedence over normalized profile anchors.
func resolve_anchor(id: String, anchor_name: String) -> Dictionary:
	var it: Dictionary = items.get(id, {})
	var sz := size_of(id)
	var override: Dictionary = it.get("anchors", {}).get(anchor_name, {})
	if not override.is_empty():
		return {"pos": Vector2(float(override.get("x", 0)), float(override.get("y", 0))), "lift": float(override.get("lift", 0)), "slots": int(override.get("slots", 1)), "face": override.get("face", ""), "hidden": float(override.get("hidden", 0))}
	var p: Dictionary = profile_of(id)
	var a: Dictionary = p.get("anchors", {}).get(anchor_name, {})
	if a.is_empty():
		return {}
	return {
		"pos": Vector2(float(a.get("u", 0)) * sz.x, float(a.get("v", 0)) * sz.y),
		"lift": float(a.get("lift", 0)) * sz.z,
		"slots": int(a.get("slots", 1)),
		"face": a.get("face", ""),
		"hidden": float(a.get("hidden", 0)),
	}


func approach_points(id: String) -> Array:
	var sz := size_of(id)
	var out: Array = []
	var override: Array = items.get(id, {}).get("approach", [])
	if override.size() > 0:
		for p in override:
			out.append(Vector2(float(p[0]), float(p[1])))
		return out
	for a in profile_of(id).get("approach", []):
		out.append(Vector2(float(a.get("u", 0)) * sz.x, float(a.get("v", 0)) * sz.y))
	return out


## Actions available for the given actor kind ("girl", "cat", "dog").
## Variants may tweak profile actions ("action_overrides": {id: {...}}) and
## add their own ("extra_actions"), e.g. the front-facing heart bed.
func actions_for(id: String, actor_kind: String) -> Array:
	var out: Array = []
	var it: Dictionary = items.get(id, {})
	var ov: Dictionary = it.get("action_overrides", {})
	var all: Array = profile_of(id).get("actions", []) + it.get("extra_actions", [])
	for a in all:
		var who: String = a.get("actor", "")
		if who == actor_kind or (who == "pet" and actor_kind in ["cat", "dog"]):
			if ov.has(a.get("id", "")):
				var merged: Dictionary = a.duplicate()
				merged.merge(ov[a["id"]], true)
				out.append(merged)
			else:
				out.append(a)
	return out


func find_action(id: String, action_id: String, actor_kind: String) -> Dictionary:
	for a in actions_for(id, actor_kind):
		if a.get("id") == action_id:
			return a
	return {}


static func color(c: Variant, fallback := Color.MAGENTA) -> Color:
	if typeof(c) == TYPE_STRING:
		return Color.from_string(c, fallback)
	return fallback
