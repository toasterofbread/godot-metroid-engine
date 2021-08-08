extends Timer
class_name ExTimer

signal started

func start(time_sec: float = -1):
	.start(time_sec)
	emit_signal("started")

func set_wait_time(value: float):
	wait_time = value
	return self
