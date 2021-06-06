extends NotificationBaseVariant

const start_pos = 1080.0
const end_pos = 1000.0

func ready():
#	$FancyLabel.background_colour = Notification.bg_colour
	rect_position.y = start_pos

func hide_popup(data: Dictionary):
	$Tween.interpolate_property(self, "rect_position:y", end_pos, start_pos, data["animation_duration"], Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	visible = false

# Data parameters:
# text
# input_key
# animation_duration
# show_duration
# end_signal
func trigger(data: Dictionary):
	$ButtonPrompt.action_keys[0] = data["input_key"]
	$ButtonPrompt.text[0] = data["text"]
	$ButtonPrompt.switch_to_index(0, 0)
#	$FancyLabel.set_text(data["text"], 0 if not "text_duration" in data else data["text_duration"])
	visible = true
	
	$Tween.interpolate_property(self, "rect_position:y", start_pos, end_pos, data["animation_duration"], Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	continue_triger(data)
	
	return $ButtonPrompt

func continue_triger(data):
	yield($Tween, "tween_completed")
	
	if "end_signal" in data:
		data["end_signal"][0].connect(data["end_signal"][1], self, "hide_popup", [data])
		yield(data["end_signal"][0], data["end_signal"][1])
		data["end_signal"][0].disconnect(data["end_signal"][1], self, "hide_popup")
	else:
		yield(Global.wait(data["show_duration"], true), "completed")
		hide_popup(data)
