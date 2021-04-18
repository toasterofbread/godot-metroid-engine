extends Node2D

var rng = RandomNumberGenerator.new()
onready var animator = $Animator
onready var soundmanager = $SoundManager

var velocity = Vector2.ZERO

enum face {NONE, LEFT, RIGHT}
var facing = face.RIGHT

enum aim {NONE, UP, DOWN, FRONT, SKY}
var aiming = aim.FRONT

onready var states = {
	"neutral": preload("res://scenes/samus/states/state_neutral.gd").new(self),
	"run": preload("res://scenes/samus/states/state_run.gd").new(self)
}

onready var current_state: Node = states["neutral"]

# Called when the node enters the scene tree for the first time.
func _ready():
	current_state.init(self)
	$TestSprite.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_state.process(delta)
	print(Global.timers)

func change_state(new_state_key: String, process_delta = null):
	current_state = states[new_state_key].init(self)
	if process_delta:
		current_state.process(process_delta)
