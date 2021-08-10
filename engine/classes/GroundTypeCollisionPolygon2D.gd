extends Node2D
class_name GroundTypeCollisionShape2D

enum GROUND_TYPES {GRASS, METAL, ROCK_01, ROCK_02, ROCK_03, WET, SNOW}
export(GROUND_TYPES) var ground_type: int = GROUND_TYPES.ROCK_01
onready var ground_type_string: String = GROUND_TYPES.keys()[ground_type] 
onready var sounds: Dictionary = Global.dir2dict("res://engine/audio/samus/ground_types/" + ground_type_string + "/")

var current_step_sound_index: int = -1

func _ready():
	for group in sounds:
		for sound in sounds[group]:
			var audio_key: String = Global.str_remove_all_before_input(sounds[group][sound], "/samus/ground_types/" + ground_type_string + "/")
			audio_key = Global.str_remove_all_after_input(audio_key, sound)
			sounds[group][sound] = Audio.get_player(audio_key, Audio.TYPE.SAMUS)

func play_step_sound(_is_samus: bool = true):
	if "step" in sounds:
		current_step_sound_index = wrapi(current_step_sound_index + 1, 0, len(sounds["step"]))
#		Global.random_array_item(sounds["step"].values()).play()
		sounds["step"].values()[current_step_sound_index].play()

func play_land_sound(_is_samus: bool = true):
	if "land" in sounds:
		Global.random_array_item(sounds["land"].values()).play()
