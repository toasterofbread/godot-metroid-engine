extends StaticBody2D
class_name DestroyableBlock

export(Enums.DamageType) var type = Enums.DamageType.BEAM
export var sandy: bool = false
export var respawn_time: float = 2.5
onready var RespawnTimer: Timer = Global.timer([self, "reappear", []])
onready var default_collision_layer = self.collision_layer
onready var destructive_damage_types: Array = Enums.DamageType.values()
onready var sprite_name: String = Enums.DamageType.keys()[type].to_lower()

# Called when the node enters the scene tree for the first time.
func _ready():
	
#	self.add_to_group(Groups.immune_to_projectiles)
	
	if sandy:
		if type == Enums.DamageType.BEAM:
			sprite_name = "sand"
		else:
			push_warning("DestroyableBlock is not set to BEAM even though sandy is enabled")
	
	match type:
		Enums.DamageType.BEAM: destructive_damage_types.erase(Enums.DamageType.NONE)
		Enums.DamageType.BOMB: destructive_damage_types = [Enums.DamageType.BOMB, Enums.DamageType.POWERBOMB, Enums.DamageType.SPEEDBOOSTER]
		Enums.DamageType.MISSILE: destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
		_: destructive_damage_types = [type]
	
	$AnimatedSprite.play(sprite_name)

func collide(collision_object):
	var damage_type = collision_object.get("damage_type")
	if not collision_object.is_in_group(Groups.damages_world) or damage_type == null or self.is_in_group(Groups.immune_to_projectiles):
		return
	
	if damage_type in destructive_damage_types:
		destroy()

func destroy():
	self.collision_layer = 0
	$WeaponCollider.set_deferred("monitorable", false)
	
	$AnimatedSprite.play("destroy")
	yield($AnimatedSprite, "animation_finished")
	self.visible = false
	RespawnTimer.start(respawn_time)

func reappear():
	self.visible = true
	
	$AnimatedSprite.play("destroy", true)
	while $AnimatedSprite.frame != 0:
		yield(Global, "process_frame")
	$AnimatedSprite.play(Enums.DamageType.keys()[type].to_lower())
	
	self.collision_layer = default_collision_layer
	$WeaponCollider.monitorable = true
