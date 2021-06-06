tool
extends StaticBody2D
class_name DestroyableBlock

onready var Samus: KinematicBody2D = Loader.Samus

export(Enums.DamageType) var type = Enums.DamageType.BEAM setget set_type
export var reappear_time: float = 2.5
export var overlay: Texture setget set_overlay
export var show_overlay_in_editor: bool = false setget set_show_overlay_in_editor
onready var default_collision_layer = self.collision_layer
onready var destructive_damage_types: Array = Enums.DamageType.values()
onready var sprite_name: String = Enums.DamageType.keys()[type].to_lower()

var samus_hitbox_damage_applies = false

enum STATES {NORMAL, DESTROYED, COLLISIONDISABLED}
var state: int = STATES.NORMAL

func set_show_overlay_in_editor(value: bool):
	$Overlay.visible = value
	show_overlay_in_editor = value

func set_type(value: int):
	if Engine.editor_hint:
		$AnimatedSprite.play(Enums.DamageType.keys()[value].to_lower())
	type = value

func set_overlay(value: Texture):
	if value != null:
		$Overlay.texture = value
	overlay = value

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if Engine.editor_hint:
		return
	
	set_overlay(overlay)
	$Overlay.visible = true
	$Overlay.modulate.a = 1

	if type == Enums.DamageType.CRUMBLE:
		reappear_time = 0.5
	else:
		$CrumbleArea.queue_free()
	
	match type:
		Enums.DamageType.BEAM: destructive_damage_types.erase(Enums.DamageType.NONE)
		Enums.DamageType.BOMB: destructive_damage_types = [Enums.DamageType.BOMB, Enums.DamageType.POWERBOMB, Enums.DamageType.SPEEDBOOSTER]
		Enums.DamageType.MISSILE: destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
		_: destructive_damage_types = [type]
	
	if Enums.DamageType.SPEEDBOOSTER in destructive_damage_types or Enums.DamageType.SCREWATTACK in destructive_damage_types:
		samus_hitbox_damage_applies = true
	
	$WeaponCollisionArea.connect("body_entered", self, "body_entered_area")
	$AnimatedSprite.play(sprite_name)
	
	$ScanNode.data_key = "block_" + sprite_name
	
	z_index = Enums.Layers.BLOCK
	z_as_relative = false

#func set_reverse(value, property: String):
#	set(property, value)

func damage(type: int, _value: float):
	if type in destructive_damage_types:
		destroy()

func get_disable() -> bool:
	for type in Samus.self_damage:
		if type in destructive_damage_types:
			return true
	return false

func _process(_delta: float):
	
	if Engine.editor_hint or not samus_hitbox_damage_applies:
		return
	
	var disable = get_disable()
	
	if disable:
#		$VisibilityEnabler2D.process_parent = false
		self.set_collision_layer_bit(19, false)
		state = STATES.COLLISIONDISABLED
	elif state == STATES.COLLISIONDISABLED and not disable:
#		$VisibilityEnabler2D.process_parent = true
		self.set_collision_layer_bit(19 , true)
		state = STATES.NORMAL
			

func body_entered_area(body):
	if body == Samus:
		if get_disable():
			destroy()

func destroy(time: float = reappear_time):
	state = STATES.DESTROYED
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
		$ReappearTimer.start(time)
	else:
		self.queue_free()

func reappear():
	state = STATES.NORMAL
	self.visible = true
	$AnimatedSprite.play("reappear")
	yield($AnimatedSprite, "animation_finished")
	
	$WeaponCollisionArea/CollisionShape2D.set_deferred("disabled", false)
	yield(get_tree(), "idle_frame")
	yield(Global, "physics_frame")
	
	for body in $WeaponCollisionArea.get_overlapping_bodies():
		if body.get_collision_layer_bit(0) or body.get_collision_layer_bit(2):
			destroy(0.5)
			return
	
	if type == Enums.DamageType.CRUMBLE:
		$CrumbleArea/CollisionShape2D.set_deferred("disabled", false)
		$WeaponCollisionArea/CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", false)
	$AnimatedSprite.play(sprite_name)


func _on_CrumbleArea_body_entered(_body):
	destroy()
