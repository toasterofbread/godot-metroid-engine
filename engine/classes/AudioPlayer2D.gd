extends  AudioStreamPlayer2D
class_name AudioPlayer2D

signal started
signal looping

enum STATE {PLAYING, STOPPED, UNSTARTED, FINISHED}
var status: int = STATE.UNSTARTED
var loop_amount

func _init(sound, _loop_amount: int):
	loop_amount = _loop_amount
	connect("finished", self, "_on_finished")
	stream = sound

func play(from_position: float = 0.0):
	.play(from_position)
	status = STATE.PLAYING
	emit_signal("started")

func pause():
	status = STATE.PAUSED
	stream_paused = true

func resume():
	status = STATE.PLAYING
	stream_paused = false

func stop():
	.stop()
	status = STATE.STOPPED

func _on_finished():
	if loop_amount != 0:
		if status == STATE.PLAYING:
			loop_amount -= 1
			.play()
			emit_signal("looping")
	else:
		status = STATE.FINISHED
