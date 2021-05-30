extends Area2D
class_name AmmoPickup

enum TYPES {energy_small, energy_large, missile, supermissile, powerbomb}
var type: int

func gravitate_to(position: Vector2):
	global_position = lerp(global_position, position, 0.5)

func _ready():
	visible = false
	monitorable = false
	monitoring = false

func init_by_energy(Samus):
	
	var possible = []
	
	if Samus.energy < (Samus.etanks*100)+99:
		possible += [TYPES.energy_small, TYPES.energy_large]
	
	for upgrade in [Enums.Upgrade.MISSILE, Enums.Upgrade.SUPERMISSILE, Enums.Upgrade.POWERBOMB]:
		if Samus.is_upgrade_active(upgrade) and Samus.Weapons.all_weapons["upgrade"].ammo < Samus.Weapons.all_weapons["upgrade"].amount:
			possible.append(TYPES.keys().find(Enums.Upgrade.keys()[upgrade].to_lower()))
	
	if len(possible) == 0:
		possible = TYPES.keys()
	
	type = Global.random_item(possible)
	$AnimatedSprite.play(TYPES.keys()[type])
	
	
