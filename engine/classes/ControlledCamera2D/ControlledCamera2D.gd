extends Node2D
class_name ControlledCamera2D, "icon.png"

signal stopped

export var current: bool = false setget set_current
export var zoom: Vector2 = Vector2.ONE setget set_zoom
export var offset: Vector2 = Vector2.ZERO setget set_offset

export var smoothing: float = 1.0
export var limit_smoothing: float = 0.15

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
var dim_colour: Color = Color.transparent setget set_dim_colour
var dim_layer: int = 0 setget set_dim_layer

var camera: Camera2D = Camera2D.new()

func _ready():
	set_as_toplevel(true)
	add_child(camera)
	
	smoothing *= 60
	limit_smoothing *= 60
	
	if has_node(follow_node_path):
		follow_node = get_node(follow_node_path)

func _process(delta: float):
	if follow_active:
		process_follow(delta)

var moving: bool = false
func process_follow(delta: float):
	var a: Vector2 = follow_node.global_position if follow_node_pos else follow_pos
	var target_pos: Vector2 = follow_node.global_position if follow_node_pos else follow_pos
	var view_size: Vector2 = get_view_size()
	
	var x_smoothing: float = smoothing
	var y_smoothing: float = smoothing
	
#	var smooth_x: bool = target_pos.x - global_position.x > 1 or true
#	var smooth_y: bool = target_pos.y - global_position.y > 1 or true
	
	var l: float = limit_left + (view_size.x / 2)
	var r: float = limit_right - (view_size.x / 2)
	var t: float = limit_top + (view_size.y / 2)
	var b: float = limit_bottom - (view_size.y / 2)
	
#	print(target_pos.x, " | ", l)
#	print(abs(target_pos.x - global_position.x))
	
	target_pos.x = max(min(target_pos.x, r), l)
#	if abs(target_pos.x - global_position.x) > 0.1:
#		print(1)
#		x_smoothing = limit_smoothing
#	else:
#		print(2)
#		pass
	target_pos.y = max(min(target_pos.y, b), t)
#	if abs(target_pos.y - global_position.y) > 0.1:
#		y_smoothing = limit_smoothing
#	else:
#		pass
		
	moving = (target_pos - global_position).length() != 0
	
	if moving:
		
		var x_mod: float = abs(global_position.x - target_pos.x)
		if x_mod < 20:
			x_mod *= 2
		global_position.x = move_toward(global_position.x, target_pos.x, x_smoothing*delta*x_mod)
		
		var y_mod: float = abs(global_position.y - target_pos.y)
		if y_mod < 20:
			y_mod *= 2
		global_position.y = move_toward(global_position.y, target_pos.y, y_smoothing*delta*y_mod)
#		global_position.x = lerp(global_position.x, target_pos.x, x_smoothing*delta)
#		global_position.y = lerp(global_position.y, target_pos.y, y_smoothing*delta)
		
		if (target_pos - global_position).length() == 0:
			emit_signal("stopped")
			moving = false
	
func get_view_limits() -> Dictionary:
	var ctrans = get_canvas_transform()
	var min_pos = -ctrans.get_origin() / ctrans.get_scale()
	var max_pos = min_pos + get_view_size()
	
	return {
		"left": min_pos.x,
		"right": max_pos.x,
		"top": min_pos.y,
		"bottom": max_pos.y
	}

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

func set_dim_colour(colour: Color):
	dimColorRect.rect_global_position = camera.get_camera_screen_center() - (dimColorRect.rect_size / 2)
	dim_colour = colour
	dimColorRect.color = colour
	dimColorRectContainer.visible = colour.a > 0
