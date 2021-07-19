extends Node

const id = "airboost"

var Samus: Node2D
var Animator: Node
var Physics: Node
var animations: Dictionary = {}
var physics_data: Dictionary

var direction: Vector2 = Vector2.ZERO
var time_remaining: float
var sprite
var trailEmitter: SpriteTrailEmitter

# Called during Samus's readying period
func _init(_samus: Node2D):
	Samus = _samus
	Animator = Samus.Animator
	Physics = Samus.Physics
	trailEmitter = Animator.SpriteContainer
	
	animations = Animator.load_from_json("shinespark")
	physics_data = Physics.data[id]

# Called when Samus's state is changed to this one
func init_state(data: Dictionary = {}):
	direction = Shortcut.get_pad_vector("pressed")
	if direction == Vector2.ZERO:
		direction = Vector2(0, -1)
	
	animations["horiz" if direction.x != 0 else "vert"].play()
	
	Physics.apply_gravity = false
	Physics.vel = direction.normalized() * physics_data["speed"]
	time_remaining = physics_data["duration"]
	trailEmitter.current_profile = "airboost"
	
	if direction.x != 0:
		Samus.facing = Enums.dir.LEFT if direction.x == -1 else Enums.dir.RIGHT
	else:
		sprite = Animator.current[false].sprites[Samus.facing]
		if direction.y == 1:
			sprite.flip_v = true
		sprite.playing = physics_data["vert_spin_sprite"]
	

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	if sprite != null:
		sprite.flip_v = false
		sprite = null
	trailEmitter.current_profile = null
	Physics.apply_gravity = true
	Samus.change_state(new_state_key, data)

# Called every frame while this state is active
func process(delta):
	time_remaining -= delta
	
	if time_remaining <= 0.0 or not Input.is_action_pressed("airboost"):
		change_state("jump", {"options": ["fall"]})
		return

func physics_process(delta: float):
	pass

#func paused_process(delta):
#	pass
