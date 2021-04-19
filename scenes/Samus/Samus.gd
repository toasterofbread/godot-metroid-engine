extends Node2D

var rng = RandomNumberGenerator.new()
onready var animator = $Animator
onready var soundmanager = $SoundManager
onready var physics = $PhysicsManager

var facing = Global.dir.RIGHT

enum aim {NONE, UP, DOWN, FRONT, SKY}
var aiming = aim.FRONT

onready var states = {
	"neutral": preload("res://scenes/Samus/states/state_neutral.gd").new(self),
	"run": preload("res://scenes/Samus/states/state_run.gd").new(self),
	"crouch": preload("res://scenes/Samus/states/state_crouch.gd").new(self),
	"morphball": preload("res://scenes/Samus/states/state_morphball.gd").new(self),
	"jump": preload("res://scenes/Samus/states/state_jump.gd").new(self)
}
onready var current_state: Node = states["neutral"]
var state_change_record = [["", 0]]

# Called when the node enters the scene tree for the first time.
func _ready():
	change_state("neutral")
	$TestSprite.queue_free()

func _process(delta):
	current_state.process(delta)

func _physics_process(delta):
	current_state.physics_process(delta)

func change_state(new_state_key: String, data: Dictionary = {}):
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key].init(data)

func is_upgrade_active(upgrade_key: String):
	return true

# Returns true if the current state has been active for more than the specified time
# Or if the previous state doesn't match the state key
func time_since_last_state(state_key: String, seconds: float):
	print(state_change_record)
	return state_change_record[1][0] != state_key or Global.time() - state_change_record[0][1] >= seconds*1000
