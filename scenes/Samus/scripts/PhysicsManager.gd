extends Node

onready var Samus: KinematicBody2D = get_parent()

const GRAVITY = 20*60
const FALL_SPEED_CAP = 325
const UP_DIRECTION = Vector2.UP
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_DISTANCE = 15.0
const SNAP_VECTOR = SNAP_DIRECTION * SNAP_DISTANCE

var vel: Vector2 = Vector2.ZERO
var apply_gravity: bool = true
var apply_velocity: bool = true
var disable_floor_snap: bool = false
var on_slope: bool = false

const fluid_acceleration_modifier = Vector2(0.1, 0.1)
const fluid_velocity_modifier = Vector2(0.4, 0.4)

# Keeping this around for the memories
#var time = -1

func _physics_process(delta: float):
	
	if Samus.is_on_ceiling() or Samus.is_on_wall():
		Samus.boosting = false
	
#	if Samus.paused:
#		return
	
#	if get_tree().paused and Samus.paused == null or Samus.paused:
#		Samus.move_and_slide_with_snap(Vector2.ZERO, Vector2.ZERO)
	if get_tree().paused:
		return
	
	if apply_gravity:
		vel.y = min(vel.y + GRAVITY*delta*get_fluid_acceleration_modifier().y, FALL_SPEED_CAP*get_fluid_velocity_modifier().y)
	
	var slope_angle = Samus.get_floor_normal().dot(Vector2.UP)
	on_slope = slope_angle != 0 and slope_angle != 1
	
	if apply_velocity:
		
		var result_velocity = Samus.move_and_slide_with_snap(vel, SNAP_VECTOR if not disable_floor_snap else Vector2.ZERO, UP_DIRECTION, true)
		
		if slope_angle:
			vel.y = result_velocity.y
		else:
			vel = result_velocity
		
	vOverlay.SET("Physics.vel", vel)
	
	disable_floor_snap = false

func can_walk(direction: int):
	var collision = Samus.move_and_collide(Vector2(1*direction, 0), true, true, true)
	if not collision:
		return true
	else:
		var slope_angle = abs(collision.normal.dot(Vector2.UP))
		return slope_angle < 0.785398 and slope_angle != 0

func move_y(to: float, by: float = INF):
	vel.y = move_toward(vel.y, to*get_fluid_velocity_modifier().y, by*get_fluid_acceleration_modifier().y)
	disable_floor_snap = true

func move_x(to: float, by: float = INF):
	vel.x = move_toward(vel.x, to*get_fluid_velocity_modifier().x, by*get_fluid_acceleration_modifier().x)

func move(to: Vector2, by: float = INF):
	vel = vel.move_toward(to*get_fluid_velocity_modifier(), by*get_fluid_acceleration_modifier().length())

func get_fluid_velocity_modifier() -> Vector2:
	if Samus.current_fluid != Fluid.TYPES.NONE:
		return fluid_velocity_modifier*Fluid.viscosities[Samus.current_fluid]
	else:
		return Vector2(1.0, 1.0)

func get_fluid_acceleration_modifier() -> Vector2:
	if Samus.current_fluid != Fluid.TYPES.NONE:
		return fluid_acceleration_modifier*Fluid.viscosities[Samus.current_fluid]
	else:
		return Vector2(1.0, 1.0)
