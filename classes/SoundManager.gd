extends Node

export var starting_channel_amount = 5
enum types {NONE, VOICE, MUSIC, SFX, TEXT}

class AudioChannel extends AudioStreamPlayer:
	func _init():
		var type = types.NONE

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(starting_channel_amount):
		create_new_channel()

func create_new_channel() -> AudioStreamPlayer:
	
	var channel = AudioChannel.new()
	self.add_child(channel)
	
	return channel

func play(sound: AudioStreamSample, type: int, start_position: float = 0.0) -> AudioStreamPlayer:
	
	var channel_to_use = null
	
	for channel in self.get_children():
		if channel.playing:
			continue
		else:
			channel_to_use = channel
			break
	
	if channel_to_use == null:
		push_warning("Not enough audio channels, creating a new one")
		channel_to_use = create_new_channel()
	
	channel_to_use.type = type
	channel_to_use.stream = sound
	channel_to_use.play(start_position)
	return channel_to_use
