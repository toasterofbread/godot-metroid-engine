extends Control

onready var Tiles = $CenterContainer/Center/Tiles
onready var tween: Tween = $Tween

onready var minimap_size: Vector2 = self.rect_size
onready var minimap_position: Vector2 = self.rect_position
onready var minimap_scale: Vector2 = self.rect_scale

var focus_position = Vector2.ZERO setget set_focus_position

#func _ready():
#	minimap_size = rect_size
#	minimap_position = rect_position
#	minimap_scale = rect_scale

func reset_minimap_properties():
	self.rect_size = minimap_size
	self.rect_position = minimap_position
	self.rect_scale = minimap_scale

func set_focus_position(position: Vector2, instant: bool = false):
	focus_position = position
	tween.stop_all()
	tween.interpolate_property(Tiles, "position", Tiles.position, -position, 0.0 if instant else 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
