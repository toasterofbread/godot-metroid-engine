extends Node

const data_path = "res://data/"
const logbook_images_path = "res://sprites/ui/map/logbook_images/"

var language: Dictionary
var cdb_text_database: Dictionary
var data: Dictionary

func _ready():
	
	var settings_information = Global.load_json(data_path + "static/settings_information.json")
	var language_information = Global.load_json(data_path + "static/language_information.json")
	language = language_information[settings_information["other"]["language"]["type"][Settings.get("other/language")]]
	
	cdb_text_database = Global.load_json(data_path + "localisable/" + language["code"] + ".cdb")
	
	# Format settings data
	var settings_text_information = get_cdb_sheet("settings_information")
	for group in settings_text_information:
		settings_text_information[group]["options"] = format_cdb_dict(settings_text_information[group]["options"])
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
		"settings_information": settings_text_information,
		"language_information": language_information,
	}

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
