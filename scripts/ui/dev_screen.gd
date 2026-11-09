class_name DevScreen
extends Screen
## Developer mode panel (adult only): screen recording via the Kotlin plugin,
## bug marks, overlay, live metrics, report ZIP with per-file review, share.

var info: Label
var files_box: VBoxContainer
var manifest: Array = []
var summary: TextEdit
var rec_btn: Button
var free_btn: Button


func _init() -> void:
	screen_name = "dev"
	title_key = "title_dev"


func build() -> void:
	var row := UIKit.hbox(14)
	rec_btn = UIKit.button("", _toggle_rec, Color("#e86a6a"), 300)
	row.add_child(rec_btn)
	row.add_child(UIKit.button(Loc.t("dev_mark"), _mark, UIKit.SUN, 300))
	row.add_child(UIKit.button(Loc.t("dev_overlay"), func():
		Diag.toggle_overlay()
		_refresh(), UIKit.LILAC, 300))
	row.add_child(UIKit.button(Loc.t("dev_snapshot"), _snapshot, UIKit.SKY, 300))
	body.add_child(row)
	var row2 := UIKit.hbox(14)
	for q in ["low", "medium", "high"]:
		row2.add_child(UIKit.button(q, _set_q.bind(q), UIKit.MINT if Diag.recorder.quality == q else Color("#d9cfd3"), 150))
	for m in [2, 5, 10]:
		row2.add_child(UIKit.button("%d min" % m, _set_m.bind(m), UIKit.SKY if Diag.recorder.max_minutes == m else Color("#d9cfd3"), 150))
	var free_on := bool(GameState.setting("dev_free_shop", false))
	free_btn = UIKit.button(Loc.t("dev_free_shop_on") if free_on else Loc.t("dev_free_shop_off"), _toggle_free, UIKit.MINT if free_on else Color("#d9cfd3"), 360)
	row2.add_child(free_btn)
	row2.add_child(UIKit.button("seed 1234", func():
		Diag.set_seed(1234)
		_refresh(), Color("#d8b9c6"), 220))
	body.add_child(row2)
	info = UIKit.label("", 24, UIKit.INK, false, true)
	body.add_child(info)
	summary = TextEdit.new()
	summary.placeholder_text = Loc.t("dev_summary_ph")
	summary.custom_minimum_size = Vector2(0, 110)
	body.add_child(summary)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	files_box = UIKit.vbox(6)
	sc.add_child(files_box)
	body.add_child(sc)
	var row3 := UIKit.hbox(14)
	row3.add_child(UIKit.button(Loc.t("dev_build_report"), _build_report, UIKit.MINT, 380))
	row3.add_child(UIKit.button(Loc.t("dev_refresh_files"), _refresh_manifest, Color("#d8b9c6"), 320))
	body.add_child(row3)
	Diag.recorder.state_changed.connect(_on_rec_state)
	_refresh_manifest()
	_refresh()


func _toggle_free() -> void:
	GameState.set_setting("dev_free_shop", not bool(GameState.setting("dev_free_shop", false)))
	Diag.event("dev_free_shop", {"on": GameState.setting("dev_free_shop")})
	Save.request_save("dev")
	var on := bool(GameState.setting("dev_free_shop", false))
	free_btn.text = Loc.t("dev_free_shop_on") if on else Loc.t("dev_free_shop_off")
	hud.show_toast("dev_free_shop_on" if on else "dev_free_shop_off")


func _process(_d: float) -> void:
	if Engine.get_process_frames() % 20 == 0:
		_refresh()


