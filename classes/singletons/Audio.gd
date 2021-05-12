extends Node

export var starting_channel_amount = 5
enum types {Voice, Music, Samus, Enemies, OTHER}

var _playing_sounds = {}

class AudioPlayer extends AudioStreamPlayer:
	var loop: bool = false
	func _init():
		self.connect("finished", self, "_finished")
	
	func _finished():
		if loop:
			self.play()
		else:
			Audio._playing_sounds.erase(self.stream)

class AudioPlayer2D extends AudioStreamPlayer2D:
	var loop: bool = false
	func _init():
		self.connect("finished", self, "_finished")
	
	func _finished():
		if loop:
			self.play()
		else:
			Audio._playing_sounds.erase(self.channel)

func playing(sound: AudioStreamSample):
	return sound in _playing_sounds

func create_new_channel(parent_node: Node) -> AudioStreamPlayer:
	var channel
	if parent_node == self:
		channel = AudioPlayer.new()
	else:
		channel = AudioPlayer2D.new()
	parent_node.add_child(channel)
	return channel

func play(sound: AudioStreamSample, type: int, loop: bool = false, parent_node = null, start_position: float = 0.0) -> AudioStreamPlayer:
	
	if playing(sound):
		return _playing_sounds[sound]
	
	var channel_to_use: AudioStreamPlayer
	var parent = self
	if parent_node != null:
		parent = parent_node
	
	for channel in parent.get_children():
		if channel.playing or channel.bus != types.keys()[type]:
			continue
		else:
			channel_to_use = channel
			break
	
	if channel_to_use == null:
		channel_to_use = create_new_channel(parent)
	
	_playing_sounds[sound] = channel_to_use
	
	channel_to_use.loop = loop
	channel_to_use.bus = types.keys()[type]
	channel_to_use.stream = sound
	channel_to_use.play(start_position)
	return channel_to_use

func stop(sound: AudioStreamSample):
	if sound in _playing_sounds:
		_playing_sounds[sound].loop = false
		_playing_sounds[sound].stop()
