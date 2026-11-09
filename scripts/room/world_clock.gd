class_name WorldClock
extends Node
## Season / time of day / weather. Auto mode: game clock runs one day per
## DAY_MINUTES (independent from real time), season follows the real month,
## weather changes now and then with seasonal weights. Manual mode: fixed values.

signal changed()

const SEASONS := ["spring", "summer", "autumn", "winter"]
const TIMES := ["morning", "day", "evening", "night"]
const WEATHERS := ["sun", "clouds", "rain", "snow"]
const DAY_MINUTES := 16.0
const TIME_CLOCK := {"morning": 0.28, "day": 0.5, "evening": 0.76, "night": 0.94}
const SEASON_WEATHER := {
	"spring": {"sun": 4, "clouds": 3, "rain": 3, "snow": 0},
	"summer": {"sun": 6, "clouds": 2, "rain": 2, "snow": 0},
	"autumn": {"sun": 3, "clouds": 4, "rain": 4, "snow": 0},
	"winter": {"sun": 3, "clouds": 3, "rain": 0, "snow": 5},
}

var auto := true
var season := "autumn"
var weather := "sun"
var clock := 0.4          # 0..1, 0 = midnight
var _weather_timer := 90.0
var _last_tod := ""


func load_from_state() -> void:
	var w: Dictionary = GameState.data["world"]
	auto = bool(w.get("auto", true))
	season = w.get("season", "autumn")
	weather = w.get("weather", "sun")
	clock = float(w.get("auto_clock", 0.4))
	if auto:
		season = season_for_month(Time.get_date_dict_from_system()["month"])
	else:
		clock = TIME_CLOCK.get(w.get("time_of_day", "day"), 0.5)
	_last_tod = time_of_day()
	changed.emit()


func store_to_state() -> void:
	var w: Dictionary = GameState.data["world"]
	w["auto"] = auto
	w["season"] = season
	w["weather"] = weather
	w["time_of_day"] = time_of_day()
	w["auto_clock"] = clock


static func season_for_month(m: int) -> String:
	if m in [3, 4, 5]:
		return "spring"
	if m in [6, 7, 8]:
		return "summer"
	if m in [9, 10, 11]:
		return "autumn"
	return "winter"


func time_of_day() -> String:
	return tod_for_clock(clock)


static func tod_for_clock(c: float) -> String:
	if c >= 0.2 and c < 0.36:
		return "morning"
	if c >= 0.36 and c < 0.68:
		return "day"
	if c >= 0.68 and c < 0.84:
		return "evening"
	return "night"


func game_hour() -> float:
	return clock * 24.0


func _process(delta: float) -> void:
	if not auto:
		return
	clock = fmod(clock + delta / (DAY_MINUTES * 60.0), 1.0)
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		_weather_timer = randf_range(90.0, 200.0)
		weather = pick_weather(season, randf())
		Diag.event("weather", {"w": weather})
		changed.emit()
	var tod := time_of_day()
	if tod != _last_tod:
		_last_tod = tod
		Diag.event("time_of_day", {"tod": tod})
		changed.emit()


static func pick_weather(s: String, r: float) -> String:
	var weights: Dictionary = SEASON_WEATHER.get(s, SEASON_WEATHER["summer"])
	var total := 0.0
	for k in weights:
		total += weights[k]
	var acc := 0.0
	for k in WEATHERS:
		acc += weights.get(k, 0)
		if r * total < acc:
			return k
	return "sun"


func set_manual(s: String, tod: String, w: String) -> void:
	auto = false
	season = s if s in SEASONS else season
	weather = w if w in WEATHERS else weather
	clock = TIME_CLOCK.get(tod, clock)
	_last_tod = time_of_day()
	store_to_state()
	Save.request_save("world")
	changed.emit()


func set_auto(on: bool) -> void:
	auto = on
	if on:
		season = season_for_month(Time.get_date_dict_from_system()["month"])
	store_to_state()
	Save.request_save("world")
	changed.emit()


## Mild room tint by time of day (never blurs, only colour; kept light so the
## girl and pets stay crisp and readable).
func room_tint() -> Color:
	var keys := [[0.0, Color(0.74, 0.76, 0.92)], [0.22, Color(0.95, 0.88, 0.9)], [0.35, Color(1, 1, 1)], [0.68, Color(1, 0.97, 0.94)], [0.8, Color(0.96, 0.84, 0.82)], [0.9, Color(0.76, 0.77, 0.92)], [1.0, Color(0.74, 0.76, 0.92)]]
	var c := _interp(keys, clock)
	if weather in ["rain", "clouds"]:
		c = c.lerp(Color(0.9, 0.92, 0.96), 0.3)
	return c


func sky_colors() -> Array:
	var top_keys := [[0.0, Color("#1d2550")], [0.22, Color("#7f8fd6")], [0.3, Color("#9ccbf0")], [0.5, Color("#79bdf0")], [0.72, Color("#8a8fd8")], [0.8, Color("#5a4f9a")], [0.9, Color("#232b5c")], [1.0, Color("#1d2550")]]
	var bot_keys := [[0.0, Color("#3b3f78")], [0.22, Color("#ffc1a8")], [0.3, Color("#ffe3cf")], [0.5, Color("#d8f0ff")], [0.72, Color("#ffc08a")], [0.8, Color("#f08a8a")], [0.9, Color("#3b3f78")], [1.0, Color("#3b3f78")]]
	var top := _interp(top_keys, clock)
	var bot := _interp(bot_keys, clock)
	if weather in ["rain", "snow", "clouds"]:
		var g := Color(0.7, 0.74, 0.8) if weather != "snow" else Color(0.82, 0.85, 0.9)
		var k := 0.45 if weather == "clouds" else 0.6
		top = top.lerp(g * Color(top.v + 0.3, top.v + 0.3, top.v + 0.3), k)
		bot = bot.lerp(g, k * 0.8)
	return [top, bot]


static func _interp(keys: Array, x: float) -> Color:
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if x >= a[0] and x <= b[0]:
			return (a[1] as Color).lerp(b[1], (x - a[0]) / max(0.0001, b[0] - a[0]))
	return keys[0][1]


func is_dark() -> bool:
	return clock < 0.22 or clock > 0.84
