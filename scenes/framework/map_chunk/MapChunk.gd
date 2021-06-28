tool
extends CollisionShape2D
class_name MapChunk

signal tile_set

export var grid_position: Vector2
export(MapTile.icons) var icon: = MapTile.icons.none
export(MapTile.colours) var colour = MapTile.colours.default
export(MapTile.wall_types) var left_wall = MapTile.wall_types.none
export(MapTile.wall_types) var right_wall = MapTile.wall_types.none
export(MapTile.wall_types) var top_wall = MapTile.wall_types.none
export(MapTile.wall_types) var bottom_wall = MapTile.wall_types.none
#export var reset_size = false setget reset_size

onready var area: Area2D = Area2D.new()
var tile: MapTile

#func reset_size(_value=false):
#	shape.extents = Vector2(256, 256)
#	reset_size = false

func _ready():
	
	modulate = Color("ff008f")
	
	if Engine.editor_hint:
		if not shape:
			shape = RectangleShape2D.new()
#			reset_size()
		return
	
	var room: Room = get_parent().get_parent()
	grid_position += room.grid_position
	if colour == MapTile.colours.default:
		colour = room.default_mapchunk_colour
	
	area.set_collision_layer_bit(0, false)
	area.set_collision_layer_bit(15, false)
	area.set_collision_mask_bit(18, true)
	
	yield(get_parent(), "ready")
	get_parent().add_child(area)
	Global.reparent_child(self, area)
	area.connect("body_entered", Map, "samus_entered_chunk", [self])
	area.connect("body_exited", Map, "samus_exited_chunk", [self])
	yield(Map, "samus_entered_chunk")
	
	if Map.tiles == null:
		yield(Map, "tiles_loaded")
	tile = Map.get_tile(grid_position)
	emit_signal("tile_set")


func generate_tile_data():
	var data: Dictionary = Global.load_json(Map.tile_data_path)
	
	var x = str(grid_position.x)
	var y = str(grid_position.y)
	
	if not x in data:
		data[x] = {}
		
	data[x][y] = {"w": [top_wall, right_wall, bottom_wall, left_wall], "i": icon, "c": colour}
	
	Global.save_json(Map.tile_data_path, data, false)

func set_upgrade_icon(pickup: Area2D):
	if tile == null:
		yield(self, "tile_set")
	if pickup.acquired:
		tile.icon = tile.icons.obtained_item
	else:
		tile.icon = tile.icons.unobtained_item
