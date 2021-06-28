extends Area2D
class_name AmmoPickup

enum TYPES {energy_small, energy_large, missile, supermissile, powerbomb}
var type: int

var sounds = {
	"energy_small": Sound.new("res://audio/objects/ammo_pickup/sndHPickup.wav", Sound.TYPE.FX),
	"energy_large": Sound.new("res://audio/objects/ammo_pickup/sndHBigPickup.wav", Sound.TYPE.FX),
	"missile": Sound.new("res://audio/objects/ammo_pickup/sndMPickup.wav", Sound.TYPE.FX),
	"supermissile": Sound.new("res://audio/objects/ammo_pickup/sndSMPickup.wav", Sound.TYPE.FX),
	"powerbomb": Sound.new("res://audio/objects/ammo_pickup/sndPBPickup.wav", Sound.TYPE.FX),
}

func gravitate_to(position: Vector2, delta):
	global_position = global_position.linear_interpolate(position, delta*2)

func _ready():
	z_as_relative = false
	z_index = Enums.Layers.AMMOPICKUP
	init_by_energy(Loader.Samus)

func init_by_energy(Samus):
	
	var possible = []
	
	if Samus.energy < (Samus.etanks*100)+99:
		possible += [TYPES.energy_small, TYPES.energy_large]
	
	for upgrade in [Enums.Upgrade.MISSILE, Enums.Upgrade.SUPERMISSILE, Enums.Upgrade.POWERBOMB]:
		var weapon: SamusWeapon = Samus.Weapons.all_weapons[upgrade]
		if Samus.is_upgrade_active(upgrade) and weapon.ammo < weapon.amount:
			possible.append(upgrade)
	
	if len(possible) == 0:
		possible = TYPES.values()
	
	
	type = Global.random_array_item(possible)
	$AnimatedSprite.play(TYPES.keys()[type])

func _on_AmmoPickup_body_entered(body):
	if body == Loader.Samus:
		body.acquire_ammo_pickup(self)
		visible = false
		monitorable = false
		monitoring = false
		
		var sound: Sound = sounds[TYPES.keys()[type]]
		sound.play()
		yield(sound, "finished")
		
		for s in sounds.values():
			s.queue_free()
		queue_free()
