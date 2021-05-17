extends Control

onready var Tiles = $CenterContainer/Center/Tiles
onready var tween: Tween = $Tween

onready var minimap_size: Vector2 = self.rect_size
onready var minimap_position: Vector2 = self.rect_position
onready var minimap_scale: Vector2 = self.rect_scale

var focus_position = Vector2.ZERO setget set_focus_position

onready var Background: TextureRect = $Background
var background_offset: Vector2 = Vector2.ZERO setget set_background_offset
var background_size: Vector2 = Vector2(80, 48)

func fade(fade_in: bool, duration: float):
	tween.interpolate_property(self, "modulate:a", int(!fade_in), int(fade_in), duration)
	tween.start()
	yield(tween, "tween_completed")

func position_to_offset(position: Vector2) -> Vector2:
	
	for axis in ["x", "y"]:
		while position[axis] > 8:
			position[axis] -= 8
		while position[axis] < -8:
			position[axis] += 8
	
	return position

func set_background_offset(value: Vector2):
	if value == background_offset:
		return
	
	background_offset = position_to_offset(value)
	Background.rect_position = Vector2(-8, -8) + background_offset

var map_offset_offset = Vector2.ZERO
func _process(_delta):
	# Background size gets set to null for no reason when closing the pause menu
	# Only way I could find to prevent that was this
	Background.rect_size = background_size + Vector2(16, 16)
	set_background_offset(Tiles.position + map_offset_offset)

func reset_minimap_properties():
	rect_size = minimap_size
	rect_position = minimap_position
	rect_scale = minimap_scale
	background_size = Vector2(80, 48)
	map_offset_offset = Vector2.ZERO
	visible = true

#	modulate = Color.white
func set_focus_position(position: Vector2, instant: bool = false):
	focus_position = position
	
#	tween.stop_all()
	tween.interpolate_property(Tiles, "position", Tiles.position, -position, 0.0 if instant else 0.1, Tween.TRANS_LINEAR)
	tween.start()
