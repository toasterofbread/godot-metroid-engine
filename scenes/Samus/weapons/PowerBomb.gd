extends SamusProjectile

const bomb_detonation_time: float = 0.6
const bomb_bounce_amount: float = 325.0
const bomb_horiz_bounce_amount: float = 200.0
const samus_aerial_damage: int = 10

func _ready():
	pass

func projectile_fired(projectile: Projectile):
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
			
			if body != Samus:
				if body.has_method("damage"):
					body.damage(damage_type, damage_amount)
		
		yield(Global, "process_frame")
	
	projectile.kill()
