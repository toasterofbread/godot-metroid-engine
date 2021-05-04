extends Node

var samus: Node2D
var animator: Node
var physics: Node

const id = "crouch"

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	
	animations = animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary):
	return self

# Called every frame while this state is active
func process(_delta):
	
	var play_transition = false
	var original_facing = samus.facing
	
	if Config.get("zm_controls"):
		animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if not animator.transitioning():
		if Input.is_action_just_pressed("morph_shortcut"):
			change_state("morphball", {"options": ["animate"]})
			return
		if Input.is_action_just_pressed("fire_weapon"):
			samus.weapons.fire()
		if Input.is_action_just_pressed("jump"):
			change_state("jump", {"options": ["jump"]})
			return
		
		if Input.is_action_pressed("pad_left"):
			samus.facing = Enums.dir.LEFT
			Global.remove_hold_action("pad_right")
			
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
			elif not animator.transitioning() and Global.is_action_held("pad_left", 0.1) and samus.time_since_last_state("morphball", 0.1):
				change_state("run")
				return
			elif not animator.transitioning():
				Global.create_hold_action("pad_left")
				
		elif Input.is_action_pressed("pad_right"):
			samus.facing = Enums.dir.RIGHT
			Global.remove_hold_action("pad_left")
			
			if original_facing == Enums.dir.LEFT:
				play_transition = true
			elif not animator.transitioning() and Global.is_action_held("pad_right", 0.1) and samus.time_since_last_state("morphball", 0.1):
				change_state("run")
				return
			elif not animator.transitioning():
				Global.create_hold_action("pad_right")
	
	if Input.is_action_pressed("aim_weapon"):
		
		if samus.aiming == samus.aim.FRONT:
			samus.aiming = samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			
			if samus.aiming == samus.aim.UP and not animator.transitioning():
				change_state("neutral")
				return
			
			samus.aiming = samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			
			if samus.aiming == samus.aim.DOWN and not animator.transitioning():
				change_state("morphball", {"options": ["animate"]})
				return
			
			samus.aiming = samus.aim.DOWN
		
	elif Input.is_action_just_pressed("pad_up") and not animator.transitioning():
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("pad_down") and not animator.transitioning():
		change_state("morphball", {"options": ["animate"]})
		return
	else:
		samus.aiming = samus.aim.FRONT
	
	var animation: String
	match samus.aiming:
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	if play_transition:
		animations["turn_" + animation].play()
	elif not animator.transitioning(false, true):
		animations[animation].play(true)
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	
	Global.remove_hold_action("pad_right")
	Global.remove_hold_action("pad_left")
	
	samus.change_state(new_state_key, data)
	
func physics_process(_delta: float):
	physics.decelerate_x(samus.states["run"].run_deceleration)
