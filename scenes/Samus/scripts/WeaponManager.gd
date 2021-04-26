extends Node

onready var samus: KinematicBody2D = get_parent()

var equipped_weapons = []
var current_weapon: int = 0
var all_weapons = {
	"beam": preload("res://scenes/Samus/weapons/Beam.tscn").instance(),
	"missile": preload("res://scenes/Samus/weapons/Missile.tscn").instance(),
}

func _ready():
	pass

func fire():
	equipped_weapons[current_weapon].fire()

func add_weapon(weapon_key: String):
	if all_weapons[weapon_key].hud_icon:
		samus.hud.add_weapon(all_weapons[weapon_key])
	
	equipped_weapons.append(all_weapons[weapon_key])
	var temp = equipped_weapons
	equipped_weapons = []
	
	for weapon in all_weapons.values():
		if weapon in temp:
			equipped_weapons.append(weapon)

func remove_weapon(weapon_key: String):
	equipped_weapons.remove(all_weapons[weapon_key])
	samus.hud.remove_weapon(all_weapons[weapon_key])
