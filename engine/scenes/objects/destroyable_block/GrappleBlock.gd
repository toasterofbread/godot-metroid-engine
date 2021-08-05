extends StaticBody2D

onready var Samus: KinematicBody2D = Loader.Samus

export var crumble_reappear_time: float = 2.5
export var show_overlay_in_editor: bool = false setget set_show_overlay_in_editor
onready var default_collision_layer = self.collision_layer

enum STATES {NORMAL, DESTROYED, COLLISIONDISABLED}
var state: int = STATES.NORMAL

func set_show_overlay_in_editor(value: bool):
	$Overlay.visible = value
	show_overlay_in_editor = value

func _ready():
	z_index = Enums.Layers.BLOCK
	z_as_relative = false

func _destroy(time: float = crumble_reappear_time):
	state = STATES.DESTROYED
	$Overlay.visible = false
	$WeaponCollisionArea/CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	
	$AnimatedSprite.play("destroy")
	yield($AnimatedSprite, "animation_finished")
	self.visible = false
	
	if time > 0:
		$ReappearTimer.start(time)
	else:
		self.queue_free()

func _reappear():
	state = STATES.NORMAL
	self.visible = true
	$AnimatedSprite.play("reappear")
	yield($AnimatedSprite, "animation_finished")
	$WeaponCollisionArea/CollisionShape2D.set_deferred("disabled", false)
	if len($WeaponCollisionArea.get_overlapping_bodies()) != 0:
		_destroy(0.5)
	else:
		$CollisionShape2D.set_deferred("disabled", false)
		$AnimatedSprite.play("grapple")

func attach_grapple():
	return $Anchor
