extends SamusWeapon

onready var sounds: Dictionary = Audio.get_players_from_dir("/samus/weapons/missile/", Audio.TYPE.SAMUS)

func projectile_physics_process(projectile: SamusKinematicProjectile, colliders: Array, _delta: float):
	if len(colliders) > 0:
		projectile.moving = false
		projectile.visible = false
		if id == Enums.Upgrade.SUPERMISSILE:
			Loader.current_room.earthquake(projectile.global_position, damage_values["earthquake_strength"], damage_values["earthquake_duration"])
			sounds["sndSMissileExpl"].play()
		else:
			sounds["sndMissileExpl"].play()
		yield(projectile.burst_end(), "completed")
		projectile.queue_free()

func get_fire_object(pos: SamusCannonPosition, chargebeam_damage_multiplier):
	if Cooldown.time_left > 0 or ammo == 0:
		return null
	set_ammo(max(0, ammo - 1))
	var projectile: SamusKinematicProjectile = ProjectileNode.duplicate()
	projectile.init(self, pos, chargebeam_damage_multiplier)
	InputManager.vibrate_controller(0.5 if id == Enums.Upgrade.SUPERMISSILE else 0.25, 0.1)
	sounds["sndFireMissile"].play()
	return projectile
