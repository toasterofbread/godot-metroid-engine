extends NotificationBaseVariant

const start_pos = 1080.0
const end_pos = 1000.0

func ready():
	$FancyLabel.background_colour = Notification.bg_colour
	rect_position.y = start_pos

# Data parameters:
# text
# animation_duration
# text_duration
# show_duration
func trigger(data: Dictionary):
	$FancyLabel.set_text(data["text"], 0 if not "text_duration" in data else data["text_duration"])
	visible = true
	
	$Tween.interpolate_property(self, "rect_position:y", start_pos, end_pos, data["animation_duration"], Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	yield(Global.wait(data["show_duration"], true), "completed")
	
	$Tween.interpolate_property(self, "rect_position:y", end_pos, start_pos, data["animation_duration"], Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	visible = false
