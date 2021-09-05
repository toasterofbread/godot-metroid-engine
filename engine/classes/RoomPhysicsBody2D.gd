extends PhysicsBody2D
class_name RoomPhysicsBody2D

onready var Samus: KinematicBody2D = Loader.Samus
var collides_with_samus: bool = false

func _ready():
	update_samus_collision_status()

func _set(property: String, value):
	if property in ["collision_layer", "collision_mask"]:
		update_samus_collision_status()
	return false

func update_samus_collision_status():
	collides_with_samus = false
	for bit in range(20):
		if (Samus.get_collision_layer_bit(bit) and get_collision_mask_bit(bit)) or (Samus.get_collision_mask_bit(bit) and get_collision_layer_bit(bit)):
			collides_with_samus = true
			break
