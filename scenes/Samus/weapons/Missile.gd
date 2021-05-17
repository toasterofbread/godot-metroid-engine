extends SamusProjectile

func projectile_collided(_projectile: Projectile):
	if id == "supermissile":
		Global.shake(Samus.camera, Vector2.ZERO, 2, cooldown*0.75)

#func projectile_fired(_projectile: Projectile):
#	pass
