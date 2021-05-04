extends Node

onready var samus: KinematicBody2D = get_parent().get_parent()

var weapons = {
	true: [], # Morphball weapons
	false: [] # Standard weapons
}
var base_weapons = {
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
		weapon.samus = samus

func _process(_delta):
	
	current_weapon[1] = samus.current_state.id == "morphball"
	
	if Input.is_action_just_pressed("cancel_weapon_selection"):
		current_weapon[0] = 0 if Config.get("zm_controls") else -1
	elif Input.is_action_just_pressed("select_weapon"):
		current_weapon[0] += 1
		if Config.get("zm_controls"):
			if current_weapon[0] >= len(weapons[current_weapon[1]]):
				current_weapon[0] = 0
		else:
			if current_weapon[0] >= len(all_equipped_weapons()):
				current_weapon[0] = -1
	else:
		return
	update_weapon_icons()

func all_equipped_weapons() -> Array:
	return weapons[false] + weapons[true]

func update_weapon_icons():
	for weapon in all_equipped_weapons():
		if weapon.Icon:
			weapon.Icon.update_icon(all_equipped_weapons()[current_weapon[0]] if current_weapon[0] >= 0 else null, samus.armed)	

func fire():
	
	if Config.get("zm_controls"):
		if samus.armed:
			if len(weapons[current_weapon[1]]) > current_weapon[0]:
				weapons[current_weapon[1]][current_weapon[0]].fire()
			elif base_weapons[current_weapon[1]] != null:
				base_weapons[current_weapon[1]].fire()
		else:
			if base_weapons[current_weapon[1]] != null:
				base_weapons[current_weapon[1]].fire()
	else:
		if current_weapon[0] == -1:
			if base_weapons[current_weapon[1]] != null:
				base_weapons[current_weapon[1]].fire()
		else:
			(weapons[true] + weapons[false])[current_weapon[0]].fire()

func add_weapon(weapon_key: String):

	var weapon = all_weapons[weapon_key]
	samus.get_node("Weapons").add_child(weapon)

	if weapon.is_base_weapon:
		base_weapons[weapon.is_morph_weapon] = weapon
	else:
		weapons[weapon.is_morph_weapon].append(weapon)
		var temp = weapons[weapon.is_morph_weapon]
		weapons[weapon.is_morph_weapon] = []

		for w in all_weapons.values():
			if w in temp:
				weapons[weapon.is_morph_weapon].append(w)

func remove_weapon(weapon_key: String, is_morph_weapon: bool):
	weapons[is_morph_weapon].remove(all_weapons[weapon_key])
	samus.hud.remove_weapon(all_weapons[weapon_key])
