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
#	Samus.global_position.x = attach_point.x
	Samus.Physics.apply_velocity = false
	if Samus.aiming == Samus.aim.FRONT:
		Samus.aiming = Samus.aim.NONE

func change_state(new_state_key: String, data: Dictionary = {}):
	Physics.apply_velocity = true
	Samus.change_state(new_state_key, data)

func process(_delta):
	
	Physics.vel = Vector2.ZERO
	
	if climbing:
		return
	
	var original_aiming = Samus.aiming
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Input.is_action_just_pressed("morph_shortcut") and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"]})
		return
	elif Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed(direction[true]): 
			climbing = true
			if Samus.facing == Enums.dir.LEFT:
				Animator.Player.play("powergrip_climb_left")
			else:
				Animator.Player.play("powergrip_climb_right")
			
			var MorphballRaycast: RayCast2D = Animator.raycasts.get_node("morphball/Ceiling")
			MorphballRaycast.enabled = true
			var CrouchRaycast: RayCast2D = Animator.raycasts.get_node("crouch/Ceiling")
			var crouch_offset = 5
			CrouchRaycast.enabled = true
			CrouchRaycast.cast_to.y -= crouch_offset
			yield(Animator.Player, "animation_finished")
			
			# TODO | Disable powergrip climb if there's no space to crouch and not Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL)
			# Check the space available to see if Samus should morph
			if MorphballRaycast.is_colliding() and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
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
				change_state("neutral", {"from_powergrip": true})
#				Samus.global_position.y -= 8
#				change_state("neutral")
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
	
	# Aim shortcut
	if not Input.is_action_pressed("secondary_" + direction[true]):
		var new_aiming = Shortcut.get_aiming(Samus, true)
		if new_aiming != null:
			Samus.aiming = new_aiming
		elif Input.is_action_just_released("secondary_" + direction[false]) or Input.is_action_just_released("secondary_pad_down") or Input.is_action_just_released("secondary_pad_up"):
			Samus.aiming = Samus.aim.NONE
	
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
	if not climbing and Samus.move_and_collide(Vector2(1 if Samus.facing == Enums.dir.RIGHT else -1, 0), true, true, true) == null:
		Samus.move_and_collide(Vector2(1 if Samus.facing == Enums.dir.RIGHT else -1, 0))
