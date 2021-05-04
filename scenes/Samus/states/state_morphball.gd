extends Node

const id = "morphball"

var samus: KinematicBody2D
var animator: Node
var physics: Node

var particles: Particles2D

const bounce_fall_time: float = 0.5 # The morphball will bounce if it lands after falling for this many seconds
const bounce_fall_amount: float = 200.0 # The amount to bounce in the above case

var spiderball_active = false


# PHYSICS
const roll_ground_acceleration = 25
const roll_ground_deceleration = 50
const roll_ground_speed = 200

const roll_air_acceleration = 25
const roll_air_deceleration = 50
const roll_air_speed = 150

const springball_speed = 300
const springball_acceleration = 400
const springball_time = 0.125
var springball_current_time = 0

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	
	self.particles = samus.get_node("Particles/morphball")
	particles.emitting = false
	
	animations = animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	var options = data["options"]
	
	if "animate" in options:
		animations["morph"].play()
	
	samus.aiming = samus.aim.NONE
	spiderball_active = false
	return self

# Called every frame while this state is active
func process(_delta):
	
	var original_facing = samus.facing
	var fire_weapon = false

	if Config.get("zm_controls"):
		animator.set_armed(Input.is_action_pressed("arm_weapon"))

	if Config.get("spiderball_hold") and Input.is_action_just_pressed("spiderball"):
		spiderball_active = !spiderball_active
	else:
		spiderball_active = Input.is_action_pressed("spiderball")
	
	if (Input.is_action_just_pressed("morph_shortcut") or Input.is_action_just_pressed("pad_up")) and not animator.transitioning() and not spiderball_active:
		animations["unmorph"].play()
		
		if samus.is_on_floor():
			change_state("crouch")
		else:
			change_state("jump", {"options": []})
		
		return
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true

	if Input.is_action_pressed("pad_left") and not spiderball_active:
		samus.facing = Enums.dir.LEFT
		if original_facing == Enums.dir.RIGHT:
			animations["turn"].play()
			
	elif Input.is_action_pressed("pad_right") and not spiderball_active:
		samus.facing = Enums.dir.RIGHT
		if original_facing == Enums.dir.LEFT:
			animations["turn"].play()

	if not animator.transitioning(false, true):
		if spiderball_active:
			animations["roll_spider"].play(true)
		else:
			animations["roll"].play(true)

		if not (Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right")) and "roll" in animator.current[false].id:
			animator.pause()
	
	if fire_weapon:
		samus.weapons.fire()
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	particles.emitting = false
	animator.resume()
	samus.change_state(new_state_key, data)

func bounce(amount: float):
	physics.vel.y = -amount

func physics_process(delta: float):
	
	if samus.is_on_floor() and samus.fall_time > bounce_fall_time:
		bounce(bounce_fall_amount)
	
	
	# Vertical
	if samus.is_upgrade_active("springball"):
		if Input.is_action_just_pressed("jump") and samus.is_on_floor() and not spiderball_active:
			springball_current_time = springball_time
			physics.accelerate_y(springball_acceleration, springball_speed, Enums.dir.UP)
		elif not samus.is_on_floor() and springball_current_time != 0 and Input.is_action_pressed("jump"):
			physics.accelerate_y(springball_acceleration, springball_speed, Enums.dir.UP)
			springball_current_time -= delta
			if springball_current_time <= 0:
				springball_current_time = 0
		else:
			springball_current_time = 0
	
	# Horizontal
	if not samus.is_on_floor():
		if Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
			physics.accelerate_x(roll_air_acceleration, max(roll_air_speed, abs(physics.vel.x)), samus.facing)
		else:
			physics.decelerate_x(roll_air_deceleration)
	else:
		if not spiderball_active:
			if Input.is_action_pressed("pad_left") and samus.facing == Enums.dir.LEFT:
				physics.accelerate_x(roll_ground_acceleration, roll_ground_speed, Enums.dir.LEFT)
			elif Input.is_action_pressed("pad_right") and samus.facing == Enums.dir.RIGHT:
				physics.accelerate_x(roll_ground_acceleration, roll_ground_speed, Enums.dir.RIGHT)
			else:
				physics.decelerate_x(roll_ground_deceleration)

	particles.emitting = physics.vel != Vector2.ZERO
	particles.global_position = animator.current[false].sprites[samus.facing].global_position
