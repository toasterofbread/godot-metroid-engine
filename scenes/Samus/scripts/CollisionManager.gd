extends CollisionShape2D

onready var Samus: Node2D = get_parent()
onready var Animator: Node2D
const collision_data_json_path = "res://scenes/Samus/animations/collision_data.json"
onready var collision_data = Global.load_json(collision_data_json_path)

func _ready():
	yield(Samus, "ready")
	Animator = Samus.Animator
	
	for key in collision_data:
		collision_data[key] = Vector2(collision_data[key][0], collision_data[key][1])
	

onready var colliders = {
	false: {
		Enums.dir.LEFT: Samus.get_node("cMainLeft"),
		Enums.dir.RIGHT: Samus.get_node("cMainRight")
	},
	true: {
		Enums.dir.LEFT: Samus.get_node("cOverlayLeft"),
		Enums.dir.RIGHT: Samus.get_node("cOverlayRight")
	}
}


func set_collider(animation: SamusAnimation):
	if animation.position_node_path in collision_data:
		self.shape.extents = collision_data[animation.position_node_path]
		self.position = animation.positions[Samus.facing]
	
