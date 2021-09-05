extends Area2D
class_name ExArea2D

signal body_entered_safe
signal body_exited_safe

export var safe_wait_time: float = 0.2
var body_enter_record: Dictionary = {}
var body_exit_record: Dictionary = {}

func _ready():
	connect("body_entered", self, "_body_entered")
	connect("body_exited", self, "_body_exited")

func _body_entered(body):
	var time: int = OS.get_ticks_msec()
	body_enter_record[body] = time
	
	if body in body_exit_record and (time - body_exit_record[body]) < (safe_wait_time * 1000):
		return
	
	emit_signal("body_entered_safe", body)

func _body_exited(body):
	body_enter_record.erase(body)
	var time: int = OS.get_ticks_msec()
	body_exit_record[body] = time
	
	Global.wait(safe_wait_time, false, [self, "_body_exited_waited", [body, time]])

func _body_exited_waited(body, time: float):
	if not body in body_enter_record and is_instance_valid(body) and body in body_exit_record and body_exit_record[body] == time:
		emit_signal("body_exited_safe", body)
