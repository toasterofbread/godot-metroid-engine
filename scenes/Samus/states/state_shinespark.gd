extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

const damage_type = Enums.DamageType.SPEEDBOOSTER
const damage_amount = 0
const id = "shinespark"

var ShinesparkUseWindow: Timer = Global.timer([self, "discharge_shinespark", []])
var shinespark_hold_time: float = 3.0

var ShinesparkStoreWindow: Timer = Global.timer()
var shinespark_store_window: float = 0.2

var SpeedboosterRaycasts: Array
var SpeedboostAnimationPlayer: AnimationPlayer
var SpeedboosterArea: Area2D

# PHYSICS
const speed: float = 600.0
var velocity: Vector2
var direction: int

var moving: bool = false
var animation_key: String
var animations: Dictionary
var ballspark: bool = false

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.SpeedboostAnimationPlayer = Animator.get_node("SpeedboostAnimationPlayer")
	
	self.animations = Animator.load_from_json(self.id)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary):
	
	ballspark = data["ballspark"]
	
	Physics.apply_gravity = false
	
	discharge_shinespark()
	Physics.vel.y = -50
	Physics.disable_floor_snap = true
	
	Samus.boosting = true
	
	if not ballspark:
		yield(animations["start"].play(), "completed")
	else:
		yield(Global.wait(0.25), "completed")
	
	Physics.vel.y = 0
	
	if Input.is_action_pressed("pad_left"):
		if Input.is_action_pressed("pad_up"):
			direction = Enums.dir.TOPLEFT
		elif Input.is_action_pressed("pad_down"):
			direction = Enums.dir.BOTLEFT
		else:
			direction = Enums.dir.LEFT
		Samus.facing = Enums.dir.LEFT
	elif Input.is_action_pressed("pad_right"):
		if Input.is_action_pressed("pad_up"):
			direction = Enums.dir.TOPRIGHT
		elif Input.is_action_pressed("pad_down"):
			direction = Enums.dir.BOTRIGHT
		else:
			direction = Enums.dir.RIGHT
		Samus.facing = Enums.dir.RIGHT
	elif Input.is_action_pressed("pad_down"):
		direction = Enums.dir.DOWN
	else:
		direction = Enums.dir.UP
	
	velocity = Vector2(0, -speed).rotated(deg2rad(Enums.dir_angle(direction)))
	
	if not ballspark:
		animation_key = "horiz"
		if direction in [Enums.dir.UP, Enums.dir.DOWN]:
			animation_key = "vert"
		
		animations[animation_key].play()
		if direction == Enums.dir.DOWN:
			Animator.current[false].sprites[Samus.facing].flip_v = true
	else:
		Samus.states["morphball"].animations["roll"].play()
	
	moving = true
	
# Called every frame while this state is active
func process(_delta):

	if animation_key:
		Samus.Collision.set_collider(animations[animation_key])
	
	if not moving:
		return
	
	Physics.vel = velocity
	Samus.boosting = true
	
	if Physics.on_slope and direction in [Enums.dir.LEFT, Enums.dir.RIGHT, Enums.dir.BOTLEFT, Enums.dir.BOTRIGHT]:
		moving = false
		Physics.apply_gravity = true
		Animator.resume()
		if ballspark:
			ballspark = false
			change_state("morphball", {"options": ["animate"]})
		else:
			change_state("run", {"boost": true})
		return
	
	var stop_shinespark = false
	match direction:
		Enums.dir.LEFT, Enums.dir.RIGHT: stop_shinespark = Samus.is_on_wall()
		Enums.dir.UP: stop_shinespark = Samus.is_on_ceiling()
		Enums.dir.DOWN: stop_shinespark = Samus.is_on_floor()
		Enums.dir.TOPLEFT, Enums.dir.TOPRIGHT: stop_shinespark = Samus.is_on_ceiling() or Samus.is_on_wall()
		Enums.dir.BOTLEFT, Enums.dir.BOTRIGHT: stop_shinespark = Samus.is_on_floor() or Samus.is_on_wall()
	
	if stop_shinespark:
		
		Global.shake(Samus.camera, Vector2(0, 0), 7, 0.25)
		
		Physics.vel = Vector2.ZERO
		Samus.boosting = false
		moving = false
		Animator.pause()
		yield(Global.wait(0.5), "completed")
		
		Animator.resume()
		Physics.apply_gravity = true

		if not ballspark:
			if direction == Enums.dir.DOWN:
				Animator.current[false].sprites[Samus.facing].flip_v = false
			yield(animations["end"].play(), "completed")
			change_state("jump", {"options": []})
		else:
			change_state("morphball", {"options": []})

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.change_state(new_state_key, data)

func physics_process(_delta: float):
	pass

func speedbooster_process(_delta: float):
	
	if Samus.boosting:
		var frames: SpriteFrames = Animator.current[false].sprites[Samus.facing].frames
		var texture: Texture = frames.get_frame( Animator.current[false].sprites[Samus.facing].animation, 0)
		
#		SpeedboosterArea.get_child(0).shape.extents = (texture.get_size() / 2) + Vector2(20, 5)
#		SpeedboosterArea.rotation = Samus.Physics.vel.angle()
#		SpeedboosterArea.global_position = Animator.current[false].sprites[Samus.facing].global_position
		if Samus.current_state.id == "run":
			ShinesparkStoreWindow.start(shinespark_store_window)
	
#	for raycast in SpeedboosterRaycasts:
#		if raycast != SpeedboosterRaycasts[2]:
#			raycast.enabled = Samus.boosting and not (ballspark or Samus.current_state.id == "morphball")
#		else:
#			raycast.enabled = Samus.boosting
#		var collider = raycast.get_collider()
#		if collider:
#			if collider.has_method("damage"):
#				collider.damage(damage_type, damage_amount)
	
#	if Samus.boosting:
#		SpeedboosterArea.monitoring = true
#		for body in SpeedboosterArea.get_overlapping_bodies():
#			if body.has_method("damage"):
#				body.damage(damage_type, damage_amount)
#	else:
#		SpeedboosterArea.monitoring = false

	if Samus.boosting or Samus.shinespark_charged:
		SpeedboostAnimationPlayer.play("speedboost")
	else:
		SpeedboostAnimationPlayer.play("reset")

func charge_shinespark():
	ShinesparkUseWindow.start(shinespark_hold_time)
	Samus.shinespark_charged = true
	
func discharge_shinespark():
	ShinesparkUseWindow.stop()
	Samus.shinespark_charged = false
