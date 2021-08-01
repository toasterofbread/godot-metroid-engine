extends Node

signal loaded

const data_path = "res://data/"
const logbook_images_path = "res://engine/sprites/ui/map/logbook_images/"

var language_code: String
var cdb_text_database: Dictionary
var user_dir_path: String
var data: Dictionary

func _ready():
	
	var engine_config: Dictionary = Global.load_json("res://engine_config.json")
	var user_dir_override = engine_config["user_dir_override"]
	user_dir_path = "user://" if user_dir_override == null else user_dir_override
	
	yield(Settings, "loaded")
	language_code = Settings.get("other/language")
	Settings.connect("settings_changed", self, "settings_changed")
	update_language()
	
	# Format settings data
	var settings_information = Global.load_json(data_path + "static/settings_information.json")
	var settings_text_information = get_cdb_sheet("settings_information")
	for group in settings_text_information:
		settings_text_information[group]["options"] = format_cdb_dict(settings_text_information[group]["options"])
		
		# Format the data section of each option if it exists
		for option in settings_text_information[group]["options"]:
			var option_data: Dictionary = settings_text_information[group]["options"][option]
			if "data" in option_data:
				for i in range(len(option_data["data"])):
					option_data["data"][i] = option_data["data"][i]["key"]
		
	for group in settings_text_information:
		for setting in settings_text_information[group]["options"]:
			for key in settings_information[group][setting]:
				settings_text_information[group]["options"][setting][key] = settings_information[group][setting][key]
	
	# Format mini_upgrades data
	var mini_upgrades_data = get_cdb_sheet("mini_upgrades")
	for upgrade in mini_upgrades_data:
		mini_upgrades_data[upgrade]["key"] = upgrade
		
		var dependencies = mini_upgrades_data[upgrade]["dependencies"]
		mini_upgrades_data[upgrade]["dependencies"] = []
		for value in dependencies:
			mini_upgrades_data[upgrade]["dependencies"].append(Enums.Upgrade.keys().find(value["value"]))
	
	data = {
		"logbook": get_cdb_sheet("logbook"),
		"mini_upgrades": mini_upgrades_data,
		"damage_values": Global.load_json(data_path + "static/damage_values.json"),
		"engine_config": engine_config,
		"settings_information": settings_text_information,
		"map_areas": get_cdb_sheet("map_areas")
	}
	
	emit_signal("loaded")

func get_cdb_sheet(sheet_key: String):
	
	var base_sheet: Dictionary
	
	for sheet in cdb_text_database["sheets"]:
		if sheet["name"] == sheet_key:
			base_sheet = sheet
			break
	
	if not base_sheet:
		return false
	
	var ret_data = []
	
	for line in base_sheet["lines"]:
		
		if "key" in line:
			assert(len(ret_data) == 0, "All or no lines must have a key value")
			ret_data = format_cdb_dict(base_sheet["lines"])
			break
		else:
			assert(ret_data is Array, "All or no lines must have a key value")
			ret_data.append(line)
	
	return ret_data

func format_cdb_dict(dict: Array) -> Dictionary:
	var ret: = {}
	for line in dict:
		assert("key" in line)
		ret[line["key"]] = line
		ret[line["key"]].erase("key")
	return ret

func update_language():
	TranslationServer.set_locale(language_code)
	TranslationServer.translate("VALIDITY_TEST")
	cdb_text_database = Global.load_json(data_path + "localisable/" + language_code + ".cdb")

func settings_changed(path: String, value):
	if path == "other/language":
		language_code = value
		update_language()

func get_from_user_dir(path: String):
	path = path.trim_prefix("/")
	return user_dir_path + path
