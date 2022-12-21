extends Node2D

const READY_TIME: float = 0.5
const FIRE_DELAY: float = 0.75
const SPEED: float = 400.0
const ACCELERATION: float = 50.0

var direction: int = 0
var speed: float = 0.0

func _ready():
	visible = false
	set_physics_process(false)
	setInvisiblePercent(1.0)

func _physics_process(delta: float):
	speed = move_toward(speed, SPEED * direction, delta * ACCELERATION * 60.0)
	position.x += speed * delta

func setInvisiblePercent(value: float):
	material.set_shader_param("invisible_percent", value)

func spawn(target_position: Vector2, reverse: bool = false):
	var mod = -1 if reverse else 1
	material.set_shader_param("invert", reverse)
	global_position = target_position - Vector2(40 * mod, 0)
	visible = true
	
	var tween: Tween = $MovementTween
	tween.interpolate_property(self, "position:x", position.x, position.x + 40 * mod, 0.5, Tween.TRANS_SINE)
	tween.interpolate_method(self, "setInvisiblePercent", 1.0, 0.25, 0.5, Tween.TRANS_SINE)
	tween.start()
	yield(tween, "tween_completed")
	
	yield(Global.wait(FIRE_DELAY), "completed")
	
	Global.reparent_child(self, Global.get_anchor("kraid_spikes"))
	
	tween.interpolate_method(self, "setInvisiblePercent", 0.25, 0.0, 0.075, Tween.TRANS_SINE)
	tween.start()
	
	direction = mod
	set_physics_process(true)

func onDamageAreaBodyEntered(body: Node):
	if direction != 0:
		Global.damage(body, Enums.DamageType.SPIKE, 10, $DamageArea/CollisionShape2D.global_position)
