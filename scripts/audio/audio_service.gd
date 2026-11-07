extends Node
## Music / SFX / Voice with separate buses and volume.
## SFX are throttled per sound (max concurrent + min interval) so rapid repeats
## never stack into loud noise. Voice: pre-recorded file first
## (res://assets/audio/voice/<lang>/<key>.wav|.ogg), otherwise the device's
## offline system TTS voice for that language (no network synthesis).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const VOICE_DIR := "res://assets/audio/voice/"
const POOL := 14
const MAX_SAME := 3
const MIN_INTERVAL_MS := 70

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _last_play: Dictionary = {}
var _music: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _tts_voices: Dictionary = {}
var listener_pos := Vector2.ZERO
var listener_half_width := 1000.0
var tts_available := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(func(): _music.play())  # seamless-enough loop for any stream type
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Voice"
	add_child(_voice)
	_detect_tts()


func _ensure_buses() -> void:
	for b in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")


func _detect_tts() -> void:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return
	for lang in ["ru", "de"]:
		var v := DisplayServer.tts_get_voices_for_language(lang)
		if v.size() > 0:
			_tts_voices[lang] = v[0]
	tts_available = _tts_voices.size() > 0


func apply_volumes() -> void:
	_set_bus_lin("Music", float(GameState.setting("vol_music", 0.6)))
	_set_bus_lin("SFX", float(GameState.setting("vol_sfx", 0.8)))
	_set_bus_lin("Voice", float(GameState.setting("vol_voice", 0.9)))


func _set_bus_lin(bus: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(v, 0.001)))


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s


## Play a sound effect. world_pos (optional) attenuates/pans by camera distance.
func sfx(name: String, world_pos: Variant = null, volume_db := 0.0, pitch := 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(name, -10000)) < MIN_INTERVAL_MS:
		return
	var same := 0
	for p in _players:
		if p.playing and p.get_meta("sfx", "") == name:
			same += 1
	if same >= MAX_SAME:
		return
	var s := _stream(SFX_DIR + name + ".wav")
	if s == null:
		return
	var vol := volume_db
	if world_pos != null:
		var dx: float = absf((world_pos as Vector2).x - listener_pos.x)
		if dx > listener_half_width * 1.6:
			return
		vol += linear_to_db(clamp(1.0 - dx / (listener_half_width * 1.8), 0.15, 1.0))
	var player: AudioStreamPlayer = null
	for p in _players:
		if not p.playing:
			player = p
			break
	if player == null:
		return
	_last_play[name] = now
	player.stream = s
	player.volume_db = vol
	player.pitch_scale = pitch * randf_range(0.96, 1.04)
	player.set_meta("sfx", name)
	player.play()


func play_music(name: String) -> void:
	var s := _stream(MUSIC_DIR + name + ".wav")
	if s == null or (_music.playing and _music.stream == s):
		return
	_music.stream = s
	_music.volume_db = -6.0
	_music.play()


func stop_music() -> void:
	_music.stop()


## Speak a localized line in the given language (learning language for tasks).
func say(key: String, lang: String = "", args: Array = []) -> void:
	if not bool(GameState.setting("voice_enabled", true)):
		return
	if lang == "":
		lang = Loc.ui_lang
	for ext in [".ogg", ".wav"]:
		var s := _stream(VOICE_DIR + lang + "/" + key + ext)
		if s != null:
			_voice.stream = s
			_voice.play()
			return
	say_text(Loc.tl(key, lang, args), lang)


func say_text(text: String, lang: String) -> void:
	if not bool(GameState.setting("voice_enabled", true)) or not tts_available:
		return
	var voice: String = _tts_voices.get(lang, "")
	if voice == "":
		return
	DisplayServer.tts_stop()
	var vol := int(clamp(float(GameState.setting("vol_voice", 0.9)) * 100.0, 0, 100))
	DisplayServer.tts_speak(text, voice, vol, 1.05, 0.92)
