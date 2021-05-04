extends Node

var samus: KinematicBody2D
var animator: Node
var physics: Node

const bounce_fall_time: float = 0.5
var spiderball_active = false

const id = "morphball"

# PHYSICS
const roll_ground_acceleration = 10
const roll_ground_deceleration = 50
const roll_ground_max_speed = 200
const springball_speed = 50
const springball_time = 0.2
var springball_current_time = 0

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	
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
	
#	var play_transition = false
	var original_facing = samus.facing

	if Global.config["spiderball_hold"] and Input.is_action_just_pressed("spiderball"):
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
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	animator.resume()
	samus.change_state(new_state_key, data)
	
func landing_bounce():
	physics.vel.y = -200

func physics_process(delta: float):
	
	if samus.is_on_floor() and samus.fall_time > bounce_fall_time:
		landing_bounce()
	
	if not spiderball_active:
		if Input.is_action_pressed("pad_left") and samus.facing == Enums.dir.LEFT:
			physics.accelerate_x(roll_ground_acceleration, roll_ground_max_speed, Enums.dir.LEFT)
		elif Input.is_action_pressed("pad_right") and samus.facing == Enums.dir.RIGHT:
			physics.accelerate_x(roll_ground_acceleration, roll_ground_max_speed, Enums.dir.RIGHT)
		else:
			physics.decelerate_x(roll_ground_deceleration)
			
		if samus.is_upgrade_active("springball"):
			if Input.is_action_pressed("jump") and samus.is_on_floor():
				springball_current_time = springball_time
				physics.accelerate_y(springball_speed, 999999999999, Enums.dir.UP)
			elif not samus.is_on_floor() and springball_current_time != 0 and Input.is_action_pressed("jump"):
				physics.accelerate_y(springball_speed, 999999999999, Enums.dir.UP)
				springball_current_time -= delta
				if springball_current_time <= 0:
					springball_current_time = 0
			else:
				springball_current_time = 0
