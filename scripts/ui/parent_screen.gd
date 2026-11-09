class_name ParentScreen
extends Screen
## Adult area (behind ParentGate): learning progress, difficulty limits,
## volumes, languages, backup export/import, developer mode, low-detail mode.

signal open_dev()
signal language_changed()

var section := "progress"
var content: VBoxContainer
var _pending_import: Dictionary = {}


func _init() -> void:
	screen_name = "parent"
	title_key = "title_parent"


func build() -> void:
	# quick switch for grown-ups: everything in the shop costs 0 (to try every item)
	var free_on := bool(GameState.setting("dev_free_shop", false))
	var fb := UIKit.button(Loc.t("dev_free_shop_on") if free_on else Loc.t("dev_free_shop_off"), _toggle_free, UIKit.MINT if free_on else Color("#d9cfd3"), 520)
	fb.name = "free_shop"
	body.add_child(fb)
	var tabs := UIKit.hbox(10)
	for s in ["progress", "difficulty", "sound", "language", "backup", "developer"]:
		var b := UIKit.button(Loc.t("parent_" + s), _set_section.bind(s), UIKit.PINK if s == section else Color("#d8b9c6"))
		b.add_theme_font_size_override("font_size", 24)
		tabs.add_child(b)
	body.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content = UIKit.vbox(18)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	body.add_child(sc)
	_fill()


func _toggle_free() -> void:
	GameState.set_setting("dev_free_shop", not bool(GameState.setting("dev_free_shop", false)))
	Diag.event("free_shop", {"on": GameState.setting("dev_free_shop")})
	Save.request_save("free_shop")
	_set_section(section)


func _set_section(s: String) -> void:
	section = s
	for c in body.get_children():
		c.queue_free()
	build()


