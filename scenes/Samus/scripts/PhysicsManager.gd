extends Node

onready var Samus: KinematicBody2D = get_parent()

# GRAVITY
const gravity = 1250
const max_fall_speed = 325

var vel: Vector2 = Vector2.ZERO
var grounded: bool = false

var time = -1

func _physics_process(delta):

#	print(vel.x)

	# Apply gravity
	vel.y = min(vel.y + gravity*delta, max_fall_speed)
	
	vel = Samus.move_and_slide(vel, Vector2.UP)
	
	if Samus.is_on_floor() and time != 0 and vel.x != 0:
		
		if time == -1:
			time = 0
		
		time += delta
	elif time != 0 and vel.x != 0:
		time = 0


func decelerate_x(amount: float):
	if vel.x > 0:
		vel.x = max(vel.x - amount, 0)
	elif vel.x < 0:
		vel.x = min(vel.x + amount, 0)
		
func accelerate_x(amount: float, limit: float, direction: int):
	
	if direction == Enums.dir.LEFT:
		vel.x = max(vel.x - amount, -limit)
	elif direction == Enums.dir.RIGHT:
		vel.x = min(vel.x + amount, limit)
	else:
		return -1

func accelerate_y(amount: float, limit: float, direction: int):
	
	if direction == Enums.dir.UP:
		vel.y = max(vel.y - amount, -limit)
	elif direction == Enums.dir.DOWN:
		vel.y = min(vel.y + amount, limit)
	else:
		return -1
