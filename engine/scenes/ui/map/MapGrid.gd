extends Control

onready var Tiles: Node2D = $Center/Tiles
onready var Background: TextureRect = $Center/Background
onready var tween: Tween = $Tween
onready var backgroundOffsetTween: Tween = $BackgroundOffsetTween

const map_max_scale: float = 2.0
const map_min_scale: float = 0.2
var map_scale: Vector2 = Vector2.ONE setget set_map_scale

const default_map_size: Vector2 = Vector2(40, 24)
var map_size: Vector2 = default_map_size

onready var default_position: Vector2 = rect_position
var focus_position = Vector2.ZERO setget set_focus_position

var background_offset: Vector2 = Vector2.ZERO setget set_background_offset
var map_offset_offset: Vector2 = Vector2.ZERO

func _ready():
	backgroundOffsetTween.connect("tween_step", self, "background_offset_tween_step")

func fade(fade_in: bool, duration: float):
	tween.interpolate_property(self, "modulate:a", int(!fade_in), int(fade_in), duration)
	tween.start()
	yield(tween, "tween_completed")

func set_map_scale(value: Vector2):
	map_scale = Global.clamp_vector2(value, map_min_scale, map_max_scale)
	$Center.rect_scale = map_scale

func set_background_offset(value: Vector2):
	if value == background_offset:
		return
	background_offset = Vector2.ZERO if is_nan(value.x) else value.posmod(8)

func update_minimap():
	set_background_offset(Tiles.position + map_offset_offset)
	rect_size = map_size
	Background.rect_size = (rect_size / map_min_scale) + Vector2(8, 8)
	Background.rect_position = (-Background.rect_size/2) + background_offset - Vector2(4, 4)

func reset_minimap_properties():
	set_map_scale(Vector2.ONE)
	rect_position = default_position
	map_size = default_map_size
	rect_size = map_size
	Background.rect_size = rect_size
	Background.rect_position = (-Background.rect_size/2)
	map_offset_offset = Vector2.ZERO
	visible = true

func set_focus_position(position: Vector2, instant: bool = false):
	focus_position = position
	if not backgroundOffsetTween.is_inside_tree():
		return
	backgroundOffsetTween.interpolate_property(Tiles, "position", Tiles.position, -position, 0.0 if instant else 0.1, Tween.TRANS_LINEAR)
	backgroundOffsetTween.start()

func background_offset_tween_step(object: Object, key: NodePath, elapsed: float, value: Object):
	update_minimap()

func show_all_tiles(tiles: Array = Tiles.get_children(), instant: bool = false):
	
	# TODO | Set scale
	
	var max_pos: = Vector2.ZERO
	var min_pos: = Vector2.ZERO
	
	for tile in tiles:
		for axis in ["x", "y"]:
			max_pos[axis] = max(max_pos[axis], tile.grid_position[axis])
			min_pos[axis] = min(min_pos[axis], tile.grid_position[axis])
	
	var center: Vector2 = max_pos - min_pos
	set_focus_position(center, instant)
