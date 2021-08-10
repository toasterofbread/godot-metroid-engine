extends SamusState

var Animator: Node
var Physics: Node
var animations = {}

var CeilingRaycast: RayCast2D

const crouch_animation_speed: float = 1.5

# Called during Samus's readying period
func _init(_Samus: Node2D, _id: String).(_Samus, _id):
	CeilingRaycast = Animator.raycasts.get_node("crouch/Ceiling")

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary, previous_state_id: String):
	CeilingRaycast.enabled = true
	
	if previous_state_id == "neutral":
		var animation: String
		match Samus.aiming:
			Samus.aim.UP: animation = "aim_up"
			Samus.aim.DOWN: animation = "aim_down"
			_: animation = "aim_front"
		
		animations["crouch_" + animation].play(false, crouch_animation_speed)

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	InputManager.remove_input_hold_monitor("pad_right", id)
	InputManager.remove_input_hold_monitor("pad_left", id)
	
	if new_state_key == "neutral":
		var animation: String
		match Samus.aiming:
			Samus.aim.UP: animation = "aim_up"
			Samus.aim.DOWN: animation = "aim_down"
			_: animation = "aim_front"
		
		animations["uncrouch_" + animation].play(false, crouch_animation_speed)
	
	CeilingRaycast.enabled = false
	.change_state(new_state_key, data)

# Called every frame while this state is active
func process(_delta: float):
	
	var play_transition = false
	var original_facing = Samus.facing
	
	if Settings.get("control_options/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Samus.Weapons.cycle_visor() and not CeilingRaycast.is_colliding():
		change_state("visor")
		return
	
	if not Animator.transitioning():
		if Input.is_action_just_pressed("morph_shortcut") and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
			change_state("morphball", {"options": ["animate"]})
			return
		if Input.is_action_just_pressed("fire_weapon") and Samus.Weapons.current_visor == null:
			Samus.Weapons.fire()
		if Input.is_action_just_pressed("airspark") and Samus.states["airspark"].can_airspark():
			change_state("airspark")
			return
		elif Input.is_action_just_pressed("jump"):
			change_state("jump", {"options": ["jump"]})
			return
		
		var pad_x: int = InputManager.get_pad_x("pressed")
		if pad_x == -1:
			Samus.facing = Enums.dir.LEFT
			InputManager.remove_input_hold_monitor("pad_right", id)
			
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
			elif not Animator.transitioning() and InputManager.get_input_hold_value("pad_left") >= 0.1 and Samus.time_since_last_state("morphball", 0.1):
				if not CeilingRaycast.is_colliding():
					change_state("run", {"boost": false})
					return
			elif not Animator.transitioning():
				InputManager.add_input_hold_monitor("pad_left", id)
				
		elif pad_x == 1:
			Samus.facing = Enums.dir.RIGHT
			InputManager.remove_input_hold_monitor("pad_left", id)
			
			if original_facing == Enums.dir.LEFT:
				play_transition = true
			elif not Animator.transitioning() and InputManager.get_input_hold_value("pad_right") >= 0.1 and Samus.time_since_last_state("morphball", 0.1):
				if not CeilingRaycast.is_colliding():
					change_state("run", {"boost": false})
					return
			elif not Animator.transitioning():
				InputManager.add_input_hold_monitor("pad_right", id)
	
	if Input.is_action_pressed("aim_weapon"):
		
		if Samus.aiming == Samus.aim.FRONT:
			Samus.aiming = Samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			
			if Samus.aiming == Samus.aim.UP and not Animator.transitioning() and not CeilingRaycast.is_colliding():
				change_state("neutral")
				return
			
			Samus.aiming = Samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			
			if Samus.aiming == Samus.aim.DOWN and not Animator.transitioning() and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
				change_state("morphball", {"options": ["animate"]})
				return
			
			Samus.aiming = Samus.aim.DOWN
		
	elif Input.is_action_just_pressed("pad_up") and not Animator.transitioning():
		if not CeilingRaycast.is_colliding():
			change_state("neutral")
			return
	elif Input.is_action_just_pressed("pad_down") and not Animator.transitioning() and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"]})
		return
	else:
		Samus.aiming = Samus.aim.FRONT
	
	var animation: String
	match Samus.aiming:
		Samus.aim.UP: animation = "aim_up"
		Samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	if play_transition:
		animations["turn_" + animation].play()
		animations["legs_turn"].play()
	elif not Animator.transitioning(false, true):
		animations[animation].play(true)
		animations["legs"].play(true)

func physics_process(delta: float):
	Physics.move_x(0, Physics.data["run"]["deceleration"]*delta)
