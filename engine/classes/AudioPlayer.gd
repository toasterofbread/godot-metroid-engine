extends  AudioStreamPlayer
class_name AudioPlayer

signal started
signal looping

enum STATE {PLAYING, STOPPED, UNSTARTED, FINISHED}
var status: int = STATE.UNSTARTED
var loop_amount: int = 0

var _start_time: float

func _init(sound):
	connect("finished", self, "_on_finished")
	stream = sound

func set_loop(loop: int):
	loop_amount = loop
	return self
func set_ignore_paused(ignore_paused: bool):
	pause_mode = Node.PAUSE_MODE_PROCESS if ignore_paused else Node.PAUSE_MODE_STOP
	return self
func set_volume(volume: float):
	volume_db = volume
	return self

func play(from_position: float = 0.0, until_position: float = -1.0, play_when_finished=null):
	.play(from_position)
	status = STATE.PLAYING
	emit_signal("started")
	
	if until_position > 0.0:
		var time: float = OS.get_ticks_msec()
		_start_time = time
		yield(Global.wait(until_position, pause_mode == Node.PAUSE_MODE_PROCESS), "completed")
		if _start_time == time:
			.stop()
			status = STATE.FINISHED
			emit_signal("finished")
			if play_when_finished:
				play_when_finished.play()
	else:
		if play_when_finished:
			var time: float = OS.get_ticks_msec()
			_start_time = time
			yield(self, "finished")
			if _start_time == time:
				play_when_finished.play()
		else:
			_start_time = OS.get_ticks_msec()

func pause():
	status = STATE.PAUSED
	stream_paused = true

func resume():
	status = STATE.PLAYING
	stream_paused = false

func stop():
	.stop()
	_start_time = 0.0
	status = STATE.STOPPED

func _on_finished():
	if loop_amount != 0:
		if status == STATE.PLAYING:
			loop_amount -= 1
			.play()
			emit_signal("looping")
	else:
		status = STATE.FINISHED
