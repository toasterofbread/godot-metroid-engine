extends Node2D

export var type_weights: = {
	"1": 1,
	"big_1": 0,
	"big_2": 0,
	"smoke_1": 0,
	"smoke_2": 0
} setget set_type_weights
var types: = []

var rng: = RandomNumberGenerator.new()
onready var area: Vector2 = $EmissionArea.shape.extents*2
onready var spriteNode: AnimatedSprite = $AnimatedSprite

func _ready():
	rng.randomize()
	remove_child(spriteNode)
	spriteNode.visible = false

func set_type_weights(value: Dictionary):
	type_weights = value
	for type in type_weights:
		for i in range(type_weights[type]):
			types.append(type)

func get_point(center: bool) -> Vector2:
	if center:
		return $EmissionArea.position
	else:
		var ret: = Vector2(rng.randf_range(0, area.x), rng.randf_range(0, area.y))
		ret += $EmissionArea.position - $EmissionArea.shape.extents
		return ret

func get_animation() -> String:
	return Global.random_array_item(types, rng)

func emit():
	pass

func emit_single(center: bool):
	var position: = get_point(center)
	var animation: = get_animation()
	
	var sprite: AnimatedSprite = spriteNode.duplicate()
	add_child(sprite)
	sprite.position = position
	sprite.play(animation)
	sprite.frame = 0
	sprite.visible = true
	
	yield(sprite, "animation_finished")
