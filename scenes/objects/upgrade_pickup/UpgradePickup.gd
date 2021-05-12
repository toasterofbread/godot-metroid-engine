tool
extends Area2D

export var unique_id: String
export (Enums.Upgrade) var upgrade_type: int setget set_upgrade_type

var _save_path_acquired: Array
var acquired: bool = false setget set_acquired

func set_upgrade_type(value: int):
	$AnimatedSprite.play(Enums.Upgrade.keys()[value].to_lower())
	upgrade_type = value

func set_acquired(value: bool):
	Loader.Save.set_data_key(_save_path_acquired, value)
	self.visible = !value
	$CollisionShape2D.set_deferred("disabled", value)
	acquired = value

func _ready():
	
	if Engine.is_editor_hint():
		return
	_save_path_acquired = ["rooms", Loader.current_room.unique_id, "UpgradePickups", unique_id]
	$AnimatedSprite.play(Enums.Upgrade.keys()[upgrade_type].to_lower())
	set_acquired(Loader.Save.get_data_key(_save_path_acquired) or false)

func _on_UpgradePickup_body_entered(body):
	if body != Loader.Samus:
		return
	
	$CollectionPopup.trigger(upgrade_type)
	set_acquired(true)

