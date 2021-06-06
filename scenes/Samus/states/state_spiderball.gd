extends Node
const id = "spiderball"

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

# PHYSICS
const spider_speed = 75
const spider_acceleration = 25*60

const roll_air_acceleration = 25*60
const roll_air_deceleration = 50*60
const roll_air_speed = 150

var animations = {}
var sounds = {
	
}

var FloorRaycastL: RayCast2D
var FloorRaycastR: RayCast2D
var FloorRaycastContainer: Node2D

var rotation: float = 0

var attached = false
var FLOOR: Vector2 = Vector2.ZERO setget set_floor


# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	FloorRaycastContainer = Animator.raycasts.get_node("spiderball")
	FloorRaycastL = FloorRaycastContainer.get_node("FloorL")
	FloorRaycastR = FloorRaycastContainer.get_node("FloorR")
	
	animations = Animator.load_from_json("morphball")
	

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary):
	Samus.aiming = Samus.aim.NONE
	if Samus.is_on_floor():
		set_floor(Vector2.DOWN)
	return self

# Called every frame while this state is active
func process(_delta):
	
	var original_facing = Samus.facing

	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))

	if (Settings.get("controls/spiderball_style") == 0 and not Input.is_action_pressed("spiderball")) or (Settings.get("controls/spiderball_style") == 1 and Input.is_action_just_pressed("spiderball")):
		change_state("morphball", {"options": []})
		return
	
	if Input.is_action_just_pressed("fire_weapon"):
		Samus.Weapons.fire()
	
	var pad_x = Shortcut.get_pad_vector("pressed").x
	if not attached:
		if pad_x < 0:
			Samus.facing = Enums.dir.LEFT
			if original_facing == Enums.dir.RIGHT:
				animations["turn"].play()
				
		elif pad_x > 0:
			Samus.facing = Enums.dir.RIGHT
			if original_facing == Enums.dir.LEFT:
				animations["turn"].play()
	
	if not Animator.transitioning(false, true):
		var anim_speed: = 1.0
		if attached:
			if direction == null:
				direction = get_direction()
			anim_speed = direction * (-1.0 if Samus.facing == Enums.dir.RIGHT else 1.0)
		
		var target_physics_speed = spider_speed if attached else roll_air_speed
		anim_speed *= abs(Physics.vel.length()) / target_physics_speed
		animations["roll_spider"].play(true, anim_speed)
		FloorRaycastContainer.position.x = Animator.current[false].sprites[Samus.facing].position.x
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	set_floor(Vector2.ZERO)
	Animator.resume()
	Samus.change_state(new_state_key, data)

func set_floor(value: Vector2):
	attached = value != Vector2.ZERO
	if attached:
		Physics.vel = Vector2.ZERO
	FLOOR = value
	FloorRaycastL.enabled = attached
	FloorRaycastR.enabled = attached
	Physics.apply_velocity = !attached
	Physics.apply_gravity = !attached
	
	FloorRaycastContainer.rotation = FLOOR.rotated(deg2rad(-90)).angle()

var trigger_action
func get_direction() -> int:
	
	var pad_vector = Shortcut.get_pad_vector("pressed")
	if not Settings.get("controls/spiderball_relative_controls"):
		return pad_vector.x * -1
	
	var ret: int = 0
	
	if trigger_action != null:
		if Input.is_action_pressed(trigger_action):
			return direction
		else:
			trigger_action = null
	
	var slope = FLOOR.x != 0 and FLOOR.y != 0

	if FLOOR == Vector2.DOWN or FLOOR == Vector2.UP or slope:
		if Input.is_action_pressed("pad_left"):
			trigger_action = "pad_left"
			ret = -1
		elif Input.is_action_pressed("pad_right"):
			trigger_action = "pad_right"
			ret = 1
		if FLOOR.y > 0:
			ret *= -1
		if ret != 0:
			return ret
	
	if FLOOR == Vector2.RIGHT or FLOOR == Vector2.LEFT or slope:
		if Input.is_action_pressed("pad_up"):
			trigger_action = "pad_up"
			ret = -1
		elif Input.is_action_pressed("pad_down"):
			trigger_action = "pad_down"
			ret = 1
		if FLOOR.x < 0:
			ret *= -1
		if ret != 0:
			return ret
	
	return ret

var direction
func attached_physics_process(delta: float):
	
	direction = get_direction()
	Physics.move(FLOOR.rotated(deg2rad(90))*direction*spider_speed, spider_acceleration*delta)
	if direction == 0:
		return
	var collided = Samus.move_and_collide(FLOOR*delta*spider_speed) != null
	
	var set = false
	if not collided:
		if FloorRaycastL.is_colliding():
			set_floor(-FloorRaycastL.get_collision_normal())
			set = true
		elif FloorRaycastR.is_colliding():
			set_floor(-FloorRaycastR.get_collision_normal())
			set = true
		else:
			set_floor(Vector2.ZERO)
			return
	
	var collision = Samus.move_and_collide(Physics.vel*delta)
	if collision != null:
#		print(normal)
		set_floor(-collision.normal)
		collided = true

func bounce(amount: float):
	set_floor(Vector2.ZERO)
	Physics.disable_floor_snap = true
	Physics.vel.y = -amount

func physics_process(delta: float):
	if attached:
		attached_physics_process(delta)
		return
	
	var collision = Samus.move_and_collide(Physics.vel*delta, true, true, true)
	if collision != null:
		yield(Global, "physics_frame")
		set_floor(-collision.normal)
	else:
		var pad_x = Shortcut.get_pad_vector("pressed").x
#		if pad_x != 0:
#			Physics.accelerate_x(roll_air_acceleration, max(roll_air_speed, abs(Physics.vel.x)), Samus.facing)
		Physics.move_x(roll_air_speed*pad_x, (roll_air_acceleration if pad_x != 0 else roll_air_acceleration)*delta)
#		else:
#			Physics.decelerate_x(roll_air_deceleration)
