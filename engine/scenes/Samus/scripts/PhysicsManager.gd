extends Node

signal is_on_floor_changed
signal physics_data_set
onready var Samus: KinematicBody2D = get_parent()

const UP_DIRECTION = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_DISTANCE = 15.0
const SNAP_VECTOR = SNAP_DIRECTION * SNAP_DISTANCE
const FLOOR_MAX_ANGLE = deg2rad(70)

var gravity: float
var fall_speed_cap: float

var vel: Vector2 = Vector2.ZERO
var apply_gravity: bool = true
var apply_velocity: bool = true
var disable_floor_snap: bool = false
var on_slope: bool = false

onready var profiles: Dictionary = {}
var data: = {}

onready var profile_key: String = Settings.get("control_options/samus_physics_profile")
var mode: int = Enums.SAMUS_PHYSICS_MODES.STANDARD
var prevent_physics_override: bool = false

var current_ground_collider_shape = null

# Keeping this around for the memories
#var time = -1

func _ready():
	reload_data()
	set_data()
	Settings.connect("settings_changed", self, "settings_changed")
	Samus.connect("suit_changed", self, "samus_suit_changed")
	Samus.connect("state_changed", self, "samus_state_changed")
	connect("is_on_floor_changed", self, "is_on_floor_changed")
	
	InputManager.register_debug_shortcut("DEBUG_reload_samus_physics_data", "Reload Samus physics data", {"just_pressed": funcref(self, "shortcut_reload_data")})

func reload_data():
	profiles.clear()
	
	var profile_dirs: Array = []
	for dir in Data.data["engine_config"]["samus_physics_profiles_directories"]:
		var dir_profiles: Dictionary = Global.dir2dict(dir, Global.DIR2DICT_MODES.NESTED, null, ["json"])
		for profile in dir_profiles:
			profiles[profile] = Global.load_json(dir_profiles[profile])
	
func shortcut_reload_data():
	reload_data()
	set_data()
	Notification.types["text"].instance().init("Reloaded Samus physics data", Notification.lengths["normal"])

func _physics_process(delta: float):
	
	if get_tree().paused:# or Samus.paused:
		return
	
	if not Samus.was_on_floor:
		if Samus.is_on_floor():
			Samus.was_on_floor = true
			emit_signal("is_on_floor_changed", true)
	else:
		if not Samus.is_on_floor():
			Samus.was_on_floor = false
			emit_signal("is_on_floor_changed", false)
	
#	if Samus.current_fluid != Fluid.TYPES.NONE:
#		fluid_process(delta)
	
	if Samus.boosting and (Samus.is_on_ceiling() or Samus.is_on_wall()):
		Samus.boosting = false
	
	if apply_gravity:
		vel.y = min(vel.y + gravity*delta, fall_speed_cap)
	
	var slope_angle = Samus.get_floor_normal().dot(Vector2.UP)
	on_slope = slope_angle != 0 and slope_angle != 1
	if apply_velocity:
		var result_velocity = Samus.move_and_slide_with_snap(vel, SNAP_VECTOR if not disable_floor_snap else Vector2.ZERO, UP_DIRECTION, true, 4, FLOOR_MAX_ANGLE)
		
		if slope_angle:
			vel.y = result_velocity.y
		else:
			vel = result_velocity
	
	vOverlay.SET("Physics.vel", vel)
	
	disable_floor_snap = false

func can_walk(direction: int):
	Samus.move_and_slide_with_snap(Vector2(direction*100, 0), SNAP_VECTOR if not disable_floor_snap else Vector2.ZERO, UP_DIRECTION, true, 4, FLOOR_MAX_ANGLE)
	return !Samus.is_on_wall()

func move_y(to: float, by: float = INF):
	vel.y = move_toward(vel.y, to, by)
	disable_floor_snap = true

func move_x(to: float, by: float = INF):
	vel.x = move_toward(vel.x, to, by)

func move(to: Vector2, delta: float = INF):
	vel = vel.move_toward(to, delta)

#func fluid_process(delta):
#	pass

func settings_changed(path: String, value):
	if path == "other/physics_profile":
		mode = value
		set_data()

func set_data():
	var profile_data: Dictionary = profiles[profile_key]
	
	var mode_to_apply: int = Enums.SAMUS_PHYSICS_MODES.STANDARD if prevent_physics_override else mode
	for group in profile_data:
		if group == "profile_info":
			continue
		
		if not group in data:
			data[group] = {}
		for key in profile_data[group]:
			# DEBUG
			data[group][key] = profile_data[group][key][mode_to_apply if mode_to_apply < len(profile_data[group][key]) else 0]
#			data[group][key] = profile_data[group][key][mode]
	samus_state_changed(null, Samus.current_state.id if Samus.current_state else "general", null)
	emit_signal("physics_data_set")

func set_mode(_mode: int):
	mode = _mode
	set_data()

func samus_suit_changed(active_suits: Dictionary):
	if mode == Enums.SAMUS_PHYSICS_MODES.STANDARD:
		return
	prevent_physics_override = false
	for suit in active_suits.values():
		if suit["prevent_physics_override"]:
			prevent_physics_override = true
			break
	set_data()

func samus_state_changed(_previous_state_id, new_state_id: String, _data):
	for property in ["gravity", "fall_speed_cap"]:
		if new_state_id in data and property + "_override" in data[new_state_id]:
			set(property, data[new_state_id][property + "_override"])
		else:
			set(property, data["general"][property])

func is_on_floor_changed(is_on_floor: bool):
	if is_on_floor:
		for slide_idx in range(Samus.get_slide_count()):
			var collision: KinematicCollision2D = Samus.get_slide_collision(slide_idx)
			if collision.normal == Samus.get_floor_normal():
				current_ground_collider_shape = collision.collider_shape
				# DEBUG | Eventually, all CollisionPolygon/Shapes that Samus can land/walk on should be GroundTypeCollisionShapes
				if current_ground_collider_shape is RoomCollisionArea:
					current_ground_collider_shape.play_land_sound()
					return
	else:
		current_ground_collider_shape = null
