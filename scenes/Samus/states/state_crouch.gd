extends Node

var Samus: Node2D
var Animator: Node
var Physics: Node

var CeilingRaycast: RayCast2D

const id = "crouch"

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.CeilingRaycast = Animator.raycasts.get_node("crouch/Ceiling")
	
	animations = Animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary):
	CeilingRaycast.enabled = true
	return self

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var original_facing = Samus.facing
	
	if Settings.get("controls/aiming_style"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if not Animator.transitioning():
		if Input.is_action_just_pressed("morph_shortcut"):
			change_state("morphball", {"options": ["animate"]})
			return
		if Input.is_action_just_pressed("fire_weapon"):
			Samus.Weapons.fire()
		if Input.is_action_just_pressed("jump"):
			change_state("jump", {"options": ["jump"]})
			return
		
		if Input.is_action_pressed("pad_left"):
			Samus.facing = Enums.dir.LEFT
			Global.remove_hold_action("pad_right")
			
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
			elif not Animator.transitioning() and Global.is_action_held("pad_left", 0.1) and Samus.time_since_last_state("morphball", 0.1):
				if not CeilingRaycast.is_colliding():
					change_state("run", {"boost": false})
					return
			elif not Animator.transitioning():
				Global.create_hold_action("pad_left")
				
		elif Input.is_action_pressed("pad_right"):
			Samus.facing = Enums.dir.RIGHT
			Global.remove_hold_action("pad_left")
			
			if original_facing == Enums.dir.LEFT:
				play_transition = true
			elif not Animator.transitioning() and Global.is_action_held("pad_right", 0.1) and Samus.time_since_last_state("morphball", 0.1):
				if not CeilingRaycast.is_colliding():
					change_state("run", {"boost": false})
					return
			elif not Animator.transitioning():
				Global.create_hold_action("pad_right")
	
	if Input.is_action_pressed("aim_weapon"):
		
		if Samus.aiming == Samus.aim.FRONT:
			Samus.aiming = Samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			
			if Samus.aiming == Samus.aim.UP and not Animator.transitioning() and not CeilingRaycast.is_colliding():
				change_state("neutral")
				return
			
			Samus.aiming = Samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			
			if Samus.aiming == Samus.aim.DOWN and not Animator.transitioning():
				change_state("morphball", {"options": ["animate"]})
				return
			
			Samus.aiming = Samus.aim.DOWN
		
	elif Input.is_action_just_pressed("pad_up") and not Animator.transitioning():
		if not CeilingRaycast.is_colliding():
			change_state("neutral")
			return
	elif Input.is_action_just_pressed("pad_down") and not Animator.transitioning():
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
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	
	Global.remove_hold_action("pad_right")
	Global.remove_hold_action("pad_left")
	CeilingRaycast.enabled = false
	
	Samus.change_state(new_state_key, data)
	
func physics_process(_delta: float):
	Physics.decelerate_x(Samus.states["run"].run_deceleration)
