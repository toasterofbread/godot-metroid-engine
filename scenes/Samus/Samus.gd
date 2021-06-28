extends KinematicBody2D

onready var Animator = $Animator
onready var Collision = $Collision
onready var Physics = $Physics
onready var Weapons = $Weapons
onready var HUD = $HUD
onready var PauseMenu = $PauseMenu
onready var camera: ExCamera2D = $ExCamera2D

var facing = Enums.dir.LEFT
var armed: bool = false
enum aim {NONE, UP, DOWN, FRONT, SKY, FLOOR}
var aiming = aim.FRONT setget set_aiming
var aim_none_timer = Global.timer()

var self_damage = {}

var boosting: bool = false setget set_boosting
var shinespark_charged: bool = false

var fall_time: float = 0
var current_camerachunk
var camerachunk_set_while_paused: = false

const collision_data_json_path = "res://scenes/Samus/animations/collision_data.json"
onready var collision_data = Global.load_json(collision_data_json_path)

var current_fluid: int

onready var states = {
	"jump": preload("res://scenes/Samus/states/state_jump.gd").new(self),
	"neutral": preload("res://scenes/Samus/states/state_neutral.gd").new(self),
	"run": preload("res://scenes/Samus/states/state_run.gd").new(self),
	"crouch": preload("res://scenes/Samus/states/state_crouch.gd").new(self),
	"morphball": preload("res://scenes/Samus/states/state_morphball.gd").new(self),
	"spiderball": preload("res://scenes/Samus/states/state_spiderball.gd").new(self),
	"shinespark": preload("res://scenes/Samus/states/state_shinespark.gd").new(self),
	"powergrip": preload("res://scenes/Samus/states/state_powergrip.gd").new(self),
	"visor": $Weapons/SamusVisors,
	"grapple": preload("res://scenes/Samus/states/state_grapple.gd").new(self),
	"facefront": preload("res://scenes/Samus/states/state_facefront.gd").new(self)
	}
var previous_state_id: String
onready var current_state: Node = states["neutral"]
var state_change_record = [["", 0]]

var energy: int
var etanks: int
var upgrades: Dictionary

var paused = null

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
	z_index = Enums.Layers.SAMUS
	
	var data = Loader.Save.data["samus"]
	upgrades = data["upgrades"]
	
	etanks = upgrades[Enums.Upgrade.ETANK]["amount"]
	HUD.set_etanks(etanks)
	
	energy = data["energy"]
	if energy < 0:
		energy = etanks * 100 + 99
	HUD.set_energy(energy)
	
	for upgrade in upgrades:
		if upgrade in Weapons.all_weapons:
			var weapon: SamusWeapon = Weapons.all_weapons[upgrade]
			if "ammo" in upgrades[upgrade]:
				weapon.ammo = upgrades[upgrade]["ammo"]
			weapon.amount = upgrades[upgrade]["amount"]
	
	change_state("neutral")
	
	Loader.Save.connect("value_set", self, "save_value_set")
	
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
	
	if get_tree().paused and paused == null or paused:
		if current_state.has_method("paused_process") and not get_tree().paused:
			current_state.paused_process(delta)
		return
	
	current_state.process(delta)
	if is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		states["shinespark"].process_speedboooster(delta)
#	if is_upgrade_active(Enums.Upgrade.CHARGEBEAM):
#		process_chargebeam(delta)

var prev = ""
func _physics_process(delta):
	
	vOverlay.SET("State", current_state.id)
	
	if get_tree().paused and paused == null or paused:
		return
	
	current_state.physics_process(delta)
	
	if not is_on_floor() and Physics.vel.y > 0:
		fall_time += delta
	else:
		fall_time = 0

func change_state(new_state_key: String, data: Dictionary = {}):
	
	if get_tree().paused and paused == null or paused:
		return
	
	if new_state_key in ["crouch", "morphball"] and is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		if states["shinespark"].ShinesparkStoreWindow.time_left > 0 or boosting:
			states["shinespark"].charge_shinespark()
	
	previous_state_id = current_state.id
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key]
	states[new_state_key].init_state(data)

var upgrade_cache: = {}
func is_upgrade_active(upgrade_key: int):
	
	if not upgrade_key in upgrade_cache:
		var upgrade = Loader.Save.get_data_key(["samus", "upgrades", upgrade_key])
		upgrade_cache[upgrade_key] = upgrade["amount"] > 0 and upgrade["active"]
	
	return upgrade_cache[upgrade_key]

func set_aiming(value: int):
	if value in [aim.UP, aim.DOWN, aim.SKY, aim.FLOOR]: 
		aim_none_timer.start()
	aiming = value

func save_value_set(path: Array, _value):
	if len(path) < 4 or path[0] != "samus" or path[1] != "upgrades":
		return
	upgrade_cache = {}

# Returns true if the current state has been active for more than the specified time
# Or if the previous state doesn't match the state key
func time_since_last_state(state_key: String, seconds: float):
	return state_change_record[1][0] != state_key or Global.time() - state_change_record[0][1] >= seconds*1000

func death():
	print("F")

func damage(type: int, amount: int):
	self.energy = max(0, energy - amount)
	self.HUD.set_energy(energy)
	
	if energy == 0:
		death()

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

func get_current_limits() -> Dictionary:
	var camera_extents = (camera.get_viewport_rect().size * camera.zoom)/2
	var camera_position = camera.get_camera_center()
	return {
		"limit_left": camera_position.x - camera_extents.x,
		"limit_right": camera_position.x + camera_extents.x,
		"limit_top": camera_position.y - camera_extents.y,
		"limit_bottom": camera_position.y + camera_extents.y,
	}

