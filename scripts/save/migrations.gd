class_name SaveMigrations
extends RefCounted
## Versioned save migrations. Each step upgrades exactly one schema version.
## Keep old steps forever: a child's save from any released build must load.

const CURRENT := 5


static func migrate(d: Dictionary) -> Dictionary:
	var v: int = int(d.get("schema_version", 1))
	if v > CURRENT:
		# Save from a newer build — keep data, but mark so we don't downgrade-write blindly.
		d["_from_newer_schema"] = v
		return d
	while v < CURRENT:
		match v:
			1:
				d = _v1_to_v2(d)
			2:
				d = _v2_to_v3(d)
			3:
				d = _v3_to_v4(d)
			4:
				d = _v4_to_v5(d)
		v += 1
		d["schema_version"] = v
	return d


## v1 (prototype): "money" + "furniture" list of {id, pos:[x,y]}.
static func _v1_to_v2(d: Dictionary) -> Dictionary:
	if d.has("money") and not d.has("coins"):
		d["coins"] = int(d["money"])
		d.erase("money")
	if d.has("furniture") and not d.has("instances"):
		var out: Array = []
		var uid := 1
		for f in d["furniture"]:
			var pos: Array = f.get("pos", [0, 0])
			out.append({"uid": uid, "item_id": f.get("id", ""), "x": float(pos[0]), "y": float(pos[1]), "flip": false, "state": {}})
			uid += 1
		d["instances"] = out
		d["next_uid"] = uid
		d.erase("furniture")
	if not d.has("consumables"):
		d["consumables"] = {}
	if not d.has("surfaces"):
		d["surfaces"] = {"wall": "wall_pink_dots", "floor": "floor_oak", "landscape": "theme_mountains"}
	return d


## v2 -> v3: adult difficulty limits + time-manipulation guard for the daily chest.
static func _v2_to_v3(d: Dictionary) -> Dictionary:
	var l: Dictionary = d.get("learning", {})
	if not l.has("limits"):
		l["limits"] = {"math": [1, 3], "letters": [1, 3], "shapes": [1, 3], "colors": [1, 3], "logic": [1, 3]}
	d["learning"] = l
	var daily: Dictionary = d.get("daily", {})
	if not daily.has("max_seen_unix"):
		daily["max_seen_unix"] = int(d.get("saved_unix", 0))
	d["daily"] = daily
	return d


## v3 -> v4: starter furniture regrouped into zones (bedroom, pets, living,
## kitchen, study). Only items still at their OLD default spot are moved, so
## anything the child arranged herself stays where it is.
static func _v3_to_v4(d: Dictionary) -> Dictionary:
	var f := FileAccess.open("res://content/items/default_layout.json", FileAccess.READ)
	if f == null:
		return d
	var lay: Variant = JSON.parse_string(f.get_as_text())
	if typeof(lay) != TYPE_DICTIONARY:
		return d
	var old := {}
	for e in lay.get("previous_layout_v1", []):
		old[e["item_id"]] = Vector2(float(e["x"]), float(e["y"]))
	var neu := {}
	for e in lay.get("instances", []):
		neu[e["item_id"]] = Vector2(float(e["x"]), float(e["y"]))
	var moved := 0
	for inst in d.get("instances", []):
		var id: String = inst.get("item_id", "")
		if old.has(id) and neu.has(id) and inst.get("host_uid", -1) == -1:
			var p := Vector2(float(inst.get("x", 0)), float(inst.get("y", 0)))
			if p.distance_to(old[id]) < 1.0:
				inst["x"] = neu[id].x
				inst["y"] = neu[id].y
				moved += 1
	d["_zones_migrated"] = moved
	return d


## v4 -> v5: starter furniture replaced by the picture versions (bigger), so
## pet-corner items still at their v4 default spot move to the new spot, and
## the new free starters (dog house, chair) are added and placed.
static func _v4_to_v5(d: Dictionary) -> Dictionary:
	var f := FileAccess.open("res://content/items/default_layout.json", FileAccess.READ)
	if f == null:
		return d
	var lay: Variant = JSON.parse_string(f.get_as_text())
	if typeof(lay) != TYPE_DICTIONARY:
		return d
	var old := {}
	for e in lay.get("previous_layout_v4", []):
		old[e["item_id"]] = Vector2(float(e["x"]), float(e["y"]))
	var neu := {}
	for e in lay.get("instances", []):
		neu[e["item_id"]] = Vector2(float(e["x"]), float(e["y"]))
	var insts: Array = d.get("instances", [])
	var present := {}
	for inst in insts:
		var id: String = inst.get("item_id", "")
		present[id] = true
		if old.has(id) and neu.has(id) and inst.get("host_uid", -1) == -1:
			var p := Vector2(float(inst.get("x", 0)), float(inst.get("y", 0)))
			if p.distance_to(old[id]) < 1.0:
				inst["x"] = neu[id].x
				inst["y"] = neu[id].y
	var owned: Dictionary = d.get("owned", {})
	var top := int(d.get("next_uid", 1))
	for inst in insts:
		top = maxi(top, int(inst.get("uid", 0)) + 1)
	d["next_uid"] = top
	for id in lay.get("new_starters_v5", []):
		if present.has(id) or not neu.has(id):
			continue
		owned[id] = max(1, int(owned.get(id, 0)))
		var uid := int(d.get("next_uid", 1))
		d["next_uid"] = uid + 1
		insts.append({"uid": uid, "item_id": id, "x": neu[id].x, "y": neu[id].y, "flip": false, "state": {}})
	d["owned"] = owned
	d["instances"] = insts
	return d


## Fill keys missing in `loaded` from `defaults` (recursively for dictionaries).
static func deep_fill(loaded: Dictionary, defaults: Dictionary) -> Dictionary:
	for k in defaults.keys():
		if not loaded.has(k):
			loaded[k] = defaults[k].duplicate(true) if typeof(defaults[k]) in [TYPE_DICTIONARY, TYPE_ARRAY] else defaults[k]
		elif typeof(defaults[k]) == TYPE_DICTIONARY and typeof(loaded[k]) == TYPE_DICTIONARY:
			# only recurse into "structural" dictionaries, not id-keyed maps
			if k in ["owned", "consumables", "stats", "recent"]:
				continue
			loaded[k] = deep_fill(loaded[k], defaults[k])
	return loaded


## Structural validation; returns list of problems (empty = valid).
static func validate(d: Dictionary) -> PackedStringArray:
	var p := PackedStringArray()
	if typeof(d.get("coins")) not in [TYPE_INT, TYPE_FLOAT]:
		p.append("coins not a number")
	elif int(d["coins"]) < 0:
		p.append("negative coins")
	if typeof(d.get("owned")) != TYPE_DICTIONARY:
		p.append("owned missing")
	if typeof(d.get("instances")) != TYPE_ARRAY:
		p.append("instances missing")
	else:
		var uids := {}
		for inst in d["instances"]:
			if typeof(inst) != TYPE_DICTIONARY or not inst.has("uid") or not inst.has("item_id"):
				p.append("bad instance")
				continue
			if uids.has(int(inst["uid"])):
				p.append("duplicate uid %d" % int(inst["uid"]))
			uids[int(inst["uid"])] = true
	if typeof(d.get("pets")) != TYPE_DICTIONARY:
		p.append("pets missing")
	if typeof(d.get("settings")) != TYPE_DICTIONARY:
		p.append("settings missing")
	return p
