extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

const id = "jump"

# PHYSICS
const jump_speed = 250
const jump_acceleration = 125
const jump_time = 0.275
var jump_current_time = 125

const horiz_speed = 125
const horiz_acceleration = 10

const spin_horiz_speed = 150
const spin_horiz_deceleration = 10

var first_frame = false
var spinning: bool = false

var walljump_raycasts: Dictionary
var WalljumpTimer: Timer
const WalljumpPeriod: float = 0.075

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.walljump_raycasts = {
		Enums.dir.LEFT: Animator.raycasts.get_node("WalljumpLeft"),
		Enums.dir.RIGHT: Animator.raycasts.get_node("WalljumpRight")
	}
	self.WalljumpTimer = Global.start_timer("WalljumpPeriod", WalljumpPeriod, {}, null)
	WalljumpTimer.stop()
	
	self.animations = Animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	var options: Array = data["options"]
	first_frame = true
	set_walljumpraycast_state(true)
	
	spinning = "spin" in options and Samus.aiming in [Samus.aim.FRONT, Samus.aim.NONE]
	
	if "jump" in options:
		if not spinning:
			animations["legs_start"].play()
		jump_current_time = jump_time
		Physics.accelerate_y(jump_speed, jump_acceleration, Enums.dir.UP)
	if "fall" in options and not spinning:
		animations["legs_start"].play()
	return self

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var fire_weapon = false
	
	if Settings.get("controls/zm_style_aiming"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Samus.is_on_floor() and not Animator.transitioning(false, true) and not first_frame:
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("morph_shortcut") and not Animator.transitioning(false, true):
		change_state("morphball", {"options": ["animate"]})
		return
	elif Input.is_action_just_pressed("jump") and Settings.get("controls/spin_from_jump"):
		spinning = true
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true
		spinning = false
	
	if Input.is_action_pressed("aim_weapon"):
		if Input.is_action_just_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
			spinning = false
		elif Input.is_action_just_pressed("pad_down"):
			spinning = false
			Samus.aiming = Samus.aim.DOWN
		elif Samus.aiming == Samus.aim.FRONT:
			Samus.aiming = Samus.aim.UP
			spinning = false
	elif Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
		if Input.is_action_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
			spinning = false
		elif Input.is_action_pressed("pad_down"):
			Samus.aiming = Samus.aim.DOWN
			spinning = false
		else:
			Samus.aiming = Samus.aim.FRONT
	else:
		if Input.is_action_pressed("pad_up"):
			Samus.aiming = Samus.aim.SKY
			spinning = false
		elif Input.is_action_pressed("pad_down"):
			if Samus.aiming == Samus.aim.FLOOR and Input.is_action_just_pressed("pad_down"):
				change_state("morphball", {"options": ["animate"]})
				return
			else:
				Samus.aiming = Samus.aim.FLOOR
				spinning = false
		elif not Samus.aiming in [Samus.aim.SKY, Samus.aim.FLOOR]:
			Samus.aiming = Samus.aim.FRONT
	
	if not Animator.transitioning():
		if Input.is_action_pressed("pad_left"):
			if Samus.facing == Enums.dir.RIGHT:
				play_transition = true
			Samus.facing = Enums.dir.LEFT
			if walljump_raycasts[Enums.dir.LEFT].is_colliding():
				WalljumpTimer.start()
				animations["spin_walljump"].play()
			
		elif Input.is_action_pressed("pad_right"):
			if Samus.facing == Enums.dir.LEFT:
				play_transition = true
			Samus.facing = Enums.dir.RIGHT
			if walljump_raycasts[Enums.dir.RIGHT].is_colliding():
				WalljumpTimer.start()
				animations["spin_walljump"].play()
		
	
	var animation: String
	match Samus.aiming:
		Samus.aim.SKY: animation = "aim_sky"
		Samus.aim.UP: animation = "aim_up"
		Samus.aim.DOWN: animation = "aim_down"
		Samus.aim.FLOOR: animation = "aim_floor"
		_: animation = "aim_front"
	if play_transition and not spinning:
		animations["legs_turn"].play()
		animations["turn_" + animation].play()
	else:
		if not spinning:
			if not Animator.transitioning(false, true):
				animations[animation].play(true)
			if not Animator.transitioning(true, true) and Samus.aiming != Samus.aim.FLOOR:
				animations["legs"].play(false, false, true)
		elif not Animator.transitioning(false, true):
			animations["spin"].play(true)
	
	if fire_weapon:
		Samus.Weapons.fire()

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	set_walljumpraycast_state(false)
	Samus.change_state(new_state_key, data)

func physics_process(delta: float):
	
	# Vertical
	if (not Samus.is_on_floor() or first_frame) and jump_current_time != 0 and Input.is_action_pressed("jump"):
		Physics.accelerate_y(jump_acceleration, jump_speed, Enums.dir.UP)
		jump_current_time -= delta
		if jump_current_time < 0:
			jump_current_time = 0
	else:
		jump_current_time = 0
	
	set_walljumpraycast_state(spinning)
	
	# Horizontal
	if spinning:
		if Input.is_action_just_pressed("jump"):
			if walljump_raycasts[Enums.dir.RIGHT].is_colliding() and Input.is_action_pressed("pad_right"):
				jump_current_time = jump_time
				animations["spin_walljump"].play()
			elif walljump_raycasts[Enums.dir.LEFT].is_colliding() and Input.is_action_pressed("pad_left"):
				jump_current_time = jump_time
				animations["spin_walljump"].play()
		
		if WalljumpTimer.time_left != 0:
			return
		
		if Input.is_action_pressed("pad_left"):
			Physics.vel.x = -max(spin_horiz_speed, abs(Physics.vel.x))
		elif Input.is_action_pressed("pad_right"):
			Physics.vel.x = max(spin_horiz_speed, abs(Physics.vel.x))
		elif abs(Physics.vel.x) != spin_horiz_speed:
			if Physics.vel.x != 0:
				Physics.decelerate_x(spin_horiz_deceleration)
			else:
				match Samus.facing:
					Enums.dir.LEFT: Physics.vel.x = -max(spin_horiz_speed, abs(Physics.vel.x))
					Enums.dir.RIGHT: Physics.vel.x = max(spin_horiz_speed, abs(Physics.vel.x))
	else:
		if Input.is_action_pressed("pad_left"):
			Physics.accelerate_x(horiz_acceleration, max(horiz_speed, abs(Physics.vel.x)), Enums.dir.LEFT)
		elif Input.is_action_pressed("pad_right"):
			Physics.accelerate_x(horiz_acceleration, max(horiz_speed, abs(Physics.vel.x)), Enums.dir.RIGHT)
		else:
			Physics.decelerate_x(horiz_acceleration)
	first_frame = false

func set_walljumpraycast_state(enabled: bool):
	for raycast in walljump_raycasts.values():
		raycast.enabled = enabled
