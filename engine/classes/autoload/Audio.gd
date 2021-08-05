extends Node

enum TYPE {SAMUS, ENEMY, FX, MUSIC}
var audio_resources: Dictionary = {}

func _ready():
	
	# Register all audio files to audio_resources
	var audio_resource_dirs: Array = []
	for dir in Data.data["engine_config"]["audio_directories"]:
		audio_resource_dirs.append(Global.dir2dict(dir))
	audio_resources = Global.combine_dicts(audio_resource_dirs)
	
func get_player(audio_path: String, type: int, follow: Node = self):
	
	var sound = Global.dict_get_by_path(audio_resources, audio_path)
	
	# DEBUG
	if sound == null:
		assert(false)
		return null
	
	if sound is String:
		sound = load(sound)
		Global.dict_set_by_path(audio_resources, audio_path, sound)
	
	var player
	if follow == self:
		player = AudioPlayer.new(sound)
	else:
		player = AudioPlayer2D.new(sound)
	follow.add_child(player)
	
	player.pause_mode = PAUSE_MODE_STOP
	
	return player
