extends SamusWeapon

func fire():
	if Cooldown.time_left > 0:
		return
	
	var pos = get_fire_pos()
	match pos:
		-1: return
	
	var projectile = Projectile.new($Projectile, self, velocity, pos)
	Anchor.add_child(projectile)
	projectile.burst_start(pos)
	Cooldown.start(cooldown)
