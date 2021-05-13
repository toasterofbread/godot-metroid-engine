class_name SaveGame

var filename: String
var data: Dictionary

const default_data: Dictionary = {
	"current_room_id": "STARTING ROOM ID",
	"rooms": {
	},
	"samus": {
		"upgrades": {
			"missile": {"amount": 10, "ammo": 5, "active": true},
			"supermissile": {"amount": 100, "ammo": 69, "active": true},
			"bomb": {"amount": 1, "active": true},
			"beam": {"amount": 1, "active": true},
			"etanks": {"amount": 1, "active": true},
			"springball": {"amount": 1, "active": true},
			"powergrip": {"amount": 1, "active": true},
			"speedbooster": {"amount": 1, "active": true},
			"xray": {"amount": 1, "active": false},
			"scan": {"amount": 1, "active": true}
		},
		"energy": -1
	},
	"map": {
		"marker": null
	}
}

const debug_save_path: String = "res://debug_save.json"

func _init(_filename: String = ""):
	filename = _filename
	load_file()

func save_file():
	Global.save_json(filename, data)

func load_file():
	var file = Global.load_json(filename)
	
	# DEBUG | This is set to always use the default data
	if file == null or true:
		data = default_data
		save_file()
	else:
		data = file

func get_data_key(keys: Array):
	
	var current_value = data
	var new_keys_created = false
	
	for key in keys:
		if key in current_value:
			current_value = current_value[key]
		else:
			current_value[key] = {}
			current_value = current_value[key]
			new_keys_created = true
	
	return null if new_keys_created else current_value

func set_data_key(keys: Array, value):
	
	var current_value = data
	
	var i = 0
	for key in keys:
		if i == len(keys) - 1:
			current_value[key] = value
			return
		else:
			if key in current_value:
				current_value = current_value[key]
			else:
				current_value[key] = {}
				current_value = current_value[key]
		i += 1
