extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var sounds: Dictionary
var physics_data: Dictionary

var FloorRaycastL: RayCast2D
var FloorRaycastR: RayCast2D
var FloorRaycastD: RayCast2D
var FloorRaycastContainer: Node2D

var attached = false
var FLOOR: Vector2 = Vector2.ZERO setget set_floor

#var rotation: float = 0

# Called during Samus's readying period
func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	FloorRaycastContainer = Animator.raycasts.get_node("spiderball")
	FloorRaycastL = FloorRaycastContainer.get_node("FloorL")
	FloorRaycastR = FloorRaycastContainer.get_node("FloorR")
	FloorRaycastD = FloorRaycastContainer.get_node("FloorD")
	
	animations = Animator.load_from_json("morphball")
	
	sounds["sndSBallLoop"].set_loop(-1)
	sounds["sndSBallLoop"].enabled = false

# Called when Samus's state is changed to this one
func init_state(_data: Dictionary, _previous_state_id: String):
	Samus.aiming = Samus.aim.NONE
	trigger_action = null
	sounds["sndSBallStart"].play()
	update_passive_sound()
	if Samus.is_on_floor():
		set_floor(Vector2.DOWN)

# Called every frame while this state is active
func process(_delta: float):
	
	var original_facing = Samus.facing

	if Settings.get("control_options/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))

	if (Settings.get("control_options/spiderball_style") == 0 and not Input.is_action_pressed("spiderball")) or (Settings.get("control_options/spiderball_style") == 1 and Input.is_action_just_pressed("spiderball")):
		change_state("morphball", {"options": []})
		return
	
	if Input.is_action_just_pressed("fire_weapon"):
		Samus.Weapons.fire()
	
	var pad_x = InputManager.get_pad_vector("pressed").x
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
				update_direction()
			anim_speed = direction * (-1.0 if Samus.facing == Enums.dir.RIGHT else 1.0)
		else:
			anim_speed = int(Physics.vel.x != 0)
		
#		var target_physics_speed = physics_data["speed"] if attached else Physics.data["morphball"]["air_speed"]
#		var vector_speed: Vector2 = Physics.vel / FLOOR.rotated(deg2rad(90))*direction*spider_speed
#		anim_speed *= vector_speed.aspect()*0.5
		animations["roll_spider"].play(true, anim_speed)
		FloorRaycastContainer.position.x = Animator.current[false].sprites[Samus.facing].position.x

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	set_floor(Vector2.ZERO)
	sounds["sndSBallLoop"].stop()
	Animator.resume()
	.change_state(new_state_key, data)

func set_floor(value: Vector2):
	attached = value != Vector2.ZERO
	if attached:
		Physics.vel = Vector2.ZERO
	FLOOR = value
	FloorRaycastL.enabled = attached
	FloorRaycastR.enabled = attached
	FloorRaycastD.enabled = attached
	Physics.apply_velocity = !attached
	Physics.apply_gravity = !attached
	
	FloorRaycastContainer.rotation = FLOOR.rotated(deg2rad(-90)).angle()

var trigger_action = null
func update_direction():
	
	var pad_vector: Vector2 = InputManager.get_pad_vector("pressed")
	if not Settings.get("control_options/spiderball_relative_controls"):
		direction = int(pad_vector.x) * -1
		update_passive_sound()
		return
	
	if trigger_action != null:
		if Input.is_action_pressed(trigger_action):
			return
		else:
			trigger_action = null
	
	var slope = FLOOR.x != 0 and FLOOR.y != 0

	direction = 0
	if FLOOR == Vector2.DOWN or FLOOR == Vector2.UP or slope:
		if pad_vector.x == -1:
			trigger_action = "pad_left"
			direction = -1
		elif pad_vector.x == 1:
			trigger_action = "pad_right"
			direction = 1
		if FLOOR.y > 0:
			direction *= -1
		if direction != 0:
			update_passive_sound()
			return
	
	if FLOOR == Vector2.RIGHT or FLOOR == Vector2.LEFT or slope:
		if pad_vector.y == -1:
			trigger_action = "pad_up"
			direction = -1
		elif pad_vector.y == 1:
			trigger_action = "pad_down"
			direction = 1
		if FLOOR.x < 0:
			direction *= -1
	
	update_passive_sound()

func update_passive_sound():
	if direction == 0:
		sounds["sndSBallLoop"].stop()
	elif sounds["sndSBallLoop"].status != AudioPlayer.STATE.PLAYING:
		sounds["sndSBallLoop"].play()

var direction: int
func attached_physics_process(delta: float):
	
	update_direction()
#	Physics.move(FLOOR.rotated(deg2rad(90))*direction*spider_speed, spider_acceleration*delta)
#	Physics.vel = FLOOR.rotated(deg2rad(90))*direction*spider_speed
	
	var floor_collision = Samus.move_and_collide(FLOOR*physics_data["speed"]*delta, true, true, true)
	if floor_collision == null:
		floor_collision = Samus.move_and_collide(FLOOR*physics_data["speed"]*delta)
	if direction == 0:
		return
	
	if floor_collision == null:
		if FloorRaycastL.is_colliding():
			set_floor(-FloorRaycastL.get_collision_normal())
		elif FloorRaycastR.is_colliding():
			set_floor(-FloorRaycastR.get_collision_normal())
		else:
			set_floor(Vector2.ZERO)
			return
	else:
		set_floor(-floor_collision.normal)
	
	var collision = Samus.move_and_collide(FLOOR.rotated(deg2rad(90))*direction*physics_data["speed"]*delta)
	if collision != null:
		set_floor(-collision.normal)

func bounce(vert_speed: float, horiz_speed: float):
	set_floor(Vector2.ZERO)
	Samus.states["morphball"].bounce(vert_speed, horiz_speed)

#func bounce(amount: float):
#	set_floor(Vector2.ZERO)
#	Physics.disable_floor_snap = true
#	Physics.vel.y = -amount

func physics_process(delta: float):
	if attached:
		attached_physics_process(delta)
		return
	
	var velocity = Physics.vel*delta
	if velocity.x == 0:
		velocity.x = InputManager.get_pad_x("pressed")
	if velocity.y == 0:
		velocity.y = 1
	
	var collision = Samus.move_and_collide(velocity, true, true, true)
	if collision != null:
		yield(Samus.get_tree(), "physics_frame")
		set_floor(-collision.normal)
	else:
#		if pad_x != 0:
#			Physics.accelerate_x(roll_air_acceleration, max(roll_air_speed, abs(Physics.vel.x)), Samus.facing)
#		Physics.move_x(roll_air_speed*pad_x, (roll_air_acceleration if pad_x != 0 else roll_air_acceleration)*delta)
#		else:
#			Physics.decelerate_x(roll_air_deceleration)
	
		Samus.states["morphball"].physics_process(delta, true)
