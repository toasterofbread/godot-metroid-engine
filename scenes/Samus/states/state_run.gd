extends Node

var samus: Node2D
var animator: Node
var physics: Node

const id = "run"

var animations: Dictionary = {}

# PHYSICS
const run_acceleration = 1500
const run_deceleration = 15000
const max_run_speed = 175

func _init(_samus: Node2D):
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	
	animations = {
		"aim_down": animator.Animation.new(animator, "aim_down", self.id),
		"aim_front": animator.Animation.new(animator, "aim_front", self.id),
		"aim_none": animator.Animation.new(animator, "aim_none", self.id),
		"aim_up": animator.Animation.new(animator, "aim_up", self.id),
		"turn_aim_down": animator.Animation.new(animator, "turn_aim_down", self.id, {"transition": true}),
		"turn_aim_front": animator.Animation.new(animator, "turn_aim_front", self.id, {"transition": true}),
		"turn_aim_sky": animator.Animation.new(animator, "turn_aim_sky", self.id, {"transition": true}),
		"turn_aim_up": animator.Animation.new(animator, "turn_aim_up", self.id, {"transition": true}),
	}

# Called every frame while this state is active
func process(_delta):
	
	if Input.is_action_just_pressed("morph_shortcut") and not animator.transitioning():
		samus.states["morphball"].toggle_morph()
		return
	
	if Global.config["zm_controls"]:
		animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Input.is_action_pressed("aim_weapon"):
		
		if samus.aiming == samus.aim.FRONT:
			samus.aiming = samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			samus.aiming = samus.aim.DOWN
	elif Input.is_action_pressed("pad_up"):
		samus.aiming = samus.aim.UP
	elif Input.is_action_pressed("pad_down"):
		samus.aiming = samus.aim.DOWN
	else:
		samus.aiming = samus.aim.FRONT
	
	var animation: String
	match samus.aiming:
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		samus.aim.FRONT: animation = "aim_front"
		_: animation = "aim_none"
	
	var play_transition = false
	if not animator.transitioning():
		if Input.is_action_pressed("pad_left"):
			if samus.facing == Global.dir.RIGHT:
				play_transition = true
			samus.facing = Global.dir.LEFT
		elif Input.is_action_pressed("pad_right"):
			if samus.facing == Global.dir.LEFT:
				play_transition = true
			samus.facing = Global.dir.RIGHT
		else:
			Global.start_timer("run_transition", 0.2, {"aiming": samus.aiming})
			change_state("neutral")
			return
	
	if play_transition:
		animations["turn_" + animation].play(false)
	else:
		animations[animation].play(true)
	
# Called when Samus' state is changed to this one
func init(_data: Dictionary):
	return self

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	samus.change_state(new_state_key, data)
	
	match new_state_key:
		"neutral": pass

func physics_process(_delta: float):
	if Input.is_action_pressed("pad_left") and samus.facing == Global.dir.LEFT and not animator.transitioning():
		physics.accelerate_x(run_acceleration, max_run_speed, Global.dir.LEFT)
	elif Input.is_action_pressed("pad_right") and samus.facing == Global.dir.RIGHT and not animator.transitioning():
		physics.accelerate_x(run_acceleration, max_run_speed, Global.dir.RIGHT)


