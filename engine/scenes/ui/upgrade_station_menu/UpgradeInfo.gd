extends ColorRect

var selected: = true setget set_selected
var current_action = null
#var default_colour: Color = color
var data: Dictionary
var selection_indicator: ColorRect

signal fade_completed
var fading = false

func _ready():
	$Title.percent_visible = 0
	set_focus_mode(Control.FOCUS_ALL)

func set_selected(value: bool):
	
	if selected == value:
		return
	
	selected = value
	if selected:
		grab_focus()
		var tween: Tween = selection_indicator.get_node("Tween")
		tween.stop_all()
		tween.interpolate_property(selection_indicator, "rect_global_position:y", selection_indicator.rect_global_position.y, rect_global_position.y, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()

func init(_data: Dictionary, _selection_indicator: ColorRect):
	data = _data
	selection_indicator = _selection_indicator
	$Title.text = data["name"]
	$Cost.text = "x " + str(data["cost"])
	set_selected(false)

func show_info(fade: bool):
	var action_id = Global.time()
	current_action = action_id
	$Tween.stop_all()
	
	if not fade:
		$Tween.interpolate_property($Title, "percent_visible", 0, 1, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
	else:
		fading = true
		$Title.percent_visible = 1
		$Tween.interpolate_property(self, "modulate:a", 0, 1, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
	
	visible = true
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	if fade:
		fading = false
		emit_signal("fade_completed")
	
	if current_action == action_id:
		current_action = null
		return true
	else:
		return false

func hide_info(fade: bool):
	var action_id = Global.time()
	current_action = action_id
	$Tween.stop_all()
	if not fade:
		$Tween.interpolate_property($Title, "percent_visible", 1, 0, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
	else:
		fading = true
		$Tween.interpolate_property(self, "modulate:a", 1, 0, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
	
	$Tween.start()
	yield($Tween, "tween_completed")
	
	if fade:
		fading = false
		visible = false
		emit_signal("fade_completed")
	
	if current_action == action_id:
		current_action = null
		return true
	else:
		return false
	
