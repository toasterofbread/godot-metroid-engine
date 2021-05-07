extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node
const id = "run"

var speedboost_charge_time: float = 2.0
var SpeedboostTimer: Timer
var animations: Dictionary = {}

# PHYSICS
const run_acceleration = 15
const run_deceleration = 50
const max_run_speed = 170

const boost_acceleration = 100
const boost_deceleration = 50
const max_boost_speed = 500


func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	self.SpeedboostTimer = Global.timer([Samus, "set", ["boosting", true]])
	animations = Animator.load_from_json(self.id)

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var fire_weapon = false
	
	if Input.is_action_just_pressed("morph_shortcut") and not Animator.transitioning():
		change_state("morphball", {"options": ["animate"]})
		return
	
	if Settings.get("controls/zm_style_aiming"):
		if Input.is_action_pressed("arm_weapon"):
			Animator.set_armed(true)
		else:
			Animator.set_armed(false)
	
	if Samus.is_on_wall():
		change_state("neutral")
		return
	
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
		elif Input.is_action_pressed("pad_down"):
			change_state("crouch")
			return
		else:
			Global.start_timer("run_transition", 0.2, {"aiming": Samus.aiming})
			change_state("neutral")
			return
	
	if play_transition:
		animations["legs_turn"].qplay()
		animations["turn_" + animation].play()
	elif not Animator.transitioning(false, true):
		animations[animation].play(true)
	
	if fire_weapon:
		Samus.Weapons.fire()
	
# Called when Samus' state is changed to this one
func init_state(data: Dictionary):
	Samus.boosting = data["boost"]
	if Samus.is_upgrade_active("speedbooster"):
		SpeedboostTimer.start(speedboost_charge_time)
	return self

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	SpeedboostTimer.stop()
	Samus.aim_none_timer.stop()
	Samus.change_state(new_state_key, data)
	if new_state_key == "jump":
		Samus.boosting = "spin" in data["options"] and Samus.boosting
	elif new_state_key != "morphball":
		Samus.boosting = false

func physics_process(_delta: float):
	
	if Samus.boosting:
		if Samus.facing == Enums.dir.LEFT and not Input.is_action_pressed("pad_left"):
			Samus.boosting = false
		elif Samus.facing == Enums.dir.RIGHT and not Input.is_action_pressed("pad_right"):
			Samus.boosting = false
	
	if Animator.transitioning():
		return
	
	if Samus.boosting:
		Physics.accelerate_x(boost_acceleration, max_boost_speed, Samus.facing)
	else:
		Physics.accelerate_x(run_acceleration, max_run_speed, Samus.facing)
