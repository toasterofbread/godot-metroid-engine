extends Enemy
class_name ZoomerTemplate

onready var Samus: KinematicBody2D = Loader.Samus

var FLOOR: = Vector2.ZERO setget set_floor
var attached: = true
export var direction: int
export var speed: float
export var visual_path: NodePath
export var rotate_visual: = true
var visual: Node2D
var gravity: float = 1200 
var velocity: = Vector2.ZERO
var fall_speed_cap: float = 325
const visual_rotation_speed = 0.15

onready var Raycasts = {
	"left": $Raycasts/FloorL,
	"right": $Raycasts/FloorR,
	"down": $Raycasts/FloorD,
	"container": $Raycasts
}

func _ready():
	
	if Engine.editor_hint:
		return
	
	visual = get_node(visual_path)

func _physics_process(delta: float):
	
	if Engine.editor_hint:
		return
	
	if health == 0:
		return
	
	if attached:
		attached_physics_process(delta)
		velocity = Vector2.ZERO
		return

	if rotate_visual:
		visual.rotation = lerp_angle(visual.rotation, 0, visual_rotation_speed)
#	velocity.y = min(fall_speed_cap, velocity.y+gravity*delta)
#	velocity = FLOOR.rotated(deg2rad(0))*10
	var collision = $Dummy.move_and_collide(velocity*delta)
	position += $Dummy.position
	$Dummy.position = Vector2.ZERO
	if collision != null:
		set_floor(-collision.normal)

func set_floor(value: Vector2):
	attached = value != Vector2.ZERO
	FLOOR = value
	Raycasts["left"].enabled = attached
	Raycasts["right"].enabled = attached
	Raycasts["down"].enabled = attached
	
	Raycasts["container"].rotation = FLOOR.rotated(deg2rad(-90)).angle()

func attached_physics_process(delta: float):
	
	if rotate_visual:
		visual.rotation = lerp_angle(visual.rotation, FLOOR.angle() - deg2rad(90), visual_rotation_speed)
	
	var floor_collision = $Dummy.move_and_collide(FLOOR*200*delta, true, true, true)
	if floor_collision == null:
		floor_collision = $Dummy.move_and_collide(FLOOR*200*delta)
		position += $Dummy.position
		$Dummy.position = Vector2.ZERO
		
	if direction == 0:
		return
	
	var set = false
	if floor_collision == null:
		if Raycasts["left"].is_colliding():
			set_floor(-Raycasts["left"].get_collision_normal())
			set = true
		elif Raycasts["right"].is_colliding():
			set_floor(-Raycasts["right"].get_collision_normal())
			set = true
		else:
			attached = false
#			set_floor(Vector2.ZERO)
			return
	else:
		set_floor(-floor_collision.normal)
	
	var collision = $Dummy.move_and_collide(FLOOR.rotated(deg2rad(90))*direction*speed*delta)
	position += $Dummy.position
	$Dummy.position = Vector2.ZERO
	
	if collision != null:
		set_floor(-collision.normal)

func damage(type: int, amount: float, _impact_position):
	.damage(type, amount, _impact_position)

func death(type: int):
	visual.visible = false
	
	if type in [Enums.DamageType.SCREWATTACK, Enums.DamageType.SPEEDBOOSTER]:
		$ExplosionEmitter.type_weights = {
			"1": 0,
			"big_1": 1,
			"big_2": 1,
			"smoke_1": 0,
			"smoke_2": 0
		}
	
	$CollisionShape2D.disabled = true
	$Dummy/CollisionShape2D.disabled = true
	
	yield($ExplosionEmitter.emit_single(true), "completed")
	queue_free()

func _on_Area2D_body_entered(body):
	
	if health == 0:
		return
	
	if body == Samus:
		var damage = Samus.check_hurtbox_damage(null)
		if damage != null:
			damage(damage[0], damage[1], damage[2])
			return
	
	if body.has_method("damage"):
		body.damage(Enums.DamageType.ENEMYCOLLISION, data["collision_damage"]["outgoing"], $CollisionShape2D.global_position)
		damage(Enums.DamageType.ENEMYCOLLISION, data["collision_damage"]["incoming"], $CollisionShape2D.global_position)
