extends KinematicBody2D

var rng = RandomNumberGenerator.new()
onready var Animator = $Animator
onready var Collision = $Collision
onready var Physics = $Physics
onready var Weapons = $Weapons
onready var HUD = $HUD
onready var PauseMenu = $PauseMenu
onready var camera = $SamusCamera

var facing = Enums.dir.LEFT
var armed: bool = false
enum aim {NONE, UP, DOWN, FRONT, SKY, FLOOR}
var aiming = aim.FRONT setget set_aiming
var aim_none_timer = Global.timer()

var self_damage = {}

var boosting: bool = false setget set_boosting
var shinespark_charged: bool = false
var fall_time: float = 0

var paused: bool = false

onready var states = {
	"jump": preload("res://scenes/Samus/states/state_jump.gd").new(self),
	"neutral": preload("res://scenes/Samus/states/state_neutral.gd").new(self),
	"run": preload("res://scenes/Samus/states/state_run.gd").new(self),
	"crouch": preload("res://scenes/Samus/states/state_crouch.gd").new(self),
	"morphball": preload("res://scenes/Samus/states/state_morphball.gd").new(self),
	"spiderball": preload("res://scenes/Samus/states/state_spiderball.gd").new(self),
	"shinespark": preload("res://scenes/Samus/states/state_shinespark.gd").new(self),
	"powergrip": preload("res://scenes/Samus/states/state_powergrip.gd").new(self),
	"visor": preload("res://scenes/Samus/states/state_visor.gd").new(self),
	}
var previous_state_id: String
onready var current_state: Node = states["neutral"]
var state_change_record = [["", 0]]

var energy: int
var etanks: int
var upgrades: Dictionary

func set_boosting(value: bool):
	boosting = value
	set_hurtbox_damage(states["shinespark"].damage_type, states["shinespark"].damage_amount if boosting else null)

func set_hurtbox_damage(type: int, amount):
	if amount != null:
		self_damage[type] = amount
	elif type in self_damage:
		self_damage.erase(type)

func shift_position(position: Vector2):
	self.position += position

func _ready():
	
	var data = Loader.Save.data["samus"]
	self.upgrades = data["upgrades"]
	
	etanks = upgrades[Enums.Upgrade.ETANK]["amount"]
	HUD.set_etanks(etanks)
	
	energy = data["energy"]
	if energy < 0:
		energy = etanks * 100 + 99
	HUD.set_energy(energy)
	
	Weapons.add_weapon(Enums.Upgrade.BEAM)
	for upgrade in upgrades:
		if upgrade in Weapons.all_weapons and upgrades[upgrade]["amount"] > 0:
			var weapon: SamusProjectile = Weapons.add_weapon(upgrade)
			if not weapon.unlimited_ammo:
				weapon.ammo = upgrades[upgrade]["ammo"]
			weapon.amount = upgrades[upgrade]["amount"]
	Weapons.update_weapon_icons()
	
	
	change_state("neutral")
	
	# DEBUG
	$Animator/TestSprites.queue_free()
	

func _process(delta):
	
	# DEBUG
	if Input.is_action_just_pressed("[DEBUG] increase energy"):
		energy += 1
		print("Increased energy to: " + str(energy))
		HUD.set_energy(energy)
	elif Input.is_action_just_pressed("[DEBUG] decrease energy"):
		energy -= 1
		print("Decreased energy to: " + str(energy))
		HUD.set_energy(energy)
	
	if paused:
		return
	
	current_state.process(delta)
	if is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		states["shinespark"].speedbooster_process(delta)
	
var prev = ""
func _physics_process(delta):
	
	vOverlay.SET("State", current_state.id)
	vOverlay.SET("Pad", Shortcut.get_pad_vector("pressed"))
	vOverlay.SET("Aiming analog", Shortcut.get_joystick_vector("secondary_pad"))
	vOverlay.SET("Visor analog", Shortcut.get_joystick_vector("analog_visor"))
	
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
	
	if new_state_key == "crouch" and is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		if states["shinespark"].ShinesparkStoreWindow.time_left > 0 or boosting:
			states["shinespark"].charge_shinespark()
	
	previous_state_id = current_state.id
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key]
	states[new_state_key].init_state(data)

func is_upgrade_active(upgrade_key: int):
	var upgrade = Loader.Save.get_data_key(["samus", "upgrades", upgrade_key])
	return upgrade["amount"] > 0 and upgrade["active"]
		

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

func auto_offset_camera(amount: float = 100.0, time: float = 0.5):
	var offset: Vector2
	match aiming:
		aim.SKY: offset = Vector2(0, -1)
		aim.UP: offset = Vector2(Global.dir2vector(facing).x, -1)
		aim.FRONT: offset = Vector2(Global.dir2vector(facing).x, 0)
		aim.DOWN: offset = Vector2(Global.dir2vector(facing).x, 1)
	offset *= amount
	
	$SamusCamera/OffsetTween.interpolate_property($SamusCamera, "offset", $SamusCamera.offset, offset, time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$SamusCamera/OffsetTween.start()
