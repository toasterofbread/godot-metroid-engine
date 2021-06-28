extends SamusWeapon

const bomb_detonation_time: float = 0.6
const bomb_bounce_amount: float = 325.0
const bomb_horiz_bounce_amount: float = 200.0
const samus_aerial_damage: int = 10

func _ready():
	pass

func fired(projectile: SamusKinematicProjectile):
	var sprite: AnimatedSprite = projectile.get_node("Sprite")
	sprite.play("default")
	yield(sprite, "animation_finished")
	sprite.queue_free()
	
	var player: AnimationPlayer = projectile.get_node("AnimationPlayer")
	player.play("explode")
	
	var area: Area2D = projectile.get_node("Explosion")
	var processed_bodies = []
	
	while player.current_animation != "":
		for body in area.get_overlapping_bodies():
			
			if body in processed_bodies:
				continue
			processed_bodies.append(body)
			
			if body != Loader.Samus:
				if body.has_method("damage"):
					body.damage(damage_type, damage_amount, null)
		
		yield(Global, "process_frame")
	
	projectile.queue_free()

func get_fire_object(pos: Position2D, chargebeam_damage_multiplier):
	if Cooldown.time_left > 0 or ammo == 0:
		return null
	set_ammo(max(0, ammo - 1))
	var projectile = ProjectileNode.duplicate()
	projectile.init(self, pos, chargebeam_damage_multiplier)
	return projectile
