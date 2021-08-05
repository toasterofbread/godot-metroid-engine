extends SamusState

var Weapons: Node2D
var Animator: Node2D
var Physics: Node
var animations: Dictionary

const walk_acceleration = 15
const walk_deceleration = 50
const max_walk_speed = 75

var node: Node2D
var scanner: Node2D

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

func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	node = Weapons.get_node("VisorNode")
	scanner = node.get_node("Scanner")
	scanner.visible = false
	Weapons.connect("visor_mode_changed", self, "visor_mode_changed")
	scanner.get_node("Area2D").connect("area_entered", self, "_on_Area2D_area_entered")
	scanner.get_node("Area2D").connect("area_exited", self, "_on_Area2D_area_exited")

func init_state(_data: Dictionary, _previous_state_id: String):
	movement_speed_multiplier = 1
	var tintOverlay: ColorRect = node.get_node("CanvasLayer/TintOverlay")
	var tween: Tween = node.get_node("CanvasLayer/Tween")
	if Weapons.current_visor != null:
		
		for light in scanner.get_node("Lights").get_children():
			light.visible = light.name == str(Weapons.current_visor.id)
		
		if not tintOverlay.visible:
			tintOverlay.visible = true
			tween.interpolate_property(
				tintOverlay,
				"modulate:a",
				0,
				1,
				0.5
			)
			tintOverlay.color = Weapons.current_visor.background_tint
		else:
			node.get_node("CanvasLayer/Tween").interpolate_property(
				tintOverlay, 
				"color", 
				tintOverlay.color, 
				Weapons.current_visor.background_tint,
				0.5
			)
		tween.start()
		
	elif tintOverlay.visible:
		tween.interpolate_property(
			tintOverlay, 
			"modulate:a", 
			1, 
			0,
			0.5
		)
		tween.start()
		yield(tween, "tween_completed")
		tintOverlay.visible = false
	
	return true

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Animator.resume()
	disable()
	.change_state(new_state_key, data)

# Called every frame while the visor is enabled
func process(delta: float):
	
	var play_transition: bool = false
	var original_facing: int = Samus.facing
	
	if not Samus.Weapons.cycle_visor():
		change_state("neutral")
		init_state({}, "")
		return
	
#	if Weapons.current_visor != null:
#		Weapons.current_visor._process(delta)
	
	scanner.get_node("Lights").scale.x = scanner_scale_multiplier.x
	scanner.get_node("Lights").scale.y = scanner.get_node("Lights").scale.x * scanner_scale_multiplier.y
	
	if fire_pos:
		fire_pos.queue_free()
	fire_pos = get_emit_pos()
	
	if Settings.get("control_options/aiming_style") == 0:
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
		Samus.states["run"].animations["turn_" + animation].play()
		Samus.states["run"].animations["turn_legs"].play()
	elif not Animator.transitioning(false, true):
		if abs(Physics.vel.x) < 0.1 or Samus.is_on_wall():
			Samus.states["neutral"].animations[animation].play(true)
		else:
			animations[animation].play(true, -1 if reverse else 1)

func physics_process(delta: float):
	
#	if Weapons.current_visor != null:
#		Weapons.current_visor._physics_process(delta)
	
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
	if Weapons.current_visor:
		Weapons.current_visor.enabled()
	node.get_node("AnimationPlayer").play("enable_scanner")

func disable():
	if not enabled:
		return
	enabled = false
	if Weapons.current_visor:
		Weapons.current_visor.disabled()
	node.get_node("AnimationPlayer").play("disable_scanner")
	yield(node.get_node("AnimationPlayer"), "animation_finished")
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
		init_state({}, "")


func _on_Area2D_area_exited(area):
	if Samus.current_state == self and Weapons.current_visor:
		Weapons.current_visor._on_Area2D_area_exited(area)


func _on_Area2D_area_entered(area):
	if Samus.current_state == self and Weapons.current_visor:
		Weapons.current_visor._on_Area2D_area_entered(area)
