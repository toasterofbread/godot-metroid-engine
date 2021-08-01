extends TextureRect
class_name ButtonIcon

const icons_directory: String = "res://engine/sprites/ui/button_prompt/joypad_icons/"
const keyboard_icons_directory: String = "res://engine/sprites/ui/button_prompt/keyboard/"

export var action_key: String setget set_action_key
export var set_icon_on_ready: bool = false

var keyboard_mode_override = null
var event_override = null

var keyboard_mode: bool = false
onready var joypad_icons_key: String = Settings.get("visuals/joypad_button_icon_style")

func _ready():
	Settings.connect("settings_changed", self, "settings_changed")
	Shortcut.connect("keyboard_mode_changed", self, "keyboard_mode_changed")
	
	if set_icon_on_ready:
		update_icon()

func settings_changed(path, value):
	if path == "visuals/joypad_button_icon_style":
		joypad_icons_key = value
		update_icon()

func keyboard_mode_changed(mode: bool):
	keyboard_mode = mode
	update_icon()

func set_action_key(value: String):
	action_key = value
	update_icon()

func update_icon():
	if not InputMap.has_action(action_key):
		assert(false, "Action '" + action_key + "' doesn't seem to exist")
		return
	
	if joypad_icons_key == null:
		return
	
	var events: Array
	
	if event_override:
		var event: InputEvent
		match event_override["type"]:
			"InputEventJoypadButton":
				event = InputEventJoypadButton.new()
			"InputEventMouseButton":
				event = InputEventMouseButton.new()
			"InputEventKey":
				event = InputEventKey.new()
		for property in event_override:
			if property != "type":
				event.set(property, event_override[property])
		events = [event]
	else:
		events = InputMap.get_action_list(action_key)
	
	if (keyboard_mode and keyboard_mode_override == null) or keyboard_mode_override:
		for event in events:
			var image_key: String
			var folder_key: String
			if event is InputEventMouseButton:
				image_key = event.as_text().split("button_index=BUTTON_")[1].split(",")[0]
				folder_key = "buttons"
			elif event is InputEventKey:
				image_key = event.as_text()
				folder_key = "keys"
			else:
				continue
			
			image_key = image_key.to_upper()
			var icons: Dictionary = Shortcut.keyboard_icons[folder_key]
			if image_key in icons:
				texture = load(icons[image_key])
				break
			else:
				push_error("Keyboard/mouse image key '" + image_key + "' has no icon in the '" + folder_key + "' folder")
	else:
		for event in events:
			if not event is InputEventJoypadButton:
				continue
			var icons: Dictionary = Shortcut.joypad_icons[joypad_icons_key]
			if str(event.button_index) in icons:
				texture = load(icons[str(event.button_index)])
				break
			else:
				push_error("Joypad button index '" + str(event.button_index) + "' has no icon in the '" + joypad_icons_key + "' folder")
