class_name WeatherScreen
extends Screen
## Season / time of day / weather: automatic mode or manual choice.

var auto_btn: Button


func _init() -> void:
	screen_name = "weather"
	title_key = "title_weather"


func build() -> void:
	var c: WorldClock = room.clock
	auto_btn = UIKit.button(Loc.t("weather_auto_on") if c.auto else Loc.t("weather_auto_off"), _toggle_auto, UIKit.MINT if c.auto else Color("#d9cfd3"), 420)
	body.add_child(auto_btn)
	_row("season", [["spring", "ui_sprout"], ["summer", "ui_sun"], ["autumn", "leaf"], ["winter", "ui_snow"]], c.season)
	_row("time", [["morning", "sunrise"], ["day", "ui_sun"], ["evening", "ui_star"], ["night", "ui_moon"]], c.time_of_day())
	_row("weather", [["sun", "ui_sun"], ["clouds", "ui_cloud"], ["rain", "rain"], ["snow", "ui_snow"]], c.weather)


func _row(kind: String, entries: Array, cur: String) -> void:
	var h := UIKit.hbox(22)
	h.add_child(UIKit.label(Loc.t("weather_" + kind), 32, UIKit.INK, true))
	for e in entries:
		var b := UIKit.icon_button(e[1], _set_value.bind(kind, e[0]), UIKit.SKY if e[0] == cur else Color("#e2e6ef"), 120)
		b.bg_ring = e[0] == cur
		h.add_child(b)
	body.add_child(h)


func _set_value(kind: String, value: String) -> void:
	var c: WorldClock = room.clock
	var s := c.season
	var t := c.time_of_day()
	var w := c.weather
	match kind:
		"season":
			s = value
		"time":
			t = value
		"weather":
			w = value
	if w == "snow" and s != "winter":
		s = "winter"
	if w == "rain" and s == "winter":
		w = "clouds"
	c.set_manual(s, t, w)
	_rebuild()


func _toggle_auto() -> void:
	room.clock.set_auto(not room.clock.auto)
	_rebuild()


func _rebuild() -> void:
	for ch in body.get_children():
		ch.queue_free()
	build()
