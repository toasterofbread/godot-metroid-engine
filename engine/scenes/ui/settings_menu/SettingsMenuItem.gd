extends Control

signal current_set
signal pressed

const background_colour: Color = Color("1affffff")
const background_colour_changes_made: Color = Color("1aefeb00")

var category: String

var option
var option_data: Dictionary
var value_label: Label
var types: Dictionary = {
	"bool": ["option_process_bool", []], # Boolean
	"int": ["option_process_int", []], # An integer, which can have a custom range or none
	"enum": ["option_process_enum", []], # One item from a list of strings, stored as an int
	"string": ["option_process_enum", []] # One item from a list of strings, stores as is
}
var current_value
var new_value

var label: Label
var current: bool = false setget set_current
const current_offset_value: float = -25.0

var button_just_pressed: bool = false

func slide(slide_in: bool, wait_time: float):
	
	var normal_position: float = current_offset_value if current else 0.0
	var offset_position: float = get_parent().rect_size.x
	
	if slide_in:
		$Background.rect_position.x = offset_position
	if wait_time > 0.0:
		yield(Global.wait(wait_time, true), "completed")
	visible = true
	$SlideTween.interpolate_property($Background, "rect_position:x", $Background.rect_position.x, normal_position if slide_in else offset_position, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$SlideTween.start()
	yield($SlideTween, "tween_completed")

func init(data: Dictionary, _category: String, _option, _value_label: Label):
	
	label = $Background/HBoxContainer/Label
	category = _category
	option = _option
	value_label = _value_label
	$Background.color = background_colour
	
	if option == null:
		label.text = category.capitalize()
		name = category
	else:
		label.text = option.capitalize()
		name = option
		option_data = data[category]["options"][option]
		
		# DEBUG
		if not option_data["type"] in types:
			if option_data["type"] == "dynamic":
				assert(false, "Dynamic settings must be initialised at project runtime")
			else:
				assert(false, "Invalid setting type: " + option_data["type"])
			return
		
		current_value = load_value()

func set_current(value: bool, emit: bool = true, set_by_mouse: bool = false):
	if current == value:
		return
	current = value
	
	if emit:
		emit_signal("current_set", self, current, set_by_mouse)
	
	$Tween.stop_all()
	$Tween.interpolate_property($Background, "rect_position:x", $Background.rect_position.x, current_offset_value if current else 0, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	
	if option != null:
		update_value_label()

func option_process(delta: float, pad: Vector2, confirm_button_just_pressed: bool):
	var pressed = confirm_button_just_pressed or button_just_pressed
	button_just_pressed = false
	
	var changes_made: bool = callv(types[option_data["type"]][0], [delta, pad, pressed] + types[option_data["type"]][1])
	if changes_made:
		update_value_label()
		$Background.color = background_colour if current_value == load_value() else background_colour_changes_made
	

func option_process_bool(_delta: float, pad: Vector2, pressed: bool):
	if pad.x != 0 or pressed:
		current_value = !current_value
		return true
	else:
		return false

func option_process_int(_delta: float, pad: Vector2, _pressed: bool):
	if pad.x != 0:
		var minimum = -INF
		var maximum = INF
		if len(option_data["data"]) >= 1 and option_data["data"][0].is_valid_integer():
			minimum = int(option_data["data"][0])
		elif len(option_data["data"]) >= 2 and option_data["data"][1].is_valid_integer():
			maximum = int(option_data["data"][1])
		current_value = min(max(current_value + pad.x, minimum), maximum)
		
		return true
	else:
		return false
func option_process_enum(_delta: float, pad: Vector2, pressed: bool):
	if pad.x == 0:
		if pressed:
			pad.x = 1
		else:
			return false
	
	current_value = wrapi(current_value + pad.x, 0, len(option_data["data"]))
	return true

func load_value():
	var ret = Settings.get_split(category, option)
	if option_data["type"] == "string":
		ret = option_data["data"].find(ret)
	return ret

func save_value():
	match option_data["type"]:
		"enum", "bool", "int":
			Settings.set_split(category, option, current_value)
		"string":
			Settings.set_split(category, option, option_data["data"][current_value])

func reset_value():
	current_value = load_value()
	$Background.color = background_colour
	if current:
		update_value_label()

func update_value_label():
	match option_data["type"]:
		"bool":
			value_label.text = tr("settings_value_bool_" + ("on" if current_value else "off"))
		"int":
			value_label.text = str(current_value)
		"enum", "string":
			value_label.text = option_data["data"][current_value]

func reset_to_default():
	current_value = option_data["default"]
	update_value_label()

func _on_Button_mouse_entered():
	set_current(true, true, true)

func _on_Button_mouse_exited():
	set_current(false, true, true)

func _on_Button_pressed():
	emit_signal("pressed")
	button_just_pressed = true
