tool
extends StaticBody2D
class_name DestroyableBlock

export(Enums.DamageType) var type = Enums.DamageType.BEAM setget set_type
export var respawn_time: float = 2.5
export var overlay: Texture setget set_overlay
var RespawnTimer: Timer
onready var default_collision_layer = self.collision_layer
onready var destructive_damage_types: Array = Enums.DamageType.values()
onready var sprite_name: String = Enums.DamageType.keys()[type].to_lower()

var boosting: bool = false

func set_type(value: int):
	if Engine.is_editor_hint():
		$AnimatedSprite.play(Enums.DamageType.keys()[value].to_lower())
	type = value

func set_overlay(value: Texture):
	if value != null:
		$Overlay.texture = value
	overlay = value

# Called when the node enters the scene tree for the first time.
func _ready():
	
	$AnimationPlayer.play("fade")
	
	if Engine.is_editor_hint():
		return
	
	set_overlay(overlay)
	$AnimationPlayer.queue_free()
	$Overlay.modulate.a = 1
	RespawnTimer = Global.timer([self, "_reappear", []])

	if type == Enums.DamageType.CRUMBLE:
		respawn_time = 0.5
		$WeaponCollisionArea.queue_free()
	else:
		$CrumbleArea.queue_free()
	
	match type:
		Enums.DamageType.BEAM: destructive_damage_types.erase(Enums.DamageType.NONE)
		Enums.DamageType.BOMB: destructive_damage_types = [Enums.DamageType.BOMB, Enums.DamageType.POWERBOMB, Enums.DamageType.SPEEDBOOSTER]
		Enums.DamageType.MISSILE: destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
		_: destructive_damage_types = [type]
	
	if Enums.DamageType.SPEEDBOOSTER in destructive_damage_types:
		Loader.Samus.connect("boost_changed", self, "boost_changed")
		$SamusCheckArea.connect("body_entered", self, "body_entered_area")
	
	$AnimatedSprite.play(sprite_name)

func damage(type: int, _value: float):
	if type in destructive_damage_types:
		_destroy()

func boost_changed(value: bool):
	$CollisionShape2D.disabled = value
	boosting = value

func body_entered_area(body):
	if body == Loader.Samus and boosting:
		self._destroy()

func _destroy(time: float = respawn_time):
	$Overlay.visible = false
	if type == Enums.DamageType.CRUMBLE:
		$CrumbleArea/CollisionShape2D.set_deferred("disabled", true)
	else:
		$WeaponCollisionArea/CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	
	$AnimatedSprite.play("destroy")
	yield($AnimatedSprite, "animation_finished")
	self.visible = false
	
	if time > 0:
		RespawnTimer.start(time)

func _reappear():
	self.visible = true
	
	$AnimatedSprite.play("reappear")
	yield($AnimatedSprite, "animation_finished")
	if len($SamusCheckArea.get_overlapping_bodies()) != 0:
		_destroy(0.5)
	else:
		if type == Enums.DamageType.CRUMBLE:
			$CrumbleArea/CollisionShape2D.set_deferred("disabled", false)
		else:
			$WeaponCollisionArea/CollisionShape2D.set_deferred("disabled", false)
		$CollisionShape2D.disabled = false
		$AnimatedSprite.play(Enums.DamageType.keys()[type].to_lower())


func _on_CrumbleArea_body_entered(_body):
	_destroy()
