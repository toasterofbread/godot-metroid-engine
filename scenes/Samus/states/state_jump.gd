extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

const id = "jump"

const damage_type = Enums.DamageType.SCREWATTACK
const damage_amount = 0 

# PHYSICS
const jump_speed = 250
const jump_acceleration = 99999
const jump_time = 0.2
var jump_current_time = 125

const horiz_speed = 125
const horiz_acceleration = 10

const spin_horiz_speed = 125
const spin_horiz_deceleration = 10

var first_frame = false
var spinning: bool = false
var screwattacking: bool = false

var ledge_above_raycast: RayCast2D
var ledge_below_raycast: RayCast2D

var walljump_raycasts: Dictionary
var WalljumpTimer: Timer
const WalljumpPeriod: float = 0.075

var PowergripCooldownTimer: Timer = Global.timer()
var powergrip_cooldown: float = 0.25

var animations = {}

var sounds = {
	"jump": Sound.new("res://audio/samus/jump/sndJump.wav"),
	"walljump": Sound.new("res://audio/samus/jump/sndWallJump.wav"),
	"land": Sound.new("res://audio/samus/jump/sndLand.wav")
}

var sounds_spin = {
	"spin": Sound.new("res://audio/samus/jump/sndSpinJump.wav", true),
	"spin_space": Sound.new("res://audio/samus/jump/sndSpaceJump.wav", true),
	"spin_screw": Sound.new("res://audio/samus/jump/sndScrewAttack.wav", true),
	"spin_space_screw": Sound.new("res://audio/samus/jump/sndSpaceScrewAttack.wav", true),
}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.ledge_above_raycast = Animator.raycasts.get_node("jump/LedgeAbove")
	self.ledge_below_raycast = Animator.raycasts.get_node("jump/LedgeBelow")
	self.walljump_raycasts = {
		Enums.dir.LEFT: Animator.raycasts.get_node("jump/WalljumpLeft"),
		Enums.dir.RIGHT: Animator.raycasts.get_node("jump/WalljumpRight")
	}
	self.WalljumpTimer = Global.start_timer("WalljumpPeriod", WalljumpPeriod, {}, null)
	WalljumpTimer.stop()
	
	self.animations = Animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	var options: Array = data["options"]
	first_frame = true
	
	if Samus.previous_state_id == "powergrip":
		PowergripCooldownTimer.start(powergrip_cooldown)
	
	ledge_above_raycast.enabled = true
	ledge_below_raycast.enabled = true
	set_walljump_raycasts_state(true)
	
	spinning = "spin" in options and Samus.aiming in [Samus.aim.FRONT, Samus.aim.NONE]
	
	if "jump" in options:
		if not spinning:
			animations["legs_start"].play()
			sounds["jump"].play()
		jump_current_time = jump_time
		Physics.accelerate_y(jump_speed, jump_acceleration, Enums.dir.UP)
	if "fall" in options and not spinning:
		animations["legs_start"].play()
	return self

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var fire_weapon = false
	
	Samus.set_hurtbox_damage(damage_type, damage_amount if Samus.is_upgrade_active("screwattack") and spinning else null)
	
	if Settings.get("controls/zm_style_aiming"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Samus.shinespark_charged and not spinning:
		if Input.is_action_just_pressed("jump") and not (Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right")):
			change_state("shinespark", {"ballspark": false})
			return
	
	if Samus.is_on_floor() and not Animator.transitioning(false, true) and not first_frame:
		sounds["land"].play()
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
		elif (Samus.aiming != Samus.aim.SKY or Input.is_action_just_released("secondary_pad_up")) and (Samus.aiming != Samus.aim.FLOOR or Input.is_action_just_released("secondary_pad_down")):
			Samus.aiming = Samus.aim.FRONT
	
	var shortcut_facing = Shortcut.get_facing()
	if shortcut_facing != null and shortcut_facing != Samus.facing:
		Samus.facing = shortcut_facing
		play_transition = true
	
	var shortcut_aiming = Shortcut.get_aiming(Samus)
	if shortcut_aiming != null:
		Samus.aiming = shortcut_aiming
	
	if not Animator.transitioning():
		if Input.is_action_pressed("pad_left"):
			if Samus.facing == Enums.dir.RIGHT:
				play_transition = true
			Samus.facing = Enums.dir.LEFT
			if walljump_raycasts[Enums.dir.LEFT].is_colliding() and Input.is_action_just_pressed("pad_left"):
				WalljumpTimer.start()
				animations["spin_walljump"].play()
			
		elif Input.is_action_pressed("pad_right"):
			if Samus.facing == Enums.dir.LEFT:
				play_transition = true
			Samus.facing = Enums.dir.RIGHT
			if walljump_raycasts[Enums.dir.RIGHT].is_colliding() and Input.is_action_just_pressed("pad_right"):
				WalljumpTimer.start()
				animations["spin_walljump"].play()
	
	if not spinning:
		for sound in sounds_spin.values():
			sound.stop()
	
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
			
			var spin_animation = "spin"
			
			if Samus.is_upgrade_active("spacejump"):
				spin_animation = spin_animation + "_space"
			if Samus.is_upgrade_active("screwattack"):
				spin_animation = spin_animation + "_screw"
				animations["screw_spark"].play()
			
			animations[spin_animation].play(true)
			
			if sounds_spin[spin_animation].status != Sound.STATE.PLAYING:
				sounds_spin[spin_animation].play()
	
	if not spinning or play_transition:
		Samus.boosting = false
	
	if fire_weapon:
		Samus.Weapons.fire()

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	for sound in sounds_spin.values():
		sound.stop()
	if new_state_key != "morphball":
		Samus.boosting = false
	ledge_above_raycast.enabled = false
	ledge_below_raycast.enabled = false
	set_walljump_raycasts_state(false)
	Samus.set_hurtbox_damage(damage_type, null)
	Samus.change_state(new_state_key, data)

func physics_process(delta: float):
	
	if Samus.facing == Enums.dir.LEFT:
		ledge_above_raycast.cast_to = Vector2(-16, 0)
		ledge_above_raycast.position = Vector2(-2, -20)
		ledge_below_raycast.position = Vector2(-9, -19)
	else:
		ledge_above_raycast.cast_to = Vector2(16, 0)
		ledge_above_raycast.position = Vector2(12, -20)
		ledge_below_raycast.position = Vector2(19, -19)
	
	if ledge_above_raycast.enabled and Samus.is_upgrade_active("powergrip"):
		if Samus.is_on_wall() and PowergripCooldownTimer.time_left == 0:
			if !ledge_above_raycast.is_colliding() and ledge_below_raycast.is_colliding():
				change_state("powergrip", {"point": ledge_below_raycast.get_collision_point()})
				return
	
	# Vertical
	if (not Samus.is_on_floor() or first_frame) and jump_current_time != 0 and Input.is_action_pressed("jump"):
		Physics.accelerate_y(jump_acceleration, jump_speed, Enums.dir.UP)
		jump_current_time -= delta
		if jump_current_time < 0:
			jump_current_time = 0
	else:
		jump_current_time = 0
	
	set_walljump_raycasts_state(spinning)
	
	# Horizontal
	if spinning:
		if Input.is_action_just_pressed("jump"):
			if walljump_raycasts[Enums.dir.RIGHT].is_colliding() and Input.is_action_pressed("pad_right"):
				jump_current_time = jump_time
				sounds["walljump"].play()
			elif walljump_raycasts[Enums.dir.LEFT].is_colliding() and Input.is_action_pressed("pad_left"):
				jump_current_time = jump_time
				sounds["walljump"].play()
			elif Samus.is_upgrade_active("spacejump"):
				jump_current_time = jump_time
		
		if WalljumpTimer.time_left != 0:
			return
		
		if Input.is_action_pressed("pad_left"):
			Physics.vel.x = min(-spin_horiz_speed, Physics.vel.x)
		elif Input.is_action_pressed("pad_right"):
			Physics.vel.x = max(spin_horiz_speed, Physics.vel.x)
		elif abs(Physics.vel.x) != spin_horiz_speed:
			if Physics.vel.x != 0:
				Physics.decelerate_x(spin_horiz_deceleration)
			else:
				match Samus.facing:
					Enums.dir.LEFT: Physics.vel.x = -max(spin_horiz_speed, abs(Physics.vel.x))
					Enums.dir.RIGHT: Physics.vel.x = max(spin_horiz_speed, abs(Physics.vel.x))
	else:
		if Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
			Physics.accelerate_x(horiz_acceleration, horiz_speed, Samus.facing)
		else:
			Physics.decelerate_x(horiz_acceleration)
	first_frame = false

func set_walljump_raycasts_state(enabled: bool):
	for raycast in walljump_raycasts.values():
		raycast.enabled = enabled

#func set_screwattacking(value: bool):
#	if screwattacking != value:
#		screwattacking = value
#		emit_signal("screwattacking_changed", value)
