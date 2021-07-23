extends KinematicBody2D

signal state_changed

onready var Animator: Node2D = $Animator
onready var Collision: CollisionShape2D = $Collision
onready var Hurtbox: CollisionShape2D = $Hurtbox/CollisionShape2D
onready var Physics: Node = $Physics
onready var Weapons: Node2D = $Weapons
onready var HUD: Control = $HUD
onready var PauseMenu: Control = $PauseMenu
onready var camera: ExCamera2D = $ExCamera2D

var facing: int = Enums.dir.LEFT
var armed: bool = false
enum aim {NONE, UP, DOWN, FRONT, SKY, FLOOR}
var aiming: int = aim.FRONT setget set_aiming
var aim_none_timer: Timer = Global.get_timer()

var hurtbox_damage: Dictionary = {}

var boosting: bool = false setget set_boosting
var shinespark_charged: bool = false

var fall_time: float = 0
var was_on_floor: bool = false

const collision_data_json_path: String = "res://engine/scenes/Samus/animations/collision_data.json"
onready var collision_data: Dictionary = Global.load_json(collision_data_json_path)

var current_fluid: int

onready var states = {
	"jump": preload("res://engine/scenes/Samus/states/state_jump.gd").new(self, "jump"),
	"neutral": preload("res://engine/scenes/Samus/states/state_neutral.gd").new(self, "neutral"),
	"run": preload("res://engine/scenes/Samus/states/state_run.gd").new(self, "run"),
	"crouch": preload("res://engine/scenes/Samus/states/state_crouch.gd").new(self, "crouch"),
	"morphball": preload("res://engine/scenes/Samus/states/state_morphball.gd").new(self, "morphball"),
	"spiderball": preload("res://engine/scenes/Samus/states/state_spiderball.gd").new(self, "spiderball"),
	"shinespark": preload("res://engine/scenes/Samus/states/state_shinespark.gd").new(self, "shinespark"),
	"powergrip": preload("res://engine/scenes/Samus/states/state_powergrip.gd").new(self, "powergrip"),
	"visor": preload("res://engine/scenes/Samus/states/state_visor.gd").new(self, "visor"),
#	"visor": $Weapons/SamusVisors,
	"grapple": preload("res://engine/scenes/Samus/states/state_grapple.gd").new(self, "grapple"),
	"facefront": preload("res://engine/scenes/Samus/states/state_facefront.gd").new(self, "facefront"),
	"hurt": preload("res://engine/scenes/Samus/states/state_hurt.gd").new(self, "hurt"),
	"death": preload("res://engine/scenes/Samus/states/state_death.gd").new(self, "death"),
	"airspark": preload("res://engine/scenes/Samus/states/state_airspark.gd").new(self, "airspark"),
	}
var previous_state_id: String
onready var current_state: Node = states["neutral"]
var state_change_record = [["", 0]]

var energy: float
var etanks: int
var upgrades: Dictionary

var paused = null
var real: = false

#var functions_to_process: Array = []

func set_boosting(value: bool):
	boosting = value
	set_hurtbox_damage(states["shinespark"].damage_type, states["shinespark"].damage_amount if boosting else null)

func set_hurtbox_damage(type: int, amount):
	if amount != null:
		hurtbox_damage[type] = amount
	elif type in hurtbox_damage:
		hurtbox_damage.erase(type)
 
func check_hurtbox_damage(damage_types):
	
	if hurtbox_damage.empty():
		return null
	
	var highest = null
	for type in hurtbox_damage:
		if (damage_types == null or type in damage_types) and (highest == null or hurtbox_damage[type] > hurtbox_damage[highest]):
			highest = type
	if highest != null:
		highest = [highest, hurtbox_damage[highest], Animator.current[false].sprites[facing].global_position]
	
	return highest

func get_hurtbox_damage():
	return [states["shinespark"].damage_type, states["shinespark"].damage_amount]

func shift_position(position: Vector2):
	self.position += position

func _ready():
	z_index = Enums.Layers.SAMUS
	z_as_relative = false
	$Animator/Sprites.trail_z_index = Enums.Layers.SAMUS
	
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
	
#	for state in states.values():
#		if state.has_method("persistent_process"):
#			functions_to_process.append(funcref(state, "persistent_process"))
	
	change_state("neutral")
	Loader.Save.connect("value_set", self, "save_value_set")
	
	# DEBUG
	$Animator/TestSprites.queue_free()
	register_commands()

func _process(delta):
	# DEBUG
#	if Input.is_action_just_pressed("[DEBUG] increase energy"):
#		energy += 1
#		print("Increased energy to: " + str(energy))
#		HUD.set_energy(energy)
#	elif Input.is_action_just_pressed("[DEBUG] decrease energy"):
#		energy -= 1
#		print("Decreased energy to: " + str(energy))
#		HUD.set_energy(energy)
	
	if get_tree().paused and paused == null or paused:
		if current_state.has_method("paused_process"):
			current_state.paused_process(delta)
		return
	
	current_state.process(delta)
	if is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		states["shinespark"].process_speedboooster(delta)
	
