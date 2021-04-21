extends Node

var samus: KinematicBody2D
var animator: Node
var physics: Node

const id = "jump"

# PHYSICS
const jump_speed = 50
const jump_time = 0.2
var jump_current_time = 0

# Called during Samus's readying period
func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	self.physics = samus.physics

# Called when Samus's state is changed to this one
func init(data: Dictionary):
	if data["jump"]:
		jump_current_time = jump_time
		physics.accelerate_y(jump_speed, 999999999999, Global.dir.UP)
		
	animator.init_stackedsprite(Vector2(0, -14), Vector2(4, 4))

# Called every frame while this state is active
func process(delta):
	
	var play_transition = false

	if Input.is_action_just_pressed("morph_shortcut") and not animator.transitioning():
		toggle_morph()
		return

	if Input.is_action_pressed("aim_weapon"):
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			samus.aiming = samus.aim.DOWN
		elif samus.aiming == samus.aim.FRONT:
			samus.aiming = samus.aim.UP
	elif Input.is_action_pressed("pad_up"):
		samus.aiming = samus.aim.SKY
	else:
		samus.aiming = samus.aim.FRONT

	if Input.is_action_pressed("pad_left"):
		if samus.facing == Global.dir.RIGHT:
			play_transition = true
		samus.facing = Global.dir.LEFT
		
	elif Input.is_action_pressed("pad_right"):
		if samus.facing == Global.dir.LEFT:
			play_transition = true
		samus.facing = Global.dir.RIGHT
	
	elif Input.is_action_just_pressed("jump") and Global.config["spin_from_jump"][0]:
		change_state("spin")
		return

	animator.play("roll_ground", {"directionless": true, "retain_frame": true})

func toggle_morph():
	
	if samus.current_state == self:
		animator.play("unmorph", {"transition": true, "directionless": true, "state_id": "morphball"})
		change_state("crouch")
	else:
		animator.play("morph", {"transition": true, "directionless": true, "state_id": "crouch"})
		change_state("morphball")
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	samus.change_state(new_state_key, data)
	
func physics_process(delta: float):
	if not samus.is_on_floor() and jump_current_time != 0 and Input.is_action_pressed("jump"):
		physics.accelerate_y(jump_speed, 999999999999, Global.dir.UP)
		jump_current_time -= delta
		if jump_current_time <= 0:
			jump_current_time = 0
	else:
		jump_current_time = 0
