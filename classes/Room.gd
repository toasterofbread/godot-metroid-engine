extends Node2D
class_name Room

var id: String
export var heat_damage: bool = false
export var all_water: bool = false
export var all_lava: bool = false

onready var World: Node2D = $World

var upgrade_pickups = []
onready var Doors = $World/Doors.get_children()
onready var CameraChunks = $CameraChunks.get_children()
onready var MapChunks = $MapChunks.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Get the room's id from the parent folder name
	id = filename.split("/")[len(filename.split("/")) - 2]
	vOverlay.SET("Room ID", id)
	
	z_index = Enums.Layers.WORLD
	z_as_relative = false
	
	for node in World.get_children() + self.get_children():
		if node is UpgradePickup:
			upgrade_pickups.append(node)
	
	var i = 0
	for upgrade in upgrade_pickups:
		upgrade.unique_id = i
		i += 1

func transitioning():
	for node in CameraChunks:
		node.queue_free()
		yield(node, "tree_exited")

func generate_maptiles():
	var i = 0
	for child in self.get_children():
		if child.name == "MapChunks":
			for mapchunk in self.get_child(i).get_children():
				mapchunk.generate_tile_data()
			break
		i += 1
