extends Node2D

export(Array, String) var action_keys: Array = [""]
export(Array, String) var text: Array = [""] setget set_text
export var text_colour: Color = Color.white setget set_text_colour

export var enabled: bool = true setget set_enabled
const default_fade_time: float = 0.25
export(ExTween.TransitionType) var transition_type: int
export(ExTween.EaseType) var ease_type: int

onready var current_action_key: String = action_keys[0]
onready var current_action_key_formatted: String = action_keys[0].replace("#", "")

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
	$Labels/Template/ColorRect.color = background_colour
	$Labels/Template/ColorRect.visible = background_colour.a != 0

var transitioning: bool = false
var current = 0
func switch_to_index(index: int, fade_time: float = default_fade_time, ignore_transitioning: bool = false):
	if transitioning and not ignore_transitioning:
		return false
	transitioning = true
	
	current += 1
	var self_current = current
	
	var to_show = [$Labels.get_node(action_keys[index]), $Icons.get_node(action_keys[index])]
	var to_hide = [$Labels.get_node(current_action_key), $Icons.get_node(current_action_key)]
	
	current_action_key = action_keys[index]
	current_action_key_formatted = action_keys[index].replace("#", "")
	
	if to_show[0] == to_hide[0] and to_show[1] == to_hide[1]:
		transitioning = false
		return
	
	if fade_time <= 0:
		for node in to_hide:
			node.modulate.a = 0
			node.visible = false
		for node in to_show:
			node.modulate.a = 1
			node.visible = true
	else:
		for node in to_hide:
			$IndexTween.interpolate_property(node, "modulate:a", 1, 0, fade_time, transition_type, ease_type)
		for node in to_show:
			$IndexTween.interpolate_property(node, "modulate:a", 0, 1, fade_time, transition_type, ease_type)
			node.visible = true
		$IndexTween.start()
		yield($IndexTween, "tween_completed")
		
		if current == self_current:
			for node in to_hide:
				node.visible = false
		
	transitioning = false

func keyboard_mode_changed(_mode: bool):
	pass

func set_text(value: Array):
#	if not Engine.editor_hint:
#		return
	$Labels/Template.text = value[0]
	text = value

func set_text_colour(value: Color):
	if Engine.editor_hint:
		return
	$Labels/Template.set("custom_colors/default_color", value)
	text_colour = value

func settings_changed(path=null, value=null):
	if path == ["miscellaneous", "joypad_button_icon_style"] or path == null:
		frames = load(icon_type_paths[Settings.get("miscellaneous/joypad_button_icon_style")])

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if Engine.editor_hint:
		return
	$Labels/Template/ColorRect.color = background_colour
	$Labels/Template/ColorRect.visible = background_colour.a != 0
	set_text_colour(text_colour)
	settings_changed()
	Shortcut.connect("keyboard_mode_changed", self, "keyboard_mode_changed")
	Settings.connect("settings_changed", self, "settings_changed")
	
	var i = 0
	for action_key in action_keys:
		if not InputMap.has_action(action_key.replace("#", "")):
			assert(false, "Action '" + action_key + "' doesn't seem to exist")
		
		var action: Array = InputMap.get_action_list(action_key.replace("#", ""))
		for event in action:
			if not event.get_class() in ["InputEventJoypadButton", "InputEventJoypadMotion"]:
				continue
			
			var icon = $Icons/Template.duplicate()
			$Icons.add_child(icon)
			icon.get_child(0).texture = frames.get_frame(str(event.button_index), 0)
			icon.visible = i == 0
			icon.modulate.a = 1 if i == 0 else 0
			icon.name = action_key
			
			var label = $Labels/Template.duplicate()
			$Labels.add_child(label)
			label.text = text[i]
			label.name = action_key
			label.visible = i == 0
			label.modulate.a = 1 if i == 0 else 0
			label.set("custom_colors/default_color", text_colour)
			break
			
		i += 1
	
	$Icons/Template.queue_free()
	$Labels/Template.queue_free()
	set_enabled(enabled, 0)

func set_enabled(value: bool, fade_time: float = default_fade_time):
	
	if not $EnabledTween.is_inside_tree():
		return
	
	enabled = value
	if enabled:
		visible = true
	if fade_time > 0:
		$EnabledTween.interpolate_property(self, "modulate:a", int(!enabled), int(enabled), fade_time, transition_type, ease_type)
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
