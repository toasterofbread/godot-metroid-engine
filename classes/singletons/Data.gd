extends Node

onready var cdb_data = Global.load_json("res://data/data.cdb")
onready var logbook = get_cdb_sheet("logbook")

func get_cdb_sheet(sheet_key: String):
	
	var base_sheet: Dictionary
	
	for sheet in cdb_data["sheets"]:
		if sheet["name"] == sheet_key:
			base_sheet = sheet
			break
	
	if not base_sheet:
		return false
	
	var ret_data = []
	
	for line in base_sheet["lines"]:
		
		if "key" in line:
			assert(ret_data is Dictionary or len(ret_data) == 0, "All or no lines must have a key value")
			if ret_data is Array:
				ret_data = {}
			ret_data[line["key"]] = line
			ret_data[line["key"]].erase("key")
		else:
			assert(ret_data is Array, "All or no lines must have a key value")
			ret_data.append(line)
	
	return ret_data