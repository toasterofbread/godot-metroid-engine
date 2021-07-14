tool
extends Node2D

export var length: = 5 setget set_length
export var spacing: = 0 setget set_spacing
const spike_width = 7

const damage_type = Enums.DamageType.SPIKE
export var damage_amount: = 10

func set_length(value: int):
	length = max(value, 1)
	
	if not Engine.editor_hint:
		return
	
	if length > $VBoxContainer.get_child_count():
		$VBoxContainer.add_child($VBoxContainer.get_child(0).duplicate())
	elif length < $VBoxContainer.get_child_count():
		$VBoxContainer.get_children()[0].queue_free()
	
	set_collisionshape()

func set_collisionshape():
	$CollisionShape2D.shape.extents.x = float((spike_width+spacing)*length-spacing) /2.0
	$CollisionShape2D.position.x = $CollisionShape2D.shape.extents.x
	
	$Area2D/CollisionShape2D.shape.extents.x = $CollisionShape2D.shape.extents.x + 2
	$Area2D/CollisionShape2D.position = $CollisionShape2D.position

func set_spacing(value: int):
	spacing = max(value, 0)
	
	if not Engine.editor_hint:
		return
	
	$VBoxContainer.set("custom_constants/separation", spacing)
	set_collisionshape()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for child in $VBoxContainer.get_children():
		child.queue_free()
	
	$Template.visible = true
	for i in range(length):
		$VBoxContainer.add_child($Template.duplicate())
	$Template.queue_free()
	
	set_collisionshape()


func _on_Area2D_body_entered(body):
	if body.has_method("damage"):
		body.damage(damage_amount, damage_type, Vector2(body.global_position.x, global_position.y))
