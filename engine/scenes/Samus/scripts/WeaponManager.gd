extends Node2D

onready var Samus: KinematicBody2D = get_parent()
onready var Animator: Node2D  = get_parent().Animator
onready var CannonPositions = $CannonPositions
onready var VisorPositions = $VisorPositions

onready var ChargebeamAnimationPlayer: AnimationPlayer = get_parent().get_node("Animator/ChargebeamAnimationPlayer")
onready var ChargebeamStartBurstPlayer: AnimationPlayer = get_parent().get_node("Animator/ChargebeamStartBurstPlayer")
onready var ChargebeamStartBurst: AnimatedSprite = get_parent().get_node("Animator/ChargebeamStartBurst")
onready var ChargeBeamGravityArea: Area2D = get_parent().get_node("Animator/ChargebeamStartBurst/Area2D")
onready var CannonPositionAnchor: Node2D = $CannonPositionAnchor

onready var charge_times: Dictionary = Data.data["damage_values"]["samus"]["weapons"]["chargebeam"]["charge_times"]
var reversed_charge_times
var charge_time_current: float = 0.0
var weapon_fired: = false

var fire_pos
var fire_pos_nodes: = {}

var morphball: bool
var aiming_style: int
var added_weapons = {
	true: [], # Morphball weapons
	false: [] # Standard weapons
}
var added_weapons_base = {
	true: null,
	false: null,
}
#var current_weapon = [
#	0, # Current weapon selection index
#	false # Whether the current selection is a morphball weapon
#]

var current_weapon = null

var all_weapons = {
	Enums.Upgrade.POWERBEAM: preload("res://engine/scenes/Samus/weapons/Beam.tscn").instance(),
	Enums.Upgrade.MISSILE: preload("res://engine/scenes/Samus/weapons/Missile.tscn").instance(),
	Enums.Upgrade.SUPERMISSILE: preload("res://engine/scenes/Samus/weapons/SuperMissile.tscn").instance(),
	Enums.Upgrade.BOMB: preload("res://engine/scenes/Samus/weapons/Bomb.tscn").instance(),
	Enums.Upgrade.POWERBOMB: preload("res://engine/scenes/Samus/weapons/PowerBomb.tscn").instance(),
	Enums.Upgrade.GRAPPLEBEAM: preload("res://engine/scenes/Samus/weapons/grapple_beam/GrappleBeam.tscn").instance(),
	Enums.Upgrade.FLAMETHROWER: preload("res://engine/scenes/Samus/weapons/Flamethrower.tscn").instance()
}

signal visor_mode_changed
var current_visor = null
var all_visors = {
	Enums.Upgrade.SCANVISOR: preload("res://engine/scenes/Samus/visors/scan/ScanVisor.tscn").instance(),
	Enums.Upgrade.XRAYVISOR: preload("res://engine/scenes/Samus/visors/xray/XRayScope.tscn").instance()
}
var equipped_visors = []


func _ready():
	for key in charge_times.keys().duplicate():
		charge_times[float(key)] = charge_times[key]
		charge_times.erase(key)
	reversed_charge_times = charge_times.keys().duplicate()
	reversed_charge_times.invert()
	
	for node in [ChargebeamStartBurst, ChargebeamStartBurstPlayer]:
		Global.reparent_child(node, CannonPositionAnchor)
	ChargebeamStartBurst.position = Vector2.ZERO
	
	for state in CannonPositions.get_children():
		state.visible = true # DEBUG
		for animation in state.get_children():
			fire_pos_nodes[state.name + "/" + animation.name] = animation
	
	# Add all weapons to the scene
	for weapon in all_weapons.values():
		$SamusWeapons.add_child(weapon)
	
	Loader.connect("room_transitioning", self, "room_transitioning")
	
	# Add all visors to the scene, passing the visor state object
	yield(Samus, "ready")
	for visor in all_visors.values():
		$VisorNode.add_child(visor)

func _process(delta: float):
	update_fire_pos()
	
	if not get_tree().paused and Samus.is_upgrade_active(Enums.Upgrade.CHARGEBEAM) and delta:
		process_chargebeam(delta)
	weapon_fired = false
	
	aiming_style = Settings.get("control_options/aiming_style")
	morphball = Samus.current_state.id in ["morphball", "spiderball"]
	var morphball_changed = false
	if current_weapon:
		morphball_changed = current_weapon.is_morph_weapon != morphball
	
	if Input.is_action_just_pressed("cancel_weapon_selection"):
		reset_weapon_selection(morphball, aiming_style)
	elif Input.is_action_just_pressed("select_weapon"):
		if not current_weapon:
			if len(added_weapons[morphball]) > 0:
				current_weapon = added_weapons[morphball][0]
		elif current_weapon.index + 1 >= len(added_weapons[morphball]):
			reset_weapon_selection(morphball, aiming_style)
		else:
			current_weapon = added_weapons[morphball][current_weapon.index + 1]
	elif morphball_changed:
		current_weapon = added_weapons[morphball][0] if len(added_weapons[morphball]) > 0 else null
	else:
		return
	update_weapon_icons()

