extends Tween
class_name ExTween

signal ended
enum END_TYPE {COMPLETED, STOPPED}

enum TransitionType {LINEAR, SINE, QUINT, QUART, QUAD, EXPO, ELASTIC, CUBIC, CIRC, BOUNCE, BACK}
enum EaseType {IN, OUT, IN_OUT, OUT_IN}

var start_timestamp
#func _ready():
#	self.connect("tween_completed")

func ex_stop_all():
	emit_signal("ended", END_TYPE.STOPPED)
	stop_all()

func ex_start():
	pass

func completed():
	pass
