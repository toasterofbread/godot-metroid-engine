extends BaseNotification

signal option_selected
onready var accept: ButtonPrompt = visual.get_node("Accept")
onready var cancel: ButtonPrompt = visual.get_node("Cancel")

var hiding = false

func trigger(text: String, accept_text: String, cancel_text: String):
	accept.text[0] = accept_text
	accept.switch_to_index(0, 0)
	
	cancel.text[0] = cancel_text
	cancel.switch_to_index(0, 0)
	
	visual.get_node("Label").text = text
	
	visual.visible = true
	hiding = false
	$Tween.interpolate_property(visual, "modulate:a", visual.modulate.a, 1, 0.25)
	$Tween.start()
	return self

func hide_popup():
	hiding = true
	$Tween.stop_all()
	$Tween.interpolate_property(visual, "modulate:a", visual.modulate.a, 0, 0.25)
	$Tween.start()
	if yield($Tween, "tween_completed") == [visual, "modulate:a"]:
		visual.visible = false

func _process(delta):
	if visual.visible and not hiding:
		if accept.just_pressed():
			emit_signal("option_selected", true)
			hide_popup()
		elif cancel.just_pressed():
			emit_signal("option_selected", false)
			hide_popup()
