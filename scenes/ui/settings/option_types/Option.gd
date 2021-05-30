extends HBoxContainer

var data: Dictionary
var option_data: Dictionary
var path: Array
var current_value
var type: int
enum TYPES {
	ENUM, BOOL, INT, PERCENTAGE
}

func compare_arrays(arrayA: Array, arrayB: Array) -> bool:
	if len(arrayA) != len(arrayB):
		return false
	for i in range(len(arrayA)):
		if arrayA[i] != arrayB[i]:
			return false
	return true

func init(_data: Dictionary, _path: Array):
	data = _data
	path = _path
	
	option_data = data[path[0]]["options"][path[1]]
	$Title.text = option_data["title"]
	name = path[1]
	
	if option_data["type"] is Array:
		
		# For some reason, the type is always String even when it's an integer in the JSON file
		# But for some reason this still works???
		if option_data["type"][0] in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]:
			if compare_arrays(option_data["type"], [0, 100]):
				type = TYPES.PERCENTAGE
			else:
				type = TYPES.INT
		else:
			type = TYPES.ENUM 
	elif option_data["default"] is bool:
		type = TYPES.BOOL
	
	if type == null:
		return false
	
	load_value()

func load_value():
	current_value = Settings.get_split(path[0], path[1])
	set_value_label()

func save_value():
	assert(current_value != null, "Cannot save, value is null")
	
	var original_value = Settings.get_split(path[0], path[1])
	
	if type in [TYPES.INT, TYPES.PERCENTAGE, TYPES.ENUM]:
		Settings.set_split(path[0], path[1], int(round(current_value)))
	else:
		Settings.set_split(path[0], path[1], current_value)
	
	return original_value != Settings.get_split(path[0], path[1])

func reset():
	current_value = option_data["default"]
	set_value_label()

func set_value_label():
	match type:
		TYPES.ENUM: $Value.text = option_data["type"][current_value]
		TYPES.BOOL: $Value.text = "On" if current_value else "Off"
		TYPES.INT: $Value.text = str(round(current_value))
		TYPES.PERCENTAGE: $Value.text = str(round(current_value)) + "%"
		_: $Value.text = str(current_value)

func process():
	match type:
		TYPES.ENUM: process_enum()
		TYPES.BOOL: process_bool()
		TYPES.INT, TYPES.PERCENTAGE: process_int()

func process_enum():
	var pad_x: int = Shortcut.get_pad_vector("just_pressed").x
	if pad_x != 0:
		current_value += pad_x
		if current_value < 0:
			current_value = len(option_data["type"]) - 1
		elif current_value > len(option_data["type"]) - 1:
			current_value = 0
		set_value_label()

func process_bool():
	if Input.is_action_just_pressed("ui_accept") or Shortcut.get_pad_vector("just_pressed").x != 0:
		current_value = !current_value
		set_value_label()

func process_int():
	var pad_x = Shortcut.get_pad_vector("pressed").x
	if pad_x != 0:
		current_value += pad_x/5
		if option_data["type"] is Array:
			current_value = max(min(current_value, option_data["type"][1]), option_data["type"][0])
		set_value_label()
