extends TextureRect

enum BUTTON_ICON_TYPES {
	PLAYSTATION,
	XBOX,
	NINTENDO
}
const icon_type_paths = {
	BUTTON_ICON_TYPES.PLAYSTATION: "res://engine/sprites/ui/button_prompt/playstation/playstation.tres",
	BUTTON_ICON_TYPES.XBOX: "",
	BUTTON_ICON_TYPES.NINTENDO: ""
}
var frames: SpriteFrames

export var action_key: String setget set_action_key
export var set_icon_on_ready: bool = false

func _ready():
	Settings.connect("settings_changed", self, "settings_changed")
	Shortcut.connect("keyboard_mode_changed", self, "keyboard_mode_changed")
	
	if set_icon_on_ready:
		update_icon()

func settings_changed(path, value):
	if path == "other/joypad_button_icon_style" or path == null:
		frames = load(icon_type_paths[value if value != null else Settings.get("other/joypad_button_icon_style")])

func keyboard_mode_changed(_mode: bool):
	pass

func set_action_key(value: String):
	action_key = value
	update_icon()

func update_icon():
	if not InputMap.has_action(action_key):
		assert(false, "Action '" + action_key + "' doesn't seem to exist")
		return
	
	if frames == null:
		settings_changed(null, null)
	
	var action: Array = InputMap.get_action_list(action_key.replace("#", ""))
	for event in action:
		if not event.get_class() in ["InputEventJoypadButton", "InputEventJoypadMotion"]:
			continue
		texture = frames.get_frame(str(event.button_index), 0)
