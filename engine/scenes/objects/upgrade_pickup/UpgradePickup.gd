tool
extends Area2D
class_name UpgradePickup

signal acquired

onready var Samus: KinematicBody2D = Loader.Samus
export (Enums.Upgrade) var upgrade_type: int = Enums.Upgrade.MISSILE setget set_upgrade_type
export var id: String
#export var hidden: = false setget set_hidden

#var unique_id: int
var save_path_acquired: Array
var acquired = false
var gain_amount: int
var mapChunk = null

func set_upgrade_type(value: int):
	$AnimatedSprite.play(Enums.Upgrade.keys()[value].to_lower())
	upgrade_type = value

func acquire():
#	mapChunk.set_upgrade_icon(false)
	emit_signal("acquired")
	Loader.loaded_save.get_data_key(save_path_acquired).append(id)
	queue_free()

func _ready():
	
	if Engine.editor_hint:
		return
	
	
	if Loader.current_room == null:
		yield(Loader, "room_loaded")
	
	save_path_acquired = ["rooms", Loader.current_room.id, "acquired_upgradepickups"]
	var acquired_upgradepickups = Loader.loaded_save.get_data_key(save_path_acquired)
	if acquired_upgradepickups == null:
		yield(Loader.current_room, "ready")
		acquired_upgradepickups = Loader.loaded_save.get_data_key(save_path_acquired)
	if id in acquired_upgradepickups:
		queue_free()
	
	$ScanNode.data_key = Enums.Upgrade.keys()[upgrade_type]
	$AnimatedSprite.play(Enums.Upgrade.keys()[upgrade_type].to_lower())
	
	if upgrade_type in Enums.upgrade_gain_amounts:
		gain_amount = Enums.upgrade_gain_amounts[upgrade_type]
	else:
		gain_amount = 1
	
	
	
#	set_hidden(hidden)

func _on_UpgradePickup_body_entered(body):
	if body != Loader.Samus:
		return
	
	var current_amount: int = Loader.loaded_save.get_data_key(["samus", "upgrades", upgrade_type, "amount"])
	Loader.loaded_save.set_data_key(["samus", "upgrades", upgrade_type, "amount"], current_amount + gain_amount)
	
	if upgrade_type in Samus.Weapons.all_weapons:
		Samus.Weapons.all_weapons[upgrade_type].ammo += gain_amount
		if Samus.is_upgrade_active(upgrade_type):
			
			if upgrade_type in Enums.UpgradeTypes["visor"]:
				Samus.Weapons.add_visor(upgrade_type)
			else:
				Samus.Weapons.add_weapon(upgrade_type)
	
	yield($CollectionPopup.trigger(upgrade_type, gain_amount, current_amount+gain_amount), "completed")
	acquire()

#func _on_UpgradePickup_area_entered(area):
#	if mapChunk == null and area.get_child_count() == 1 and area.get_child(0) is MapChunk:
#		mapChunk = area.get_child(0)
#		mapChunk.set_upgrade_icon(true)

#func set_hidden(value: bool):
#	hidden = value
#	if Engine.editor_hint:
#		return
#	visible = !hidden