#	for function in functions_to_process:
#		function.call_func(delta)
	
#	if is_upgrade_active(Enums.Upgrade.CHARGEBEAM):
#		process_chargebeam(delta)

var prev = ""
func _physics_process(delta):
	vOverlay.SET("hurboxdamage", hurtbox_damage)
	vOverlay.SET("State", current_state.id)
	
	if get_tree().paused and paused == null or paused:
		if current_state.has_method("paused_physics_process"):
			current_state.paused_physics_process(delta)
		return
	
	current_state.physics_process(delta)
	
	if not is_on_floor() and Physics.vel.y > 0:
		fall_time += delta
	else:
		fall_time = 0

func change_state(new_state_key: String, data: Dictionary = {}):
	
	if get_tree().paused and paused == null or paused:
		return
	
#	if states[new_state_key].init_state(data):
	states[new_state_key].init_state(data)
	if new_state_key in ["crouch", "morphball"] and is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER):
		if states["shinespark"].ShinesparkStoreWindow.time_left > 0 or boosting:
			states["shinespark"].charge_shinespark()
	previous_state_id = current_state.id
	state_change_record = [[new_state_key, Global.time()]] + state_change_record
	current_state = states[new_state_key]
	emit_signal("state_changed", previous_state_id, new_state_key, data)
#	return true
#	else:
#		return false
	

var upgrade_cache: = {}
func is_upgrade_active(upgrade_key: int):
	if not upgrade_key in upgrade_cache:
		var upgrade = Loader.Save.get_data_key(["samus", "upgrades", upgrade_key])
		upgrade_cache[upgrade_key] = upgrade["amount"] > 0 and upgrade["active"]
	return upgrade_cache[upgrade_key]

func is_upgrade_acquired(upgrade_key: int):
	var upgrade = Loader.Save.get_data_key(["samus", "upgrades", upgrade_key])
	return upgrade["amount"] > 0

func get_mini_upgrade(upgrade_key: String, side=null):
	if side == null:
		return [Loader.Save.get_data_key(["samus", "mini_upgrades", upgrade_key]), Data.data["mini_upgrades"][upgrade_key]]
	elif side == 0:
		return Loader.Save.get_data_key(["samus", "mini_upgrades", upgrade_key])
	else:
		return Data.data["mini_upgrades"][upgrade_key]

func set_aiming(value: int):
	if value in [aim.UP, aim.DOWN, aim.SKY, aim.FLOOR]: 
		aim_none_timer.start()
	aiming = value

func save_value_set(path: Array, _value):
	
	if len(path) < 2 or path[0] != "samus":
		return
	
	if len(path) == 4 and path[1] == "upgrades":
		upgrade_cache = {}

# Returns true if the current state has been active for more than the specified time
# Or if the previous state doesn't match the state key
func time_since_last_state(state_key: String, seconds: float):
	return state_change_record[1][0] != state_key or Global.time() - state_change_record[0][1] >= seconds*1000

func death():
	if current_state.id != "death":
		current_state.change_state("death")

onready var damage_reduction_mini_upgrade: Array = [get_mini_upgrade("power_suit_damage_reduction", 0), get_mini_upgrade("power_suit_damage_reduction", 1)["data"]["increase_percentage"]]
func _damage(type: int, amount: float, impact_position):
	
	if InvincibilityTimer.time_left > 0:
		return
	
	var diff: float = (amount - (amount * damage_reduction_mini_upgrade[0]["created"] * damage_reduction_mini_upgrade[1]))
	if diff <= 0:
		return
	
	energy = max(0, energy - diff)
	HUD.set_energy(energy)
	
	# DEBUG
	if energy == 0:
		death()
		
	else:
		InvincibilityTimer.start(states["hurt"].physics_data["invincibility_duration"])
		if impact_position == null:
			return
		
		var position_offset: Vector2 = Animator.current[false].sprites[facing].global_position - (impact_position * states["hurt"].physics_data["knockback_strength"])
		Physics.vel = position_offset.normalized()*10
		
		if current_state.id == "spiderball":
			current_state.change_state("morphball", {"options": []})
		elif not current_state.id in ["morphball"]:
			change_state("hurt", {"impact_position": impact_position})

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

var current_camerachunk = null
var previous_camerachunk = null
func camerachunk_entered(chunk: CameraChunk, room_transition:=false, duration:=0.5):
	if chunk == current_camerachunk:
		return
	
	previous_camerachunk = current_camerachunk
	current_camerachunk = chunk
	if get_tree().paused and paused == null or paused and not room_transition:
		return
	
	if not camera.is_inside_tree():
		yield(camera, "tree_entered")
	
	var limits = chunk.get_limits() if chunk != null else null
	if room_transition:
		yield(camera.interpolate_limits(limits, duration, Tween.TRANS_EXPO, Tween.EASE_OUT), "completed")
	else:
		yield(camera.interpolate_limits(limits, duration), "completed")
	
func camerachunk_exited(chunk: CameraChunk):
	if current_camerachunk == chunk:
		camerachunk_entered(previous_camerachunk)

