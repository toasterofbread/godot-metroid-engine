extends Node2D

const id: String = "visor"
var Samus: KinematicBody2D
var Animator: Node2D
var Physics: Node
var animations: Dictionary

const walk_acceleration = 15
const walk_deceleration = 50
const max_walk_speed = 75

var visor: Node2D

var enabled: bool = false
var angle: float = 90
const angle_move_speed: float = 1.0
var analog_visor: bool
onready var GhostAnchor: Node2D = Global.get_anchor("Samus/Visors/" + self.id)
var force_transition: bool = false

func _init(_Samus: KinematicBody2D):
	Samus = _Samus
	Animator = Samus.Animator
	Physics = Samus.Physics
	analog_visor = Settings.get("controls/analog_visor_control")
	animations = Animator.load_from_json(self.id)

func init_state(data: Dictionary):
	visor = Samus.Weapons.visors[Samus.Weapons.current_visor]

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Animator.resume()
	Samus.change_state(new_state_key, data)
	disable()


# Called every frame while the visor is enabled
func process(_delta: float):
	
	var play_transition: bool = false
	var original_facing: int = Samus.facing
	
	var visor = Samus.Weapons.cycle_visor()
	if not visor:
		change_state("neutral")
		return
	angle_process()
	
	if Settings.get("controls/zm_style_aiming"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if Input.is_action_just_pressed("morph_shortcut"):
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
	
	if Shortcut.get_pad_vector("pressed").x == 0:
		var shortcut_facing = Shortcut.get_facing("analog_visor")
		if shortcut_facing != null and shortcut_facing != Samus.facing:
			Samus.facing = shortcut_facing
			play_transition = true
	
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
	if analog_visor and enabled:
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

func physics_process(_delta: float):
	
	var pad_vector: float = Shortcut.get_pad_vector("pressed").x
	
	if pad_vector != 0:
		Physics.vel.x = Shortcut.add_to_limit(Physics.vel.x, walk_acceleration, max_walk_speed*pad_vector)
	else:
		Physics.vel.x = Shortcut.add_to_limit(Physics.vel.x, walk_deceleration, 0)

func angle_process():
	
	visor.process()
	if not analog_visor:
		
		if not Input.is_action_pressed("fire_weapon"):
			disable()
			return
		elif not enabled:
			enable()
			if Samus.facing == Enums.dir.LEFT:
				angle = -90
			else:
				angle = 90
		
		var pad_y = Shortcut.get_pad_vector("pressed").y
		if pad_y != 0:
			angle = min(180, max(0, angle + angle_move_speed * pad_y))
		
	else:
		var joystick_vector: Vector2 = Shortcut.get_joystick_vector("analog_visor")
		joystick_vector.y *= -1
		if joystick_vector == Vector2.ZERO:
			disable()
			return
		elif not enabled:
			enable()
			angle = rad2deg(joystick_vector.angle()) - 90
		
		angle = rad2deg(lerp_angle(deg2rad(angle), joystick_vector.angle() - deg2rad(90), angle_move_speed/35))
		
		var angle_vector = Vector2(0, -1).rotated(deg2rad(angle))
		if angle_vector.x < 0:
			if Samus.facing == Enums.dir.LEFT:
				turn(Enums.dir.RIGHT)
		elif angle_vector.x > 0:
			if Samus.facing == Enums.dir.RIGHT:
				turn(Enums.dir.LEFT)

func turn(direction: int):
	Samus.facing = direction
	force_transition = true

func enable():
	if enabled:
		return
	enabled = true
	visor.get_node("AnimationPlayer").play("enable_scanner")

func disable():
	if not enabled:
		return
	visor.get_node("AnimationPlayer").play("disable_scanner")
	yield(visor.get_node("AnimationPlayer"), "animation_finished")
	enabled = false

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
