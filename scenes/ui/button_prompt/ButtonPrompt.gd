tool
extends Node2D
class_name ButtonPrompt

export(Array, String) var action_keys: Array = [""]
export(Array, String) var text: Array = [""] setget set_text
export var text_colour: Color = Color.white setget set_text_colour

export var enabled: bool = true setget set_enabled
const default_fade_time: float = 0.25

var current_index: = 0
onready var current_action_key_formatted: String = action_keys[0].replace("#", "")

var altContainer: HBoxContainer
onready var container: HBoxContainer = $Container

enum BUTTON_ICON_TYPES {
	PLAYSTATION,
	XBOX,
	NINTENDO
}
const icon_type_paths = {
	BUTTON_ICON_TYPES.PLAYSTATION: "res://sprites/ui/button_prompt/playstation/playstation.tres",
	BUTTON_ICON_TYPES.XBOX: "",
	BUTTON_ICON_TYPES.NINTENDO: ""
}
const keyboard_icons_path = ""
var frames: SpriteFrames

export var background_colour: = Color.transparent setget set_background_colour
func set_background_colour(value: Color):
	background_colour = value
	if not Engine.editor_hint:
		return
	$Container/Text/ColorRect.color = background_colour
	$Container/Text/ColorRect.visible = background_colour.a != 0

var transitioning: bool = false
func switch_to_index(index: int, fade_time: float = default_fade_time, ignore_transitioning: bool = false):
	if transitioning and not ignore_transitioning:
		return false
	
	current_index = index
	var self_index = current_index
	current_action_key_formatted = action_keys[current_index].replace("#", "")
	
	var show = container if not container.visible else altContainer
	var hide = container if container.visible else altContainer
	show.get_node("Text").text = text[current_index]
	show.get_node("Icon").texture = get_icon(current_index)
	
	show.visible = true
	if fade_time > 0:
#		$IndexTween.stop_all()
		transitioning = true
		$IndexTween.interpolate_property(show, "modulate:a", show.modulate.a, 1, fade_time)
		$IndexTween.interpolate_property(hide, "modulate:a", hide.modulate.a, 0, fade_time)
		$IndexTween.start()
		yield($IndexTween, "tween_completed")
		if current_index == self_index:
			hide.visible = false
		transitioning = false
	else:
		show.modulate.a = 1
		hide.modulate.a = 0
		hide.visible = false
	

func keyboard_mode_changed(_mode: bool):
	pass

func set_text(value: Array):
#	if not Engine.editor_hint:
#		return
	$Container/Text.text = value[0]
	text = value

func set_text_colour(value: Color):
	if Engine.editor_hint:
		return
	$Container/Text.set("custom_colors/default_color", value)
	text_colour = value

func settings_changed(path=null, value=null):
	if path == ["miscellaneous", "joypad_button_icon_style"] or path == null:
		frames = load(icon_type_paths[Settings.get("miscellaneous/joypad_button_icon_style")])

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if Engine.editor_hint:
		return
	
	$Container/Text/ColorRect.color = background_colour
	$Container/Text/ColorRect.visible = background_colour.a != 0
	set_text_colour(text_colour)
	settings_changed()
	
	altContainer = $Container.duplicate()
	altContainer.name = "altContainer"
	altContainer.visible = false
	add_child(altContainer)
	
	Shortcut.connect("keyboard_mode_changed", self, "keyboard_mode_changed")
	Settings.connect("settings_changed", self, "settings_changed")
	
	set_enabled(enabled, 0)
	switch_to_index(0)

func get_icon(index: int):
	var action_key = action_keys[index].replace("#", "")
	if not InputMap.has_action(action_key):
		assert(false, "Action '" + action_key + "' doesn't seem to exist")
	
	var action: Array = InputMap.get_action_list(action_key.replace("#", ""))
	for event in action:
		if not event.get_class() in ["InputEventJoypadButton", "InputEventJoypadMotion"]:
			continue
		return frames.get_frame(str(event.button_index), 0)

func set_enabled(value: bool, fade_time: float = default_fade_time):
	
	if not $EnabledTween.is_inside_tree():
		return
	
	enabled = value
	if enabled:
		visible = true
	if fade_time > 0:
		$EnabledTween.interpolate_property(self, "modulate:a", int(!enabled), int(enabled), fade_time)
		$EnabledTween.start()
		yield($EnabledTween, "tween_completed")
	if not enabled:
		visible = false

func pressed():
	return Input.is_action_pressed(current_action_key_formatted) and enabled

func just_pressed():
	return Input.is_action_just_pressed(current_action_key_formatted) and enabled

func just_released():
	return Input.is_action_just_released(current_action_key_formatted) and enabled
