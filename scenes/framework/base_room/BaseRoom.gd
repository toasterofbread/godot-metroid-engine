extends Node2D
class_name Room

var id_info_set: bool = false
var id: String setget , get_id
var area: String setget , get_area
var area_index: int setget , get_area_index

export var heat_damage: bool = false
export var grid_position: Vector2 = Vector2.ZERO
export(MapTile.colours) var default_mapchunk_colour = MapTile.colours.blue

onready var upgradePickups = get_tree().get_nodes_in_group("UpgradePickip")
onready var doors = get_tree().get_nodes_in_group("Door")
onready var CameraChunks = $CameraChunks.get_children()
onready var MapChunks = $MapChunks.get_children()
var scanNodes: Array

onready var starting_children = get_children()

func set_visible(value: bool):
	for child in starting_children:
		if "visible" in child:
			child.visible = value

func get_id():
	set_id_info()
	return id
func get_area():
	set_id_info()
	return area
func get_area_index():
	set_id_info()
	return area_index

func set_id_info():
	if id_info_set:
		return
	
	id = filename.split("/")[len(filename.split("/")) - 3] + "/" + filename.split("/")[len(filename.split("/")) - 2]
	area = id.split("/")[0]
	area_index = Enums.MapAreas.keys().find(area.to_upper())
	id_info_set = true

# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_id_info()
	
	pause_mode = Node.PAUSE_MODE_STOP
	Loader.Save.add_save_function(funcref(self, "save"))
	
	vOverlay.SET("Room ID", id)
	
	# DEBUG
	if Loader.current_room == null:
		Loader.load_room(id)
		queue_free()
		return
	
#	for node in World.get_children() + self.get_children():
#		if node is UpgradePickup:
#			upgrade_pickups.append(node)
	
	var i = 0
	for upgradePickup in upgradePickups:
		upgradePickup.unique_id = i
		i += 1
	
	z_as_relative = false
	z_index = Enums.Layers.WORLD
	
	yield(self, "ready")
	scanNodes = get_tree().get_nodes_in_group("ScanNode")
	
	var all_scanNodes = scanNodes.duplicate()
	for scanNode in all_scanNodes:
		if not is_instance_valid(scanNode) or not is_a_parent_of(scanNode):
			scanNodes.erase(scanNode)

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

func save():
	Loader.Save.set_data_key(["current_room_id"], id)
