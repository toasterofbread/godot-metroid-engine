extends SamusState

var Animator: Node
var Physics: Node
var animations = {}

var CeilingRaycast: RayCast2D

# Called during Samus's readying period
func _init(_Samus: Node2D, _id: String).(_Samus, _id):
	CeilingRaycast = Animator.raycasts.get_node("crouch/Ceiling")

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary):
	CeilingRaycast.enabled = true

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Shortcut.remove_input_hold_monitor("pad_right", id)
	Shortcut.remove_input_hold_monitor("pad_left", id)
	
	CeilingRaycast.enabled = false
	
	.change_state(new_state_key, data)

# Called every frame while this state is active
func process(_delta: float):
	
	var play_transition = false
	var original_facing = Samus.facing
	
	if Settings.get("controls/aiming_style") == 0:
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
		
		if Input.is_action_pressed("pad_left"):
			Samus.facing = Enums.dir.LEFT
			Shortcut.remove_input_hold_monitor("pad_right", id)
			
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
			elif not Animator.transitioning() and Shortcut.get_input_hold_value("pad_left") >= 0.1 and Samus.time_since_last_state("morphball", 0.1):
				if not CeilingRaycast.is_colliding():
					change_state("run", {"boost": false})
					return
			elif not Animator.transitioning():
				Shortcut.add_input_hold_monitor("pad_left", id)
				
		elif Input.is_action_pressed("pad_right"):
			Samus.facing = Enums.dir.RIGHT
			Shortcut.remove_input_hold_monitor("pad_left", id)
			
			if original_facing == Enums.dir.LEFT:
				play_transition = true
			elif not Animator.transitioning() and Shortcut.get_input_hold_value("pad_right") >= 0.1 and Samus.time_since_last_state("morphball", 0.1):
				if not CeilingRaycast.is_colliding():
					change_state("run", {"boost": false})
					return
			elif not Animator.transitioning():
				Shortcut.add_input_hold_monitor("pad_right", id)
	
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
	elif not Animator.transitioning(false, true):
		animations[animation].play(true)

func physics_process(delta: float):
	Physics.move_x(0, Physics.data["run"]["deceleration"]*delta)
