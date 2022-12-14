extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var sounds: Dictionary
var physics_data: Dictionary

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
var WalljumpTimer: Timer = Global.get_timer()
const WalljumpPeriod: float = 0.075

var PowergripCooldownTimer: Timer = Global.get_timer()
var powergrip_cooldown: float = 0.25

const sounds_spin: Array = [
	"sndSpinJump",
	"sndSpaceJump",
	"sndScrewAttack",
	"sndSpaceScrewAttack",
]

# Called during Samus's readying period
func _init(_Samus: Node2D, _id: String).(_Samus, _id):
	grip_raycast_container = Animator.raycasts.get_node("jump/PowerGrip")
	grip_above_raycast = Animator.raycasts.get_node("jump/PowerGrip/Above")
	grip_below_raycast = Animator.raycasts.get_node("jump/PowerGrip/Below")
	walljump_raycasts = {
		Enums.dir.LEFT: Animator.raycasts.get_node("jump/WallJump/Left"),
		Enums.dir.RIGHT: Animator.raycasts.get_node("jump/WallJump/Right")
	}
	
	set_jump_values()
	Loader.loaded_save.connect("value_set", self, "save_value_set")
	Physics.connect("physics_data_set", self, "set_jump_values")

# Called when Samus's state is changed to this one
func init_state(data: Dictionary, previous_state_id: String):
	var options: Array = data["options"]
	first_frame = true
	
	if previous_state_id == "powergrip":
		PowergripCooldownTimer.start(powergrip_cooldown)
	
	grip_above_raycast.enabled = true
	grip_below_raycast.enabled = true
	set_walljump_raycasts_state(true)
	
	set_spinning("spin" in options and Samus.aiming in [Samus.aim.FRONT, Samus.aim.NONE])
	
	if "jump" in options:
		if not spinning:
			animations["legs_start"].play()
			sounds["sndJump"].play()
		jump_current_time = jump_time
		Physics.move_y(-jump_speed, jump_acceleration*(1/60))
	if "fall" in options and not spinning:
		animations["legs_start"].play()

