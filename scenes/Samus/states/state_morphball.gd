extends Node

var samus: KinematicBody2D
var animator: Node
var physics: Node

var spiderball_active = false

const id = "morphball"

# PHYSICS
const roll_ground_acceleration = 15
const roll_ground_deceleration = 15000
const roll_ground_max_speed = 225
const springball_speed = 50
const springball_time = 0.2
var springball_current_time = 0

var animations = {}

# Called during Samus's readying period
func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	self.physics = samus.physics
	
	animations = {
		"roll_ground": animator.Animation.new(animator,"roll_ground", self.id, false),
		"roll_spider": animator.Animation.new(animator,"roll_spider", self.id, false),
		"turn": animator.Animation.new(animator,"turn", self.id, false),
		"unmorph": animator.Animation.new(animator,"unmorph", self.id, false),
		"morph": animator.Animation.new(animator,"morph", "crouch", false)
	}

# Called when Samus's state is changed to this one
func init(data: Dictionary):
	spiderball_active = false
	return self

# Called every frame while this state is active
func process(delta):
	
	var play_transition = false
	var original_facing = samus.facing

	if Global.config["spiderball_hold"] and Input.is_action_just_pressed("spiderball"):
		spiderball_active = !spiderball_active
	else:
		spiderball_active = Input.is_action_pressed("spiderball")
	
	if (Input.is_action_just_pressed("morph_shortcut") or Input.is_action_just_pressed("pad_up")) and not animator.transitioning() and not spiderball_active:
		toggle_morph()
		return

	if Input.is_action_pressed("pad_left") and not spiderball_active:
		samus.facing = Global.dir.LEFT
		if original_facing == Global.dir.RIGHT:
			animations["turn"].play( true)
			
	elif Input.is_action_pressed("pad_right") and not spiderball_active:
		samus.facing = Global.dir.RIGHT
		if original_facing == Global.dir.LEFT:
			animations["turn"].play( true)

	if spiderball_active:
		animations["roll_spider"].play( false, true)
	else:
		animations["roll_ground"].play( false, true)
	
	if not animator.transitioning() and not (Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right")):
		animations["roll_spider"].paused = true
		animations["roll_ground"].paused = true
func toggle_morph():
	
	if samus.current_state == self:
		animations["unmorph"].play( true)
		change_state("crouch")
	else:
		animations["morph"].play( true)
		change_state("morphball")
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	samus.change_state(new_state_key, data)
	
func physics_process(delta: float):
	if not spiderball_active:
		if Input.is_action_pressed("pad_left") and samus.facing == Global.dir.LEFT:
			physics.accelerate_x(roll_ground_acceleration, roll_ground_max_speed, Global.dir.LEFT)
		elif Input.is_action_pressed("pad_right") and samus.facing == Global.dir.RIGHT:
			physics.accelerate_x(roll_ground_acceleration, roll_ground_max_speed, Global.dir.RIGHT)
		else:
			physics.decelerate_x(roll_ground_deceleration)
			
		if samus.is_upgrade_active("springball"):
			if Input.is_action_pressed("jump") and samus.is_on_floor():
				springball_current_time = springball_time
				physics.accelerate_y(springball_speed, 999999999999, Global.dir.UP)
			elif not samus.is_on_floor() and springball_current_time != 0 and Input.is_action_pressed("jump"):
				physics.accelerate_y(springball_speed, 999999999999, Global.dir.UP)
				springball_current_time -= delta
				if springball_current_time <= 0:
					springball_current_time = 0
			else:
				springball_current_time = 0
