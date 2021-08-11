extends Node

var joypad_icons: Dictionary = {}
onready var keyboard_icons = Global.dir2dict(ButtonIcon.keyboard_icons_directory)

signal update_button_icons
var using_keyboard: bool = false setget set_using_keyboard
var text_input_active: bool = false

var input_hold_monitors: Dictionary = {}

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	var dir: Directory = Directory.new()
	var error: int = dir.open(ButtonIcon.icons_directory)
	if error != OK:
		# TODO | User error reporting
		push_error("Error loading joypad icons: " + str(error))
	else:
		for file in Global.iterate_directory(dir):
			if dir.dir_exists(file):
				joypad_icons[file] = Global.dir2dict(ButtonIcon.icons_directory + file + "/", Global.DIR2DICT_MODES.NESTED, null, null)
	
	yield(Data, "loaded")
	var settings_data: Dictionary = Data.data["settings_information"]["visuals"]["options"]["joypad_button_icon_style"]
	settings_data["type"] = "string"
	settings_data["data"] = joypad_icons.keys()
	
	yield(Settings, "loaded")
	update_control_mappings()

func update_control_mappings(action_key=null):
	
	var actions: Array = Settings.get_options_in_category("control_mappings") if action_key == null else [action_key]
	for action in actions:
		InputMap.action_erase_events(action)
		
		for event_data in Settings.get_split("control_mappings", action).values():
			var event: InputEvent
			match event_data["type"]:
				"InputEventJoypadButton":
					event = InputEventJoypadButton.new()
				"InputEventMouseButton":
					event = InputEventMouseButton.new()
				"InputEventKey":
					event = InputEventKey.new()
			event.device = -1
			for property in event_data:
				if property != "type":
					event.set(property, event_data[property])
			
			InputMap.action_add_event(action, event)
	emit_signal("update_button_icons", actions)

func _process(delta: float):
	process_input_hold_monitors(delta)
	process_debug_shortcuts()

func _input(event: InputEvent):
	if using_keyboard:
		if event is InputEventJoypadButton:
			set_using_keyboard(false)
	elif not text_input_active and event.get_class() in ["InputEventKey", "InputEventMouseButton"]:
		set_using_keyboard(true)

func set_using_keyboard(value: bool):
	using_keyboard = value
	emit_signal("update_button_icons", null)

func get_facing(pad_name: String = "secondary_pad"):
	if Input.is_action_just_pressed(pad_name + "_left"):
		return Enums.dir.LEFT
	elif Input.is_action_just_pressed(pad_name + "_right"):
		return Enums.dir.RIGHT
	else:
		return null

func get_aiming(Samus: KinematicBody2D, include_front: bool = false):
	
	if Input.is_action_pressed("secondary_pad_up"):
		if Input.is_action_pressed("secondary_pad_left") or Input.is_action_pressed("secondary_pad_right"):
			return Samus.aim.UP
		else:
			return Samus.aim.SKY
	elif Input.is_action_pressed("secondary_pad_down"):
		if Input.is_action_pressed("secondary_pad_left") or Input.is_action_pressed("secondary_pad_right"):
			return Samus.aim.DOWN
		else:
			return Samus.aim.FLOOR
	elif include_front and (Input.is_action_pressed("secondary_pad_left") or Input.is_action_pressed("secondary_pad_right")):
		return Samus.aim.FRONT
	else:
		return null

func get_pad_vector(method: String) -> Vector2:
	var ret: Vector2 = Vector2.ZERO
	method = "is_action_" + method
	if Input.call(method, "pad_left"):
		ret.x += -1
	if Input.call(method, "pad_right"):
		ret.x += 1
	if Input.call(method, "pad_up"):
		ret.y += -1
	if Input.call(method, "pad_down"):
		ret.y += 1
	return ret
func get_pad_x(method: String) -> int:
	var ret: int = 0.0
	method = "is_action_" + method
	if Input.call(method, "pad_left"):
		ret += -1
	if Input.call(method, "pad_right"):
		ret += 1
	return ret
func get_pad_y(method: String) -> int:
	var ret: int = 0
	method = "is_action_" + method
	if Input.call(method, "pad_up"):
		ret += -1
	if Input.call(method, "pad_down"):
		ret += 1
	return ret

func get_joystick_vector(joystick_name: String):
	var ret = Vector2.ZERO
	ret.x = Input.get_action_strength(joystick_name + "_right") - Input.get_action_strength(joystick_name + "_left")
	ret.y = Input.get_action_strength(joystick_name + "_down") - Input.get_action_strength(joystick_name + "_up")
	return ret.normalized()

func process_input_hold_monitors(delta: float):
	for input in input_hold_monitors:
		if Input.is_action_pressed(input):
			input_hold_monitors[input]["value"] += delta
		else:
			input_hold_monitors[input]["value"] = 0

func get_input_hold_value(input_key: String):
	return input_hold_monitors[input_key]["value"] if input_key in input_hold_monitors else 0.0

func add_input_hold_monitor(input_key: String, monitor_id: String):
	if not input_key in input_hold_monitors:
		input_hold_monitors[input_key] = {"value": 0.0, "monitors": [monitor_id]}
		return
	var monitor: Dictionary = input_hold_monitors[input_key]
	if not monitor_id in monitor["monitors"]:
		monitor["monitors"].append(monitor_id)

func remove_input_hold_monitor(input_key: String, monitor_id: String):
	if not input_key in input_hold_monitors:
		return
	var monitor: Dictionary = input_hold_monitors[input_key]
	if not monitor_id in monitor["monitors"]:
		return
	if len(monitor["monitors"]) == 1:
		input_hold_monitors.erase(input_key)
	else:
		input_hold_monitors["monitors"].erase(monitor_id)

signal hide_shortcut_info
var debug_shortcuts: Dictionary = {"DEBUG_display_shortcut_info": {"name": "Display shortcut info", "triggers": {}}}
func register_debug_shortcut(action_key: String, name: String, triggers: Dictionary):
	debug_shortcuts[action_key] = {"name": name, "triggers": triggers}

func process_debug_shortcuts():
	if Input.is_action_just_pressed("DEBUG_display_shortcut_info"):
		var message: String = ""
		for shortcut in debug_shortcuts:
			var action_list: Array = InputMap.get_action_list(shortcut)
			message += debug_shortcuts[shortcut]["name"] + ": " + ("" if len(action_list) == 0 else action_list[0].as_text()) + "\n"
		Notification.types["largetext"].instance().init(message.strip_edges(), [self, "hide_shortcut_info"])
	elif Input.is_action_just_released("DEBUG_display_shortcut_info"):
		emit_signal("hide_shortcut_info")
	
	for shortcut in debug_shortcuts:
		var data: Dictionary = debug_shortcuts[shortcut]
		for trigger in data["triggers"]:
			if Input.call("is_action_" + trigger, shortcut):
				data["triggers"][trigger].call_func()
				print("Debug shortcut triggered: " + shortcut)

func update_button_icons():
	emit_signal("update_button_icons")

func vibrate_controller(strength: float, duration: float):
	strength *= Settings.get("other/controller_vibration_strength")
	if strength <= 0.0:
		return
	for joypad in Input.get_connected_joypads():
		Input.start_joy_vibration(joypad, strength, strength, duration)
