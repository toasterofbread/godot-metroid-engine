extends Node2D

const id: String = "visor"
var Samus: KinematicBody2D
var Weapons: Node2D
var Animator: Node2D
var Physics: Node
var animations: Dictionary

const walk_acceleration = 15
const walk_deceleration = 50
const max_walk_speed = 75

onready var scanner: Node2D = $Scanner

var enabled: bool = false
var angle: float = 90
var movement_speed_multiplier: = 1.0
var scanner_scale_multiplier = Vector2(1, 1)
var offset_buffer = [null, 0, false]
const angle_move_speed: float = 1.0
var analog_visor: bool
onready var GhostAnchor: Node2D = Global.get_anchor("Samus/Visors/" + self.id)
var force_transition: bool = false
var fire_pos = null

func _ready():
	$Scanner.visible = false
	Samus = Loader.Samus
	yield(Samus, "ready")
	Animator = Samus.Animator
	Physics = Samus.Physics
	Weapons = Samus.Weapons
	animations = Animator.load_from_json(self.id)
	Samus.Weapons.connect("visor_mode_changed", self, "visor_mode_changed")

func init_state(_data:={}):
	movement_speed_multiplier = 1
	if Weapons.current_visor != null:
		
#		var mask: int = 0
#		match Weapons.current_visor.id:
#			Enums.Upgrade.XRAYVISOR: mask = 2
#			Enums.Upgrade.SCANVISOR: mask = 8
		
		for light in $Scanner/Lights.get_children():
			light.visible = light.name == str(Weapons.current_visor.id)
		
		if not $CanvasLayer/TintOverlay.visible:
			$CanvasLayer/TintOverlay.visible = true
			$CanvasLayer/Tween.interpolate_property(
				$CanvasLayer/TintOverlay,
				"modulate:a",
				0,
				1,
				0.5
			)
			$CanvasLayer/TintOverlay.color = Weapons.current_visor.background_tint
		else:
			$CanvasLayer/Tween.interpolate_property(
				$CanvasLayer/TintOverlay, 
				"color", 
				$CanvasLayer/TintOverlay.color, 
				Weapons.current_visor.background_tint,
				0.5
			)
		$CanvasLayer/Tween.start()
		
	elif $CanvasLayer/TintOverlay.visible:
		$CanvasLayer/Tween.interpolate_property(
			$CanvasLayer/TintOverlay, 
			"modulate:a", 
			1, 
			0,
			0.5
		)
		$CanvasLayer/Tween.start()
		yield($CanvasLayer/Tween, "tween_completed")
		$CanvasLayer/TintOverlay.visible = false


# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Animator.resume()
	Samus.change_state(new_state_key, data)
	disable()


# Called every frame while the visor is enabled
func process(delta: float):
	
	var play_transition: bool = false
	var original_facing: int = Samus.facing
	
	if not Samus.Weapons.cycle_visor():
		change_state("neutral")
		init_state()
		return
	
	if Weapons.current_visor != null:
		Weapons.current_visor.process(delta)
	
	scanner.get_node("Lights").scale.x = scanner_scale_multiplier.x
	scanner.get_node("Lights").scale.y = scanner.get_node("Lights").scale.x * scanner_scale_multiplier.y
	
	if fire_pos:
		fire_pos.queue_free()
	fire_pos = get_emit_pos()
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(false)
	
	if Input.is_action_just_pressed("morph_shortcut") and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"]})
		return
	elif Input.is_action_just_pressed("jump"):
		if Physics.vel.x != 0 or Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
			change_state("jump", {"options": ["jump", "spin"]})
		else:
			if Samus.shinespark_charged:
				change_state("shinespark", {"ballspark": false})
				return
			else:
				change_state("jump", {"options": ["jump"]})
		return
	elif not Samus.is_on_floor():
		change_state("jump", {"options": ["fall"]})
		return
	elif Input.is_action_just_pressed("pause"):
		Animator.Player.play("neutral_open_map_left")

	if not Animator.transitioning() and not enabled:
		
		if Input.is_action_pressed("pad_left"):
			Samus.facing = Enums.dir.LEFT
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
		elif Input.is_action_pressed("pad_right"):
			Samus.facing = Enums.dir.RIGHT
			if original_facing == Enums.dir.LEFT:
				play_transition = true
	
	Samus.aiming = get_aim_direction()
	
	var animation: String
	match Samus.aiming:
		Samus.aim.SKY: animation = "aim_sky"
		Samus.aim.UP: animation = "aim_up"
		Samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	var reverse: bool = false
	if enabled:
		var pad_vector: float = Shortcut.get_pad_vector("pressed").x
		if pad_vector != 0:
			reverse = (pad_vector == 1 and Samus.facing == Enums.dir.LEFT) or (pad_vector == -1 and Samus.facing == Enums.dir.RIGHT)
	
	if play_transition or force_transition:
		force_transition = false
		Samus.states["run"].animations["turn_" + animation].play(false, false, true)
		Samus.states["run"].animations["turn_legs"].play(false, false, true)
	elif not Animator.transitioning(false, true):
		if abs(Physics.vel.x) < 0.1 or Samus.is_on_wall():
			Samus.states["neutral"].animations[animation].play(true)
		else:
			animations[animation].play(true, false, false, reverse)