func reset_weapon_selection(morphball: bool, aiming_style: int):
	if aiming_style == 0:
		current_weapon = added_weapons[morphball][0]
	elif aiming_style == 1:
		current_weapon = added_weapons_base[morphball]
	else:
		pass

func process_chargebeam(delta: float):
	
	if current_visor != null:
		charge_time_current = 0
	
	if charge_time_current >= charge_times.keys()[len(charge_times) - 1]:
		ChargebeamAnimationPlayer.play("charge")
	elif ChargebeamAnimationPlayer.current_animation == "charge":
		ChargebeamAnimationPlayer.play("reset")
	
	var fire: bool
	if Samus.current_state.id in ["neutral", "run", "jump", "crouch", "powergrip", "airspark"] and Input.is_action_pressed("fire_weapon") and get_fire_weapon().can_charge:
		charge_time_current += delta
		fire = false
	else:
		fire = Samus.current_state.can_fire_chargebeam
	
	ChargebeamStartBurst.visible = false
	if charge_time_current != 0.0:
		if charge_time_current > charge_times.keys()[len(charge_times) - 1]:
			
			ChargeBeamGravityArea.monitorable = true
			ChargeBeamGravityArea.monitoring = true
			for ammoPickup in ChargeBeamGravityArea.get_overlapping_areas():
				if ammoPickup is AmmoPickup:
					ammoPickup.gravitate_to(Samus.global_position, delta)
			
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
						
						var new_morphball = Samus.current_state.id in ["morphball", "spiderball"]
						if morphball != new_morphball:
							morphball = new_morphball
							update_weapon_icons()
						fire(charge_times[time])
					break
		else:
			ChargeBeamGravityArea.monitorable = false
			ChargeBeamGravityArea.monitoring = false
		if fire:
			charge_time_current = 0.0
	else:
		ChargeBeamGravityArea.monitorable = false
		ChargeBeamGravityArea.monitoring = false

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
	for weapon in all_equipped_weapons():
		if weapon.Icon:
			weapon.Icon.update_icon(current_weapon, Samus.armed)

func get_fire_weapon() -> SamusWeapon:
	var ret
	if aiming_style == 0:
		if Samus.armed:
			ret = current_weapon if current_weapon != null else added_weapons_base[morphball]
		else:
			ret = added_weapons_base[morphball]
	elif aiming_style == 1:
		ret = current_weapon
	
	return ret

# (DONE) TODO | Yeah this defintely needs an overhaul
func fire(chargebeam_damage_multiplier=null):
	var weapon = get_fire_weapon()
	if weapon != null:
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
		weapon.index = -1
	else:
		added_weapons[weapon.is_morph_weapon].append(weapon)
		sort_weapons(weapon.is_morph_weapon)
	
	if not current_weapon and not weapon.is_base_weapon:
		current_weapon = weapon
	if weapon.Icon:
		update_weapon_icons()
		weapon.Icon.update_digits(weapon.ammo)
	

func sort_weapons(morphball: bool):
	
#	var selected_weapon = added_weapons[current_weapon[1]][current_weapon[0]]
	var temp = added_weapons[morphball]
	added_weapons[morphball] = []
	
	for w in all_weapons.values():
		if w.Icon:
			Samus.HUD.remove_weapon(w.Icon)
	
	var i = 0
	for w in all_weapons.values():
		if w in temp and w.is_morph_weapon == morphball:
			w.index = i
			i += 1
			added_weapons[morphball].append(w)
	
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
	
	if aiming_style == 0:
		current_weapon = added_weapons[morphball][0]
	elif aiming_style == 1:
		current_weapon = added_weapons_base[morphball]
	
	Samus.HUD.remove_weapon(weapon.Icon)
	update_weapon_icons()

func is_weapon_equipped(weapon_key: int):
	return weapon_key in all_equipped_weapons() + added_weapons_base[false] + added_weapons_base[true]

func _on_SpeedboosterDamageArea_body_entered(body):
	var shinespark = Samus.states["shinespark"]
	if body.has_method("damage"):
		body.damage(shinespark.damage_type, shinespark.damage_amount)

func update_fire_pos():
	
	if not Samus.Animator.current[false]:
		return
	
	var position_node_path = Samus.Animator.current[false].position_node_path
	if not position_node_path in fire_pos_nodes:
		if fire_pos != null:
			fire_pos.is_current = false
			fire_pos.reset()
		fire_pos = null
		return null
	var pos: SamusCannonPosition = fire_pos_nodes[position_node_path]
	
	if fire_pos != null:
		fire_pos.is_current = false
		fire_pos.reset()
	
	if not Samus.facing in pos.allowed_facing_directions:
		fire_pos = null
		return
	
	fire_pos = pos
	fire_pos.is_current = true
		
	if Samus.facing == Enums.dir.RIGHT:
		fire_pos.position.x += (pos.position.x * -1 + 8) - pos.position.x
		fire_pos.rotation = (Vector2(-1, 0).rotated(pos.rotation) * Vector2(-1, 1)).angle()
	
	CannonPositionAnchor.global_position = fire_pos.global_position
	
	return fire_pos

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

func room_transitioning():
	if Settings.get("control_options/reset_weapon_on_door_enter"):
		reset_weapon_selection(morphball, aiming_style)
		update_weapon_icons()
