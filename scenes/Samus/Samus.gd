extends KinematicBody2D

var rng = RandomNumberGenerator.new()
onready var animator = $Animator
onready var soundmanager = $SoundManager
onready var physics = $PhysicsManager
onready var weapons = $WeaponManager
onready var hud = preload("res://scenes/Samus/HUD/HUD.tscn").instance()

var processes = []
var physics_processes = []

var facing = Global.dir.LEFT
enum aim {NONE, UP, DOWN, FRONT, SKY, FLOOR}
var aiming = aim.FRONT

var energy: int = 599
var etanks: int = 15

onready var states = {
	"jump": preload("res://scenes/Samus/states/state_jump.gd").new(self),
	"neutral": preload("res://scenes/Samus/states/state_neutral.gd").new(self),
	"run": preload("res://scenes/Samus/states/state_run.gd").new(self),
	"crouch": preload("res://scenes/Samus/states/state_crouch.gd").new(self),
	"morphball": preload("res://scenes/Samus/states/state_morphball.gd").new(self),
}
onready var current_state: Node = states["neutral"]
var state_change_record = [["", 0]]

# Called when the node enters the scene tree for the first time.
func _ready():
	change_state("neutral")
	$TestSprite.queue_free()
	
	Global.add_child(hud)
	hud.set_etanks(etanks)
	hud.set_energy(energy)
	
	weapons.add_weapon("missile")

func load_data(slot: int):
	weapons.weapons = [preload("res://scenes/Samus/weapons/Beam.tscn")]

func _process(delta):
	current_state.process(delta)
	for process in processes:
		process.process()

func _physics_process(delta):
	current_state.physics_process(delta)
	for process in physics_processes:
		process.physics_process()

func change_state(new_state_key: String, data: Dictionary = {}):
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key].init(data)

func is_upgrade_active(upgrade_key: String):
	return true

# Returns true if the current state has been active for more than the specified time
# Or if the previous state doesn't match the state key
func time_since_last_state(state_key: String, seconds: float):
	return state_change_record[1][0] != state_key or Global.time() - state_change_record[0][1] >= seconds*1000
