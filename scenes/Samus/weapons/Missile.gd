extends SamusProjectile

func projectile_collided(_projectile: Projectile):
	if id == Enums.Upgrade.SUPERMISSILE:
		Global.shake(Samus.camera, Vector2.ZERO, 2, cooldown*0.75)

#func projectile_fired(_projectile: Projectile):
#	pass
