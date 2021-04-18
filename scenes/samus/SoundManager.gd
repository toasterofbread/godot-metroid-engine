extends Node

export var starting_channel_amount = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	create_new_channel(starting_channel_amount)

func create_new_channel(amount: int = 1) -> AudioStreamPlayer:
	
	var ret: AudioStreamPlayer
	
	for i in range(amount):
		var channel = AudioStreamPlayer.new()
		channel.name = "channel_" + str(i)
		self.add_child(channel)
		ret = channel
		
	return ret

func play(sound: AudioStreamSample, start_position: float = 0.0) -> AudioStreamPlayer:
	
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
	
	channel_to_use.stream = sound
	channel_to_use.play(start_position)
	return channel_to_use
