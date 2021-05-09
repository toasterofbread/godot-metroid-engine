extends CollisionShape2D

onready var Samus: Node2D = get_parent()
onready var Animator: Node2D

const collision_data_json_path = "res://scenes/Samus/animations/collision_data.json"
onready var collision_data = Global.load_json(collision_data_json_path)

const speedbooster_collision_data_path = "res://scenes/Samus/animations/speedbooster_collision_data.json"
onready var speedbooster_collision_data = Global.load_json(speedbooster_collision_data_path)

func _ready():
	yield(Samus, "ready")
	Animator = Samus.Animator
	
	var i = 0
	for key in collision_data:
		for value in collision_data[key]:
			collision_data[key][i] = Vector2(value[0], value[1])
			i += 1
		i = 0
	
	i = 0
	for key in speedbooster_collision_data:
		for value in speedbooster_collision_data[key]:
			speedbooster_collision_data[key][i] = Vector2(value[0], value[1])
			i += 1
		i = 0
	
func set_collider(animation: SamusAnimation):
	
#	if Samus.boosting:
#		set_speedbooster_collider(animation)
	
	var key: String
	if animation.position_node_path in collision_data:
		key = animation.position_node_path
	elif animation.position_node_path.split("/")[0] in collision_data:
		key = animation.position_node_path.split("/")[0]
	else:
		return
	
	var i = 0
	self.position = animation.positions[Samus.facing]
	for value in collision_data[key]:
		match i:
			0: self.shape.extents = value
			1: self.position = value
			2: if Samus.facing == Enums.dir.RIGHT: self.position = value
		i += 1

#func set_speedbooster_collider(animation: SamusAnimation):
#
#	var key: String
#	if animation.position_node_path in speedbooster_collision_data:
#		key = animation.position_node_path
#	elif animation.position_node_path.split("/")[0] in speedbooster_collision_data:
#		key = animation.position_node_path.split("/")[0]
#	else:
#		return
#
#	var i = 0
#
#	var shape = Samus.SpeedboosterDamageArea.get_child(0)
#
#	shape.position = animation.positions[Samus.facing]
#	for value in speedbooster_collision_data[key]:
#		match i:
#			0: shape.shape.extents = value
#			1: shape.position = value
#			2: if Samus.facing == Enums.dir.RIGHT: shape.position = value
#		i += 1