extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var physics_data: Dictionary

var speedboost_charge_time: float = 2.0
var SpeedboostTimer: Timer

var run_transition = null

# PHYSICS
#const run_acceleration = 15*60
#const run_deceleration = 50*60
#const run_speed = 170

#const boost_acceleration = 15*60
#const boost_deceleration = 50
#const max_boost_speed = 500

func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	SpeedboostTimer = Global.get_timer([Samus, "set", ["boosting", true]])

# Called every frame while this state is active
func process(_delta: float):
	
	var play_transition = false
	
	if Input.is_action_just_pressed("morph_shortcut") and not Animator.transitioning() and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"]})
		return
	
	if Settings.get("controls/aiming_style") == 0:
		if Input.is_action_pressed("arm_weapon"):
			Animator.set_armed(true)
		else:
			Animator.set_armed(false)
	
	if Samus.Weapons.cycle_visor():
		change_state("visor")
	
	if Samus.is_on_wall():
		change_state("neutral")
		return
	
	if Input.is_action_just_pressed("fire_weapon"):
		Samus.Weapons.fire()
		Samus.aim_none_timer.start()
	
	if Input.is_action_just_pressed("jump"):
		change_state("jump", {"options": ["jump", "spin"]})
		return
	elif Input.is_action_just_pressed("airspark") and Samus.states["airspark"].can_airspark():
		change_state("airspark")
		return
	elif not Samus.is_on_floor():
		change_state("jump", {"options": ["fall"]})
		return
	
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
		if Samus.aim_none_timer.time_left == 0 and Samus.Weapons.charge_time_current == 0:
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
			run_transition = Samus.aiming
			change_state("neutral")
			yield(Global.wait(0.2), "completed")
			run_transition = null
			return
	
	if play_transition:
		animations["turn_legs"].play()
		animations["turn_" + animation].play()
	elif not Animator.transitioning(false, true):
		animations[animation].play(true, min(1.5, abs(Physics.vel.x) / physics_data["speed"]))
	
# Called when Samus' state is changed to this one
func init_state(data: Dictionary):
	Samus.boosting = data["boost"]
	if Samus.is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		SpeedboostTimer.start(speedboost_charge_time)

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	SpeedboostTimer.stop()
	Samus.aim_none_timer.stop()
	if new_state_key == "jump":
		Samus.boosting = "spin" in data["options"] and Samus.boosting
	elif new_state_key != "morphball":
		Samus.boosting = false
	.change_state(new_state_key, data)

func physics_process(delta: float):
	
	var pad_x = Shortcut.get_pad_vector("pressed").x
	if Samus.boosting and pad_x != Global.dir2vector(Samus.facing).x:
		Samus.boosting = false
	
	if Physics.vel.x != 0 and sign(Physics.vel.x) != pad_x:
		Physics.move_x(0, physics_data["deceleration"]*delta)
	elif Samus.boosting:
		Physics.move_x(physics_data["speedboost_speed"]*pad_x, physics_data["speedboost_acceleration"]*delta)
	else:
		Physics.move_x(physics_data["speed"]*pad_x, physics_data["acceleration"]*delta)
	
	if abs(Physics.vel.x) >= physics_data["speed"]:
		if SpeedboostTimer.is_stopped():
			SpeedboostTimer.start(speedboost_charge_time)
	else:
		SpeedboostTimer.stop()