func camerachunk_entered(chunk: CameraChunk, room_transition:=false, duration:=0.5):
	current_camerachunk = chunk
	if get_tree().paused and paused == null or paused and not room_transition:
		camerachunk_set_while_paused = true
		return
	
	if not camera.is_inside_tree():
		yield(camera, "tree_entered")
	
	if room_transition:
		yield(camera.interpolate_limits(chunk.get_limits(), duration, Tween.TRANS_EXPO, Tween.EASE_OUT), "completed")
	else:
		yield(camera.interpolate_limits(chunk.get_limits(), duration), "completed")
	
func camerachunk_exited(chunk: CameraChunk):
	if current_camerachunk == chunk:
		current_camerachunk = null

var collider_cache = []
func set_collider(animation: SamusAnimation):
	
	var main_key: String
	if animation.position_node_path in collision_data:
		main_key = animation.position_node_path
	elif animation.position_node_path.split("/")[0] in collision_data:
		main_key = animation.position_node_path.split("/")[0]
	else:
		return
	
	var data = [main_key, facing]
	if collider_cache == data:
		return
	collider_cache = data
	
	$Collision.position = animation.positions[facing]
	$Collision.rotation_degrees = 0
	$AltCollision.disabled = true
	for key in collision_data[main_key]:
		var value = collision_data[main_key][key]
		if key == "pos": 
			$Collision.position = Vector2(value[0], value[1])
		elif (key == "leftPos" and facing == Enums.dir.LEFT) or (key == "rightPos" and facing == Enums.dir.RIGHT):
			$Collision.position = Vector2(value[0], value[1])
		elif key == "size":
			var shape = "rect"
			if "shape" in collision_data[main_key]:
				shape = collision_data[main_key]["shape"]
			
			if shape == "rect":
				if not $Collision.shape is RectangleShape2D:
					$Collision.shape = RectangleShape2D.new()
				$Collision.shape.extents = Vector2(value[0], value[1])
			elif shape == "circle":
				if not $Collision.shape is CircleShape2D:
					$Collision.shape = CircleShape2D.new()
				$Collision.shape.radius = value[0]
			elif shape == "capsule":
				if not $Collision.shape is CapsuleShape2D:
					$Collision.shape = CapsuleShape2D.new()
				
				if value[1] < value[0]:
					$Collision.rotation_degrees = 90
					$Collision.shape.radius = value[1]
					$Collision.shape.height = value[0]
				else:
					$Collision.shape.radius = value[0]
					$Collision.shape.height = value[1]
			
#			elif shape.begins_with("semicapsule"):
#				if not $Collision.shape is CapsuleShape2D:
#					$Collision.shape = CapsuleShape2D.new()
#				if not $AltCollision.shape is RectangleShape2D:
#					$AltCollision.shape = RectangleShape2D.new()
#				$AltCollision.disabled = false
#
#				var radius: float
#				var height: float
#				if value[1] < value[0]:
#					$Collision.rotation_degrees = 90
#					radius = value[1]
#					height = value[0]
#				else:
#					radius = value[0]
#					height = value[1]
#
#				$Collision.shape.radius = radius
#				$Collision.shape.height = height
#				$AltCollision.shape.extents = Vector2(radius, height/radius*2)
#
#				if "pos" in collision_data[main_key]:
#					var pos = collision_data[main_key]["pos"]
#					$AltCollision.position = Vector2(pos[0], pos[1])
#
#					if shape.ends_with("top"):
#						pass
#					else:
#						$AltCollision.position.y += value[1] + ($AltCollision.shape.extents.y/2)
				
				
				
			else:
				push_error("Unknown collision_data shape")
	
#	$CollisionHead.shape.radius = $Collision.shape.extents.x
#	$CollisionHead.position = $Collision.position - Vector2(0, $Collision.shape.extents.y)
#	$CollisionHead.scale.y = 10/$CollisionHead.shape.radius/2
#
#	$CollisionHead.position.y  += $CollisionHead.shape.radius*$CollisionHead.scale.y
#	$Collision.shape.extents.y -= $CollisionHead.shape.radius*$CollisionHead.scale.y/2
#	$Collision.position.y += $CollisionHead.shape.radius/2*$CollisionHead.scale.y
	
#	$CollisionHead.shape.height = 0
#	$Collision.shape.extents.y -= $Collision.shape.extents.x/2
#	$CollisionHead.position.y -= $Collision.shape.extents.x

func fluid_entered(fluid: Fluid):
	current_fluid = fluid.type
	Physics.set_profile(Fluid.TYPES.keys()[fluid.type])

func fluid_exited(fluid: Fluid):
	if current_fluid == fluid.type:
		current_fluid = Fluid.TYPES.NONE
		Physics.set_profile(null)

func fluid_splash(type: int) -> bool:
	return abs(Physics.vel.y) > 50

func acquire_ammo_pickup(pickup: AmmoPickup):
	print(pickup)

var step_sounds = {
	"snow": [
		Sound.new("res://audio/samus/step_sounds/snow/snow_step_dry-01.wav", Sound.TYPE.SAMUS), 
		Sound.new("res://audio/samus/step_sounds/snow/snow_step_dry-02.wav", Sound.TYPE.SAMUS),
		Sound.new("res://audio/samus/step_sounds/snow/snow_step_dry-03.wav", Sound.TYPE.SAMUS),
		Sound.new("res://audio/samus/step_sounds/snow/snow_step_dry-04.wav", Sound.TYPE.SAMUS),
	]
}

func step(index: int):
	step_sounds["snow"][index].play()
