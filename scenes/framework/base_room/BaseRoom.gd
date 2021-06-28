extends Node2D
class_name Room

var id: String
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

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pause_mode = Node.PAUSE_MODE_STOP
	
	# Get the room's id from the parent folder name
	id = filename.split("/")[len(filename.split("/")) - 3] + "/" + filename.split("/")[len(filename.split("/")) - 2]
	vOverlay.SET("Room ID", id)
	
	z_index = Enums.Layers.WORLD
	z_as_relative = false
	
#	for node in World.get_children() + self.get_children():
#		if node is UpgradePickup:
#			upgrade_pickups.append(node)
	
	var i = 0
	for upgradePickup in upgradePickups:
		upgradePickup.unique_id = i
		i += 1
	
	z_as_relative = false
	z_index = Enums.Layers.WORLD
	
#	$Fluids.z_as_relative = false
#	$Fluids.z_index = Enums.Layers.FLUID
	
	if $Background is ParallaxBackground:
		for parallaxLayer in $Background.get_children():
			if parallaxLayer is ParallaxLayer:
				parallaxLayer.z_index = Enums.Layers.BACKGROUND
				parallaxLayer.z_as_relative = false
	
#	if scale != Vector2.ONE:
#		for child in get_children():
#			if "scale" in child:
#				child.scale *= scale
#			elif "rect_scale" in child:
#				child.rect_scale *= scale
#		scale = Vector2.ONE
	
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
