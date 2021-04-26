extends Node

var samus: KinematicBody2D
var animator: Node
var physics: Node

const id = "jump"

# PHYSICS
const jump_speed = 500
const jump_time = 1
var jump_current_time = 0

var animations = {}

# Called during Samus's readying period
func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	self.physics = samus.physics
	
	self.animations = {
		"aim_front": animator.Animation.new(animator, "aim_front", self.id, true, Global.dir.UP, Vector2(0, -14)),
		"turn_aim_front": animator.Animation.new(animator, "turn_aim_front", self.id, true, Global.dir.UP, Vector2(0, -14)),
		"aim_up": animator.Animation.new(animator, "aim_up", self.id, true, Global.dir.UP, Vector2(0, -14)),
		"turn_aim_up": animator.Animation.new(animator, "turn_aim_up", self.id, true, Global.dir.UP, Vector2(0, -14)),
		"aim_down": animator.Animation.new(animator, "aim_down", self.id, true, Global.dir.UP, Vector2(0, -14)),
		"turn_aim_down": animator.Animation.new(animator, "turn_aim_down", self.id, true, Global.dir.UP, Vector2(0, -14)),
		"legs": animator.Animation.new(animator, "legs", self.id, true, Global.dir.DOWN, Vector2(4, 4)),
		"legs_turn": animator.Animation.new(animator, "legs_turn", self.id, true, Global.dir.DOWN, Vector2(4, 4)),
	}

# Called when Samus's state is changed to this one
func init(data: Dictionary):
	if data["jump"]:
		jump_current_time = jump_time
		physics.accelerate_y(jump_speed, 999999999999, Global.dir.UP)
	return self

# Called every frame while this state is active
func process(delta):
	var play_transition = false
	
	if samus.is_on_floor():
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("morph_shortcut") and not animator.transitioning():
		samus.states["morphball"].toggle_morph()
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
	elif Input.is_action_pressed("pad_down"):
		samus.aiming = samus.aim.FLOOR
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
	
	elif Input.is_action_just_pressed("jump") and Global.config["spin_from_jump"]:
		return
		change_state("spin")
	
	var animation: String
	match samus.aiming:
		samus.aim.SKY: animation = "aim_sky"
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	if play_transition:
		if animator.animation_id(Global.dir.DOWN) == "legs_start":
			samus.states["neutral"].animations["legs_start"].play(true, true, true)
		else:
			animations["legs_turn"].play(true)
		animations["turn_" + animation].play(true)
	else:
		animations["legs"].play()
		animations[animation].play(false, true)

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
