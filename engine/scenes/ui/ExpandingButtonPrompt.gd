tool
extends Node2D

export var duration: float
export(ExTween.TransitionType) var transition_type: int
export(ExTween.EaseType) var ease_type: int

onready var default_state: ColorRect = $Background.duplicate()

const properties_to_set = [
	"rect_size", "rect_position", "rect_scale",
	"margin_left", "margin_right", "margin_left", "margin_top"
]

func _ready():
	$BackgroundStates.visible = false

var transitioning = false
func expand_to_point(index: int, instant: bool = false):
	if transitioning:
		return false
	transitioning = true
	
	var state: ColorRect
	if index < 0:
		state = default_state
	else:
		state = $BackgroundStates.get_child(index)
	
	for property in properties_to_set:
		if not instant:
			$Tween.interpolate_property($Background, property, $Background.get(property), state.get(property), duration, transition_type, ease_type)
		else:
			$Background.set(property, state.get(property))
	if not instant:
		$Tween.start()
		yield(Global.wait(duration, true), "completed")
	
	transitioning = false
	return true
