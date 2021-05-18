extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

const id = "grapple"
var animations: = {}

var beam: Node2D
var anchor: Node2D

var SpeedboostTimer: Timer = Global.timer([self, "speedboost", []])
var speedboost_charge_time: float
var previous_angle: = 0.0

# PHYSICS
const max_angular_velocity = 0.12
const max_speedboost_angular_velocity = 0.25
var angular_velocity: = 0.0
var angular_acceleration: = 0.0
var linear_velocity = Vector2.ZERO
const gravity = 0.4*30
const damping = 0.998
const speedboost_damping = 1.0
var angle

# Called during Samus's readying period
func _init(_samus: KinematicBody2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	yield(Samus, "ready")
	speedboost_charge_time = Samus.states["run"].speedboost_charge_time*1.25
	
	self.animations = Animator.load_from_json("neutral")

# Called every frame while this state is active
func process(_delta):
	
	var original_facing = Samus.facing
	var play_transition = false
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
	
	if not Input.is_action_pressed("fire_weapon"):
		
		Samus.aiming = Samus.aim.FRONT
		if Input.is_action_pressed("pad_left"):
			Samus.facing = Enums.dir.LEFT
		elif Input.is_action_pressed("pad_right"):
			Samus.facing = Enums.dir.RIGHT
		
		change_state("jump", {"options": ["spin"] if Samus.boosting else ["fall"]})
		return
	
	if Input.is_action_just_pressed("morph_shortcut"):
		change_state("morphball", {"options": ["animate"]})
		return
	
#	animations["aim_sky"].play(true)
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.change_state(new_state_key, data)
	if beam:
		beam.queue_free()
	beam = null
	anchor = null
	SpeedboostTimer.stop()
	
	Samus.rotation = 0
	Physics.vel = linear_velocity * (40 if Samus.boosting else 30)
	Physics.apply_velocity = true

# Called when Samus's state changes to this one
func init_state(data: Dictionary):
	anchor = data["anchor"]
	beam = data["beam"]
	previous_angle = 0.0
	Physics.apply_velocity = false
	
	angle = anchor.global_position.angle_to_point(beam.global_position) - deg2rad(90)
	
	angle = (Vector2.LEFT.rotated(angle) * Vector2(1, -1)).angle()
	
	angular_velocity = 0.0
	angular_acceleration = 0.0

func physics_process(delta: float):
	
	var pad_vector = Shortcut.get_pad_vector("pressed")
	beam.length += pad_vector.y*2
	
	vOverlay.SET("beam.length", beam.length)
	
	angular_velocity += pad_vector.x*0.0005
	
	angular_acceleration = ((-gravity*delta) / beam.length) * sin(angle)
	angular_velocity += angular_acceleration
	angular_velocity *= speedboost_damping if Samus.boosting else damping
	angle += angular_velocity
	
	Samus.rotation = (Vector2.LEFT.rotated(angle) * Vector2(-1, 1)).angle()
	
	var max_velocity = max_speedboost_angular_velocity if Samus.boosting else max_angular_velocity
	angular_velocity = min(max(angular_velocity, -max_velocity), max_velocity)
	
	if Samus.is_upgrade_active(Enums.Upgrade.SPEEDBOOSTER) and (abs(angular_velocity) < 0.04 or pad_vector.x != sign(angular_velocity)):
		SpeedboostTimer.start(speedboost_charge_time)
		Samus.boosting = false
	
	linear_velocity = anchor.global_position + Vector2(beam.length*sin(angle), beam.length*cos(angle)) - beam.global_position #Samus.global_position - Samus.to_local(beam.global_position)
	var collision = Samus.move_and_collide(linear_velocity)
	if collision:
		if collision.normal == Vector2.UP:
			change_state("neutral")

func speedboost():
	Samus.boosting = true
