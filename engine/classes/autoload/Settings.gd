extends Node

signal loaded
signal settings_changed

var settings_file_path: String
var _config: ConfigFile = ConfigFile.new()

func _ready():
	yield(Data, "ready")
	settings_file_path = Data.get_from_user_dir("settings.cfg")
	load_file()
	apply_custom_settings()

func save_file():
	return _config.save(settings_file_path)

func load_file():
	_config.load(settings_file_path)
	emit_signal("loaded")

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
