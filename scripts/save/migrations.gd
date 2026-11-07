class_name SaveMigrations
extends RefCounted
## Versioned save migrations. Each step upgrades exactly one schema version.
## Keep old steps forever: a child's save from any released build must load.

const CURRENT := 3


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
