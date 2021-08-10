extends Node

enum TYPE {SAMUS, ENEMY, FX, MUSIC}
var audio_resources: Dictionary = {}

func _ready():
	
	# Register all audio files to audio_resources
	var audio_resource_dirs: Array = []
	for dir in Data.data["engine_config"]["audio_directories"]:
		audio_resource_dirs.append(Global.dir2dict(dir, Global.DIR2DICT_MODES.SINGLE_LAYER_FILE, null, ["ogg", "wav"]))
	audio_resources = Global.combine_dicts(audio_resource_dirs)
	
func get_player(audio_path: String, type: int, follow: Node = self):
	
	audio_path = audio_path.trim_prefix("/")
	var sound = audio_resources[audio_path]
	
	# DEBUG
	if sound == null:
		assert(false)
		return null
	
	if sound is String:
		sound = load(sound)
		audio_resources[audio_path] = sound
	
	var player
	if follow == self:
		player = AudioPlayer.new(sound)
	else:
		player = AudioPlayer2D.new(sound)
	follow.add_child(player)
	
	player.pause_mode = PAUSE_MODE_STOP
	
	return player

func get_players_from_dir(dir_path: String, type: int, follow: Node = self) -> Dictionary:
	
	var audio_resource_dirs: Array = []
	for dir in Data.data["engine_config"]["audio_directories"]:
		var result = Global.dir2dict(dir + dir_path, Global.DIR2DICT_MODES.SINGLE_LAYER_FILE, null, ["ogg", "wav"])
		if result is Dictionary:
			audio_resource_dirs.append(result)
	
	var ret: Dictionary = Global.combine_dicts(audio_resource_dirs)
	if not dir_path.ends_with("/"):
		dir_path += "/"
	for sound_path in ret:
		ret[sound_path] = get_player(dir_path + sound_path, type, follow)
	return ret
