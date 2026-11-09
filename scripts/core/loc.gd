extends Node
## Localization service. UI language and learning language are independent.
## Strings live in res://i18n/strings.json as {key: {"ru": "...", "de": "..."}}.

signal ui_language_changed(lang: String)

const SUPPORTED := ["ru", "de"]
const STRINGS_PATH := "res://i18n/strings.json"

var ui_lang: String = "ru"
var learn_lang: String = "ru"
var _strings: Dictionary = {}
var missing_keys: Dictionary = {}


func _ready() -> void:
	load_strings(STRINGS_PATH)


func load_strings(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Loc: cannot open %s" % path)
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Loc: invalid json %s" % path)
		return false
	_strings = data
	return true


func set_ui_language(lang: String) -> void:
	if lang not in SUPPORTED:
		return
	ui_lang = lang
	TranslationServer.set_locale(lang)
	ui_language_changed.emit(lang)


func set_learn_language(lang: String) -> void:
	if lang in SUPPORTED:
		learn_lang = lang


## Translate for UI language.
func t(key: String, args: Array = []) -> String:
	return tl(key, ui_lang, args)


## Translate for a given language.
func tl(key: String, lang: String, args: Array = []) -> String:
	var entry: Variant = _strings.get(key)
	var s: String = key
	if typeof(entry) == TYPE_DICTIONARY and entry.has(lang):
		s = entry[lang]
	elif typeof(entry) == TYPE_DICTIONARY and entry.has("ru"):
		s = entry["ru"]
		missing_keys[key + "@" + lang] = true
	else:
		missing_keys[key] = true
	if args.size() > 0:
		s = s % args
	return s


func has_key(key: String) -> bool:
	return _strings.has(key)


## Returns keys that are missing a translation for any supported language.
func validate() -> PackedStringArray:
	var bad := PackedStringArray()
	for key in _strings.keys():
		var e: Variant = _strings[key]
		if typeof(e) != TYPE_DICTIONARY:
			bad.append(key)
			continue
		for lang in SUPPORTED:
			if not e.has(lang) or str(e[lang]).strip_edges() == "":
				bad.append("%s@%s" % [key, lang])
	return bad