# Called every frame while this state is active
func process(_delta: float):
	
	Physics.disable_floor_snap = true
	
	var play_transition = false
	var original_spinning = spinning
	var pad_vector: Vector2 = InputManager.get_pad_vector("pressed")
	
	Samus.set_hurtbox_damage(id, damage_type, damage_amount if (Samus.is_upgrade_active(Enums.Upgrade.SCREWATTACK) and spinning) else null)
	
	if Settings.get("control_options/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Input.is_action_just_pressed("fire_weapon") and Samus.Weapons.current_visor == null:
		if spinning:
			set_spinning(false)
			play_animation(false)
			Samus.Weapons.update_fire_pos()
		Samus.Weapons.fire()
	
	if Samus.shinespark_charged and not spinning and Input.is_action_just_pressed("jump") and pad_vector.x == 0:
		change_state("shinespark", {"ballspark": false})
		return
	
	if Samus.is_on_floor() and not Animator.transitioning(false, true) and not first_frame:
		change_state("neutral" if pad_vector.x == 0 else "run", {"boost": Samus.boosting})
		return
	
	if Input.is_action_just_pressed("morph_shortcut") and not Animator.transitioning(false, true) and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"], "jump_current_time": jump_current_time})
		return
	
	if Input.is_action_just_pressed("airspark") and Samus.states["airspark"].can_airspark():
		change_state("airspark")
		return
	
	if Input.is_action_just_pressed("jump") and Settings.get("control_options/spin_from_jump"):
		set_spinning(true)
	
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
	elif pad_vector.x != 0:
		if pad_vector.y == -1:
			Samus.aiming = Samus.aim.UP
			set_spinning(false)
		elif pad_vector.y == 1:
			Samus.aiming = Samus.aim.DOWN
			set_spinning(false)
		else:
			Samus.aiming = Samus.aim.FRONT
	else:
		if pad_vector.y == -1:
			Samus.aiming = Samus.aim.SKY
			set_spinning(false)
		elif pad_vector.y == 1:
			if Samus.aiming == Samus.aim.FLOOR and Input.is_action_just_pressed("pad_down") and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
				change_state("morphball", {"options": ["animate"], "jump_current_time": jump_current_time})
				return
			else:
				Samus.aiming = Samus.aim.FLOOR
				set_spinning(false)
		elif (Samus.aiming != Samus.aim.SKY or Input.is_action_just_released("secondary_pad_up")) and (Samus.aiming != Samus.aim.FLOOR or Input.is_action_just_released("secondary_pad_down")):
			Samus.aiming = Samus.aim.FRONT
	
	var shortcut_facing = InputManager.get_facing()
	if shortcut_facing != null and shortcut_facing != Samus.facing:
		Samus.facing = shortcut_facing
		play_transition = true
	
	var shortcut_aiming = InputManager.get_aiming(Samus)
	if shortcut_aiming != null:
		Samus.aiming = shortcut_aiming
	
	if not Animator.transitioning():
		if pad_vector.x == -1:
			if Samus.facing == Enums.dir.RIGHT:
				play_transition = true
			Samus.facing = Enums.dir.LEFT
			if walljump_raycasts[Enums.dir.LEFT].is_colliding() and Input.is_action_just_pressed("pad_left"):
				WalljumpTimer.start(WalljumpPeriod)
				animations["spin_walljump"].play()
			
		elif pad_vector.x == 1:
			if Samus.facing == Enums.dir.LEFT:
				play_transition = true
			Samus.facing = Enums.dir.RIGHT
			if walljump_raycasts[Enums.dir.RIGHT].is_colliding() and Input.is_action_just_pressed("pad_right"):
				WalljumpTimer.start(WalljumpPeriod)
				animations["spin_walljump"].play()
	
	play_animation(play_transition)
	
	if not spinning or play_transition:
		Samus.boosting = false

func play_animation(play_transition):
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
			animations["spin_space" if Samus.is_upgrade_active(Enums.Upgrade.SPACEJUMP) else "spin"].play(true)
			if Samus.is_upgrade_active(Enums.Upgrade.SCREWATTACK):
				animations["spin_screw_overlay"].play(true)

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	for sound in sounds_spin:
		sounds[sound].stop()
	if new_state_key != "morphball" and new_state_key != "run":
		Samus.boosting = false
	grip_above_raycast.enabled = false
	grip_below_raycast.enabled = false
	set_walljump_raycasts_state(false)
	set_spinning(false)
	Samus.set_hurtbox_damage(id, damage_type, null)
	.change_state(new_state_key, data)

func physics_process(delta: float):
	
	var pad_x = InputManager.get_pad_vector("pressed").x
	
	if Samus.is_upgrade_active(Enums.Upgrade.POWERGRIP) and pad_x == (1 if Samus.facing == Enums.dir.RIGHT else -1):
		
		if Samus.facing == Enums.dir.LEFT:
			grip_above_raycast.rotation_degrees = 180
			grip_below_raycast.rotation_degrees = 180
			grip_raycast_container.position.x = 12
		else:
			grip_above_raycast.rotation_degrees = 0
			grip_below_raycast.rotation_degrees = 0
			grip_raycast_container.position.x = -2
		if PowergripCooldownTimer.time_left == 0 and grip_below_raycast.is_colliding():
			var angle = 0
			if grip_above_raycast.is_colliding():
				angle = abs(rad2deg(grip_above_raycast.get_collision_normal().angle()) + 90)
			
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
				sounds["sndWallJump"].play()
			elif walljump_raycasts[Enums.dir.LEFT].is_colliding() and Input.is_action_pressed("pad_left"):
				jump_current_time = jump_time
				sounds["sndWallJump"].play()
			elif Samus.is_upgrade_active(Enums.Upgrade.SPACEJUMP) and Physics.vel.y > 0:
				jump_current_time = jump_time
		
		if WalljumpTimer.time_left != 0.0:
			return
		
		var target_speed: float
		if Samus.boosting and sign(Physics.vel.x) == pad_x:
			target_speed = max(abs(Physics.vel.x), physics_data["horiz_spin_speed"])
		else:
			target_speed = clamp(abs(Physics.vel.x), physics_data["horiz_spin_speed"], physics_data["horiz_spin_max_speed"])
		
		if abs(target_speed) > physics_data["horiz_spin_speed"]:
			Physics.move_x(target_speed*pad_x, physics_data["horiz_spin_deceleration"])
		else:
			if pad_x == 0:
				Physics.move_x(physics_data["horiz_spin_speed"]*(1.0 if Samus.facing == Enums.dir.RIGHT else -1.0))
			else:
				Physics.move_x(target_speed*pad_x)
		
#		if Input.is_action_pressed("pad_left"):
#			Physics.move_x(min(-physics_data["horiz_spin_speed"], -Physics.vel.x))
#		elif Input.is_action_pressed("pad_right"):
#			Physics.move_x(max(physics_data["horiz_spin_speed"], Physics.vel.x))
#		elif abs(Physics.vel.x) != physics_data["horiz_spin_speed"]:
#			var polarity = 1 if Samus.facing == Enums.dir.RIGHT else -1
#			if abs(Physics.vel.x) > physics_data["horiz_spin_speed"]:
#				Physics.move_x(max(physics_data["horiz_spin_speed"], abs(Physics.vel.x))*polarity, physics_data["horiz_spin_deceleration"])
#			else:
#				Physics.move_x(max(physics_data["horiz_spin_speed"], abs(Physics.vel.x))*polarity)
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
		Samus.Weapons.update_fire_pos()

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
	
	var spacejump_active: bool = Samus.is_upgrade_active(Enums.Upgrade.SPACEJUMP)
	if spinning and spacejump_active:
		Animator.SpriteContainer.current_profile = "spacejump"
	else:
		Animator.SpriteContainer.current_profile = null
	
	if not spinning:
		for sound in sounds_spin:
			sounds[sound].stop()
	else:
		if Samus.is_upgrade_active(Enums.Upgrade.SCREWATTACK):
			sounds["sndSpaceScrewAttack" if spacejump_active else "sndScrewAttack"].play()
		else:
			sounds["sndSpaceJump" if spacejump_active else "sndSpinJump"].play()
	
	grip_raycast_container.position.y = -14
#	grip_raycast_container.position.y = -1 if spinning else -14
