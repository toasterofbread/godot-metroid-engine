extends TextureRect
class_name ButtonIcon

const icons_directory: String = "res://engine/sprites/ui/button_prompt/joypad_icons/"
const keyboard_icons_directory: String = "res://engine/sprites/ui/button_prompt/keyboard/"

export var action_key: String setget set_action_key
export var set_icon_on_ready: bool = false

var keyboard_mode_override: bool = null
var event_override: InputEvent = null

var joypad_icons_key: String = null

func _ready():
	Settings.connect("settings_changed", self, "settings_changed")
	InputManager.connect("update_button_icons", self, "update_icon")
	
	if set_icon_on_ready:
		update_icon()

func settings_changed(path, value):
	if path == "visuals/joypad_button_icon_style":
		joypad_icons_key = value
		update_icon()

func set_action_key(value: String):
	action_key = value
	update_icon()

func update_icon(icons_to_update=null):
	if not InputMap.has_action(action_key) and not event_override:
		push_warning("Action '" + action_key + "' doesn't seem to exist")
		return
	
	if joypad_icons_key == null:
		if Settings.loaded and Settings.get("visuals/joypad_button_icon_style") != null:
			joypad_icons_key = Settings.get("visuals/joypad_button_icon_style")
		else:
			return
	if not (icons_to_update == null or action_key in icons_to_update):
		return
	
	var events: Array = [event_override] if event_override else InputMap.get_action_list(action_key)
	
	if (InputManager.using_keyboard and keyboard_mode_override == null) or keyboard_mode_override:
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
			var icons: Dictionary = InputManager.keyboard_icons[folder_key]
			if image_key in icons:
				texture = load(icons[image_key])
				break
			else:
				push_error("Keyboard/mouse image key '" + image_key + "' has no icon in the '" + folder_key + "' folder")
	else:
		for event in events:
			if not event is InputEventJoypadButton:
				continue
			var icons: Dictionary = InputManager.joypad_icons[joypad_icons_key]
			if str(event.button_index) in icons:
				texture = load(icons[str(event.button_index)])
				break
			else:
				push_error("Joypad button index '" + str(event.button_index) + "' has no icon in the '" + joypad_icons_key + "' folder")
