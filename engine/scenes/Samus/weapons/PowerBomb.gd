extends SamusWeapon

onready var explosion_damage_refresh_time: float = damage_values["explosion_damage_refresh_time"]
onready var sounds: Dictionary = Audio.get_players_from_dir("/samus/weapons/powerbomb/", Audio.TYPE.SAMUS)

func _ready():
	
	# Set animation lengths
	var sprite: AnimatedSprite = ProjectileNode.get_node("Sprite")
	var length: float = sprite.frames.get_frame_count("default") / sprite.frames.get_animation_speed("default")
	sprite.speed_scale = length / damage_values["time_to_detonation"]
	
	var player: AnimationPlayer = ProjectileNode.get_node("AnimationPlayer")
	player.playback_speed = player.get_animation("explode").length / damage_values["explosion_duration"]

func fired(projectile: SamusKinematicProjectile):
	var sprite: AnimatedSprite = projectile.get_node("Sprite")
	sprite.play("default")
	sounds["sndPBombSet"].play()
	
	yield(sprite, "animation_finished")
	sprite.queue_free()
	
	var player: AnimationPlayer = projectile.get_node("AnimationPlayer")
	player.play("explode")
	sounds["sndPBombExpl"].play()
	
	var area: Area2D = projectile.get_node("Explosion")
	var processed_bodies = []
	
	while player.current_animation != "":
		for body in area.get_overlapping_bodies():
			
			if body in processed_bodies:
				continue
			
			if explosion_damage_refresh_time != 0:
				processed_bodies.append(body)
			if explosion_damage_refresh_time > 0:
				Global.wait(explosion_damage_refresh_time, false, [self, "erase", [processed_bodies, body]])
			
			if body != Loader.Samus:
				if body.has_method("damage"):
					body.damage(damage_type, damage_amount * Loader.loaded_save.difficulty_data["outgoing_damage_multiplier"], null)
		
		yield(Global, "process_frame")
	
	projectile.queue_free()

func erase(container: Array, body):
	container.erase(body)

func get_fire_object(pos: SamusCannonPosition, chargebeam_damage_multiplier):
	if Cooldown.time_left > 0 or ammo == 0:
		return null
	set_ammo(max(0, ammo - 1))
	var projectile = ProjectileNode.duplicate()
	projectile.init(self, pos, chargebeam_damage_multiplier)
	return projectile
