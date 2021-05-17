extends Node

const id = "morphball"

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

var CeilingRaycast: RayCast2D
var particles: Particles2D

const bounce_fall_time: float = 0.5 # The morphball will bounce if it lands after falling for this many seconds
const bounce_fall_amount: float = 200.0 # The amount to bounce in the above case

# PHYSICS
const roll_ground_acceleration = 25
const roll_ground_deceleration = 50
const roll_ground_speed = 225

const roll_air_acceleration = 25
const roll_air_deceleration = 50
const roll_air_speed = 150

const springball_speed = 300
const springball_acceleration = 400
const springball_time = 0.125
var springball_current_time = 0

var animations = {}
var sounds = {
	"morph": Sound.new("res://audio/samus/morphball/sndMorph.wav"),
	"unmorph": Sound.new("res://audio/samus/morphball/sndUnMorph.wav"),
	"bounce": Sound.new("res://audio/samus/morphball/sndBallBounce.wav")
}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.CeilingRaycast = Animator.raycasts.get_node("morphball/Ceiling")
	self.particles = Samus.get_node("Particles/morphball")
	particles.emitting = false
	
	animations = Animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	var options = data["options"]
	if "animate" in options:
		animations["morph"].play()
		sounds["morph"].play()
	Samus.aiming = Samus.aim.NONE
	CeilingRaycast.enabled = true
	return self

# Called every frame while this state is active
func process(_delta):
	
	var original_facing = Samus.facing
	var fire_weapon = false

	if Settings.get("controls/aiming_style"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))

	if Samus.is_upgrade_active(Enums.Upgrade.SPIDERBALL):
		if (Settings.get("controls/spiderball_style") == 0 and Input.is_action_pressed("spiderball")) or (Settings.get("controls/spiderball_style") == 1 and Input.is_action_just_pressed("spiderball")):
			change_state("spiderball")
			return
	
	if Samus.shinespark_charged and Input.is_action_just_pressed("jump") and not Animator.transitioning(false, true):
		if not Input.is_action_pressed("pad_left") and not Input.is_action_pressed("pad_right"):
			change_state("shinespark", {"ballspark": true})
	
	if (Input.is_action_just_pressed("morph_shortcut") or Input.is_action_just_pressed("pad_up")) and not Animator.transitioning():
		if not CeilingRaycast.is_colliding():
			animations["unmorph"].play()
			if Samus.is_on_floor():
				change_state("crouch")
			else:
				change_state("jump", {"options": []})
			return
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true

	if Input.is_action_pressed("pad_left"):
		Samus.facing = Enums.dir.LEFT
		if original_facing == Enums.dir.RIGHT:
			animations["turn"].play()
			
	elif Input.is_action_pressed("pad_right"):
		Samus.facing = Enums.dir.RIGHT
		if original_facing == Enums.dir.LEFT:
			animations["turn"].play()

	if not Animator.transitioning(false, true):
		animations["roll"].play(true, false, true)

		if (abs(Physics.vel.x) < 1 or Samus.is_on_wall()) and "roll" in Animator.current[false].id:
			Animator.pause()
	
	if fire_weapon:
		Samus.Weapons.fire()
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.boosting = false
	CeilingRaycast.enabled = false
	particles.emitting = false
	
	if new_state_key != "spiderball":
		sounds["unmorph"].play()
		Animator.resume()
	
	Samus.change_state(new_state_key, data)

func bounce(amount: float):
	Physics.disable_floor_snap = true
	Physics.vel.y = -amount

func physics_process(delta: float):
	
	if Samus.is_on_floor() and Samus.fall_time > bounce_fall_time:
		bounce(bounce_fall_amount)
		sounds["bounce"].play()
	
	# Vertical
	if Samus.is_upgrade_active(Enums.Upgrade.SPRINGBALL):
		if Input.is_action_just_pressed("jump") and Samus.is_on_floor():
			springball_current_time = springball_time
			Physics.accelerate_y(springball_acceleration, springball_speed, Enums.dir.UP)
		elif not Samus.is_on_floor() and springball_current_time != 0 and Input.is_action_pressed("jump"):
			Physics.accelerate_y(springball_acceleration, springball_speed, Enums.dir.UP)
			springball_current_time -= delta
			if springball_current_time <= 0:
				springball_current_time = 0
		else:
			springball_current_time = 0
	
	# Horizontal
	if not Samus.is_on_floor():
		if Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
			Physics.accelerate_x(roll_air_acceleration, max(roll_air_speed, abs(Physics.vel.x)), Samus.facing)
		else:
			Physics.decelerate_x(roll_air_deceleration)
	else:
		if Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
			Physics.accelerate_x(roll_ground_acceleration, max(roll_ground_speed, abs(Physics.vel.x)), Samus.facing)
		else:
			Physics.decelerate_x(roll_ground_deceleration)
	
	CeilingRaycast.global_position.x = Animator.current[false].sprites[Samus.facing].global_position.x
	particles.emitting = Physics.vel != Vector2.ZERO
	particles.global_position = Animator.current[false].sprites[Samus.facing].global_position
