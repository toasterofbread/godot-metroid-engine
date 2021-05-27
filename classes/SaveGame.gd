class_name SaveGame

signal value_set

var filename: String
var data: Dictionary

const default_data: Dictionary = {
	"current_room_id": "STARTING ROOM ID",
	"rooms": {
	},
	"samus": {
		"upgrades": {
			Enums.Upgrade.ETANK: {"amount": 15, "active": true},
			Enums.Upgrade.MISSILE: {"amount": 50, "ammo": 50, "active": true},
			Enums.Upgrade.SUPERMISSILE: {"amount": 50, "ammo": 50, "active": true},
			Enums.Upgrade.GRAPPLEBEAM: {"amount": 1, "active": true},
			
			Enums.Upgrade.BOMB: {"amount": 1, "active": true},
			Enums.Upgrade.POWERBOMB: {"amount": 50, "ammo": 50, "active": true},
			
			Enums.Upgrade.CHARGEBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.BEAM: {"amount": 1, "active": true},
			Enums.Upgrade.ICEBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.SPAZERBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.WAVEBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.PLASMABEAM: {"amount": 1, "active": true},
			
			Enums.Upgrade.MORPHBALL: {"amount": 1, "active": true},
			Enums.Upgrade.SPRINGBALL: {"amount": 1, "active": true},
			Enums.Upgrade.SPEEDBOOSTER: {"amount": 1, "active": true},
			Enums.Upgrade.POWERGRIP: {"amount": 1, "active": true},
			Enums.Upgrade.SPACEJUMP: {"amount": 1, "active": true},
			Enums.Upgrade.SCREWATTACK: {"amount": 1, "active": true},
			Enums.Upgrade.SPIDERBALL: {"amount": 1, "active": true},
			
			Enums.Upgrade.XRAY: {"amount": 1, "active": true},
			Enums.Upgrade.SCAN: {"amount": 1, "active": false}
		},
		"energy": -1 # Setting energy to below 0 will fill all available ETanks
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

func get_data_key(keys: Array, create_new_keys:=false):
	
	var current_value = data
	var new_keys_created = false
	
	for key in keys:
		if key in current_value:
			current_value = current_value[key]
		elif create_new_keys:
			current_value[key] = {}
			current_value = current_value[key]
			new_keys_created = true
		else:
			return null
	
	return null if new_keys_created else current_value

func set_data_key(keys: Array, value):
	
	emit_signal("value_set", keys, value)
	
	var current_value = data
	var i = 0
	for key in keys:
		if i == len(keys) - 1:
			current_value[key] = value
			break
		else:
			if key in current_value:
				current_value = current_value[key]
			else:
				current_value[key] = {}
				current_value = current_value[key]
		i += 1
