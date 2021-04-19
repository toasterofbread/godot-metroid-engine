extends Node

var samus: Node2D
var animator: Node
var physics: Node

const id = "run"

# PHYSICS
const run_acceleration = 1500
const run_deceleration = 15000
const max_run_speed = 175

func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	self.physics = samus.physics

# Called every frame while this state is active
func process(delta):
	
	if Input.is_action_just_pressed("morph_shortcut") and not animator.transitioning():
		samus.states["morphball"].toggle_morph()
		return
	
	if Input.is_action_pressed("aim_weapon"):
		
		if samus.aiming == samus.aim.FRONT:
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
		samus.aiming = samus.aim.FRONT
	
	var animation: String
	match samus.aiming:
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		samus.aim.FRONT: animation = "aim_front"
		_: animation = "aim_none"
	
	var turn = false
	if Input.is_action_pressed("pad_left"):
		if samus.facing == Global.dir.RIGHT:
			turn = true
		samus.facing = Global.dir.LEFT
	elif Input.is_action_pressed("pad_right"):
		if samus.facing == Global.dir.LEFT:
			turn = true
		samus.facing = Global.dir.RIGHT
	else:
		Global.start_timer("run_transition", 0.2, {"aiming": samus.aiming})
		change_state("neutral")
		return
	
	if turn:
		animator.play("turn_" + animation, {"transition": true})
	else:
		animator.play(animation, {"retain_frame": true})
	
# Called when Samus' state is changed to this one
func init(data: Dictionary):
	return self

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	samus.change_state(new_state_key, data)
	
	match new_state_key:
		"neutral": pass

func physics_process(delta: float):
	if Input.is_action_pressed("pad_left") and samus.facing == Global.dir.LEFT and not animator.transitioning():
		physics.accelerate_x(run_acceleration, max_run_speed, Global.dir.LEFT)
	elif Input.is_action_pressed("pad_right") and samus.facing == Global.dir.RIGHT and not animator.transitioning():
		physics.accelerate_x(run_acceleration, max_run_speed, Global.dir.RIGHT)


