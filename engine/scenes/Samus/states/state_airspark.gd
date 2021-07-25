extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var physics_data: Dictionary

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2
var time_remaining: float
var sprite
var trailEmitter: SpriteTrailEmitter
var animation: String

var additional_midair_airsparks: Dictionary

# Called during Samus's readying period
func _init(_Samus: Node2D, _id: String).(_Samus, _id):
	trailEmitter = Animator.SpriteContainer
	additional_midair_airsparks = Samus.get_mini_upgrade("additional_midair_airsparks", 0)
	Physics.connect("landed", self, "samus_landed")
	animations = Animator.load_from_json("shinespark")

# Called when Samus's state is changed to this one
func init_state(data: Dictionary, _previous_state_id: String):
	direction = Shortcut.get_pad_vector("pressed")
	if direction == Vector2.ZERO:
		direction = Vector2(0, -1)
	
	animation = "horiz" if direction.x != 0 else "vert"
	velocity = direction.normalized() * physics_data["speed"]
	Physics.apply_gravity = false
	Physics.vel = direction.normalized() * physics_data["speed"]
	time_remaining = physics_data["duration"]
	trailEmitter.current_profile = "airspark"
	
	if direction.x != 0:
		Samus.facing = Enums.dir.LEFT if direction.x == -1 else Enums.dir.RIGHT

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	if sprite != null:
		sprite.flip_v = false
		sprite = null
	trailEmitter.current_profile = null
	Physics.apply_gravity = true
	Samus.aiming = Samus.aim.NONE
	.change_state(new_state_key, data)

# Called every frame while this state is active
func process(delta: float):
	time_remaining -= delta
	
	if time_remaining <= 0.0 or not Input.is_action_pressed("airspark"):
		change_state("jump", {"options": ["fall"]})
		return
	
	Physics.vel = velocity
	Physics.disable_floor_snap = true
	if animation != "" and not Animator.transitioning():
		animations[animation].play()
		animation = ""
		
		sprite = Animator.current[false].sprites[Samus.facing]
		if direction == Vector2(0, 1):
			sprite.flip_v = true
		sprite.playing = physics_data["vert_spin_sprite"]

func physics_process(_delta: float):
	pass

func samus_landed():
	# TODO
	pass

func can_airspark() -> bool:
	if not Samus.is_upgrade_active(Enums.Upgrade.AIRSPARK):
		return false
	elif Samus.current_state.id in ["run", "crouch"]:
		return not Input.is_action_pressed("pad_down")
	else:
		return true
	
