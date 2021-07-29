tool
extends Control

export var preview_text: String setget set_preview_text
export var preview_texture: Texture setget set_preview_texture

export var default_text: String
export var default_action_key: String

enum HOLD_TIMES {NONE, SHORT, MEDIUM, LONG}
const hold_times_data: Dictionary = {
	HOLD_TIMES.NONE: 0.0,
	HOLD_TIMES.SHORT: 0.5,
	HOLD_TIMES.MEDIUM: 1.0,
	HOLD_TIMES.LONG: 1.5
}
export(HOLD_TIMES) var hold_time: int = HOLD_TIMES.NONE
var current_hold_time: float = 0.0
var hold_completed: bool = false

export var start_invisible: bool = false

func _ready():
	
	if Engine.editor_hint:
		return
	
	if default_action_key != "":
		set_action_key(default_action_key, false)
	if default_text != "":
		set_text(default_text, false)
	
	if start_invisible:
		visible = false
	
	if hold_time == HOLD_TIMES.NONE:
		current_hold_time = -1
		hold_completed = true
		set_process(false)
	else:
		set_process(not start_invisible)
	
	$ProgressBarContainer.visible = false

func _process(delta: float):
	
	if Engine.editor_hint:
		return
	
	if Input.is_action_pressed(_action_key) and current_hold_time != -1:
		$ProgressBarContainer.visible = true
		current_hold_time += delta
		$ProgressBarContainer/ColorRect.rect_size.x = (rect_size.x + 4) * (current_hold_time / hold_times_data[hold_time])
		if current_hold_time >= hold_times_data[hold_time]:
			current_hold_time = -1
			hold_completed = true
	else:
		if $ProgressBarContainer.visible:
			$ProgressBarContainer/ColorRect.rect_size.x = lerp($ProgressBarContainer/ColorRect.rect_size.x, 0, delta*10)
			if $ProgressBarContainer/ColorRect.rect_size.x == 0:
				$ProgressBarContainer.visible = false
		if not Input.is_action_pressed(_action_key):
			current_hold_time = 0.0
			hold_completed = false

func set_preview_texture(value: Texture):
	preview_texture = value
	if not Engine.editor_hint:
		return
	$ButtonIconContainer/ButtonIcon.texture = preview_texture

func set_preview_text(value: String):
	preview_text = value
	if not Engine.editor_hint:
		return
	$Label.text = preview_text

var _action_key: String
var current_action_key_tween: float
func set_action_key(action_key: String, animate: bool):
	_action_key = action_key
	
	if animate:
		var time: float = OS.get_ticks_msec()
		current_action_key_tween = time
		
		$TweenIcon.stop_all()
		$TweenIcon.interpolate_property($ButtonIconContainer/ButtonIcon, "modulate:a", $ButtonIconContainer/ButtonIcon.modulate.a, 0.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$TweenIcon.start()
		yield($TweenIcon, "tween_completed")
		if current_action_key_tween != time:
			return
	
	$ButtonIconContainer/ButtonIcon.action_key = action_key
	
	if animate:
		$TweenIcon.interpolate_property($ButtonIconContainer/ButtonIcon, "modulate:a", $ButtonIconContainer/ButtonIcon.modulate.a, 1.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)

var current_text_tween: float
func set_text(text_key: String, animate: bool):
	
	if animate:
		var time: float = OS.get_ticks_msec()
		current_text_tween = time
		
		$TweenLabel.stop_all()
		$TweenLabel.interpolate_property($Label, "modulate:a", $Label.modulate.a, 0.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$TweenIcon.start()
		yield($TweenLabel, "tween_completed")
		if current_text_tween != time:
			return
	
	$Label.text = tr(text_key)
	
	if animate:
		$TweenLabel.interpolate_property($Label, "modulate:a", $Label.modulate.a, 1.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)

var current_visibility_tween: float
func set_visibility(visibility: bool, animate: bool):
	
	set_process(hold_time != HOLD_TIMES.NONE and visibility)
	if visibility:
		modulate.a = 0.0
		visible = true
	
	if animate:
		var time: float = OS.get_ticks_msec()
		current_visibility_tween = time
		$TweenVisibility.stop_all()
		$TweenVisibility.interpolate_property(self, "modulate:a", modulate.a, float(visibility), 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$TweenVisibility.start()
		
		if not visibility:
			yield($TweenVisibility, "tween_completed")
			if current_visibility_tween != time:
				return
	
	if not visibility:
		visible = false
		modulate.a = 1.0

func pressed():
	if hold_time != HOLD_TIMES.NONE:
		return _held()
	else:
		return Input.is_action_pressed(_action_key)
func just_pressed():
	if hold_time != HOLD_TIMES.NONE:
		return _held()
	else:
		return Input.is_action_just_pressed(_action_key)
func just_released():
	if hold_time != HOLD_TIMES.NONE:
		return _held()
	else:
		return Input.is_action_just_released(_action_key)
func _held():
	if hold_completed:
		hold_completed = false
		return Input.is_action_pressed(_action_key)
	return false