func _fill() -> void:
	match section:
		"progress":
			var sm: Dictionary = Learning.summary()
			for cat in ExerciseGen.CATEGORIES:
				var e: Dictionary = sm[cat]
				var pct := 0 if int(e["exercises"]) == 0 else int(100.0 * int(e["first_try"]) / int(e["exercises"]))
				content.add_child(UIKit.label(Loc.t("progress_line", [Loc.t("learn_" + cat), int(e["level"]), int(e["sessions"]), int(e["exercises"]), pct]), 28))
			content.add_child(UIKit.label(Loc.t("progress_note"), 24, Color("#8a7480"), false, true))
		"difficulty":
			for cat in ExerciseGen.CATEGORIES:
				var lim: Array = Learning.limits_of(cat)
				var h := UIKit.hbox(14)
				var l := UIKit.label(Loc.t("learn_" + cat), 30, UIKit.INK, true)
				l.custom_minimum_size = Vector2(260, 0)
				h.add_child(l)
				h.add_child(UIKit.label(Loc.t("diff_min"), 26))
				for lv in [1, 2, 3]:
					h.add_child(UIKit.button(str(lv), _set_lim.bind(cat, lv, lim[1]), UIKit.MINT if lim[0] == lv else Color("#d9cfd3"), 70))
				h.add_child(UIKit.label(Loc.t("diff_max"), 26))
				for lv in [1, 2, 3]:
					h.add_child(UIKit.button(str(lv), _set_lim.bind(cat, min(lim[0], lv), lv), UIKit.SKY if lim[1] == lv else Color("#d9cfd3"), 70))
				content.add_child(h)
		"sound":
			for k in ["vol_music", "vol_sfx", "vol_voice"]:
				var h2 := UIKit.hbox(14)
				var l2 := UIKit.label(Loc.t(k), 30)
				l2.custom_minimum_size = Vector2(300, 0)
				h2.add_child(l2)
				var sl := HSlider.new()
				sl.min_value = 0
				sl.max_value = 1
				sl.step = 0.05
				sl.value = float(GameState.setting(k, 0.7))
				sl.custom_minimum_size = Vector2(600, 60)
				sl.value_changed.connect(_on_vol.bind(k))
				h2.add_child(sl)
				content.add_child(h2)
			var vt := CheckButton.new()
			vt.text = Loc.t("voice_enabled")
			vt.button_pressed = bool(GameState.setting("voice_enabled", true))
			vt.toggled.connect(func(on: bool):
				GameState.set_setting("voice_enabled", on)
				Save.request_save("settings"))
			content.add_child(vt)
			content.add_child(UIKit.label(Loc.t("tts_note") if not AudioSvc.tts_available else Loc.t("tts_ok"), 24, Color("#8a7480"), false, true))
			var ld := CheckButton.new()
			ld.text = Loc.t("low_detail")
			ld.button_pressed = bool(GameState.setting("low_detail", false))
			ld.toggled.connect(func(on: bool):
				GameState.set_setting("low_detail", on)
				room.set_low_detail(on)
				Save.request_save("settings"))
			content.add_child(ld)
		"language":
			content.add_child(UIKit.label(Loc.t("ui_language"), 32, UIKit.INK, true))
			var h3 := UIKit.hbox(14)
			for lang in ["ru", "de"]:
				h3.add_child(UIKit.button(Loc.t("lang_" + lang), _set_ui_lang.bind(lang), UIKit.MINT if Loc.ui_lang == lang else Color("#d9cfd3"), 260))
			content.add_child(h3)
			content.add_child(UIKit.label(Loc.t("learn_language"), 32, UIKit.INK, true))
			var h4 := UIKit.hbox(14)
			for lang in ["ru", "de"]:
				h4.add_child(UIKit.button(Loc.t("lang_" + lang), _set_learn_lang.bind(lang), UIKit.SKY if Loc.learn_lang == lang else Color("#d9cfd3"), 260))
			content.add_child(h4)
		"backup":
			content.add_child(UIKit.label(Loc.t("backup_info"), 26, UIKit.INK, false, true))
			content.add_child(UIKit.button(Loc.t("backup_export"), _export, UIKit.MINT))
			content.add_child(UIKit.button(Loc.t("backup_import"), _import, UIKit.SKY))
			if not _pending_import.is_empty():
				content.add_child(UIKit.label(Loc.t("backup_confirm", [_pending_import["created_text"], _pending_import["coins"]]), 28, Color("#c25a78")))
				content.add_child(UIKit.button(Loc.t("backup_restore_yes"), _restore, Color("#e8a0a0")))
		"developer":
			content.add_child(UIKit.label(Loc.t("dev_info"), 26, UIKit.INK, false, true))
			var dv := CheckButton.new()
			dv.text = Loc.t("dev_enable")
			dv.button_pressed = bool(GameState.setting("dev_mode", false)) or GameState.is_test_build
			dv.disabled = GameState.is_test_build
			dv.toggled.connect(func(on: bool):
				GameState.set_setting("dev_mode", on)
				Save.request_save("dev_mode")
				_set_section("developer"))
			content.add_child(dv)
			if Diag.dev_allowed():
				content.add_child(UIKit.button(Loc.t("dev_open"), func():
					close()
					open_dev.emit(), UIKit.LILAC))
			var tut := UIKit.button(Loc.t("tutorial_again"), func():
				GameState.set_setting("tutorial_done", false)
				Save.request_save("tutorial")
				hud.show_toast("tutorial_next_start"), Color("#d8b9c6"))
			content.add_child(tut)
	content.add_child(UIKit.label("v%s · Godot %s%s" % [ProjectSettings.get_setting("application/config/version", "0"), Engine.get_version_info().get("string", ""), " · TEST" if GameState.is_test_build else ""], 20, Color("#a08890")))


func _set_lim(cat: String, lo: int, hi: int) -> void:
	Learning.set_limits(cat, lo, hi)
	_set_section("difficulty")


func _on_vol(v: float, k: String) -> void:
	GameState.set_setting(k, v)
	AudioSvc.apply_volumes()
	Save.request_save("volume")


