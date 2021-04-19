extends Node

var samus: Node2D
var animator: Node
var physics: Node

const id = "crouch"

# Called during Samus's readying period
func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	self.physics = samus.physics

# Called when Samus's state is changed to this one
func init(data: Dictionary):
	Global.create_hold_action("pad_right")
	Global.create_hold_action("pad_left")
	return self

# Called every frame while this state is active
func process(delta):
	
	var play_transition = false
	var original_facing = samus.facing
	
	if Input.is_action_just_pressed("morph_shortcut"):
		samus.states["morphball"].toggle_morph()
		return
	
	if Input.is_action_pressed("pad_left"):
		samus.facing = Global.dir.LEFT
		
		if original_facing == Global.dir.RIGHT:
			play_transition = true
		elif not animator.transitioning() and Global.is_action_held("pad_left", 0.1) and samus.time_since_last_state("morphball", 0.1):
			change_state("run")
			return
			
	elif Input.is_action_pressed("pad_right"):
		samus.facing = Global.dir.RIGHT
		
		if original_facing == Global.dir.LEFT:
			play_transition = true
		elif not animator.transitioning() and Global.is_action_held("pad_right", 0.1) and samus.time_since_last_state("morphball", 0.1):
			change_state("run")
			return
	
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
				samus.states["morphball"].toggle_morph()
				return
			
			samus.aiming = samus.aim.DOWN
		
	elif Input.is_action_just_pressed("pad_up") and not animator.transitioning():
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("pad_down") and not animator.transitioning():
		samus.states["morphball"].toggle_morph()
		return
	else:
		samus.aiming = samus.aim.FRONT
	
	var animation: String
	match samus.aiming:
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	if play_transition:
		animator.play("turn_" + animation, {"transition": true})
		Global.start_timer("transition_cooldown", 0.1, {})
	else:
		animator.play(animation, {"retain_frame": true})
	
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	
	Global.remove_hold_action("pad_right")
	Global.remove_hold_action("pad_left")
	
	samus.change_state(new_state_key, data)
	
func physics_process(delta: float):
	physics.decelerate_x(samus.states["run"].run_deceleration)
