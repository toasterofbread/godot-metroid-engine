extends Node2D
class_name Room

export var unique_id: String
export var heat_damage: bool = false
export var all_water: bool = false
export var all_lava: bool = false

var doors = []
var upgrade_pickups = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for node in self.get_children():
		if node is Door:
			doors.append(node)
		elif node is UpgradePickup:
			upgrade_pickups.append(node)
	
	var i = 0
	for upgrade in upgrade_pickups:
		upgrade.unique_id = i
		i += 1
