tool
extends Control
class_name Fluid

enum TYPES {NONE, WATER, LAVA}
export(TYPES) var type: int = TYPES.WATER setget set_type
export var update_sizes = false setget update_sizes

onready var baseSplash = $Splash
onready var splashAnchor = Global.get_anchor("Fluid/" + TYPES.keys()[type] + "_splash")

var frame = 0
const fps = 5

const horiz_scroll_speed = 3.0

const textures_path = "res://sprites/objects/fluid/"
onready var textures = {
	TYPES.WATER: [load(textures_path + "water/bgWater0.png"), load(textures_path + "water/bgWater1.png"), load(textures_path + "water/bgWater2.png"), load(textures_path + "water/bgWater1.png"), load(textures_path + "water/bgWater0.png")],
	TYPES.LAVA: [load(textures_path + "lava/sLavaSurface_0.png"), load(textures_path + "lava/sLavaSurface_1.png"), load(textures_path + "lava/sLavaSurface_2.png"), load(textures_path + "lava/sLavaSurface_3.png")]
}
const colours = {
	TYPES.WATER: Color("7f0000ff"),
	TYPES.LAVA: Color("FF1E00")
}
const color_overlaps_texture = {
	TYPES.WATER: true,
	TYPES.LAVA: false
}

# The lower the value, the slower the movement
const viscosities = {
	TYPES.WATER: 1.0,
	TYPES.LAVA: 0.25,
}

func set_type(value: int):
	type = value
	$ColorRect.color = colours[type]
	
	if not color_overlaps_texture[type]:
		$ColorRect.rect_position.y = textures[type][0].get_height()
	else:
		$ColorRect.rect_position.y = 0

func update_sizes(value:=false):
	update_sizes = false
	
	$TextureRect.rect_size = rect_size
	$TextureRect.rect_size.y = min($TextureRect.rect_size.y, textures[type][0].get_height())
	
	$TextureRect.margin_right = textures[type][0].get_width()
	$TextureRect.rect_position.x = 0
	
	$ColorRect.rect_size = rect_size
	if not color_overlaps_texture[type]:
		$ColorRect.rect_size.y -= textures[type][0].get_height()
	
	$Area2D/CollisionShape2D.position = rect_size / 2
	$Area2D/CollisionShape2D.shape.extents = rect_size / 2
	
	$SurfaceArea2D/CollisionShape2D.shape.b.x = rect_size.x

func _ready():
	if Engine.editor_hint:
		return
	update_sizes()
	remove_child(baseSplash)

func _process(delta):
	
	if Engine.editor_hint:
		return
	
	frame += delta*fps
	if frame > len(textures[type]) - 1:
		frame = 0
	$TextureRect.texture = textures[type][int(frame)]
	
	var width = textures[type][0].get_width()
	$TextureRect.rect_position.x -= (delta/horiz_scroll_speed)*width
	if $TextureRect.rect_position.x <= -width:
		$TextureRect.rect_position.x = 0


func _on_Area2D_body_entered(body):
	if body.has_method("fluid_entered"):
		body.fluid_entered(self)

func _on_Area2D_body_exited(body):
	if body.has_method("fluid_exited"):
		body.fluid_exited(self)

func _on_SurfaceArea2D_body_entered(body):
	splash(body)

func _on_SurfaceArea2D_body_exited(body):
	return
	if not body in $Area2D.get_overlapping_bodies():
		splash(body)

func splash(body):
	
#	print(abs(body.global_position.y - $TextureRect.rect_global_position.y))
#	if abs(body.global_position.y - $TextureRect.rect_global_position.y) > 50:
#		return
	
	var size: String
	if body.has_method("fluid_splash"):
		var override = body.fluid_splash(type)
		if bool(override) != false:
			if override is String:
				size = override
		else:
			return
	
	if not size:
		if body.get_collision_layer_bit(0):
			size = "large"
		else:
			size = "small"
	var sprite = baseSplash.duplicate()
	splashAnchor.add_child(sprite)
	sprite.global_position.x = body.global_position.x
	sprite.global_position.y = $TextureRect.rect_global_position.y
	sprite.play(size)
	yield(sprite, "animation_finished")
	sprite.queue_free()

