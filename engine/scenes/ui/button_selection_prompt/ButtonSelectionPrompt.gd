extends Control
class_name ButtonGetter

enum TYPE {BUTTON, STICK}
var current_type: int = -1

var stick_ret: Dictionary = {}
var blacklist: Array = []
var active: bool = true

const get_button_wait_time: float = 10.0
signal _result
signal status_changed
signal _accept_or_cancel_pressed

onready var buttonIcon: ButtonIcon = $ScaleContainer/VBoxContainer/DetectionLabel/ScaleContainer/ButtonIcon

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = false
	modulate.a = 0.0

func get_button(action_key: String, type: int):
	current_type = type
	active = true
	stick_ret.clear()
	blacklist.clear()
	$TimeoutTimer.start(get_button_wait_time)
	get_tree().paused = true
	
	if type == TYPE.BUTTON:
		$ScaleContainer/VBoxContainer/TitleLabel.text = tr("buttongetter_button_assign") + " " + action_key
	else:
		$ScaleContainer/VBoxContainer/TitleLabel.text = tr("buttongetter_stick_assign") + " " + action_key
		$ScaleContainer/VBoxContainer/Buttons/Blacklist.set_text("buttongetter_button_blacklist_" + ("button" if type == TYPE.BUTTON else "axis"), false)
	$ScaleContainer/VBoxContainer/Buttons.modulate.a = 0
	$ScaleContainer/VBoxContainer/DetectionLabel.text = ""
	buttonIcon.visible = false
	
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
	visible = false
	
	get_tree().paused = false
	return result

func _input(event: InputEvent):
	if $TimeoutTimer.time_left <= 0 or ("pressed" in event and not event.pressed) or not active:
		return
	
	# Button
	if current_type == TYPE.BUTTON:
		if event.get_class() in ["InputEventKey", "InputEventMouseButton", "InputEventJoypadButton"] and not event.as_text() in blacklist:
			
			$ScaleContainer/VBoxContainer/Buttons/Tween.interpolate_property($ScaleContainer/VBoxContainer/Buttons, "modulate:a", $ScaleContainer/VBoxContainer/Buttons.modulate.a, 1.0, 0.2)
			$ScaleContainer/VBoxContainer/Buttons/Tween.start()
			$ScaleContainer/VBoxContainer/DetectionLabel.text = tr("buttongetter_detected_button") + " "
			buttonIcon.event_override = event
			buttonIcon.keyboard_mode_override = not event is InputEventJoypadButton
			buttonIcon.update_icon()
			buttonIcon.visible = true
			
			active = false
			$TimeoutTimer.start(get_button_wait_time)
			$TimeoutTimer.stop()
			var blacklist_button: bool = !yield(self, "_accept_or_cancel_pressed")
			$TimeoutTimer.start(get_button_wait_time)
			$ScaleContainer/VBoxContainer/Buttons/Tween.stop_all()
			$ScaleContainer/VBoxContainer/Buttons/Tween.interpolate_property($ScaleContainer/VBoxContainer/Buttons, "modulate:a", $ScaleContainer/VBoxContainer/Buttons.modulate.a, 0.0, 0.2)
			$ScaleContainer/VBoxContainer/Buttons/Tween.start()
			buttonIcon.visible = false
			if blacklist_button:
				$ScaleContainer/VBoxContainer/DetectionLabel.text = tr("buttongetter_button_press")
				blacklist.append(event.as_text())
				yield(get_tree(), "idle_frame") # Prevent ui_cancel from being immediately detected
				active = true
			else:
				emit_signal("_result", {"joypad" if event is InputEventJoypadButton else "keyboard": event})
	
	# Stick
	elif event is InputEventJoypadMotion and not event.axis in blacklist and abs(event.axis_value) >= InputManager.joystick_deadzone:
		
		$ScaleContainer/VBoxContainer/Buttons/Tween.interpolate_property($ScaleContainer/VBoxContainer/Buttons, "modulate:a", $ScaleContainer/VBoxContainer/Buttons.modulate.a, 1.0, 0.2)
		$ScaleContainer/VBoxContainer/Buttons/Tween.start()
		$ScaleContainer/VBoxContainer/DetectionLabel.text = tr("buttongetter_detected_axis") + " " + str(event.axis)
		
		active = false
		$TimeoutTimer.start(get_button_wait_time)
		$TimeoutTimer.stop()
		var blacklist_axis: bool = !yield(self, "_accept_or_cancel_pressed")
		$TimeoutTimer.start(get_button_wait_time)
		$ScaleContainer/VBoxContainer/Buttons/Tween.stop_all()
		$ScaleContainer/VBoxContainer/Buttons/Tween.interpolate_property($ScaleContainer/VBoxContainer/Buttons, "modulate:a", $ScaleContainer/VBoxContainer/Buttons.modulate.a, 0.0, 0.2)
		$ScaleContainer/VBoxContainer/Buttons/Tween.start()
		active = true
		if blacklist_axis:
			$ScaleContainer/VBoxContainer/DetectionLabel.text = tr("buttongetter_stick_press_" + ("x" if len(stick_ret) == 0 else "y"))
			blacklist.append(event.axis)
			return
		
		event.axis_value = sign(event.axis_value)
		if len(stick_ret) == 0:
			stick_ret["x"] = event
		else:
			stick_ret["y"] = event
			emit_signal("_result", stick_ret)
			return
		
		$ScaleContainer/VBoxContainer/DetectionLabel.text = tr("buttongetter_stick_press_" + ("x" if len(stick_ret) == 0 else "y"))

func _process(_delta: float):
	$TimeLabel.text = str(get_button_wait_time) if $TimeoutTimer.is_stopped() else str(int($TimeoutTimer.time_left))

func _on_TimeoutTimer_timeout():
	emit_signal("_result", null)

func _on_ButtonGetter_status_changed(shown: bool):
	set_process(shown)

func _on_Accept_just_pressed():
	emit_signal("_accept_or_cancel_pressed", true)

func _on_Blacklist_just_pressed():
	emit_signal("_accept_or_cancel_pressed", false)
