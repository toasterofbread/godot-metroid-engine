extends Node

const _settings_file_path: String = "res://settings.cfg"

var _config: ConfigFile = ConfigFile.new()

func _ready():
	load_file()

func save_file():
	_config.save(_settings_file_path)

func load_file():
	_config.load(_settings_file_path)

func get(value_path: String):
	return _auto_get_value(value_path)

func set(value_path: String, value):
	_auto_set_value(value_path, value)

func _auto_get_value(value_path: String):
	return _config.get_value(value_path.split("/")[0], value_path.split("/")[1])
func _auto_set_value(value_path: String, value):
	_config.set_value(value_path.split("/")[0], value_path.split("/")[1], value)
