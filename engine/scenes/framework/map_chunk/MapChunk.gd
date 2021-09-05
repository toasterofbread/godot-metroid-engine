tool
extends CollisionShape2D
class_name MapChunk

signal tile_set

export var grid_position: Vector2
var grid_position_adjusted: = false
export(MapTile.icons) var icon: = MapTile.icons.none
export(MapTile.wall_types) var left_wall = MapTile.wall_types.none
export(MapTile.wall_types) var right_wall = MapTile.wall_types.none
export(MapTile.wall_types) var top_wall = MapTile.wall_types.none
export(MapTile.wall_types) var bottom_wall = MapTile.wall_types.none
export(Array, NodePath) var upgrade_pickups_paths: Array = []
export var hidden: bool = false

var upgrade_pickups: Dictionary = {}
var upgrade_pickup_ids: Array = []

onready var area: ExArea2D = ExArea2D.new()
var tile: MapTile

func _ready():
	
	# DEBUG
	assert(icon == MapTile.icons.none or icon in MapTile.valid_export_icons)
	
	if not Loader.is_a_parent_of(self):
		return
	
	modulate = Color("ff008f")
	
	if Engine.editor_hint:
		if not shape:
			shape = RectangleShape2D.new()
		return
	
	for path in upgrade_pickups_paths:
		var upgradePickup = get_node_or_null(path)
		if upgradePickup != null:
			upgrade_pickups[upgradePickup] = false
			upgradePickup.connect("acquired", self, "upgradePickup_acquired", [upgradePickup])
	
	if not grid_position_adjusted:
		grid_position += get_parent().get_parent().grid_position
		grid_position_adjusted = true
	
	area.set_collision_layer_bit(0, false)
	area.set_collision_layer_bit(15, true)
	area.set_collision_mask_bit(0, false)
	
	yield(get_parent(), "ready")
	get_parent().add_child(area)
	Global.reparent_child(self, area)
	area.connect("body_entered_safe", Map, "samus_entered_chunk", [self])
	area.connect("body_exited_safe", Map, "samus_exited_chunk", [self])
	yield(Map, "samus_entered_chunk")
	
	if len(Map.tiles) == 0:
		yield(Map, "tiles_loaded")
	
	tile = Map.get_tile(grid_position)
	emit_signal("tile_set")

func generate_tile_data():
	
	var data: Dictionary = Global.load_json(Map.tile_data_path)
	
	var room: GameRoom = get_parent().get_parent()
	if not grid_position_adjusted:
		grid_position += room.grid_position
		grid_position_adjusted = true
	var x: String = str(grid_position.x)
	var y: String = str(grid_position.y)
	
	if not x in data:
		data[x] = {}
	
#	upgradePickup = get_node_or_null(upgrade_pickup) 
	
	for path in upgrade_pickups_paths:
		var upgradePickup = get_node_or_null(path)
		if upgradePickup != null:
#			upgrade_pickups[upgradePickup] = false
#			upgradePickup.connect("acquired", self, "upgradePickup_acquired", [upgradePickup])
			upgrade_pickup_ids.append(upgradePickup.id)
	
	data[x][y] = {
		"w": [top_wall, right_wall, bottom_wall, left_wall], # Walls
		"i": icon, # Icon
		"h": hidden, # Hidden
		"r": room.id, # Room ID
		"u": upgrade_pickup_ids # UpgradePickup IDs
		}
	
#	if not "areas" in data:
#		data["areas"] = {area: []}
#	elif not area in data["areas"]:
#		data["areas"][area] = []
#	data["areas"][area].append([x, y])
	
	Global.save_json(Map.tile_data_path, data, false)

func set_upgrade_icon(value: bool):
	if tile == null:
		yield(self, "tile_set")
	tile.icon = tile.icons.unobtained_item if value else tile.icons.obtained_item
	tile.save_icon()

func upgradePickup_acquired(upgradePickup: UpgradePickup):
	upgrade_pickups[upgradePickup] = true
	for acquired in upgrade_pickups.values():
		if not acquired:
			return
	set_upgrade_icon(false)

#func area_entered(area):
#	if not area is UpgradePickup or area.mapChunk != null:
#		return
#	set_upgrade_icon(true)
#	area.mapChunk = self
#	area.connect("acquired", self, "set_upgrade_icon", [false])
