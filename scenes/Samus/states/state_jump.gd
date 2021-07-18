extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

const id = "jump"

const damage_type: int = Enums.DamageType.SCREWATTACK
var damage_amount: float = Data.data["damage_values"]["samus"]["weapons"]["screwattack"]["damage"]

# PHYSICS
const ledge_max_angle = 20

var jump_speed: float
var jump_acceleration: float
var jump_time: float
var jump_current_time: float

var first_frame = false
var spinning: bool = false setget set_spinning
var screwattacking: bool = false

var grip_raycast_container: Node2D
var grip_above_raycast: RayCast2D
var grip_below_raycast: RayCast2D
#var ledgeRaycastVert: RayCast2D
#var ledgeRaycastHoriz: RayCast2D

var walljump_raycasts: Dictionary
var WalljumpTimer: Timer
const WalljumpPeriod: float = 0.075

var PowergripCooldownTimer: Timer = Global.timer()
var powergrip_cooldown: float = 0.25

var animations = {}
var sounds = {
	"jump": Sound.new("res://audio/samus/jump/sndJump.wav", Sound.TYPE.SAMUS),
	"walljump": Sound.new("res://audio/samus/jump/sndWallJump.wav", Sound.TYPE.SAMUS),
	"land": Sound.new("res://audio/samus/jump/sndLand.wav", Sound.TYPE.SAMUS)
}
var sounds_spin = {
	"spin": Sound.new("res://audio/samus/jump/sndSpinJump.wav", true),
	"spin_space": Sound.new("res://audio/samus/jump/sndSpaceJump.wav", true),
	"spin_screw": Sound.new("res://audio/samus/jump/sndScrewAttack.wav", true),
	"spin_space_screw": Sound.new("res://audio/samus/jump/sndSpaceScrewAttack.wav", true),
}
var physics_data: Dictionary

# Called during Samus's readying period
func _init(_samus: Node2D):
	Samus = _samus
	Animator = Samus.Animator
	Physics = Samus.Physics
	
#	ledgeRaycastVert = Animator.raycasts.get_node("jump/LedgeVert")
#	ledgeRaycastHoriz = Animator.raycasts.get_node("jump/LedgeHoriz")
	grip_raycast_container = Animator.raycasts.get_node("jump/PowerGrip")
	grip_above_raycast = Animator.raycasts.get_node("jump/PowerGrip/Above")
	grip_below_raycast = Animator.raycasts.get_node("jump/PowerGrip/Below")
	walljump_raycasts = {
		Enums.dir.LEFT: Animator.raycasts.get_node("jump/WallJump/Left"),
		Enums.dir.RIGHT: Animator.raycasts.get_node("jump/WallJump/Right")
	}
	WalljumpTimer = Global.start_timer("WalljumpPeriod", WalljumpPeriod, {}, null)
	WalljumpTimer.stop()
	
	animations = Animator.load_from_json(self.id)
	physics_data = Physics.data["jump"]
	
	set_jump_values()
	Loader.Save.connect("value_set", self, "save_value_set")

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	var options: Array = data["options"]
	first_frame = true
	
	if Samus.previous_state_id == "powergrip":
		PowergripCooldownTimer.start(powergrip_cooldown)
	
#	ledgeRaycastVert.enabled = true
	grip_above_raycast.enabled = true
	grip_below_raycast.enabled = true
	set_walljump_raycasts_state(true)
	
	set_spinning("spin" in options and Samus.aiming in [Samus.aim.FRONT, Samus.aim.NONE])
	
	if "jump" in options:
		if not spinning:
			animations["legs_start"].play()
			sounds["jump"].play()
		jump_current_time = jump_time
		Physics.move_y(-jump_speed, jump_acceleration*(1/60))
	if "fall" in options and not spinning:
		animations["legs_start"].play()
	return self

