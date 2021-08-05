extends Control
class_name ButtonGetter

const get_button_wait_time: float = 5.0
signal _result

signal status_changed

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = false
	modulate.a = 0.0

func get_button(action_key: String):
	$TimeoutTimer.start(get_button_wait_time)
	get_tree().paused = true
	
	$Label.text = tr("buttongetter_main_text") + " " + action_key
	
	visible = true
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.2)
	$Tween.start()
	
	emit_signal("status_changed", true)
	var result = yield(self, "_result")
	
	emit_signal("status_changed", false)
	$TimeoutTimer.stop()
	
	$Tween.stop_all()
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	get_tree().paused = false
	return result

func _input(event: InputEvent):
	if $TimeoutTimer.time_left <= 0 or not event.get_class() in ["InputEventKey", "InputEventMouseButton", "InputEventJoypadButton"] or not event.pressed:
		return
	
	var ret: Dictionary = {"type": event.get_class()}
	if event is InputEventJoypadButton:
		ret["button_index"] = event.button_index
		ret = {"joypad": ret}
	else:
		if event is InputEventKey:
			ret["scancode"] = event.scancode
		elif event is InputEventMouseButton:
			ret["button_index"] = event.button_index
		ret = {"keyboard": ret}
	
	emit_signal("_result", ret)

func _process(_delta: float):
	if $TimeoutTimer.time_left > 0.0:
		$TimeLabel.text = tr("buttongetter_time_remaining") + " " + str(int($TimeoutTimer.time_left))

func _on_TimeoutTimer_timeout():
	emit_signal("_result", null)

func _on_ButtonGetter_status_changed(shown: bool):
	set_process(shown)
