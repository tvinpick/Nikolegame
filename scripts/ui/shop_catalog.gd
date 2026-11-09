class_name ShopCatalog
extends RefCounted
## Shop structure: 4 big sections (furniture, clothes, pets, room), each with
## picture sub-sections. Every tab is shown as a picture of a real item, so a
## child who can't read yet still finds beds, chairs, dresses, cats...
## "rep" = the item drawn on the tab; "rule" = which catalog items belong there.

const SECTIONS := [
	{"id": "furniture", "color": "#f7a8c4", "pic": "tab_sofa", "subs": [
		{"id": "beds", "pic": "tab_bed", "rep": "bed_heart", "rule": {"profile": ["bed"]}},
		{"id": "sofas", "pic": "tab_sofa", "rep": "sofa_mint", "rule": {"profile": ["sofa"]}},
		{"id": "chairs", "pic": "tab_chair", "rep": "chair_daisy", "rule": {"profile": ["seat"]}},
		{"id": "tables", "pic": "tab_table", "rep": "table_small", "rule": {"profile": ["desk", "dining"]}},
		{"id": "wardrobes", "pic": "tab_wardrobe", "rep": "wardrobe_white", "rule": {"profile": ["wardrobe", "surface", "mirror"]}},
		{"id": "lamps", "pic": "tab_lamp", "rep": "lamp_floor", "rule": {"cat": ["devices"]}},
	]},
	{"id": "clothes", "color": "#c9a8ec", "pic": "tab_dress", "subs": [
		{"id": "outfits", "pic": "dress_c", "rep": "princess_gown", "rule": {"cat": ["clothes_girl"], "slot": ["outfit"]}},
		{"id": "shoes", "icon": "pic_shoe", "rep": "boots_red", "rule": {"cat": ["clothes_girl"], "slot": ["shoes"]}},
		{"id": "hats", "pic": "crown", "rep": "crown_gold", "rule": {"cat": ["clothes_girl"], "slot": ["hat"]}},
		{"id": "accessories", "pic": "glasses", "rep": "purse_heart", "rule": {"cat": ["clothes_girl"], "slot": ["accessory"]}},
		{"id": "earrings", "pic": "earrings", "rep": "earrings_heart", "rule": {"cat": ["clothes_girl"], "slot": ["earrings"]}},
		{"id": "makeup", "pic": "lips", "rep": "lips_rose", "rule": {"cat": ["clothes_girl"], "slot": ["makeup"]}},
		{"id": "pet_clothes", "pic": "bow", "rep": "bow_pink_pet", "rule": {"cat": ["clothes_pet"]}},
	]},
	{"id": "pets", "color": "#f6c56a", "pic": "tab_pets", "subs": [
		{"id": "cats", "rep": "cat_ginger", "rule": {"cat": ["breeds"], "species": "cat"}},
		{"id": "dogs", "rep": "dog_corgi", "rule": {"cat": ["breeds"], "species": "dog"}},
		{"id": "pet_houses", "pic": "tab_doghouse", "rep": "doghouse_lilac", "rule": {"profile": ["pet_house", "pet_bed"]}},
		{"id": "pet_play", "pic": "tab_toys", "rep": "scratcher_post", "rule": {"any": [{"cat": ["toys"]}, {"profile": ["scratcher", "tunnel"]}]}},
		{"id": "pet_care", "pic": "tab_bowl", "rep": "bowl_food_star", "rule": {"cat": ["care"]}},
	]},
	{"id": "room", "color": "#8fd3c0", "pic": "tab_window", "subs": [
		{"id": "walls", "rep": "wall_stars", "rule": {"shape": ["swatch_wall"]}},
		{"id": "floors", "rep": "floor_cherry", "rule": {"shape": ["swatch_floor"]}},
		{"id": "views", "pic": "tab_window", "rep": "theme_sea", "rule": {"cat": ["themes"]}},
		{"id": "rugs", "pic": "tab_rug", "rep": "rug_round", "rule": {"shape": ["rug"]}},
		{"id": "plants", "pic": "tab_plant", "rep": "plant_pot", "rule": {"shape": ["plant"]}},
		{"id": "decor", "pic": "tab_picture", "rep": "picture_cat", "rule": {"cat": ["decor"], "shape": ["picture", "garland"]}},
	]},
]


static func pic_tex(name: String) -> Texture2D:
	var path := "res://assets/ui/icons/%s.png" % name
	return load(path) if name != "" and ResourceLoader.exists(path) else null


static func section(id: String) -> Dictionary:
	for s in SECTIONS:
		if s["id"] == id:
			return s
	return SECTIONS[0]


static func sub(sec_id: String, sub_id: String) -> Dictionary:
	for s in section(sec_id)["subs"]:
		if s["id"] == sub_id:
			return s
	return section(sec_id)["subs"][0]


static func matches(it: Dictionary, rule: Dictionary) -> bool:
	if rule.has("any"):
		for r in rule["any"]:
			if matches(it, r):
				return true
		return false
	if it.get("category", "") == "fixed":
		return false
	if rule.has("cat") and it.get("category", "") not in rule["cat"]:
		return false
	if rule.has("profile") and it.get("interaction_profile", "") not in rule["profile"]:
		return false
	if it.get("category", "") == "breeds" and not rule.has("cat"):
		return false
	if rule.has("shape") and it.get("shape", "") not in rule["shape"]:
		return false
	if rule.has("slot") and it.get("slot", "") not in rule["slot"]:
		return false
	if rule.has("species") and it.get("species", "") != rule["species"]:
		return false
	return true


## Items of a sub-section, cheapest first (free/starter things first).
static func items_in(sec_id: String, sub_id: String) -> Array:
	var rule: Dictionary = sub(sec_id, sub_id)["rule"]
	var out: Array = []
	for id in Content.items.keys():
		var it: Dictionary = Content.items[id]
		if matches(it, rule):
			out.append(it)
	out.sort_custom(func(a, b): return Content.base_price(a["item_id"]) < Content.base_price(b["item_id"]) or (Content.base_price(a["item_id"]) == Content.base_price(b["item_id"]) and str(a["item_id"]) < str(b["item_id"])))
	return out


## Where an item lives in the shop: [section, sub] (or ["", ""] if nowhere).
static func find_place(it: Dictionary) -> Array:
	for s in SECTIONS:
		for sb in s["subs"]:
			if matches(it, sb["rule"]):
				return [s["id"], sb["id"]]
	return ["", ""]
