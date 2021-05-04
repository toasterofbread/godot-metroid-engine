extends Node

var samus: KinematicBody2D
var animator: Node
var physics: Node
const id = "run"

var animations: Dictionary = {}

# PHYSICS
const run_acceleration = 15
const run_deceleration = 50
const max_run_speed = 170

func _init(_samus: Node2D):
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	animations = animator.load_from_json(self.id)

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var fire_weapon = false
	
	if Input.is_action_just_pressed("morph_shortcut") and not animator.transitioning():
		change_state("morphball", {"options": ["animate"]})
		return
	
	if Config.get("zm_controls"):
		if Input.is_action_pressed("arm_weapon"):
			animator.set_armed(true)
		else:
			animator.set_armed(false)
	
	if Input.is_action_just_pressed("jump"):
		change_state("jump", {"options": ["jump", "spin"]})
		return
	elif not samus.is_on_floor():
		change_state("jump", {"options": ["fall"]})
		return
	
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true
		samus.aim_none_timer.start()
	
	if Input.is_action_pressed("aim_weapon"):
		if samus.aiming == samus.aim.FRONT or samus.aiming == samus.aim.NONE:
			samus.aiming = samus.aim.UP
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			samus.aiming = samus.aim.DOWN
		
		
	elif Input.is_action_pressed("pad_up"):
		samus.aiming = samus.aim.UP
		
	elif Input.is_action_pressed("pad_down"):
		samus.aiming = samus.aim.DOWN
		
	else:
		if samus.aim_none_timer.time_left == 0:
			samus.aiming = samus.aim.NONE
		else:
			samus.aiming = samus.aim.FRONT
	
	var animation: String
	match samus.aiming:
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		samus.aim.FRONT: animation = "aim_front"
		_: animation = "aim_none"
	
	
	if not animator.transitioning():
		if Input.is_action_pressed("pad_left"):
			if samus.facing == Enums.dir.RIGHT:
				play_transition = true
			samus.facing = Enums.dir.LEFT
		elif Input.is_action_pressed("pad_right"):
			if samus.facing == Enums.dir.LEFT:
				play_transition = true
			samus.facing = Enums.dir.RIGHT
		else:
			Global.start_timer("run_transition", 0.2, {"aiming": samus.aiming})
			change_state("neutral")
			return
	
	if play_transition:
		animations["legs_turn"].play()
		animations["turn_" + animation].play()
	elif not animator.transitioning(false, true):
		animations[animation].play(true)
	
	if fire_weapon:
		samus.weapons.fire()
	
# Called when Samus' state is changed to this one
func init_state(_data: Dictionary):
	return self

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	samus.aim_none_timer.stop()
	samus.change_state(new_state_key, data)
	
	match new_state_key:
		"neutral": pass

func physics_process(_delta: float):
	if Input.is_action_pressed("pad_left") and samus.facing == Enums.dir.LEFT and not animator.transitioning():
		physics.accelerate_x(run_acceleration, max_run_speed, Enums.dir.LEFT)
	elif Input.is_action_pressed("pad_right") and samus.facing == Enums.dir.RIGHT and not animator.transitioning():
		physics.accelerate_x(run_acceleration, max_run_speed, Enums.dir.RIGHT)
