extends KinematicBody2D

var rng = RandomNumberGenerator.new()
onready var Animator = $Animator
onready var Collision = $Collision
onready var Physics = $Physics
onready var Weapons = $Weapons
onready var HUD = $HUD
onready var camera = $SamusCamera

var facing = Enums.dir.LEFT
var armed: bool = false

enum aim {NONE, UP, DOWN, FRONT, SKY, FLOOR}
var aiming = aim.FRONT setget set_aiming
var aim_none_timer = Global.timer()

signal boost_changed
var boosting: bool = false setget set_boosting
var shinespark_charged: bool = false
var shinespark_affected_collision: bool = false

var fall_time: float = 0

var energy: int = 105
var etanks: int = 15

var paused: bool = false

onready var states = {
	"jump": preload("res://scenes/Samus/states/state_jump.gd").new(self),
	"neutral": preload("res://scenes/Samus/states/state_neutral.gd").new(self),
	"run": preload("res://scenes/Samus/states/state_run.gd").new(self),
	"crouch": preload("res://scenes/Samus/states/state_crouch.gd").new(self),
	"morphball": preload("res://scenes/Samus/states/state_morphball.gd").new(self),
	"shinespark": preload("res://scenes/Samus/states/state_shinespark.gd").new(self),
	"powergrip": preload("res://scenes/Samus/states/state_powergrip.gd").new(self)
}
var previous_state_id: String
onready var current_state: Node = states["neutral"]
var state_change_record = [["", 0]]

func set_boosting(value: bool):
	boosting = value
	emit_signal("boost_changed", value)

# Called when the node enters the scene tree for the first time.
func _ready():
	change_state("neutral")
	$Animator/TestSprites.queue_free()
	
	HUD.set_etanks(etanks)
	HUD.set_energy(energy)
	
	Weapons.add_weapon("missile")
	Weapons.add_weapon("supermissile")
	Weapons.add_weapon("beam")
	Weapons.add_weapon("bomb")

func _process(delta):
	
	if paused:
		return
	
	current_state.process(delta)
	if is_upgrade_active("speedbooster"):
		states["shinespark"].speedbooster_process(delta)
	
var prev = ""
func _physics_process(delta):
	
	if paused:
		return
	
	current_state.physics_process(delta)
	
	if not is_on_floor() and Physics.vel.y > 0:
		fall_time += delta
	else:
		fall_time = 0

func change_state(new_state_key: String, data: Dictionary = {}):
	
	if paused:
		return
	
	if new_state_key == "crouch" and is_upgrade_active("speedbooster"):
		if states["shinespark"].ShinesparkStoreWindow.time_left > 0 or boosting:
			states["shinespark"].charge_shinespark()
	
	previous_state_id = current_state.id
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key]
	states[new_state_key].init_state(data)

func is_upgrade_active(_upgrade_key: String):
	return true

func set_aiming(value: int):
	if value in [aim.UP, aim.DOWN, aim.SKY, aim.FLOOR]: 
		aim_none_timer.start()
	aiming = value


# Returns true if the current state has been active for more than the specified time
# Or if the previous state doesn't match the state key
func time_since_last_state(state_key: String, seconds: float):
	return state_change_record[1][0] != state_key or Global.time() - state_change_record[0][1] >= seconds*1000

func _death():
	print("F")

func damage(amount: int):
	self.energy = max(0, energy - amount)
	self.HUD.set_energy(energy)
	
	if energy == 0:
		_death()

func shift_position(by_amount: Vector2):
	self.global_position += by_amount