# Called every frame while this state is active
func process(_delta):
	
	Physics.disable_floor_snap = true
	
	var play_transition = false
	var fire_weapon = false
	var original_spinning = spinning
	
	Samus.set_hurtbox_damage(damage_type, damage_amount if (Samus.is_upgrade_active(Enums.Upgrade.SCREWATTACK) and spinning) else null)
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Samus.shinespark_charged and not spinning:
		if Input.is_action_just_pressed("jump") and not (Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right")):
			change_state("shinespark", {"ballspark": false})
			return
	
	if Samus.is_on_floor() and not Animator.transitioning(false, true) and not first_frame:
		sounds["land"].play()
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("morph_shortcut") and not Animator.transitioning(false, true) and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"]})
		return
	elif Input.is_action_just_pressed("airboost"):
		change_state("airboost")
		return
	elif Input.is_action_just_pressed("jump") and Settings.get("controls/spin_from_jump"):
		set_spinning(true)
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true
		set_spinning(false)
	
	if Input.is_action_pressed("aim_weapon"):
		if Input.is_action_just_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
			set_spinning(false)
		elif Input.is_action_just_pressed("pad_down"):
			set_spinning(false)
			Samus.aiming = Samus.aim.DOWN
		elif Samus.aiming == Samus.aim.FRONT:
			Samus.aiming = Samus.aim.UP
			set_spinning(false)
	elif Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
		if Input.is_action_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
			set_spinning(false)
		elif Input.is_action_pressed("pad_down"):
			Samus.aiming = Samus.aim.DOWN
			set_spinning(false)
		else:
			Samus.aiming = Samus.aim.FRONT
	else:
		if Input.is_action_pressed("pad_up"):
			Samus.aiming = Samus.aim.SKY
			set_spinning(false)
		elif Input.is_action_pressed("pad_down"):
			if Samus.aiming == Samus.aim.FLOOR and Input.is_action_just_pressed("pad_down") and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
				change_state("morphball", {"options": ["animate"]})
				return
			else:
				Samus.aiming = Samus.aim.FLOOR
				set_spinning(false)
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
				animations["legs"].play(true)
		elif not Animator.transitioning(false, true):
			
			var spin_animation = "spin"
			
			if Samus.is_upgrade_active(Enums.Upgrade.SPACEJUMP):
				spin_animation = spin_animation + "_space"
			if Samus.is_upgrade_active(Enums.Upgrade.SCREWATTACK):
				spin_animation = spin_animation + "_screw"
				animations["screw_spark"].play()
			
			animations[spin_animation].play(true)
			
			if sounds_spin[spin_animation].status != Sound.STATE.PLAYING:
				sounds_spin[spin_animation].play()
	
	if not spinning or play_transition:
		Samus.boosting = false
	
	if fire_weapon and Samus.Weapons.current_visor == null:
		if spinning != original_spinning:
			Samus.Weapons.reset_fire_pos()
		Samus.Weapons.fire()

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	for sound in sounds_spin.values():
		sound.stop()
	if new_state_key != "morphball":
		Samus.boosting = false
#	ledgeRaycastVert.enabled = false
#	ledgeRaycastHoriz.enabled = false
	grip_above_raycast.enabled = false
	grip_below_raycast.enabled = false
	set_walljump_raycasts_state(false)
	set_spinning(false)
	Samus.set_hurtbox_damage(damage_type, null)
	Samus.change_state(new_state_key, data)

func physics_process(delta: float):
	
	var pad_x = Shortcut.get_pad_vector("pressed").x
	
	if Samus.is_upgrade_active(Enums.Upgrade.POWERGRIP) and pad_x == (1 if Samus.facing == Enums.dir.RIGHT else -1):
		
		if Samus.facing == Enums.dir.LEFT:
			grip_above_raycast.rotation_degrees = 180
			grip_below_raycast.rotation_degrees = 180
			grip_raycast_container.position.x = 12
		else:
			grip_above_raycast.rotation_degrees = 0
			grip_below_raycast.rotation_degrees = 0
			grip_raycast_container.position.x = -2
		vOverlay.SET("ang", null)
#		ledgeRaycastVert.force_raycast_update()
		if PowergripCooldownTimer.time_left == 0 and grip_below_raycast.is_colliding():
			var angle = 0
			if grip_above_raycast.is_colliding():
				angle = abs(rad2deg(grip_above_raycast.get_collision_normal().angle()) + 90)
			vOverlay.SET("ang", angle)
			
			if angle <= ledge_max_angle:
				
#				ledgeRaycastHoriz.enabled = true
#				ledgeRaycastHoriz.position.x = ledgeRaycastVert.get_collision_point().y + 0.1
#				if ledgeRaycastHoriz.is_colliding():
				change_state("powergrip", {"point": grip_below_raycast.get_collision_point()})
#					ledgeRaycastHoriz.enabled = false
#					return
#				ledgeRaycastHoriz.enabled = false
			
#			if collision_angle > abs(rad2deg(Physics.FLOOR_MAX_ANGLE)):
#				pass
#			return

	# Vertical
	if (not Samus.is_on_floor() or first_frame) and jump_current_time != 0 and Input.is_action_pressed("jump"):
		Physics.move_y(-jump_speed, (jump_acceleration if not spinning else INF)*delta)
#		Physics.accelerate_y(jump_acceleration, jump_speed, Enums.dir.UP)
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
			elif Samus.is_upgrade_active(Enums.Upgrade.SPACEJUMP) and Physics.vel.y > 0:
				jump_current_time = jump_time
		
		if WalljumpTimer.time_left != 0:
			return
		
		if Input.is_action_pressed("pad_left"):
			Physics.move_x(min(-physics_data["horiz_spin_speed"], Physics.vel.x))
		elif Input.is_action_pressed("pad_right"):
			Physics.move_x(max(physics_data["horiz_spin_speed"], Physics.vel.x))
		elif abs(Physics.vel.x) != physics_data["horiz_spin_speed"]:
			var polarity = 1 if Samus.facing == Enums.dir.RIGHT else -1
			if abs(Physics.vel.x) > physics_data["horiz_spin_speed"]:
				Physics.move_x(max(physics_data["horiz_spin_speed"], abs(Physics.vel.x))*polarity, physics_data["horiz_spin_deceleration"])
			else:
				Physics.move_x(max(physics_data["horiz_spin_speed"], abs(Physics.vel.x))*polarity)
	else:
		if pad_x != 0:
			Physics.move_x(max(physics_data["horiz_speed"], abs(Physics.vel.x)) * pad_x, physics_data["horiz_acceleration"])
		else:
			Physics.move_x(0, physics_data["horiz_acceleration"])
#			Physics.decelerate_x(horiz_acceleration)
	first_frame = false

func set_walljump_raycasts_state(enabled: bool):
	for raycast in walljump_raycasts.values():
		raycast.enabled = enabled

func chargebeam_fired():
	if spinning:
		set_spinning(false)
		process(0)
		Samus.Weapons.reset_fire_pos()

func set_jump_values():
	if Samus.is_upgrade_active(Enums.Upgrade.HIGHJUMP):
		jump_speed = physics_data["speed_high"]
		jump_acceleration = physics_data["acceleration_high"]
		jump_time = physics_data["time_high"]
	else:
		jump_speed = physics_data["speed"]
		jump_acceleration = physics_data["acceleration"]
		jump_time = physics_data["time"]

func save_value_set(path: Array, _value):
	if len(path) != 4 or path[0] != "samus" or path[1] != "upgrades" or path[2] != Enums.Upgrade.HIGHJUMP:
		return
	set_jump_values()

func set_spinning(value: bool):
	
	if spinning == value:
		return
	
	spinning = value
	Animator.SpriteContainer.current_profile = "spacejump" if spinning and Samus.is_upgrade_active(Enums.Upgrade.SPACEJUMP) else null
	if Animator.SpriteContainer.current_profile == null:
		Animator.SpriteContainer.clear_trail()
	
	grip_raycast_container.position.y = -1 if spinning else -14
