extends Node

const _user_config_path: String = "res://user_settings.cfg"
const _system_config_path: String = "res://system_settings.cfg"

var modified_system_config: bool = false
var _user_config: ConfigFile = ConfigFile.new()
var _system_config: ConfigFile = ConfigFile.new()

func _ready():
	load_user()
	load_system()
	modified_system_config = _check_system_originality()

func save_user():
	_user_config.save(_user_config_path)

func load_user():
	_user_config.load(_user_config_path)

func save_system():
	_system_config.save(_system_config_path)

func load_system():
	_system_config.load(_system_config_path)


func get(value_path: String):
	return _auto_get_value(value_path, _user_config)

func set(value_path: String, value):
	_auto_set_value(value_path, _user_config, value)

func get_system(value_path: String):
	return _auto_get_value(value_path, _system_config)

func set_system(value_path: String, value, set_flag: bool):
	
	var ret = _auto_set_value(value_path, _system_config, value)
	
	if set_flag:
		modified_system_config = true
	
	return ret


func _auto_get_value(value_path: String, file: ConfigFile):
	return file.get_value(value_path.split("/")[0], value_path.split("/")[1])
func _auto_set_value(value_path: String, file: ConfigFile, value):
	file.set_value(value_path.split("/")[0], value_path.split("/")[1], value)

func _check_system_originality() -> bool:
	
	for section in _system_config.get_sections():
		for key in _system_config.get_section_keys(section):
			key = section + "/" + key
	return true
