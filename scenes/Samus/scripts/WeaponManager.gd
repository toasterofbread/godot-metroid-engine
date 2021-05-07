extends Node2D

onready var Samus: KinematicBody2D = get_parent()
onready var CannonPositions = $CannonPositions

var added_weapons = {
	true: [], # Morphball weapons
	false: [] # Standard weapons
}
var added_weapons_base = {
	true: null,
	false: null,
}
var current_weapon = [
	0, # Current weapon selection index
	false # Whether the current selection is a morphball weapon
]

var all_weapons = {
	"beam": preload("res://scenes/Samus/weapons/Beam.tscn").instance(),
	"missile": preload("res://scenes/Samus/weapons/Missile.tscn").instance(),
	"supermissile": preload("res://scenes/Samus/weapons/SuperMissile.tscn").instance(),
	"bomb": preload("res://scenes/Samus/weapons/Bomb.tscn").instance()
}

func _ready():
	for weapon in all_weapons.values():
		weapon.Samus = Samus

func _process(_delta):
	
	current_weapon[1] = Samus.current_state.id == "morphball"
	
	if Input.is_action_just_pressed("cancel_weapon_selection"):
		current_weapon[0] = 0 if Settings.get("controls/zm_style_aiming") else -1
	elif Input.is_action_just_pressed("select_weapon"):
		current_weapon[0] += 1
		if Settings.get("controls/zm_style_aiming"):
			if current_weapon[0] >= len(added_weapons[current_weapon[1]]):
				current_weapon[0] = 0
		else:
			if current_weapon[0] >= len(all_equipped_weapons()):
				current_weapon[0] = -1
	else:
		return
	update_weapon_icons()

func all_equipped_weapons() -> Array:
	return added_weapons[false] + added_weapons[true]

func update_weapon_icons():
	for weapon in all_equipped_weapons():
		if weapon.Icon:
			weapon.Icon.update_icon(all_equipped_weapons()[current_weapon[0]] if current_weapon[0] >= 0 else null, Samus.armed)	

func fire():
	
	if Settings.get("controls/zm_style_aiming"):
		if Samus.armed:
			if len(added_weapons[current_weapon[1]]) > current_weapon[0]:
				added_weapons[current_weapon[1]][current_weapon[0]].fire()
			elif added_weapons_base[current_weapon[1]] != null:
				added_weapons_base[current_weapon[1]].fire()
		else:
			if added_weapons_base[current_weapon[1]] != null:
				added_weapons_base[current_weapon[1]].fire()
	else:
		if current_weapon[0] == -1:
			if added_weapons_base[current_weapon[1]] != null:
				added_weapons_base[current_weapon[1]].fire()
		else:
			(added_weapons[true] + added_weapons[false])[current_weapon[0]].fire()

func add_weapon(weapon_key: String):

	var weapon = all_weapons[weapon_key]
	Samus.get_node("Weapons").add_child(weapon)

	if weapon.is_base_weapon:
		added_weapons_base[weapon.is_morph_weapon] = weapon
	else:
		added_weapons[weapon.is_morph_weapon].append(weapon)
		var temp = added_weapons[weapon.is_morph_weapon]
		added_weapons[weapon.is_morph_weapon] = []

		for w in all_weapons.values():
			if w in temp:
				added_weapons[weapon.is_morph_weapon].append(w)

func remove_weapon(weapon_key: String, is_morph_weapon: bool):
	added_weapons[is_morph_weapon].remove(all_weapons[weapon_key])
	Samus.HUD.remove_weapon(all_weapons[weapon_key])


func _on_SpeedboosterDamageArea_body_entered(body):
	var shinespark = Samus.states["shinespark"]
	if body.has_method("damage"):
		body.damage(shinespark.damage_type, shinespark.damage_amount)
