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
const roll_ground_acceleration = 25*60
const roll_ground_deceleration = 50*60
const roll_ground_speed = 225

const roll_air_acceleration = 25*60
const roll_air_deceleration = 50*60
const roll_air_speed = 150

const springball_speed = 200
const springball_acceleration = 400*60
const springball_time = 0.2
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

	if Settings.get("controls/aiming_style") == 0:
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
		var anim_speed = 0 if (abs(Physics.vel.x) < 1 or Samus.is_on_wall()) and "roll" in Animator.current[false].id else 1
		
		var target_physics_speed = roll_ground_speed if Samus.is_on_floor() else roll_air_speed
		animations["roll"].play(true, anim_speed * (abs(Physics.vel.x)/target_physics_speed))

#		if (abs(Physics.vel.x) < 1 or Samus.is_on_wall()) and "roll" in Animator.current[false].id:
#			Animator.pause()
	
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
	if Samus.current_fluid == Fluid.TYPES.NONE:
		Physics.move_y(-amount)
	else:
		Physics.move_y(-amount*0.5)
#	Physics.disable_floor_snap = true
#	Physics.vel.y = -amount

func physics_process(delta: float):
	
	if Samus.is_on_floor() and Samus.fall_time > bounce_fall_time:
		bounce(bounce_fall_amount)
		sounds["bounce"].play()
	
	# Vertical
	if Samus.is_upgrade_active(Enums.Upgrade.SPRINGBALL):
		if Input.is_action_just_pressed("jump") and Samus.is_on_floor():
			springball_current_time = springball_time
			Physics.move_y(-springball_speed, springball_acceleration*delta)
#			Physics.vel.y = move_toward(Physics.vel.y, -springball_speed, springball_acceleration*delta)
			Physics.disable_floor_snap = true
		elif not Samus.is_on_floor() and springball_current_time != 0 and Input.is_action_pressed("jump"):
#			Physics.vel.y = move_toward(Physics.vel.y, -springball_speed, springball_acceleration*delta)
			Physics.move_y(-springball_speed, springball_acceleration*delta)
			Physics.disable_floor_snap = true
			springball_current_time -= delta
			if springball_current_time <= 0:
				springball_current_time = 0
		else:
			springball_current_time = 0
	
	# Horizontal
	var pad_x = Shortcut.get_pad_vector("pressed").x
	if not Samus.is_on_floor():
		Physics.move_x(roll_air_speed*pad_x, (roll_air_acceleration if pad_x != 0 else roll_air_deceleration)*delta)
	else:
		Physics.move_x(roll_ground_speed*pad_x, (roll_ground_acceleration if pad_x != 0 else roll_ground_deceleration)*delta)
	
	CeilingRaycast.global_position.x = Animator.current[false].sprites[Samus.facing].global_position.x
	particles.emitting = Physics.vel != Vector2.ZERO
	particles.global_position = Animator.current[false].sprites[Samus.facing].global_position