var collider_cache = []
func set_collider(animation: SamusAnimation):
	
	var main_key: String
	if animation.position_node_path in collision_data:
		main_key = animation.position_node_path
	elif animation.position_node_path.split("/")[0] in collision_data:
		main_key = animation.position_node_path.split("/")[0]
	else:
		return
	
	if "ignore" in collision_data[main_key] and collision_data[main_key]["ignore"]:
		return
	
	var data = [main_key, facing]
	if collider_cache == data:
		return
	collider_cache = data

#	var tempcollision: CollisionShape2D = Collision.duplicate()
#	add_child(tempcollision)
	Collision.position = animation.positions[facing]
	Collision.rotation_degrees = 0
	for key in collision_data[main_key]:
		var value = collision_data[main_key][key]
		if key == "pos": 
			Collision.position = Vector2(value[0], value[1])
		elif (key == "leftPos" and facing == Enums.dir.LEFT) or (key == "rightPos" and facing == Enums.dir.RIGHT):
			Collision.position = Vector2(value[0], value[1])
		elif key == "size":
			var shape = "rect"
			if "shape" in collision_data[main_key]:
				shape = collision_data[main_key]["shape"]
			
			if shape == "rect":
				if not Collision.shape is RectangleShape2D:
					Collision.shape = RectangleShape2D.new()
				Collision.shape.extents = Vector2(value[0], value[1])
			elif shape == "circle":
				if not Collision.shape is CircleShape2D:
					Collision.shape = CircleShape2D.new()
				Collision.shape.radius = value[0]
			elif shape == "capsule":
				if not Collision.shape is CapsuleShape2D:
					Collision.shape = CapsuleShape2D.new()
				
				if value[1] < value[0]:
					Collision.rotation_degrees = 90
					Collision.shape.radius = value[1]
					Collision.shape.height = value[0]
				else:
					Collision.shape.radius = value[0]
					Collision.shape.height = value[1]
				
			else:
				push_error("Unknown collision_data shape")
	
	for property in ["shape", "position", "rotation_degrees"]:
		Hurtbox.set(property, Collision.get(property))
	

func fluid_entered(fluid: Fluid):
	current_fluid = fluid.type
	Physics.set_profile(Fluid.TYPES.keys()[fluid.type])

func fluid_exited(fluid: Fluid):
	if current_fluid == fluid.type:
		current_fluid = Fluid.TYPES.NONE
		Physics.set_profile(null)

func fluid_splash(type: int) -> bool:
	return abs(Physics.vel.y) > 50

func acquire_ammo_pickup(ammo_data: Dictionary):
	
	if ammo_data["type"] == AmmoPickup.TYPES.ENERGY:
		energy = min((etanks*100)+99, energy + ammo_data["amount"])
		HUD.set_energy(energy)
	elif ammo_data["type"] == AmmoPickup.TYPES.UPGRADE:
		ammo_data["weapon"].ammo = min(ammo_data["weapon"].amount, ammo_data["weapon"].ammo + ammo_data["amount"]) 


onready var step_sounds = {
	"snow": [
		Audio.get_player("/samus/step_sounds/snow/snow_step_dry-01", Audio.TYPE.SAMUS),
		Audio.get_player("/samus/step_sounds/snow/snow_step_dry-02", Audio.TYPE.SAMUS),
		Audio.get_player("/samus/step_sounds/snow/snow_step_dry-03", Audio.TYPE.SAMUS),
		Audio.get_player("/samus/step_sounds/snow/snow_step_dry-04", Audio.TYPE.SAMUS),
	]
}

func step(index: int):
	step_sounds["snow"][index].play()

onready var InvincibilityPlayer: AnimationPlayer = Animator.get_node("InvincibilityPlayer")
var InvincibilityTimer: ExTimer = Global.get_timer([self, "invincibility_changed", [false]], [self, "invincibility_changed", [true]])
func invincibility_changed(status: bool):
	if status == (InvincibilityPlayer.current_animation == "invincibility"):
		return
	InvincibilityPlayer.play("invincibility" if status else "reset")
	if not status:
		# DEBUG
		pass
#		Collision.disabled = true
		Hurtbox.disabled = true
		yield(get_tree(), "idle_frame")
		Hurtbox.disabled = false
#		Collision.disabled = false

# DEBUG
func register_commands():
	# Registering command
	# 1. argument is command name
	# 2. arg. is target (target could be a funcref)
	# 3. arg. is target name (name is not required if it is the same as first arg or target is a funcref)
	Console.add_command("samussetenergy", self, "command_setenergy")\
		.set_description("Sets Samus's energy value. Fills all ETanks if the value is below 0.")\
		.add_argument('value', TYPE_INT)\
		.register()
	Console.add_command("samuskill", self, "death")\
		.set_description("Triggers Samus's death animation, regardless of remaining energy.")\
		.register()

func command_setenergy(value: int):
	if value < 0:
		energy = etanks * 100 + 99
	else:
		energy = value
	Console.write_line("Samus's energy was set to " + str(energy))
	HUD.set_energy(energy)
