extends Node

var Samus: Node2D
var Animator: Node
var Physics: Node

const id = "facefront"

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	animations = Animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary):
	Samus.aiming = Samus.aim.NONE
	animations["turn"].play()

func paused_process(delta):
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(false)
	if not Animator.transitioning(false, true):
		animations["idle"].play()

# Called every frame while this state is active
func process(_delta):
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(false)
	
	if Input.is_action_just_pressed("pad_left"):
		Samus.facing = Enums.dir.LEFT
		animations["turn"].play()
		change_state("neutral")
		return
	elif Input.is_action_just_pressed("pad_right"):
		Samus.facing = Enums.dir.RIGHT
		animations["turn"].play()
		change_state("neutral")
		return
	
	if not Animator.transitioning(false, true):
		animations["idle"].play()
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.change_state(new_state_key, data)
	
func physics_process(_delta: float):
	Physics.move_x(0, Physics.data["run"]["deceleration"])
