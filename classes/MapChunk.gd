extends Control
class_name MapChunk

export var map_grid_position: Vector2
export(MapTile.icons) var icon = MapTile.icons.none
export(MapTile.colours) var colour = MapTile.colours.blue
export(MapTile.wall_types) var left_wall = MapTile.wall_types.none
export(MapTile.wall_types) var right_wall = MapTile.wall_types.none
export(MapTile.wall_types) var top_wall = MapTile.wall_types.none
export(MapTile.wall_types) var bottom_wall = MapTile.wall_types.none

onready var CollisionArea: Area2D = Area2D.new()
onready var CollisionBox: CollisionShape2D = CollisionShape2D.new()

var tile: MapTile

func _ready():
	
	Map.chunks_to_load.append(self)
	
	self.add_child(CollisionArea)
	CollisionArea.add_child(CollisionBox)
	CollisionBox.shape = RectangleShape2D.new()
	CollisionBox.shape.extents = self.rect_size / 2
	CollisionBox.position = self.rect_size / 2
	CollisionBox.modulate = Color("00ff87")
	CollisionBox.z_as_relative = false
	CollisionBox.z_index = -100
	
	CollisionArea.connect("body_entered", Map, "samus_entered_chunk", [self])
	
	if not Map.tiles:
		yield(Map, "tiles_loaded")
	tile = Map.get_tile(map_grid_position)

func generate_tile_data():
	var data: Dictionary = Global.load_json(Map.tile_data_path)
	
	var x = str(map_grid_position.x)
	var y = str(map_grid_position.y)
	
	if not x in data:
		data[x] = {}
		
	data[x][y] = {"w": [top_wall, right_wall, bottom_wall, left_wall], "i": icon, "c": colour}
	
	Global.save_json(Map.tile_data_path, data, false)
