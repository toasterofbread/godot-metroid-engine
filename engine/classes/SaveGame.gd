class_name SaveGame

signal value_set

var filename: String
var data: Dictionary
var file_exists: bool = false

# These functions are called before saving the game
var save_functions: Array = []

const default_data: Dictionary = {
	"save_point": {"room_id": "Caves/ship_saveroom", "save_station_id": 0},
	"rooms": {
#		"Caves/ship": {
#			"acquired_upgradepickups": ["etank_0"]
#		}
	},
	"samus": {
		"upgrades": {
			Enums.Upgrade.POWERSUIT: {"amount": 1, "active": true},
			Enums.Upgrade.VARIASUIT: {"amount": 0, "active": true},
			Enums.Upgrade.GRAVITYSUIT: {"amount": 0, "active": true},
			
			Enums.Upgrade.ETANK: {"amount": 15, "active": true},
			Enums.Upgrade.MISSILE: {"amount": 50, "ammo": 50, "active": true},
			Enums.Upgrade.SUPERMISSILE: {"amount": 50, "ammo": 50, "active": true},
			Enums.Upgrade.POWERBOMB: {"amount": 50, "ammo": 50, "active": true},
			
			Enums.Upgrade.CHARGEBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.POWERBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.ICEBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.SPAZERBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.PLASMABEAM: {"amount": 1, "active": true},
			Enums.Upgrade.WAVEBEAM: {"amount": 1, "active": true},
			Enums.Upgrade.GRAPPLEBEAM: {"amount": 1, "active": true},
			
			Enums.Upgrade.BOMB: {"amount": 1, "active": true},
			Enums.Upgrade.MORPHBALL: {"amount": 1, "active": true},
			Enums.Upgrade.SPRINGBALL: {"amount": 1, "active": true},
			Enums.Upgrade.SPEEDBOOSTER: {"amount": 1, "active": true},
			Enums.Upgrade.POWERGRIP: {"amount": 1, "active": true},
			Enums.Upgrade.HIGHJUMP: {"amount": 1, "active": false},
			Enums.Upgrade.SPACEJUMP: {"amount": 1, "active": false},
			Enums.Upgrade.SCREWATTACK: {"amount": 1, "active": false},
			Enums.Upgrade.SPIDERBALL: {"amount": 1, "active": true},
			
			Enums.Upgrade.SCANVISOR: {"amount": 1, "active": true},
			Enums.Upgrade.XRAYVISOR: {"amount": 1, "active": true},
			
			Enums.Upgrade.FLAMETHROWER: {"amount": 1, "active": true},
			Enums.Upgrade.AIRSPARK: {"amount": 1, "active": true},
			Enums.Upgrade.SCRAPMETAL: {"amount": 60}
		},
		"mini_upgrades": {
			"missile_travel_speed": {"blueprint": true, "created": 0},
			"missile_firing_speed": {"blueprint": true, "created": 0},
			"missile_tank_capacity": {"blueprint": true, "created": 0},
			"missile_super_tank_capacity": {"blueprint": true, "created": 0},
			"power_suit_damage_reduction": {"blueprint": true, "created": 0},
			"bomb_placement_cap_increase": {"blueprint": true, "created": 0},
			"grapple_range_increase": {"blueprint": true, "created": 0},
			"maintain_shinespark_when_airsparking": {"blueprint": true, "created": 1},
			"additional_midair_airsparks": {"blueprint": true, "created": 1},
		},
		"energy": -1 # Setting energy to below 0 will fill all available ETanks
	},
	"map": {
		"marker": null,
		"entered_chunks": {}, # Chunks that have been entered by Samus
		"revealed_chunks": {}, # Chunks that have been revealed by a map station
		"scanned_areas": []
	},
	"logbook": {
		"recorded_entries": ["POWERSUIT", "POWERBEAM"]
	},
	"difficulty": {
		"level": 1
	},
	"statistics": {
		"playtime": (5*60*60) + (43*60) + 27,
	}
}

func _init(_filename: String):
	filename = _filename
	load_file()

func save_file():
	
	var functions: Array = []
	for function in save_functions:
		if not function.is_valid():
			continue
		functions.append(function.call_func())
	
	for function in functions:
		if function is GDScriptFunctionState and function.is_valid():
			yield(function, "completed")
	
	Global.save_json(filename, data)

func load_file():
	var file = Global.load_json(filename)
	file_exists = file != null
	
	# DEBUG | This is set to always use the default data
	if not file_exists or true:
		data = default_data
#		save_file()
	else:
		data = file
	
	var upgrades = data["samus"]["upgrades"]
	for upgrade in upgrades:
		upgrades[int(upgrade)] = upgrades[upgrade]
	for upgrade in upgrades:
		if upgrade is String:
			upgrades.erase(upgrade)

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
	
	emit_signal("value_set", keys, value)

func add_save_function(function: FuncRef):
	save_functions.append(function)

func get_overall_percentage() -> float:
	var acquired: int = len(get_data_key(["logbook", "recorded_entries"])) + get_total_acquired_upgrades()
	var total: int = len(Data.data["logbook"]) + Map.total_upgrade_amount
	return float(acquired) / float(total)

func get_scan_percentage() -> float:
	return float(len(get_data_key(["logbook", "recorded_entries"]))) / float(len(Data.data["logbook"]))

func get_upgrade_percentage() -> float:
	return float(get_total_acquired_upgrades()) / float(Map.total_upgrade_amount)

func get_total_acquired_upgrades() -> int:
	var acquired_upgrades: int = 0
	for upgrade in get_data_key(["samus", "upgrades"]).values():
		if upgrade["amount"] > 0:
			acquired_upgrades += upgrade["amount"]
	return acquired_upgrades

func copy_file(path: String) -> int:
	var dir: Directory = Directory.new()
	return dir.copy(filename, path)

func delete_file() -> int:
	var dir: Directory = Directory.new()
	return dir.remove(filename)
