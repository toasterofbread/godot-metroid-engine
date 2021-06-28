extends SamusKinematicProjectile

func collision():
	if not Enums.Upgrade.WAVEBEAM in Weapon.current_types:
		queue_free()
