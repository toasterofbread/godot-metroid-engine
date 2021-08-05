tool
extends Control
class_name Fluid

enum TYPES {NONE, WATER, LAVA}
export(TYPES) var type: int = TYPES.WATER setget set_type
export var update_sizes = false setget update_sizes
export var flow_speed: = 1.0

onready var baseSplash = $Splash
onready var baseBubble = $Bubble
onready var decorationAnchor = Global.get_anchor("Fluid/" + TYPES.keys()[type] + "_splash")

var frame = 0
const fps = 5
const horiz_scroll_speed = 3.0

var entered_damageable_entities = []

const textures_path = "res://engine/sprites/objects/fluid/"
var textures = {
	TYPES.WATER: [load(textures_path + "water/bgWater0.png"), load(textures_path + "water/bgWater1.png"), load(textures_path + "water/bgWater2.png"), load(textures_path + "water/bgWater1.png"), load(textures_path + "water/bgWater0.png")],
	TYPES.LAVA: [load(textures_path + "lava/sLavaSurface_0.png"), load(textures_path + "lava/sLavaSurface_1.png"), load(textures_path + "lava/sLavaSurface_2.png"), load(textures_path + "lava/sLavaSurface_3.png")]
}
const colours = {
	TYPES.WATER: Color("bb558bc1"),
	TYPES.LAVA: Color("bfff1e00")
}
const color_overlaps_texture = {
	TYPES.WATER: true,
	TYPES.LAVA: false
}
const viscosities = {
	TYPES.WATER: 1.0,
	TYPES.LAVA: 0.75,
}
const samus_physics_mode = {
	TYPES.WATER: Enums.SAMUS_PHYSICS_MODES.WATER,
	TYPES.LAVA: Enums.SAMUS_PHYSICS_MODES.WATER
}
const damage = {
	TYPES.LAVA: [Enums.DamageType.FIRE, 1]
}


func set_type(value: int):
	if not is_inside_tree():
		return
	if not Engine.editor_hint and textures == null:
		yield(self, "ready")
	
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
	remove_child(baseBubble)
	remove_child(baseSplash)

func _process(delta):
	
	if Engine.editor_hint:
		return
	
	frame += delta*fps
	if frame > len(textures[type]) - 1:
		frame = 0
	$TextureRect.texture = textures[type][int(frame)]
	
	if flow_speed == 0:
		return
	
	var width = textures[type][0].get_width()
	$TextureRect.rect_position.x -= (delta/horiz_scroll_speed*flow_speed)*width
	
	if flow_speed > 0:
		if $TextureRect.rect_position.x <= -width:
			$TextureRect.rect_position.x = 0
	else:
		if $TextureRect.rect_position.x > 0:
			$TextureRect.rect_position.x = -width
	
#	if abs($TextureRect.rect_position.x) >= (width if flow_speed > 0 else 0):
#		$TextureRect.rect_position.x = 0 if flow_speed > 0 else -width
	
	if type in damage:
		var damage_data = damage[type]
		for entity in entered_damageable_entities:
			entity.damage(damage_data[0], damage_data[1])


func _on_Area2D_body_entered_safe(body):
	if body.has_method("fluid_entered"):
		body.fluid_entered(self)
	
	if body == Loader.Samus:
		hide()
	
	if body.has_method("damage") and not body in entered_damageable_entities:
		entered_damageable_entities.append(body)

func _on_Area2D_body_exited_safe(body):
	if body.has_method("fluid_exited"):
		body.fluid_exited(self)
	
	if body == Loader.Samus:
		show()
	
	create_splash(body)
	entered_damageable_entities.erase(body)

func _on_SurfaceArea2D_body_entered_safe(body):
	create_splash(body)

func create_splash(body):
	
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
	decorationAnchor.add_child(sprite)
	sprite.global_position.x = body.global_position.x
	sprite.global_position.y = $TextureRect.rect_global_position.y
	sprite.play(TYPES.keys()[type].to_lower() + "_" + size)
	yield(sprite, "animation_finished")
	sprite.queue_free()

func create_bubble(position: Vector2):
	var size = Global.random_array_item(["small", "large"])
	var bubble = baseBubble.duplicate()
	bubble.get_node("AnimatedSprite").play(TYPES.keys()[type].to_lower() + "_" + size)
	decorationAnchor.add_child(bubble)
	bubble.global_position = position

func show():
	$ShowTween.stop_all()
	$ShowTween.interpolate_property($TextureRect, "modulate:a", $TextureRect.modulate.a, 1, 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
	$ShowTween.interpolate_property($ColorRect, "modulate:a", $ColorRect.modulate.a, 1, 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
	$ShowTween.start()

func hide():
	$ShowTween.stop_all()
	$ShowTween.interpolate_property($TextureRect, "modulate:a", $TextureRect.modulate.a, 0.25, 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
	if type == TYPES.LAVA:
		$ShowTween.interpolate_property($ColorRect, "modulate:a", $ColorRect.modulate.a, 0.25, 0.75, Tween.TRANS_SINE, Tween.EASE_IN)
	$ShowTween.start()