func _set_ui_lang(lang: String) -> void:
	GameState.set_setting("ui_lang", lang)
	Loc.set_ui_language(lang)
	Save.request_save("lang")
	language_changed.emit()
	_set_section("language")


func _set_learn_lang(lang: String) -> void:
	GameState.set_setting("learn_lang", lang)
	Loc.set_learn_language(lang)
	Save.request_save("lang")
	_set_section("language")


func _export() -> void:
	var path := Save.make_export_file()
	if path == "":
		hud.show_toast("backup_failed")
		return
	if Diag.recorder.share(path, "application/json"):
		hud.show_toast("backup_shared")
	elif DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show(Loc.t("backup_export"), "", path.get_file(), false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(["*.json"]), func(ok: bool, paths: PackedStringArray, _f: int):
			if ok and paths.size() > 0:
				var f := FileAccess.open(paths[0], FileAccess.WRITE)
				if f:
					f.store_string(FileAccess.get_file_as_string(path))
					f.close()
					hud.show_toast("backup_saved")
				else:
					hud.show_toast("backup_failed"))
	else:
		hud.show_toast("backup_saved_local", [ProjectSettings.globalize_path(path)])


func _import() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		hud.show_toast("backup_no_picker")
		return
	DisplayServer.file_dialog_show(Loc.t("backup_import"), "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.json"]), func(ok: bool, paths: PackedStringArray, _f: int):
		if not ok or paths.is_empty():
			return
		var info := Save.inspect_backup(paths[0])
		if info.is_empty():
			hud.show_toast("backup_invalid")
			return
		_pending_import = info
		_set_section("backup"))


func _restore() -> void:
	if Save.apply_backup(_pending_import):
		_pending_import = {}
		get_tree().reload_current_scene()
	else:
		hud.show_toast("backup_failed")


## Adult check: hold 3 seconds, then solve a multiplication.
class ParentGate extends Screen:
	signal passed()
	var a := 0
	var b := 0
	var entry := ""
	var hold_t := 0.0
	var holding := false
	var stage := 0
	var answer_label: Label
	var hold_btn: Button
	var bar: ProgressBar

	func _init() -> void:
		screen_name = "gate"
		title_key = "title_gate"

	func build() -> void:
		a = randi_range(6, 9)
		b = randi_range(3, 9)
		body.add_child(UIKit.label(Loc.t("gate_hold"), 30))
		hold_btn = UIKit.button(Loc.t("gate_hold_btn"), func(): pass, UIKit.LILAC, 420)
		hold_btn.button_down.connect(func(): holding = true)
		hold_btn.button_up.connect(func():
			holding = false
			if stage == 0:
				hold_t = 0.0)
		body.add_child(hold_btn)
		bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(420, 24)
		bar.show_percentage = false
		bar.max_value = 3.0
		body.add_child(bar)

	func _process(delta: float) -> void:
		if stage == 0 and holding:
			hold_t += delta
			bar.value = hold_t
			if hold_t >= 3.0:
				stage = 1
				_show_question()

	func _show_question() -> void:
		for c in body.get_children():
			c.queue_free()
		body.add_child(UIKit.label(Loc.t("gate_question", [a, b]), 40, UIKit.INK, true))
		answer_label = UIKit.label("", 48, UIKit.INK, true)
		body.add_child(answer_label)
		var g := GridContainer.new()
		g.columns = 6
		for n in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]:
			g.add_child(UIKit.button(str(n), _digit.bind(str(n)), UIKit.SKY, 100))
		g.add_child(UIKit.button("←", func():
			entry = entry.substr(0, max(0, entry.length() - 1))
			answer_label.text = entry, Color("#d8b9c6"), 100))
		g.add_child(UIKit.button("OK", _check, UIKit.MINT, 100))
		body.add_child(g)

	func _digit(d: String) -> void:
		if entry.length() < 3:
			entry += d
		answer_label.text = entry

	func _check() -> void:
		if entry == str(a * b):
			passed.emit()
			close()
		else:
			entry = ""
			answer_label.text = ""
			AudioSvc.sfx("hint")
