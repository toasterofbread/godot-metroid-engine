extends Node2D

onready var Samus: KinematicBody2D = get_parent()
onready var Animator: Node2D  = get_parent().Animator
onready var CannonPositions = $CannonPositions
onready var VisorPositions = $VisorPositions

onready var ChargebeamAnimationPlayer: AnimationPlayer = get_parent().get_node("Animator/ChargebeamAnimationPlayer")
onready var ChargebeamStartBurstPlayer: AnimationPlayer = get_parent().get_node("Animator/ChargebeamStartBurstPlayer")
onready var ChargebeamStartBurst: AnimatedSprite = get_parent().get_node("Animator/ChargebeamStartBurst")
onready var CannonPositionAnchor: Node2D = $CannonPositionAnchor

const charge_times = {1.5: 2.0, 1.0: 1.0, 0.5: 1.0}
var reversed_charge_times
var charge_time_current: float = 0.0
var weapon_fired: = false

var fire_pos
var fire_pos_nodes: = {}

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
	Enums.Upgrade.BEAM: preload("res://scenes/Samus/weapons/Beam.tscn").instance(),
	Enums.Upgrade.MISSILE: preload("res://scenes/Samus/weapons/Missile.tscn").instance(),
	Enums.Upgrade.SUPERMISSILE: preload("res://scenes/Samus/weapons/SuperMissile.tscn").instance(),
	Enums.Upgrade.BOMB: preload("res://scenes/Samus/weapons/Bomb.tscn").instance(),
	Enums.Upgrade.POWERBOMB: preload("res://scenes/Samus/weapons/PowerBomb.tscn").instance(),
	Enums.Upgrade.GRAPPLEBEAM: preload("res://scenes/Samus/weapons/grapple_beam/GrappleBeam.tscn").instance()
}

var current_visor = null
onready var visors = {
	Enums.Upgrade.XRAY: $Visors/XRayScope
}

func _ready():
	reversed_charge_times = charge_times.keys().duplicate()
	reversed_charge_times.invert()
	
	for node in [ChargebeamStartBurst, ChargebeamStartBurstPlayer]:
		Global.reparent_child(node, CannonPositionAnchor)
	ChargebeamStartBurst.position = Vector2.ZERO
	
	for state in CannonPositions.get_children():
		for animation in state.get_children():
			fire_pos_nodes[state.name + "/" + animation.name] = animation

func _process(delta: float):
	
	reset_fire_pos()
	
	if Samus.is_upgrade_active(Enums.Upgrade.CHARGEBEAM) and delta:
		process_chargebeam(delta)
	weapon_fired = false
	
	var morphball = Samus.current_state.id in ["morphball", "spiderball"]
	var morphball_changed = morphball != current_weapon[1]
	if morphball_changed:
		current_weapon[1] = morphball
		current_weapon[0] = 0
	
	if Input.is_action_just_pressed("cancel_weapon_selection"):
		current_weapon[0] = 0 if Settings.get("controls/aiming_style") == 0 else -1
	elif Input.is_action_just_pressed("select_weapon"):
		current_weapon[0] += 1
		if Settings.get("controls/aiming_style") == 0:
			if current_weapon[0] >= len(added_weapons[current_weapon[1]]):
				current_weapon[0] = 0
		else:
			if current_weapon[0] >= len(all_equipped_weapons()):
				current_weapon[0] = -1
	elif not morphball_changed:
		return
	update_weapon_icons()

func process_chargebeam(delta: float):
	if charge_time_current >= charge_times.keys()[len(charge_times) - 1]:
		ChargebeamAnimationPlayer.play("charge")
	else:
		ChargebeamAnimationPlayer.play("reset")
	
	var fire = true
	if Samus.current_state.id in ["neutral", "run", "jump", "crouch", "powergrip"] and Input.is_action_pressed("fire_weapon"):
		charge_time_current += delta
		fire = false
	
	ChargebeamStartBurst.visible = false
	if charge_time_current != 0.0:
		if charge_time_current > charge_times.keys()[len(charge_times) - 1]:
			
			for time in charge_times:
				if charge_time_current >= time:
					var animation = Enums.Upgrade.keys()[all_weapons[Enums.Upgrade.BEAM].get_base_type(true)]
					var i = charge_times.keys().find(time)
					animation += " " + str(i)
					if i == 2:
						ChargebeamStartBurstPlayer.play(animation)
					else:
						ChargebeamStartBurst.play(animation)
					if fire_pos:
						ChargebeamStartBurst.visible = true
					
					if fire:
						if Samus.current_state.has_method("chargebeam_fired"):
							Samus.current_state.chargebeam_fired()
						
						var morphball = Samus.current_state.id in ["morphball", "spiderball"]
						if morphball != current_weapon[1]:
							current_weapon[1] = morphball
							current_weapon[0] = 0
							update_weapon_icons()
						fire(charge_times[time])
					break
		if fire:
			charge_time_current = 0.0

