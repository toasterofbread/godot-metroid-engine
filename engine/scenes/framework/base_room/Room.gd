extends Node2D
class_name Room

var is_preview: bool = false

var id_info_set: bool = false
var id: String setget , get_id
var area: String setget , get_area
var area_index: int setget , get_area_index

export var heat_damage: bool = false
export var grid_position: Vector2 = Vector2.ZERO

onready var upgrade_pickups = get_tree().get_nodes_in_group("UpgradePickip")
onready var doors = Enums.get_nodes_in_group(Enums.Groups.DOOR)
onready var camera_chunks = $CameraChunks.get_children()
onready var map_chunks = $MapChunks.get_children()
var scan_nodes: Array
var save_stations: Dictionary = {}

var spawnPosition = null

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
	area_index = Data.data["map_areas"].keys().find(area.to_upper())
	id_info_set = true

func init(data: Dictionary):
	
	# DEBUG
	assert(not is_inside_tree(), "Room must be initialised before entering the scene tree")
	
	if "preview" in data:
		is_preview = data["preview"]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_id_info()
	
	# DEBUG | Handles launching current scene with F6
	if Loader.current_room == null:
		Loader.load_room(id)
		queue_free()
		return
	
	pause_mode = Node.PAUSE_MODE_STOP
	Loader.Save.add_save_function(funcref(self, "save"))
	vOverlay.SET("Room ID", id)
	
	var room_data: Dictionary = Loader.Save.get_data_key(["rooms"])
	if not id in room_data:
		room_data[id] = {
			"acquired_upgradepickups": []
		}
	
	for saveStation in Enums.get_nodes_in_group(Enums.Groups.SAVESTATION):
		save_stations[saveStation.id] = saveStation
	
	# Ensure UpgradePickup IDs within this room are unique
	var ids: Array = []
	for upgradePickup in upgrade_pickups:
		assert(not upgradePickup.id in ids)
		ids.append(upgradePickup.id)
	
	z_as_relative = false
	z_index = Enums.Layers.WORLD
	
	var spawn_positions = get_tree().get_nodes_in_group("SpawnPosition")
	
	for position in spawn_positions:
		if not is_a_parent_of(position):
			spawn_positions.erase(position)
	
	if len(spawn_positions) == 1:
		spawnPosition = spawn_positions[0]
	elif len(spawn_positions) == 0:
		assert(false, "No SpawnPositions found in room")
		return "No SpawnPositions found in room"
	else:
		push_warning("Multiple SpawnPositions found in room: " + id)
	
	if is_preview:
		for enemy in Enums.get_nodes_in_group(Enums.Groups.ENEMY):
			enemy.queue_free()
	
	yield(self, "ready")
	scan_nodes = Enums.get_nodes_in_group(Enums.Groups.SCANNODE)
	
	var all_scan_nodes = scan_nodes.duplicate()
	for scanNode in all_scan_nodes:
		if not is_instance_valid(scanNode) or not is_a_parent_of(scanNode):
			scan_nodes.erase(scanNode)

#func transitioning():
#	for node in CameraChunks:
#		node.queue_free()
#		yield(node, "tree_exited")

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

signal earthquake
func earthquake(center: Vector2, strength: float, duration):
	emit_signal("earthquake", center, strength)
	Global.shake_camera(Loader.Samus.camera, Vector2.ZERO, strength*10, duration)
