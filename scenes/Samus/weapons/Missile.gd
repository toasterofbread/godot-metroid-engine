extends SamusWeapon

func projectile_physics_process(projectile: SamusKinematicProjectile, collision: KinematicCollision2D, _delta: float):
	if collision:
		projectile.moving = false
		projectile.visible = false
		if id == Enums.Upgrade.SUPERMISSILE:
			Global.shake(Samus.camera, Vector2.ZERO, 2, cooldown*0.75)
		yield(projectile.burst_end(), "completed")
		projectile.queue_free()

func get_fire_object(pos: Position2D, chargebeam_damage_multiplier):
	if Cooldown.time_left > 0 or ammo == 0:
		return null
	set_ammo(max(0, ammo - 1))
	var projectile: SamusKinematicProjectile = ProjectileNode.duplicate()
	projectile.init(self, pos, chargebeam_damage_multiplier)
	return projectile
