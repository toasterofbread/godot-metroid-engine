extends KinematicBody2D

var rng = RandomNumberGenerator.new()
onready var animator = $Animator
onready var sound = $Scripts/SoundManager
onready var physics = $Scripts/PhysicsManager
onready var weapons = $Scripts/WeaponManager
onready var hud = preload("res://scenes/Samus/HUD/HUD.tscn").instance()

var facing = Enums.dir.LEFT
enum aim {NONE, UP, DOWN, FRONT, SKY, FLOOR}
var aiming = aim.FRONT

var armed: bool = false

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
	$Animator/TestSprites.queue_free()
	
	self.add_child(hud)
	hud.set_etanks(etanks)
	hud.set_energy(energy)
	
	weapons.add_weapon("missile")
	weapons.add_weapon("supermissile")
	weapons.add_weapon("beam")

func load_data(slot: int):
	weapons.weapons = [preload("res://scenes/Samus/weapons/Beam.tscn")]

func _process(delta):
	current_state.process(delta)

func _physics_process(delta):
#	print(animator.current)
#	print(current_state.id)
#	print(animator.transitioning(false, true))
	current_state.physics_process(delta)

func change_state(new_state_key: String, data: Dictionary = {}):
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key].init_state(data)

func is_upgrade_active(upgrade_key: String):
	return true

# Returns true if the current state has been active for more than the specified time
# Or if the previous state doesn't match the state key
func time_since_last_state(state_key: String, seconds: float):
	return state_change_record[1][0] != state_key or Global.time() - state_change_record[0][1] >= seconds*1000
