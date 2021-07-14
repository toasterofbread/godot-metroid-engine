extends Control

onready var sprites = {
	true: preload("res://sprites/ui/map/equipment/selected.png"),
	false: preload("res://sprites/ui/map/equipment/unselected.png"),
}

onready var EquipmentItem = preload("res://scenes/ui/map/EquipmentItem.tscn")
enum GROUP {MISC, SUIT, BOOTS, WEAPONS, BEAMS}
const upgrade_data = {
	
	Enums.Upgrade.CHARGEBEAM: {"group": GROUP.BEAMS, "exclusive": false, "point": "cannon"}, 
#	POWERBEAM, 
	Enums.Upgrade.ICEBEAM: {"group": GROUP.BEAMS, "exclusive": false, "point": "cannon"}, 
	Enums.Upgrade.PLASMABEAM: {"group": GROUP.BEAMS, "exclusive": false, "point": "cannon"}, 
	Enums.Upgrade.SPAZERBEAM: {"group": GROUP.BEAMS, "exclusive": false, "point": "cannon"}, 
	Enums.Upgrade.WAVEBEAM: {"group": GROUP.BEAMS, "exclusive": false, "point": "cannon"}, 
	Enums.Upgrade.GRAPPLEBEAM: {"group": GROUP.BEAMS, "exclusive": false, "point": "cannon"},
	
	Enums.Upgrade.SCREWATTACK: {"group": GROUP.WEAPONS, "exclusive": false, "point": "body"}, 
	Enums.Upgrade.BOMB: {"group": GROUP.WEAPONS, "exclusive": false, "point": "body"},
	Enums.Upgrade.POWERBOMB: {"group": GROUP.WEAPONS, "exclusive": false, "point": "body"},
	Enums.Upgrade.MISSILE: {"group": GROUP.WEAPONS, "exclusive": false, "point": "cannon"},
	Enums.Upgrade.SUPERMISSILE: {"group": GROUP.WEAPONS, "exclusive": false, "point": "cannon"},
	
	Enums.Upgrade.POWERSUIT: {"group": GROUP.SUIT, "exclusive": true, "point": "shoulder"},
	Enums.Upgrade.VARIASUIT: {"group": GROUP.SUIT, "exclusive": true, "point": "shoulder"}, 
	Enums.Upgrade.GRAVITYSUIT: {"group": GROUP.SUIT, "exclusive": true, "point": "shoulder"}, 
	Enums.Upgrade.SCANVISOR: {"group": GROUP.SUIT, "exclusive": false, "point": "visor"}, 
	Enums.Upgrade.XRAYVISOR: {"group": GROUP.SUIT, "exclusive": false, "point": "visor"},
	
	Enums.Upgrade.MORPHBALL: {"group": GROUP.MISC, "exclusive": false, "point": "body"}, 
	Enums.Upgrade.SPIDERBALL: {"group": GROUP.MISC, "exclusive": false, "point": "body"}, 
	Enums.Upgrade.SPRINGBALL: {"group": GROUP.MISC, "exclusive": false, "point": "body"}, 
	Enums.Upgrade.POWERGRIP: {"group": GROUP.MISC, "exclusive": false, "point": "hand"}, 
	
	Enums.Upgrade.HIGHJUMP: {"group": GROUP.BOOTS, "exclusive": false, "point": "boots"}, 
	Enums.Upgrade.SPACEJUMP: {"group": GROUP.BOOTS, "exclusive": false, "point": "boots"}, 
	Enums.Upgrade.SPEEDBOOSTER: {"group": GROUP.BOOTS, "exclusive": false, "point": "boots"}, 
	
}

var selected_item: Control

func _ready():
	visible = false
#	$AnimationPlayer.play("open", -1, 1.0, true)
	
	var i = 0
	var save_data = Loader.Save.get_data_key(["samus", "upgrades"])
	for upgrade in upgrade_data:
		
		var node = EquipmentItem.instance()
		match upgrade_data[upgrade]["group"]:
			GROUP.WEAPONS: $Left/Weapons/VBoxContainer.add_child(node)
			GROUP.BEAMS: $Left/Beams/VBoxContainer.add_child(node)
			
			GROUP.MISC: $Right/Misc/VBoxContainer.add_child(node)
			GROUP.SUIT: $Right/Suit/VBoxContainer.add_child(node)
			GROUP.BOOTS: $Right/Boots/VBoxContainer.add_child(node)
		if i == 0:
			node.selected = true
			selected_item = node
		
		upgrade_data[upgrade]["point"] = $Samus/Sprite/Points.get_node(upgrade_data[upgrade]["point"])
		node.init(upgrade, upgrade_data[upgrade], sprites)
		node.unobtained = save_data[upgrade]["amount"] < 1
		
		i += 1

func open():
	$AnimationPlayer.play("open")
	yield($AnimationPlayer, "animation_finished")
	selected_item.opened()

func close(instant: bool = false):
	selected_item.closed()
	$AnimationPlayer.play("close", -1, INF if instant else 1.0)
#	yield($AnimationPlayer, "animation_finished")

func process():
	var pad_vector = Shortcut.get_pad_vector("just_pressed")
	
	var group: Control = selected_item.get_parent()
	if pad_vector.y != 0:
		selected_item.selected = false
		if selected_item.get_position_in_parent() == 0 and pad_vector.y == -1:
			var dest = group.get_parent().get_node_or_null(str(group.get_parent().focus_neighbour_top) + "/VBoxContainer")
			if dest:
				selected_item = dest.get_child(dest.get_child_count() - 1)
			selected_item.selected = true
		elif selected_item.get_position_in_parent() + 1 == group.get_child_count() and pad_vector.y == 1:
			var dest = group.get_parent().get_node_or_null(str(group.get_parent().focus_neighbour_bottom) + "/VBoxContainer")
			if dest:
				selected_item = dest.get_child(0)
			selected_item.selected = true
		else:
			selected_item = group.get_child(selected_item.get_position_in_parent() + pad_vector.y)
			selected_item.set_selected(true, true, true)
	elif pad_vector.x != 0:
		selected_item.set_selected(false, true)
		
		var dest = group.get_parent().get_node_or_null(str(group.get_parent().focus_neighbour_right) + "/VBoxContainer")
		if not dest:
			dest = group.get_parent().get_node_or_null(str(group.get_parent().focus_neighbour_left) + "/VBoxContainer")
		if dest:
			selected_item = dest.get_child(0)
		selected_item.set_selected(true, true)
	
	if Input.is_action_just_pressed("ui_accept"):
		selected_item.toggle()
