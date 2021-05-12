extends Node2D

signal scan_status_changed

onready var Samus: KinematicBody2D = get_parent()
onready var CannonPositions = $CannonPositions
onready var VisorPositions = $VisorPositions

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

var current_visor = null
onready var visors = {
	Enums.Visor.SCAN: $Visors/ScanVisor
}

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

func cycle_visor():
	if Input.is_action_just_pressed("select_visor") and (not Settings.get("controls/select_visor_shortcut") or Input.is_action_pressed("shortcut")):
		var checking = current_visor == null
		var set = false
		for visor in Enums.Visor.values():
			if visor == current_visor:
				checking = true
			elif checking and Samus.is_upgrade_active(Enums.Visor.keys()[visor].to_lower()):
				current_visor = visor
				set = true
				break
		if not set:
			current_visor = null
		Samus.HUD.display_visor(current_visor)
	if current_visor != null:
		return "visor"
	else:
		return false

func all_equipped_weapons() -> Array:
	return added_weapons[false] + added_weapons[true]

func update_weapon_icons():
	for weapon in all_equipped_weapons():
		if weapon.Icon:
			var selected_weapon = all_equipped_weapons()[current_weapon[0]] if current_weapon[0] >= 0 else null
			weapon.Icon.update_icon(selected_weapon, Samus.armed)	

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
	return weapon

func remove_weapon(weapon_key: String, is_morph_weapon: bool):
	added_weapons[is_morph_weapon].remove(all_weapons[weapon_key])
	Samus.HUD.remove_weapon(all_weapons[weapon_key])


func _on_SpeedboosterDamageArea_body_entered(body):
	var shinespark = Samus.states["shinespark"]
	if body.has_method("damage"):
		body.damage(shinespark.damage_type, shinespark.damage_amount)
