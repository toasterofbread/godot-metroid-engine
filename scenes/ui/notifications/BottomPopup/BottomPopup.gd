extends BaseNotification

const start_pos = 1080.0
const end_pos = 1000.0

func ready():
	visual.get_node("FancyLabel").background_colour = Notification.bg_colour
	visual.rect_position.y = start_pos

func trigger(text: String, end=2.0, animation_duration:=0.25, text_show_duration:=0.0):
	visual.get_node("FancyLabel").set_text(text, text_show_duration)
	visual.visible = true
	
	$Tween.interpolate_property(visual, "rect_position:y", start_pos, end_pos, animation_duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	if end is Array:
		yield(end[0], end[1])
	else:
		yield(Global.wait(end, true), "completed")
	
	$Tween.interpolate_property(visual, "rect_position:y", end_pos, start_pos, animation_duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	visual.visible = false
