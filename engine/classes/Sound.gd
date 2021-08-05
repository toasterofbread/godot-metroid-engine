extends Node
#class_name Sound

var loop: bool = false
var StreamPlayer: Node
var parent: Node
var length: float

signal finished
signal looping

enum STATE {PLAYING, PAUSED, STOPPED, UNSTARTED, FINISHED}
var status: int = STATE.UNSTARTED

enum TYPE {SAMUS, ENEMY, FX, MUSIC}
var type: int

func _init(stream_path: String, _type: int, volume: float = 0.0, _parent: Node = Audio):
	
#	if _parent == null:
#		yield(Audio, "ready")
#		_parent = Audio
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	type = _type
	parent = _parent
	parent.add_child(self)
	if parent == Audio:
		StreamPlayer = AudioStreamPlayer.new()
	else:
		StreamPlayer = AudioStreamPlayer2D.new()
	StreamPlayer.volume_db = volume
	StreamPlayer.stream = load(stream_path)
	StreamPlayer.connect("finished", self, "_finished")
	self.add_child(StreamPlayer)
	
func _finished():
	if status == STATE.STOPPED:
		return
	if loop:
		play()
		emit_signal("looping")
	else:
		status = STATE.FINISHED
		emit_signal("finished")

func play(_loop:=false, ignore_paused:=false, from_position: float = 0.0):
	loop = _loop
	StreamPlayer.pause_mode = Node.PAUSE_MODE_PROCESS if ignore_paused else Node.PAUSE_MODE_STOP
	status = STATE.PLAYING
	StreamPlayer.play(from_position)
	return self

func pause():
	status = STATE.PAUSED
	StreamPlayer.stream_paused = true

func resume():
	status = STATE.PLAYING
	StreamPlayer.stream_paused = false

func stop():
	status = STATE.STOPPED
	StreamPlayer.stop()

func get_length():
	return StreamPlayer.stream.get_length()
