extends BaseNotification

const start_pos = 1080.0
const end_pos = 1000.0

func ready():
#	$FancyLabel.background_colour = Notification.bg_colour
	visual.rect_position.y = start_pos

func hide_popup(animation_duration):
	$Tween.interpolate_property(visual, "rect_position:y", end_pos, start_pos, animation_duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	visual.visible = false

func trigger(input_key: String, text: String, animation_duration: float, end):
	visual.get_node("ButtonPrompt").action_keys[0] = input_key
	visual.get_node("ButtonPrompt").text[0] = text
	visual.get_node("ButtonPrompt").switch_to_index(0, 0)
#	$FancyLabel.set_text(data["text"], 0 if not "text_duration" in data else data["text_duration"])
	visual.visible = true
	
	$Tween.interpolate_property(visual, "rect_position:y", start_pos, end_pos, animation_duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	continue_triger(end, animation_duration)
	
	return visual.get_node("ButtonPrompt")

func continue_triger(end, animation_duration):
	yield($Tween, "tween_completed")
	
	if end is Array:
		end[0].connect(end[1], self, "hide_popup", [animation_duration])
		yield(end[0], end[1])
		end[0].disconnect(end[1], self, "hide_popup")
	else:
		yield(Global.wait(end, true), "completed")
		hide_popup(animation_duration)
