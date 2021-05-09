extends Node

var Samus: KinematicBody2D
var Animator: Node2D
var Physics: Node
const id = "powergrip"

var attach_point: Vector2
var animations: Dictionary

var climbing: bool = false

var direction = {
	true: "", # Toward wall
	false: "" # Away from wall
}

func _init(_Samus: KinematicBody2D):
	self.Samus = _Samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.animations = Animator.load_from_json(self.id)

func init_state(data: Dictionary):
	
	if Samus.facing == Enums.dir.LEFT:
		direction = {
			true: "pad_left",
			false: "pad_right"
		}
	else:
		direction = {
			true: "pad_right",
			false: "pad_left"
		}
	
	climbing = false
	attach_point = data["point"]
	Samus.global_position.y = attach_point.y + 19
	Samus.Physics.apply_velocity = false
	Samus.Physics.vel = Vector2.ZERO
	if Samus.aiming == Samus.aim.FRONT:
		Samus.aiming = Samus.aim.NONE

func change_state(new_state_key: String, data: Dictionary = {}):
	Physics.vel = Vector2.ZERO
	Physics.apply_velocity = true
	Samus.change_state(new_state_key, data)

func process(_delta):
	
	var original_aiming = Samus.aiming
	
	if Settings.get("controls/zm_style_aiming"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed(direction[true]): 
			climbing = true
			if Samus.facing == Enums.dir.LEFT:
				Animator.Player.play("powergrip_climb_left")
			else:
				Animator.Player.play("powergrip_climb_right")
			
			var MorphballRaycast: RayCast2D = Animator.raycasts.get_node("MorphballCeiling")
			MorphballRaycast.enabled = true
			var CrouchRaycast: RayCast2D = Animator.raycasts.get_node("CrouchCeiling")
			var crouch_offset = 5
			CrouchRaycast.enabled = true
			CrouchRaycast.cast_to.y -= crouch_offset
			yield(Animator.Player, "animation_finished")
			
			# Check the space available to see if Samus should morph
			if MorphballRaycast.is_colliding():
				CrouchRaycast.enabled = false
				change_state("morphball", {"options": ["animate"]})
				return
			MorphballRaycast.enabled = false
			
			# Check the space available to see if Samus should crouch
			if CrouchRaycast.is_colliding():
				CrouchRaycast.cast_to.y += crouch_offset
				change_state("crouch")
				return
			CrouchRaycast.enabled = false
			CrouchRaycast.cast_to.y += crouch_offset
			
			if Input.is_action_pressed("pad_left"):
				Samus.facing = Enums.dir.LEFT
				change_state("run", {"boost": false})
			elif Input.is_action_pressed("pad_right"):
				Samus.facing = Enums.dir.RIGHT
				change_state("run", {"boost": false})
			else:
				change_state("neutral")
			return
		
		else:
			var options = []
			if Input.is_action_pressed(direction[false]):
				options = ["jump", "spin"]
			elif Input.is_action_pressed("pad_down"):
				options = ["fall"]
			else:
				options = ["jump"]
			change_state("jump", {"options": options})
		return
	elif Input.is_action_just_pressed("fire_weapon"):
		Samus.Weapons.fire()

	if Input.is_action_pressed("aim_weapon"):
		
		if Input.is_action_just_pressed("aim_weapon") or Input.is_action_just_pressed(direction[false]):
			Samus.aiming = Samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			Samus.aiming = Samus.aim.DOWN
		
	elif Input.is_action_pressed(direction[true]):
		Samus.aiming = Samus.aim.NONE
	elif Input.is_action_pressed(direction[false]):
		
		if Input.is_action_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
		elif Input.is_action_pressed("pad_down"):
			Samus.aiming = Samus.aim.DOWN
		else:
			Samus.aiming = Samus.aim.FRONT
		
	elif Input.is_action_pressed("pad_up"):
		Samus.aiming = Samus.aim.SKY
	elif Input.is_action_pressed("pad_down"):
		Samus.aiming = Samus.aim.FLOOR
	else:
		if Samus.aiming == Samus.aim.UP or Samus.aiming == Samus.aim.DOWN:
			Samus.aiming = Samus.aim.FRONT
	
	if (original_aiming == Samus.aim.NONE or Samus.aiming == Samus.aim.NONE) and original_aiming != Samus.aiming:
		animations["turn"].play()
	elif not Animator.transitioning(false, true):
		
		var animation: String
		match Samus.aiming:
			Samus.aim.NONE: animation = "aim_none"
			Samus.aim.SKY: animation = "aim_sky"
			Samus.aim.UP: animation = "aim_up"
			Samus.aim.FRONT: animation = "aim_front"
			Samus.aim.DOWN: animation = "aim_down"
			Samus.aim.FLOOR: animation = "aim_floor"
		
		animations[animation].play(true)

func physics_process(_delta: float):
	if not climbing:
		if Samus.facing == Enums.dir.LEFT:
			Samus.move_and_collide(Vector2(-10, 0))
		else:
			Samus.move_and_collide(Vector2(10, 0))
