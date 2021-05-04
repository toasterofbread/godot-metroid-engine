extends Node

var _loaded_config = {
	"spiderball_hold": false, 
	"spin_from_jump": true, 
	"zm_controls": true, 
	"turn_speed": 60
	}

var _default_config_values = {
	"spiderball_hold": false, 
	"spin_from_jump": true, 
	"zm_controls": true, 
	"turn_speed": 60
	}

func get(key: String):
	return _loaded_config[key]

func set(key: String, value):
	pass

func reset(key: String):
	pass
