extends Timer
class_name ExTimer

signal started

func start(time_sec: float = -1):
	.start(time_sec)
	emit_signal("started")
