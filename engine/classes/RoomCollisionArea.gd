extends Node2D
class_name RoomCollisionArea

enum GROUND_TYPES {GRASS, METAL, ROCK_01, ROCK_02, ROCK_03, WET, SNOW}
export(GROUND_TYPES) var ground_type: int = GROUND_TYPES.METAL

onready var ground_type_string: String = GROUND_TYPES.keys()[ground_type] 
var sounds: Dictionary
var current_step_sound_index: int = -1

const RoomPhysicsBody2D_script: String = "res://engine/classes/RoomPhysicsBody2D.gd"
var visual: Polygon2D

func _ready():
	
	assert(get_class() in ["CollisionShape2D", "CollisionPolygon2D"])
	assert(get_parent() is RoomPhysicsBody2D)
	
	# Prepare step and land sounds
	sounds = Global.dir2dict("res://engine/audio/samus/ground_types/" + ground_type_string + "/")
	for group in sounds:
		for sound in sounds[group]:
			var audio_key: String = Global.str_remove_all_before_input(sounds[group][sound], "/samus/ground_types/" + ground_type_string + "/")
			audio_key = Global.str_remove_all_after_input(audio_key, sound)
			sounds[group][sound] = Audio.get_player(audio_key, Audio.TYPE.SAMUS)
	
	# Add visible polygon for X-Ray visor
#	var s = self
#	if s is CollisionShape2D:
#		visual = ShapePolygon2D.new()
#		visual.shape = self.shape
#	else: # CollisionPolygon2D
#		visual = Polygon2D.new()
#		visual.polygon = self.polygon
#
#	visual.z_as_relative = false
#	visual.z_index = Enums.Layers.WORLD - 1
#	add_child(visual)
	
	if not is_visible_in_tree():
		var target: CanvasItem = self
		while target.is_visible_in_tree():
			target.visible = true
			if target.get_parent() is Viewport:
				break
			else:
				target = target.get_parent()

#func _set(property: String, value):
#	if property == "disabled":
#		visual.visible = !value
#	return false

func play_step_sound(_is_samus: bool = true):
	if "step" in sounds:
		current_step_sound_index = wrapi(current_step_sound_index + 1, 0, len(sounds["step"]))
#		Global.random_array_item(sounds["step"].values()).play()
		sounds["step"].values()[current_step_sound_index].play()

func play_land_sound(_is_samus: bool = true):
	if "land" in sounds:
		Global.random_array_item(sounds["land"].values()).play()