func _refresh() -> void:
	if info == null:
		return
	var r := Diag.recorder
	rec_btn.text = Loc.t("dev_stop") if r.state == "recording" else Loc.t("dev_record")
	var last: Dictionary = Diag.perf_rows[-1] if Diag.perf_rows.size() > 0 else {}
	info.text = "FPS %d · 1%%low %.0f · p95 %.1f ms · max %.1f ms · long %d · nodes %d · mem %.0f MB · vram %.0f MB\nrec: %s %s · plugin: %s · audio: %s · errors: %d · overlay: %s · seed: %d · marks: %d" % [
		Engine.get_frames_per_second(), Diag.one_percent_low_fps(), float(last.get("p95_ms", 0)), float(last.get("max_ms", 0)), Diag.long_frames,
		int(last.get("nodes", 0)), float(last.get("static_mem_mb", 0)), float(last.get("video_mem_mb", 0)),
		r.state, (r.last_error if r.last_error != "" else ""), "yes" if r.available() else Loc.t("dev_no_plugin"), r.audio_note if r.audio_note != "" else "—",
		Diag.logger.count(), "on" if Diag.overlay_on else "off", Diag.rng_seed, Diag.marks.size()]


func _toggle_rec() -> void:
	if Diag.recorder.state == "recording":
		Diag.recorder.stop()
	else:
		if not Diag.recorder.start():
			hud.show_toast("dev_rec_fail", [Diag.recorder.last_error])
	_refresh()


func _on_rec_state(_s: String, info_: Dictionary) -> void:
	if info_.has("error"):
		hud.show_toast("dev_rec_fail", [info_["error"]])
	_refresh_manifest()
	_refresh()


func _set_q(q: String) -> void:
	Diag.recorder.quality = q
	_rebuild()


func _set_m(m: int) -> void:
	Diag.recorder.max_minutes = m
	_rebuild()


func _rebuild() -> void:
	for c in body.get_children():
		c.queue_free()
	build()


func _mark() -> void:
	Diag.mark_bug(summary.text if summary else "")
	hud.show_toast("dev_marked")
	_refresh_manifest()


func _snapshot() -> void:
	var path := Diag.DEV_DIR.path_join("test_scene_state-%d.json" % Time.get_ticks_msec())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(Diag.sanitized_state(), "\t"))
		f.close()
		hud.show_toast("dev_snapshot_ok")


func _refresh_manifest() -> void:
	manifest = Diag.report_manifest()
	for c in files_box.get_children():
		c.queue_free()
	for i in manifest.size():
		var e: Dictionary = manifest[i]
		var cb := CheckBox.new()
		cb.text = e["name"]
		cb.button_pressed = e.get("include", true)
		cb.toggled.connect(func(on: bool): manifest[i]["include"] = on)
		files_box.add_child(cb)
	for rec in Diag.recorder.list_recordings():
		var h := UIKit.hbox(10)
		h.add_child(UIKit.label("%s  %.1f MB" % [rec["name"], float(rec["size"]) / 1048576.0], 22))
		h.add_child(UIKit.button(Loc.t("dev_share"), func(): Diag.recorder.share(rec["path"], "video/mp4" if str(rec["name"]).ends_with(".mp4") else "audio/wav"), UIKit.SKY, 160))
		h.add_child(UIKit.button(Loc.t("dev_delete"), func():
			Diag.recorder.delete_recording(rec["path"])
			_refresh_manifest(), Color("#e8a0a0"), 160))
		files_box.add_child(h)
	for rp in Diag.list_reports():
		var h2 := UIKit.hbox(10)
		h2.add_child(UIKit.label(str(rp).get_file(), 22))
		h2.add_child(UIKit.button(Loc.t("dev_share"), func():
			if not Diag.share_report(rp):
				hud.show_toast("dev_share_local", [ProjectSettings.globalize_path(rp)]), UIKit.SKY, 160))
		h2.add_child(UIKit.button(Loc.t("dev_delete"), func():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(rp))
			_refresh_manifest(), Color("#e8a0a0"), 160))
		files_box.add_child(h2)


func _build_report() -> void:
	room.store_runtime_state()
	var path := Diag.export_report(summary.text, manifest)
	if path == "":
		hud.show_toast("dev_report_fail")
		return
	hud.show_toast("dev_report_ok", [path.get_file()])
	_refresh_manifest()
