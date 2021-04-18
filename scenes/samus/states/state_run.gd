extends Node

var samus: Node2D
var animator: Node

const id = "run"

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass

func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator

# Called every frame while this state is active
func process(delta):
	
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
	
	var turn = false
	if Input.is_action_pressed("pad_left"):
		if samus.facing == samus.face.RIGHT:
			turn = true
		samus.facing = samus.face.LEFT
	elif Input.is_action_pressed("pad_right"):
		if samus.facing == samus.face.LEFT:
			turn = true
		samus.facing = samus.face.RIGHT
	else:
		Global.clear_timer("run_transition")
		Global.start_timer("run_transition", 0.2, {"aiming": samus.aiming})
		change_state("neutral", delta)
		return
	
	if turn:
		animator.play("turn_" + animation, {"transition": true})
	else:
		animator.play(animation, {"retain_frame": true})
	
# Called when Samus' state is changed to this one
func init(previous_state: Node2D):
	return self

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, process_delta=null):
	samus.change_state(new_state_key, process_delta)
	
	match new_state_key:
		"neutral": pass

