extends Area2D
class_name AmmoPickup

var anchor: Node2D = Global.get_anchor("AmmoPickups")

enum TYPES {ENERGY, UPGRADE}
var ammo_types: Dictionary = {
	"energy_small": {"type": TYPES.ENERGY, "amount": 5},
	"energy_large": {"type": TYPES.ENERGY, "amount": 15},
	"missile": {"type": TYPES.UPGRADE, "amount": 5, "upgrade": Enums.Upgrade.MISSILE},
	"supermissile": {"type": TYPES.UPGRADE, "amount": 1, "upgrade": Enums.Upgrade.SUPERMISSILE},
	"powerbomb": {"type": TYPES.UPGRADE, "amount": 1, "upgrade": Enums.Upgrade.POWERBOMB}
}
const profiles = [
	["energy_small", "energy_large", "missile"],
	["energy_small", "energy_large", "missile", "supermissile"],
	["energy_small", "energy_large", "missile", "supermissile", "powerbomb"],
]
var type: String

var sounds = {
	"energy_small": Audio.get_player("/objects/ammo_pickup/sndHPickup", Audio.TYPE.FX),
	"energy_large": Audio.get_player("/objects/ammo_pickup/sndHBigPickup.wav", Audio.TYPE.FX),
	"missile": Audio.get_player("/objects/ammo_pickup/sndMPickup.wav", Audio.TYPE.FX),
	"supermissile": Audio.get_player("/objects/ammo_pickup/sndSMPickup.wav", Audio.TYPE.FX),
	"powerbomb": Audio.get_player("/objects/ammo_pickup/sndPBPickup.wav", Audio.TYPE.FX),
}

# TODO | This looks horrible
func gravitate_to(position: Vector2, delta):
	var value: float = 1 - (((global_position - position).length()*delta*0.2)+0.2)
	global_position = global_position.move_toward(position, abs(value)*8.0)

func _ready():
	z_as_relative = false
	z_index = Enums.Layers.AMMOPICKUP

func spawn(Samus: KinematicBody2D, profile_index: int, position: Vector2):
	if is_inside_tree():
		get_parent().remove_child(self)
	anchor.add_child(self)
	global_position = position
	
	var possible: Array = []
	var profile: Array = profiles[profile_index]
	
	for ammo_type in ammo_types:
		if not ammo_type in profile:
			continue
		var data: Dictionary = ammo_types[ammo_type]
		
		if data["type"] == TYPES.ENERGY and Samus.energy < (Samus.etanks*100)+99:
			possible.append(ammo_type)
		elif data["type"] == TYPES.UPGRADE and Samus.is_upgrade_active(data["upgrade"]):
			data["weapon"] = Samus.Weapons.all_weapons[data["upgrade"]]
			if data["weapon"].ammo < data["weapon"].amount:
				possible.append(ammo_type)
	
	if len(possible) == 0:
		possible = profile
	
	type = Global.random_array_item(possible)
	$AnimatedSprite.play(type)

func _on_AmmoPickup_body_entered(body):
	if body == Loader.Samus:
		body.acquire_ammo_pickup(ammo_types[type])
		var sound: AudioPlayer = sounds[type]
		sound.play()
		sound.connect("finished", sound, "queue_free")
		for s in sounds.values():
			if s != sound:
				s.queue_free()
		queue_free()

func fade_out():
	$FadeOutTween.interpolate_property(self, "modulate:a", modulate.a, 0, 3.0)
	$FadeOutTween.start()
	yield($FadeOutTween, "tween_completed")
	for s in sounds.values():
		s.queue_free()
	queue_free()