func physics_process(delta: float):
	
	if Weapons.current_visor != null:
		Weapons.current_visor.physics_process(delta)
	
	angle_process()
	
	var pad_vector: float = Shortcut.get_pad_vector("pressed").x
	
	if pad_vector != 0:
		Physics.vel.x = move_toward(Physics.vel.x, max_walk_speed*pad_vector, walk_acceleration)
	else:
		Physics.vel.x = move_toward(Physics.vel.x, 0, walk_deceleration)

func angle_process():
	
	if fire_pos:
		scanner.global_position = fire_pos.global_position
	
	if not enabled:
		if Input.is_action_pressed("fire_weapon"):
			enable()
			analog_visor = false
			angle = 90
		else:
			var joystick_vector = Shortcut.get_joystick_vector("analog_visor")
			if joystick_vector != Vector2.ZERO:
				enable()
				analog_visor = true
				joystick_vector.y *= -1
				angle = rad2deg(joystick_vector.angle()) - 90
			else:
				return
	
	if not analog_visor:
		
		if not Input.is_action_pressed("fire_weapon"):
			disable()
			return
		
		var pad_y = Shortcut.get_pad_vector("pressed").y
		if pad_y != 0:
			angle = min(180, max(0, angle + angle_move_speed * pad_y * movement_speed_multiplier))
#		elif fire_pos:
#			angle = lerp_angle(angle, rad2deg((Vector2.UP.rotated(fire_pos.global_position.angle_to_point(lock_target.get_global_position())) * Vector2(1, -1)).angle()) + lock_target_offset, 0.25)
		
		if Input.is_action_just_pressed("arm_weapon"):
			turn(Enums.dir.RIGHT)
		elif Input.is_action_just_pressed("aim_weapon"):
			turn(Enums.dir.LEFT)
		
		if Samus.facing == Enums.dir.LEFT:
			scanner.rotation_degrees = -angle - 90
		else:
			scanner.rotation_degrees = angle - 90
		
	else:
		var joystick_vector: Vector2 = Shortcut.get_joystick_vector("analog_visor")
		joystick_vector.y *= -1
		if joystick_vector == Vector2.ZERO:
			disable()
			return
		
#		if not lock_target:
		angle = rad2deg(lerp_angle(deg2rad(angle), joystick_vector.angle() - deg2rad(90), angle_move_speed/35*movement_speed_multiplier))
#		elif fire_pos:
#			angle = lerp_angle(angle, rad2deg((Vector2.UP.rotated(fire_pos.global_position.angle_to_point(lock_target.get_global_position())) * Vector2(1, -1)).angle()) + lock_target_offset, 0.25)
		
		var ang = rad2deg(Vector2(1, 0).rotated(deg2rad(angle)).angle())
		
		if ang <= 0:
			turn(Enums.dir.RIGHT)
		elif ang > 0:
			turn(Enums.dir.LEFT)
		
		scanner.rotation_degrees = -angle - 90
		

func turn(direction: int):
	if direction == Samus.facing or Animator.transitioning():
		return
	Samus.facing = direction
	force_transition = true

func enable():
	if enabled:
		return
	enabled = true
	$AnimationPlayer.play("enable_scanner")

func disable():
	if not enabled:
		return
	$AnimationPlayer.play("disable_scanner")
	yield($AnimationPlayer, "animation_finished")
	enabled = false
	movement_speed_multiplier = 1

func get_emit_pos():
	var pos: Position2D = Samus.Weapons.VisorPositions.get_node_or_null(Samus.Animator.current[false].position_node_path)
	if pos == null:
		return null
	pos = pos.duplicate()
	Samus.add_child(pos)
	
	if Samus.facing == Enums.dir.RIGHT:
		pos.position.x  = pos.position.x * -1 + 8
	
	# For some reason the default global_position is the same as the relative position
	pos.global_position = Samus.global_position + pos.position
	
	return pos

func get_aim_direction():
	
	if not enabled:
		return Samus.aim.FRONT
	
	var ang: float = abs(rad2deg(Vector2(1, 0).rotated(deg2rad(angle)).angle()))
	
	if ang < 30:
		return Samus.aim.SKY
	elif ang < 65:
		return Samus.aim.UP
	elif ang < 115:
		return Samus.aim.FRONT
	else:
		return Samus.aim.DOWN

func visor_process():
	if fire_pos:
		scanner.global_position = fire_pos.global_position
	
	if not analog_visor:
		if Samus.facing == Enums.dir.LEFT:
			scanner.rotation_degrees = -angle - 90
		else:
			scanner.rotation_degrees = angle - 90
			
	else:
		scanner.rotation_degrees = -angle - 90

func visor_mode_changed(mode):
	if mode != null:
		init_state()


func _on_Area2D_area_exited(area):
	if Samus.current_state == self and Weapons.current_visor:
		Weapons.current_visor._on_Area2D_area_exited(area)


func _on_Area2D_area_entered(area):
	if Samus.current_state == self and Weapons.current_visor:
		Weapons.current_visor._on_Area2D_area_entered(area)
