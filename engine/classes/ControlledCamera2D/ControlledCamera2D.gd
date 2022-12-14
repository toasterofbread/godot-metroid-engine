extends Node2D
class_name ControlledCamera2D, "icon.png"

signal stopped

export var current: bool = false setget set_current
export var zoom: Vector2 = Vector2.ONE setget set_zoom
export var offset: Vector2 = Vector2.ZERO setget set_offset

export var speed: float = 1.0
var speed_override: float = null
export var snap_threshold: float = 1.0

export var follow_active: bool = true
var follow_pos: Vector2 = Vector2.ZERO
export var follow_node_path: NodePath
var follow_node: Node2D
export var follow_node_pos: bool = false

const default_limits: Dictionary = {
	"limit_left": -10000000,
	"limit_right": 10000000,
	"limit_top": -10000000,
	"limit_bottom": 10000000
}
export var limit_left: float = default_limits["limit_left"]
export var limit_right: float = default_limits["limit_right"]
export var limit_top: float = default_limits["limit_top"]
export var limit_bottom: float = default_limits["limit_bottom"]

# Dim
onready var dimColorRectContainer: Node2D = Node2D.new()
onready var dimColorRect: ColorRect = ColorRect.new()
var overlay_colour: Color = null setget set_overlay_colour
var dim_layer: int = 0 setget set_dim_layer

var camera: Camera2D = Camera2D.new()

func _ready():
	set_as_toplevel(true)
	
	add_child(camera)
	
	add_child(dimColorRectContainer)
	dimColorRectContainer.add_child(dimColorRect)
	dimColorRectContainer.visible = false
	
	if has_node(follow_node_path):
		follow_node = get_node(follow_node_path)

func _process(delta: float):
	if follow_active:
		process_follow(delta)
	
	if dimColorRectContainer.visible:
		var size = get_view_size()
		dimColorRect.rect_size = size
		dimColorRect.rect_position = -size/2

var moving: bool = false
func process_follow(delta: float):
	var target_pos: Vector2 = follow_node.global_position if follow_node_pos else follow_pos
	var view_size: Vector2 = get_view_size()
	
	var l: float = limit_left + (view_size.x / 2)
	var r: float = limit_right - (view_size.x / 2)
	var t: float = limit_top + (view_size.y / 2)
	var b: float = limit_bottom - (view_size.y / 2)
	
	target_pos.x = max(min(target_pos.x, r), l)
	target_pos.y = max(min(target_pos.y, b), t)
	
	moving = (target_pos - global_position).length() != 0
	
	if moving:
		
		var speed: float = getCurrentSpeed()
		
		var x_mod: float = abs(global_position.x - target_pos.x)
		if x_mod < 20:
			x_mod *= 2
		global_position.x = move_toward(global_position.x, target_pos.x, speed * delta * x_mod)
		
		var y_mod: float = abs(global_position.y - target_pos.y)
		if y_mod < 20:
			y_mod *= 2
		global_position.y = move_toward(global_position.y, target_pos.y, speed * delta * y_mod)
		
		if (target_pos - global_position).length() <= snap_threshold:
			global_position = target_pos
			emit_signal("stopped")
			moving = false

func getCurrentSpeed() -> float:
	if speed_override != null:
		return speed_override * 60.0
	return speed * 60.0

func get_view_size() -> Vector2:
	return get_viewport_rect().size / get_canvas_transform().get_scale()

func reset_limits():
	set_limits(default_limits)

func set_limits(limits: Dictionary):
	for limit in limits:
		set(limit, limits[limit])

func set_current(value: bool):
	current = value
	camera.current = current

func set_zoom(value: Vector2):
	zoom = value
	camera.zoom = zoom

func set_offset(value: Vector2):
	offset = value
	camera.offset = offset

func set_dim_layer(z_index: int):
	dim_layer = z_index
	dimColorRectContainer.z_index = z_index

func set_overlay_colour(colour: Color):
	overlay_colour = colour
	
	if colour == null:
		dimColorRectContainer.visible = false
	else:
		dimColorRectContainer.visible = colour.a > 0
		dimColorRect.color = colour
