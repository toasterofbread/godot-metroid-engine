extends Control

onready var Tiles = $CenterContainer/Center/Tiles
onready var tween: Tween = $Tween

const minimap_size = Vector2(80, 48)
const minimap_position = Vector2(552, 8)
const minimap_scale = Vector2(1, 1)

var focus_position = Vector2.ZERO setget set_focus_position

func _ready():
	self.rect_size = minimap_size
	self.rect_position = minimap_position

func reset_minimap_properties():
	self.rect_size = minimap_size
	self.rect_position = minimap_position
	self.rect_scale = minimap_scale

func set_focus_position(position: Vector2, instant: bool = false):
	focus_position = position
	tween.stop_all()
	tween.interpolate_property(Tiles, "position", Tiles.position, -position, 0.0 if instant else 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
