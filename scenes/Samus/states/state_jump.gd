extends Node

var samus: KinematicBody2D
var animator: Node
var physics: Node

const id = "jump"

# PHYSICS
const jump_speed = 150
const jump_acceleration = 200
const jump_time = 0.5
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
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	
	self.walljump_raycasts = {
		Enums.dir.LEFT: animator.get_node("WalljumpRaycastLeft"),
		Enums.dir.RIGHT: animator.get_node("WalljumpRaycastRight")
	}
	self.WalljumpTimer = Global.start_timer("WalljumpPeriod", WalljumpPeriod, {}, null)
	WalljumpTimer.stop()
	
	self.animations = animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	var options: Array = data["options"]
	first_frame = true
	set_walljumpraycast_state(true)
	spinning = "spin" in options
	if "jump" in options:
		if not spinning:
			animations["legs_start"].play()
		jump_current_time = jump_time
		physics.accelerate_y(jump_speed, jump_acceleration, Enums.dir.UP)
	if "fall" in options and not spinning:
		animations["legs_start"].play()
	return self

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var fire_weapon = false
#	if first_frame:
#		return
	
	if Global.config["zm_controls"]:
		animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if samus.is_on_floor() and not animator.transitioning() and not first_frame:
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("morph_shortcut") and not animator.transitioning():
		change_state("morphball", {"options": ["animate"]})
		return
	elif Input.is_action_just_pressed("jump") and Global.config["spin_from_jump"]:
		spinning = true
#	elif WalljumpRaycast.is_colliding() and Input.is_action_just_pressed("jump") and WalljumpTimer.time_left != 0:
#		animations["spin_walljump"].play()
#		print("PLAYYY")
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true
		spinning = false
	
	if Input.is_action_pressed("aim_weapon"):
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.UP
			spinning = false
		elif Input.is_action_just_pressed("pad_down"):
			samus.aiming = samus.aim.DOWN
			spinning = false
		elif samus.aiming == samus.aim.FRONT:
			samus.aiming = samus.aim.UP
			spinning = false
	elif Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
		if Input.is_action_pressed("pad_up"):
			samus.aiming = samus.aim.UP
		elif Input.is_action_pressed("pad_down"):
			samus.aiming = samus.aim.DOWN
		else:
			samus.aiming = samus.aim.FRONT
	else:
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.SKY
		elif Input.is_action_just_pressed("pad_down"):
			if samus.aiming == samus.aim.FLOOR:
				change_state("morphball", {"options": ["animate"]})
				return
			else:
				samus.aiming = samus.aim.FLOOR
		elif not samus.aiming in [samus.aim.SKY, samus.aim.FLOOR]:
			samus.aiming = samus.aim.FRONT
	
	if not animator.transitioning():
		if Input.is_action_pressed("pad_left"):
			if samus.facing == Enums.dir.RIGHT:
				play_transition = true
			samus.facing = Enums.dir.LEFT
			if walljump_raycasts[Enums.dir.LEFT].is_colliding():
				WalljumpTimer.start()
				animations["spin_walljump"].play()
			
		elif Input.is_action_pressed("pad_right"):
			if samus.facing == Enums.dir.LEFT:
				play_transition = true
			samus.facing = Enums.dir.RIGHT
			if walljump_raycasts[Enums.dir.RIGHT].is_colliding():
				WalljumpTimer.start()
				animations["spin_walljump"].play()
		
	
	var animation: String
	match samus.aiming:
		samus.aim.SKY: animation = "aim_sky"
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		samus.aim.FLOOR: animation = "aim_floor"
		_: animation = "aim_front"
	if play_transition and not spinning:
		animations["legs_turn"].play()
		animations["turn_" + animation].play()
	else:
		if not spinning:
			if not animator.transitioning(false, true):
				animations[animation].play(true)
			if not animator.transitioning(true, true) and samus.aiming != samus.aim.FLOOR:
				animations["legs"].play()
		elif not animator.transitioning(false, true):
			animations["spin"].play(true)
	
	if fire_weapon:
		samus.weapons.fire()

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	set_walljumpraycast_state(false)
	samus.change_state(new_state_key, data)

func physics_process(delta: float):
	
	# Vertical
	if (not samus.is_on_floor() or first_frame) and jump_current_time != 0 and Input.is_action_pressed("jump"):
		physics.accelerate_y(jump_speed, jump_acceleration, Enums.dir.UP)
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
			physics.vel.x = -max(spin_horiz_speed, abs(physics.vel.x))
		elif Input.is_action_pressed("pad_right"):
			physics.vel.x = max(spin_horiz_speed, abs(physics.vel.x))
		elif abs(physics.vel.x) != spin_horiz_speed:
			if physics.vel.x != 0:
				physics.decelerate_x(spin_horiz_deceleration)
			else:
				match samus.facing:
					Enums.dir.LEFT: physics.vel.x = -max(spin_horiz_speed, abs(physics.vel.x))
					Enums.dir.RIGHT: physics.vel.x = max(spin_horiz_speed, abs(physics.vel.x))
	else:
		if Input.is_action_pressed("pad_left"):
			physics.accelerate_x(horiz_acceleration, max(horiz_speed, abs(physics.vel.x)), Enums.dir.LEFT)
		elif Input.is_action_pressed("pad_right"):
			physics.accelerate_x(horiz_acceleration, max(horiz_speed, abs(physics.vel.x)), Enums.dir.RIGHT)
		else:
			physics.decelerate_x(horiz_acceleration)
	first_frame = false

func set_walljumpraycast_state(enabled: bool):
	for raycast in walljump_raycasts.values():
		raycast.enabled = enabled
