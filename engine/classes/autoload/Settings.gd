extends Node

signal loaded
signal settings_changed
signal language_loaded

var loaded: bool = false

var settings_file_path: String
var _config: ConfigFile = ConfigFile.new()

var global_stats: Dictionary
const default_global_stats: Dictionary = {
	"total_playtime": 0, # TODO | Total and per-save playtime tracking
}

func get_value_as_saveable(value, option_data: Dictionary):
	if option_data["type"] == "string":
		return option_data["data"][value]
	else:
		return value

func get_default_of_option(option: String, option_data: Dictionary):
	if option_data["type"] == "input":
		var ret: Dictionary = {}
		for event in ProjectSettings.get_setting("input/" + option)["events"]:
			if event.get_class() in ["InputEventKey", "InputEventMouseButton"] and not "keyboard" in ret:
				ret["keyboard"] = {"type": event.get_class()}
				if event is InputEventKey:
					ret["keyboard"]["scancode"] = event.scancode
				else:
					ret["keyboard"]["button_index"] = event.button_index
			elif event is InputEventJoypadButton and not "joypad" in ret:
				ret["joypad"] = {"type": event.get_class(), "button_index": event.button_index}
			if len(ret) == 2:
				break
		return ret
	else:
		return option_data["default"]

func _ready():
	yield(Data, "ready")
	settings_file_path = Data.get_from_user_dir("settings.cfg")
	load_file()
	
	var loaded_global_stats = Global.load_json(Data.get_from_user_dir("stats.json"))
	if loaded_global_stats == null:
		global_stats = default_global_stats
		Global.save_json(Data.get_from_user_dir("stats.json"), global_stats, true)
	else:
		global_stats = loaded_global_stats

func save_file():
	return _config.save(settings_file_path)

func load_file():
	var error: int = ERR_FILE_NOT_FOUND
#	var error: int = _config.load(settings_file_path)
	if error == ERR_FILE_NOT_FOUND:
		emit_signal("language_loaded", "en")
		apply_custom_settings()
		
		# Generate settings file with default data if it doesn't exist
		var settings_information: Dictionary = Data.data["settings_information"]
		for category in settings_information:
			for key in settings_information[category]["options"]:
				var value: Dictionary = settings_information[category]["options"][key]
				_config.set_value(category, key, get_value_as_saveable(get_default_of_option(key, value), value))
		error = _config.save(settings_file_path)
	elif error == OK:
		apply_custom_settings()
	if error != OK:
		# TODO | Fatal error screen
		push_error("Could not load config file at path '" + settings_file_path + "'. Error code: " + str(error) + ".")
		get_tree().quit(1)
		return
	
	emit_signal("language_loaded", get("other/language"))
	loaded = true
	emit_signal("loaded")
	return error

func get(value_path: String):
	return get_split(value_path.split("/")[0], value_path.split("/")[1])

func set(value_path: String, value):
	set_split(value_path.split("/")[0], value_path.split("/")[1], value)

func get_split(category: String, option: String):
	return _config.get_value(category, option)

func set_split(category: String, option: String, value):
	emit_signal("settings_changed", category + "/" + option, value)
	_config.set_value(category, option, value)

# Writes data to settings_information that can only be known at runtime
func apply_custom_settings():
	# Samus physics profiles
	var data: Dictionary = Data.data["settings_information"]["control_options"]["options"]["samus_physics_profile"]
	data["type"] = "string"
	data["data"] = []
	for dir in Data.data["engine_config"]["samus_physics_profiles_directories"]:
		var profiles: Dictionary = Global.dir2dict(dir, Global.DIR2DICT_MODES.NESTED, null, ["json"])
		for profile in profiles:
			var profile_info: Dictionary = Global.load_json(profiles[profile])["profile_info"]
			data["data"].append(profile_info["name"][Data.language_code])

func get_options_in_category(category: String) -> PoolStringArray:
	return _config.get_section_keys(category)

func get_config_as_dict() -> Dictionary:
	var ret: Dictionary = {}
	for category in _config.get_sections():
		ret[category] = {}
		for key in _config.get_section_keys(category):
			ret[category][key] = get_split(category, key)
	return ret
