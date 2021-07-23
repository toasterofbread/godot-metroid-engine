extends SamusKinematicProjectile

func collision():
	return
	if not Enums.Upgrade.WAVEBEAM in Weapon.current_types:
		queue_free()
