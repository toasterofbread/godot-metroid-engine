tool
extends Area2D
class_name UpgradePickup

export var gain_amount: int = 0
export (Enums.Upgrade) var upgrade_type: int = Enums.Upgrade.MISSILE setget set_upgrade_type
const default_amounts = {
	Enums.Upgrade.ETANK: 1,
	Enums.Upgrade.MISSILE: 5,
	Enums.Upgrade.SUPERMISSILE: 5,
	Enums.Upgrade.POWERBOMB: 1,
	
	Enums.Upgrade.BOMB: 1,
	Enums.Upgrade.MORPHBALL: 1,
	Enums.Upgrade.SPRINGBALL: 1,
	Enums.Upgrade.SPEEDBOOSTER: 1,
	Enums.Upgrade.POWERGRIP: 1,
	Enums.Upgrade.SPACEJUMP: 1,
	Enums.Upgrade.SCREWATTACK: 1,
	Enums.Upgrade.SPIDERBALL: 1,
	
	Enums.Upgrade.XRAY: 1,
	Enums.Upgrade.SCAN: 1,
}

var unique_id: int
var _save_path_acquired: Array
var acquired: bool = false setget set_acquired


func set_upgrade_type(value: int):
	$AnimatedSprite.play(Enums.Upgrade.keys()[value].to_lower())
	gain_amount = default_amounts[value]
	upgrade_type = value

func set_acquired(value: bool):
	self.visible = !value
	$CollisionShape2D.set_deferred("disabled", value)
	acquired = value

func _ready():
	
	if Engine.is_editor_hint():
		return
	assert(upgrade_type in default_amounts, "Invalid upgrade type")
	_save_path_acquired = ["rooms", Loader.current_room.unique_id, "UpgradePickups", str(unique_id)]
	$AnimatedSprite.play(Enums.Upgrade.keys()[upgrade_type].to_lower())
	gain_amount = default_amounts[upgrade_type]
	set_acquired(Loader.Save.get_data_key(_save_path_acquired) or false)
	print(gain_amount)

func _on_UpgradePickup_body_entered(body):
	if body != Loader.Samus:
		return
	
	$CollectionPopup.trigger(upgrade_type)
	set_acquired(true)
	Loader.Save.set_data_key(_save_path_acquired, true)
	
	var current_amount: int = Loader.Save.get_data_key(["samus", "upgrades", upgrade_type, "amount"])
	Loader.Save.set_data_key(["samus", "upgrades", upgrade_type, "amount"], current_amount + gain_amount)
