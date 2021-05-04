extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node
const id = "run"

var animations: Dictionary = {}

# PHYSICS
const run_acceleration = 15
const run_deceleration = 50
const max_run_speed = 170

func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	animations = Animator.load_from_json(self.id)

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var fire_weapon = false
	
	if Input.is_action_just_pressed("morph_shortcut") and not Animator.transitioning():
		change_state("morphball", {"options": ["animate"]})
		return
	
	if Config.get("zm_controls"):
		if Input.is_action_pressed("arm_weapon"):
			Animator.set_armed(true)
		else:
			Animator.set_armed(false)
	
	if Input.is_action_just_pressed("jump"):
		change_state("jump", {"options": ["jump", "spin"]})
		return
	elif not Samus.is_on_floor():
		change_state("jump", {"options": ["fall"]})
		return
	
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true
		Samus.aim_none_timer.start()
	
	if Input.is_action_pressed("aim_weapon"):
		if Samus.aiming == Samus.aim.FRONT or Samus.aiming == Samus.aim.NONE:
			Samus.aiming = Samus.aim.UP
		if Input.is_action_just_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			Samus.aiming = Samus.aim.DOWN
		
		
	elif Input.is_action_pressed("pad_up"):
		Samus.aiming = Samus.aim.UP
		
	elif Input.is_action_pressed("pad_down"):
		Samus.aiming = Samus.aim.DOWN
		
	else:
		if Samus.aim_none_timer.time_left == 0:
			Samus.aiming = Samus.aim.NONE
		else:
			Samus.aiming = Samus.aim.FRONT
	
	var animation: String
	match Samus.aiming:
		Samus.aim.UP: animation = "aim_up"
		Samus.aim.DOWN: animation = "aim_down"
		Samus.aim.FRONT: animation = "aim_front"
		_: animation = "aim_none"
	
	
	if not Animator.transitioning():
		if Input.is_action_pressed("pad_left"):
			if Samus.facing == Enums.dir.RIGHT:
				play_transition = true
			Samus.facing = Enums.dir.LEFT
		elif Input.is_action_pressed("pad_right"):
			if Samus.facing == Enums.dir.LEFT:
				play_transition = true
			Samus.facing = Enums.dir.RIGHT
		else:
			Global.start_timer("run_transition", 0.2, {"aiming": Samus.aiming})
			change_state("neutral")
			return
	
	if play_transition:
		animations["legs_turn"].play()
		animations["turn_" + animation].play()
	elif not Animator.transitioning(false, true):
		animations[animation].play(true)
	
	if fire_weapon:
		Samus.Weapons.fire()
	
# Called when Samus' state is changed to this one
func init_state(_data: Dictionary):
	return self

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.aim_none_timer.stop()
	Samus.change_state(new_state_key, data)
	
	match new_state_key:
		"neutral": pass

func physics_process(_delta: float):
	if Input.is_action_pressed("pad_left") and Samus.facing == Enums.dir.LEFT and not Animator.transitioning():
		Physics.accelerate_x(run_acceleration, max_run_speed, Enums.dir.LEFT)
	elif Input.is_action_pressed("pad_right") and Samus.facing == Enums.dir.RIGHT and not Animator.transitioning():
		Physics.accelerate_x(run_acceleration, max_run_speed, Enums.dir.RIGHT)
