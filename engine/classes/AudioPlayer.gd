extends  AudioStreamPlayer
class_name AudioPlayer

signal started

enum STATE {PLAYING, STOPPED, UNSTARTED, FINISHED}
var status: int = STATE.UNSTARTED
#var loop_amount: int = 0

func _init(sound):
	connect("finished", self, "_on_finished")
	stream = sound

#func set_loop(loop: int):
#	loop_amount = loop
#	return self
func set_ignore_paused(ignore_paused: bool):
	pause_mode = Node.PAUSE_MODE_PROCESS if ignore_paused else Node.PAUSE_MODE_STOP
	return self
func set_volume(volume: float):
	volume_db = volume
	return self

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
#	if loop_amount != 0:
#		if status == STATE.PLAYING:
#			loop_amount -= 1
#			.play()
#			emit_signal("looping")
#	else:
	status = STATE.FINISHED
