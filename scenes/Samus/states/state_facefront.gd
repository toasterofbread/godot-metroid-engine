extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary

var face_back: = false setget set_face_back
var prefix: = "front_"

func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	pass

# Called when Samus's state is changed to this one
func init_state(data: Dictionary = {}):
	Samus.aiming = Samus.aim.NONE
	if "face_back" in data:
		set_face_back(data["face_back"])
	animations[prefix + "turn"].play()

func paused_process(delta):
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(false)
	if not Animator.transitioning(false, true):
		animations[prefix + "idle"].play()

func set_face_back(value: bool):
	face_back = value
	prefix = "back_" if face_back else "front_"

# Called every frame while this state is active
func process(_delta: float):
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(false)
	
	if Input.is_action_pressed("pad_left"):
		Samus.facing = Enums.dir.LEFT
		animations[prefix + "turn"].play()
		change_state("neutral")
		return
	elif Input.is_action_pressed("pad_right"):
		Samus.facing = Enums.dir.RIGHT
		animations[prefix + "turn"].play()
		change_state("neutral")
		return
	
	if not Animator.transitioning(false, true):
		animations[prefix + "idle"].play()

func physics_process(_delta: float):
	Physics.move_x(0, Physics.data["run"]["deceleration"])