func cycle_visor():
	if Input.is_action_just_pressed("select_visor") and (not Settings.get("controls/visor_combo") or Input.is_action_pressed("shortcut")):
		var checking = false
		if current_visor == null:
			checking = true
		else:
			visors[current_visor].set_overlay(false)
		var set = false
		for visor in Enums.UpgradeTypes["visor"]:
			if visor == current_visor:
				checking = true
			elif checking and Samus.is_upgrade_active(visor):
				current_visor = visor
				set = true
				break
		if not set:
			current_visor = null
		else:
			visors[current_visor].set_overlay(true)
	if current_visor != null:
		return "visor"
	else:
		return false

func all_equipped_weapons(include_base_weapons:=false) -> Array:
	var ret = added_weapons[false] + added_weapons[true]
	if include_base_weapons:
		ret += [added_weapons_base[false], added_weapons_base[true]]
	
	return ret

func update_weapon_icons():
	for weapon in all_equipped_weapons():
		if weapon.Icon:
			var selected_weapon = added_weapons[current_weapon[1]][current_weapon[0]] if current_weapon[0] >= 0 else null
			weapon.Icon.update_icon(selected_weapon, Samus.armed)

# TODO | Yeah this defintely needs an overhaul
func fire(chargebeam_damage_multiplier=null):
	var weapon: SamusWeapon
	if Settings.get("controls/aiming_style") == 0:
		if Samus.armed:
			if len(added_weapons[current_weapon[1]]) > current_weapon[0]:
				weapon = added_weapons[current_weapon[1]][current_weapon[0]]
			elif added_weapons_base[current_weapon[1]] != null:
				weapon = added_weapons_base[current_weapon[1]]
		else:
			if added_weapons_base[current_weapon[1]] != null:
				weapon = added_weapons_base[current_weapon[1]]
	else:
		if current_weapon[0] == -1:
			if added_weapons_base[current_weapon[1]] != null:
				weapon = added_weapons_base[current_weapon[1]]
		else:
			weapon = (added_weapons[true] + added_weapons[false])[current_weapon[0]]
	
	if weapon:
		weapon_fired = weapon.fire(chargebeam_damage_multiplier)
		return weapon_fired
	else:
		return false
	
func add_weapon(weapon_key: int):
	
	if all_weapons[weapon_key] in all_equipped_weapons(true):
		return
	
	var weapon = all_weapons[weapon_key]
	Samus.get_node("Weapons").call_deferred("add_child", weapon)
	yield(weapon, "ready")
	
	if weapon.is_base_weapon:
		added_weapons_base[weapon.is_morph_weapon] = weapon
	else:
		added_weapons[weapon.is_morph_weapon].append(weapon)
		sort_weapons(weapon.is_morph_weapon)
	return weapon

func sort_weapons(is_morph_weapon: bool):
	
	var selected_weapon = added_weapons[current_weapon[1]][current_weapon[0]]
	var temp = added_weapons[is_morph_weapon]
	added_weapons[is_morph_weapon] = []
	
	for w in all_weapons.values():
		Samus.HUD.remove_weapon(w.Icon)
	
	var i = 0
	for w in all_weapons.values():
		if w in temp:
			if selected_weapon != null:
				if w == selected_weapon:
					current_weapon[0] = i
					selected_weapon = null
				elif w.is_morph_weapon == current_weapon[1]:
					i += 1
			added_weapons[is_morph_weapon].append(w)
	
	for w in all_equipped_weapons():
		Samus.HUD.add_weapon(w.Icon)

func remove_weapon(weapon_key: int, is_morph_weapon: bool):
	
	if not all_weapons[weapon_key] in all_equipped_weapons(true):
		return
	
	added_weapons[is_morph_weapon].remove(all_weapons[weapon_key])
	Samus.HUD.remove_weapon(all_weapons[weapon_key])

func is_weapon_equipped(weapon_key: int):
	return weapon_key in all_equipped_weapons() + added_weapons_base[false] + added_weapons_base[true]

func _on_SpeedboosterDamageArea_body_entered(body):
	var shinespark = Samus.states["shinespark"]
	if body.has_method("damage"):
		body.damage(shinespark.damage_type, shinespark.damage_amount)

func get_fire_pos(facing_override:=Samus.facing):
	
	if not Samus.Animator.current[false]:
		return
	
	var position_node_path = Samus.Animator.current[false].position_node_path
	if not position_node_path:
		return null
	var pos: Position2D = fire_pos_nodes[position_node_path]
	
	var ret = pos.duplicate()
	ret.global_position = pos.global_position
	
	if facing_override == Enums.dir.RIGHT:
		ret.position.x += (pos.position.x * -1 + 8) - pos.position.x
		ret.rotation = (Vector2(-1, 0).rotated(pos.rotation) * Vector2(-1, 1)).angle()
	
	CannonPositionAnchor.global_position = ret.position
	
	return ret

func reset_fire_pos():
	if fire_pos:
		fire_pos.queue_free()
	fire_pos = get_fire_pos()
