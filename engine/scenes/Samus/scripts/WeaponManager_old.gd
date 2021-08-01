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
	Enums.Upgrade.POWERBEAM: preload("res://engine/scenes/Samus/weapons/Beam.tscn").instance(),
	Enums.Upgrade.MISSILE: preload("res://engine/scenes/Samus/weapons/Missile.tscn").instance(),
	Enums.Upgrade.SUPERMISSILE: preload("res://engine/scenes/Samus/weapons/SuperMissile.tscn").instance(),
	Enums.Upgrade.BOMB: preload("res://engine/scenes/Samus/weapons/Bomb.tscn").instance(),
	Enums.Upgrade.POWERBOMB: preload("res://engine/scenes/Samus/weapons/PowerBomb.tscn").instance(),
	Enums.Upgrade.GRAPPLEBEAM: preload("res://engine/scenes/Samus/weapons/grapple_beam/GrappleBeam.tscn").instance()
}

signal visor_mode_changed
var current_visor = null
var all_visors = {
	Enums.Upgrade.SCANVISOR: preload("res://engine/scenes/Samus/visors/scan/ScanVisor.tscn").instance(),
	Enums.Upgrade.XRAYVISOR: preload("res://engine/scenes/Samus/visors/xray/XRayScope.tscn").instance()
}
var equipped_visors = []


func _ready():
	reversed_charge_times = charge_times.keys().duplicate()
	reversed_charge_times.invert()
	
	for node in [ChargebeamStartBurst, ChargebeamStartBurstPlayer]:
		Global.reparent_child(node, CannonPositionAnchor)
	ChargebeamStartBurst.position = Vector2.ZERO
	
	for state in CannonPositions.get_children():
		for animation in state.get_children():
			fire_pos_nodes[state.name + "/" + animation.name] = animation
	
	# Add all weapons to the scene
	for weapon in all_weapons.values():
		$SamusWeapons.add_child(weapon)
	
	# Add all visors to the scene, passing the visor state object
	yield(Samus, "ready")
	for visor in all_visors.values():
		visor.visor_state = Samus.states["visor"]
		$SamusVisors.add_child(visor)

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
		current_weapon[0] = 0 if Settings.get("control_options/aiming_style") == 0 else -1
	elif Input.is_action_just_pressed("select_weapon"):
		current_weapon[0] += 1
		if Settings.get("control_options/aiming_style") == 0:
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
					var animation = Enums.Upgrade.keys()[all_weapons[Enums.Upgrade.POWERBEAM].get_base_type(true)]
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
	if len(equipped_visors) == 0:
		return false
	if Input.is_action_just_pressed("select_visor") and (not Settings.get("control_options/visor_combo") or Input.is_action_pressed("shortcut")):
		if current_visor == null:
			current_visor = equipped_visors[0]
		elif current_visor == equipped_visors[len(equipped_visors) - 1]:
			current_visor = null
		else:
			current_visor = equipped_visors[equipped_visors.find(current_visor) + 1]
		emit_signal("visor_mode_changed", current_visor)
	return current_visor != null

func all_equipped_weapons(include_base_weapons:=false) -> Array:
	var ret = added_weapons[false] + added_weapons[true]
	if include_base_weapons:
		ret += [added_weapons_base[false], added_weapons_base[true]]
	
	return ret

func update_weapon_icons():
	var selected_weapon = added_weapons[current_weapon[1]][current_weapon[0]] if current_weapon[0] >= 0 else null
	for weapon in all_equipped_weapons():
		if weapon.Icon:
			weapon.Icon.update_icon(selected_weapon, Samus.armed)

# (OLD) TODO | Yeah this defintely needs an overhaul
func fire(chargebeam_damage_multiplier=null):
	var weapon: SamusWeapon
	if Settings.get("control_options/aiming_style") == 0:
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
	
func add_weapon(weapon):
	
	if weapon is int:
		weapon = all_weapons[weapon]
	
	if weapon in all_equipped_weapons(true):
		return
	
	if weapon.is_base_weapon:
		added_weapons_base[weapon.is_morph_weapon] = weapon
	else:
		added_weapons[weapon.is_morph_weapon].append(weapon)
		sort_weapons(weapon.is_morph_weapon)
	
	if weapon.Icon:
		update_weapon_icons()
		weapon.Icon.update_digits(weapon.ammo)

func sort_weapons(is_morph_weapon: bool):
	
	var selected_weapon = added_weapons[current_weapon[1]][current_weapon[0]]
	var temp = added_weapons[is_morph_weapon]
	added_weapons[is_morph_weapon] = []
	
	for w in all_weapons.values():
		if w.Icon:
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
		if w.Icon:
			Samus.HUD.add_weapon(w.Icon)

func remove_weapon(weapon: SamusWeapon):
	
	if not weapon in all_equipped_weapons(true):
		return
	
	if weapon.is_base_weapon:
		added_weapons_base[weapon.is_morph_weapon] = null
	else:
		added_weapons[weapon.is_morph_weapon].erase(weapon)
	
	current_weapon[0] = 0 if Settings.get("control_options/aiming_style") == 0 else -1
	
	Samus.HUD.remove_weapon(weapon.Icon)

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
	if not position_node_path in fire_pos_nodes:
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

func add_visor(visor: SamusVisor):
	if visor in equipped_visors:
		return
	
	equipped_visors.append(visor)
	sort_visors()

func remove_visor(visor: SamusVisor):
	if not visor in equipped_visors:
		return
	
	equipped_visors.erase(visor)
	Samus.HUD.remove_visor(visor.Icon)

func sort_visors():
	
	var temp = equipped_visors
	equipped_visors = []
	
	for visor in all_visors.values():
		Samus.HUD.remove_visor(visor.Icon)
	
	var i = 0
	for visor in all_visors.values():
		if visor in temp:
			equipped_visors.append(visor)
			Samus.HUD.add_visor(visor.Icon)
