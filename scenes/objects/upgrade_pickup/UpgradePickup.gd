tool
extends Area2D
class_name UpgradePickup

onready var Samus: KinematicBody2D = Loader.Samus
export (Enums.Upgrade) var upgrade_type: int = Enums.Upgrade.MISSILE setget set_upgrade_type

var unique_id: int
var save_path_acquired: Array
var acquired = false setget set_acquired

var gain_amount: int

func set_upgrade_type(value: int):
	$AnimatedSprite.play(Enums.Upgrade.keys()[value].to_lower())
	upgrade_type = value

func set_acquired(value):
	if value == null:
		value = false
	
	self.visible = !value
	$CollisionShape2D.set_deferred("disabled", value)
	acquired = value
	
	Loader.Save.set_data_key(save_path_acquired, value)

func _ready():
	
	if Engine.editor_hint:
		return
	
	$ScanNode.data_key = "pickup_" + Enums.Upgrade.keys()[upgrade_type].to_lower()
	
	save_path_acquired = ["rooms", Loader.current_room.id, "UpgradePickups", str(unique_id)]
	$AnimatedSprite.play(Enums.Upgrade.keys()[upgrade_type].to_lower())
	
	if upgrade_type in Enums.upgrade_gain_amounts:
		gain_amount = Enums.upgrade_gain_amounts[upgrade_type]
	else:
		gain_amount = 1
	
	set_acquired(Loader.Save.get_data_key(save_path_acquired))

func _on_UpgradePickup_body_entered(body):
	if body != Loader.Samus:
		return
	
	var current_amount: int = Loader.Save.get_data_key(["samus", "upgrades", upgrade_type, "amount"])
	Loader.Save.set_data_key(["samus", "upgrades", upgrade_type, "amount"], current_amount + gain_amount)
	
	if upgrade_type in Samus.Weapons.all_weapons:
		Samus.Weapons.all_weapons[upgrade_type].ammo += gain_amount
		if Samus.is_upgrade_active(upgrade_type):
			
			if upgrade_type in Enums.UpgradeTypes["visor"]:
				Samus.Weapons.add_visor(upgrade_type)
			else:
				Samus.Weapons.add_weapon(upgrade_type)
	
	set_acquired(true)
	
	$CollectionPopup.trigger(upgrade_type, gain_amount, current_amount+gain_amount)
