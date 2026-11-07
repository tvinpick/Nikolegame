class_name PetsScreen
extends Screen
## Pet collection: change breed/look of the existing cat or dog (owned breeds
## free to switch, others bought with coins) and pet accessories.

var species := "cat"
var grid: GridContainer
var top: HBoxContainer
var onboarding := false   # first launch: free starter choice


func _init() -> void:
	screen_name = "pets"
	title_key = "title_pets"


func build() -> void:
	top = UIKit.hbox(16)
	body.add_child(top)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	sc.add_child(grid)
	body.add_child(sc)
	_fill()


func _fill() -> void:
	for c in top.get_children():
		c.queue_free()
	if not onboarding:
		top.add_child(UIKit.icon_button("cat", _set_species.bind("cat"), UIKit.PINK if species == "cat" else Color("#e9c9d5"), 100))
		top.add_child(UIKit.icon_button("dog", _set_species.bind("dog"), UIKit.PINK if species == "dog" else Color("#e9c9d5"), 100))
	else:
		top.add_child(UIKit.label(Loc.t("onb_choose_cat" if species == "cat" else "onb_choose_dog"), 40, UIKit.INK, true))
	for c in grid.get_children():
		c.queue_free()
	var cur: String = GameState.pet(species).get("breed", "")
	for b in Content.breeds_of(species):
		var id: String = b["breed_id"]
		if onboarding and not b.get("starter_choice", false):
			continue
		var owned: bool = GameState.owned_count(id) > 0 or (onboarding and b.get("starter_choice", false))
		var badge := "" if owned else Screen.price_badge(id)
		grid.add_child(Screen.item_card(id, _pick_breed.bind(id), badge, id == cur and not onboarding, 220, 220))
	if not onboarding:
		var acc_label := UIKit.label(Loc.t("pet_accessories"), 30, UIKit.INK, true)
		grid.add_child(acc_label)
		for it in Content.items_in_category("clothes_pet"):
			var aid: String = it["item_id"]
			if GameState.owned_count(aid) > 0:
				grid.add_child(Screen.item_card(aid, _pick_acc.bind(aid), "", GameState.pet(species).get("accessory") == aid, 220, 220))
		grid.add_child(Screen.item_card("collar_red", _pick_acc.bind("none"), "—", false, 220, 220))


func _set_species(s: String) -> void:
	species = s
	_fill()


func _pick_breed(id: String) -> void:
	if onboarding:
		GameState.data["owned"][id] = 1
		GameState.pet(species)["breed"] = id
		var pet: Pet = room.cat if species == "cat" else room.dog
		if pet:
			pet.set_breed(id)
		AudioSvc.sfx("meow" if species == "cat" else "bark")
		if species == "cat":
			species = "dog"
			_fill()
		else:
			Save.save_now()
			close()
		return
	if GameState.owned_count(id) <= 0:
		var r := Economy.purchase(id)
		if r == Economy.Result.NOT_ENOUGH_COINS:
			hud.show_toast("msg_not_enough", [Content.price(id) - GameState.coins()])
			return
		if r != Economy.Result.OK:
			return
		AudioSvc.sfx("sparkle")
	var p: Pet = room.cat if species == "cat" else room.dog
	p.set_breed(id)
	GameState.pet(species)["breed"] = id
	GameState.pets_changed.emit()
	Diag.event("breed_change", {"pet": species, "breed": id})
	Save.request_save("breed")
	_fill()


func _pick_acc(id: String) -> void:
	var p: Pet = room.cat if species == "cat" else room.dog
	p.set_accessory(id)
	GameState.pet(species)["accessory"] = id
	Save.request_save("pet_acc")
	_fill()
