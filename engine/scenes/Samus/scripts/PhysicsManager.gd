extends Node

signal landed
signal physics_data_set
onready var Samus: KinematicBody2D = get_parent()

const UP_DIRECTION = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_DISTANCE = 15.0
const SNAP_VECTOR = SNAP_DIRECTION * SNAP_DISTANCE
const FLOOR_MAX_ANGLE = deg2rad(70)

var vel: Vector2 = Vector2.ZERO
var apply_gravity: bool = true
var apply_velocity: bool = true
var disable_floor_snap: bool = false
var on_slope: bool = false

onready var profiles: Dictionary = {}
const physics_profiles_path = Data.data_path + "static/samus/physics_profiles/"
var data: = {}
onready var mode: int = Settings.get("controls/physics_mode")
var profile: = "STANDARD"

# Keeping this around for the memories
#var time = -1

func _ready():
	reload_data()
	set_data()
	Settings.connect("settings_changed", self, "settings_changed")
	
	Shortcut.register_debug_shortcut("DEBUG_reload_samus_physics_data", "Reload Samus physics data", {"just_pressed": funcref(self, "shortcut_reload_data")})

func reload_data():
	var dir = Directory.new()
	assert(dir.open(physics_profiles_path) == OK, "Profiles directory couldn't be opened")
	profiles.clear()
	for file in Global.iterate_directory(dir):
		if not dir.dir_exists(file) and file.ends_with(".json"):
			profiles[file.replace(".json", "")] = Global.load_json(physics_profiles_path + file)

func shortcut_reload_data():
	reload_data()
	set_data()
	Notification.types["text"].instance().init("Reloaded Samus physics data", Notification.lengths["normal"])

func _physics_process(delta: float):
	
	if get_tree().paused:# or Samus.paused:
		return
	
	if not Samus.was_on_floor and Samus.is_on_floor():
		Samus.was_on_floor = true
		emit_signal("landed")
	else:
		Samus.was_on_floor = Samus.is_on_floor()
	
	if Samus.current_fluid != Fluid.TYPES.NONE:
		fluid_process(delta)
	
	if Samus.boosting and (Samus.is_on_ceiling() or Samus.is_on_wall()):
		Samus.boosting = false
	
	if apply_gravity:
		vel.y = min(vel.y + data["general"]["gravity"]*delta, data["general"]["fall_speed_cap"])
	
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

func fluid_process(delta):
	pass

func settings_changed(path: String, value):
	if path == "other/physics_mode":
		mode = value
		set_data()

func set_data():
	var profile_data: Dictionary = profiles[profile]
	for group in profile_data:
		if not group in data:
			data[group] = {}
		for key in profile_data[group]:
			data[group][key] = profile_data[group][key][mode]
	emit_signal("physics_data_set")

func set_profile(key):
	profile = key if key != null else "STANDARD"
	set_data()
