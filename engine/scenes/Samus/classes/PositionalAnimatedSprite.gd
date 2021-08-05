tool
extends AnimatedSprite
class_name PositionalAnimatedSprite

const data_json_path = "res://data/static/samus/animation_data.json"

enum FACING {LEFT, RIGHT}

export var state_key: String
export var animation_key: String
export(FACING) var facing: int = FACING.LEFT setget set_facing
export var data: Dictionary = {}

export var save_data: bool setget save_data
export var load_data: bool setget load_data
export(Array, int) var step_frames = [] setget set_step_frames
export var set_position_data: bool setget set_position_data

func set_step_frames(value: Array):
	step_frames = value
	data["step_frames"] = value

func set_position_data(value: bool):
	match facing:
		FACING.LEFT: data["leftPos"] = [position.x, position.y]
		FACING.RIGHT: data["rightPos"] = [position.x, position.y]
	print("Position set")

func save_data(_value: bool):
	if get_unset_variables() != []:
		print("Cannot save data. The following variables have not been set:")
		print(get_unset_variables())
		return
	name = animation_key
	
	var loaded_data = load_file()
	
	if not state_key in loaded_data:
		loaded_data[state_key] = {}
	
	loaded_data[state_key][animation_key] = data
	
	save_file(loaded_data)
	
	print("Sprite data has been succesfully saved")

func load_data(_value: bool):
	if get_unset_variables() != []:
		print("Cannot load data. The following variables have not been set:")
		print(get_unset_variables())
		return
	name = animation_key
	
	var loaded_data = load_file()
	
	if not state_key in loaded_data:
		print("Could not load data: state_key doesn't exist")
		return
	elif not animation_key in loaded_data[state_key]:
		print("Could not load data: animation_key doesn't exist in state_key")
		return
	
	data = loaded_data[state_key][animation_key]
	
	if facing == FACING.LEFT and "leftPos" in data:
		position = Vector2(data["leftPos"][0], data["leftPos"][1])
	elif facing == FACING.RIGHT and "rightPos" in data:
		position = Vector2(data["rightPos"][0], data["rightPos"][1])
	
	var animation_id: String
	if "state_id" in data:
		animation_id = data["state_id"] + "_" + animation_key
	else:
		animation_id = state_key + "_" + animation_key
	
	var directional = true
	if "directional" in data:
		directional = data["directional"]
	
	if directional:
		match facing:
			FACING.LEFT: animation_id = animation_id + "_left"
			FACING.RIGHT: animation_id = animation_id + "_right"
	
	play(animation_id)
	
	print("Sprite data has been succesfully loaded and applied")
	

func get_unset_variables() -> Array:
	
	var ret = []
	
	for property in ["state_key", "animation_key"]:
		if self.get(property) == null:
			ret.append(property)
	
	return ret

func set_facing(value: int):
	flip_h = value == FACING.LEFT
	facing = value

func load_file():
	var f = File.new()
	if not f.file_exists(data_json_path):
		return null
	f.open(data_json_path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data).result

func save_file(data):
	var f = File.new()
	f.open(data_json_path, File.WRITE)
	f.store_string(JSON.print(data, "\t"))
	f.close()

func _ready():
	frames = load("res://engine/scenes/Samus/animations/power.tres")
