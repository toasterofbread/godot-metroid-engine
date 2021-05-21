tool
extends CollisionShape2D
class_name MapChunk

export var grid_position: Vector2
export(MapTile.icons) var icon = MapTile.icons.none
export(MapTile.colours) var colour = MapTile.colours.blue
export(MapTile.wall_types) var left_wall = MapTile.wall_types.none
export(MapTile.wall_types) var right_wall = MapTile.wall_types.none
export(MapTile.wall_types) var top_wall = MapTile.wall_types.none
export(MapTile.wall_types) var bottom_wall = MapTile.wall_types.none

var area: Area2D
var tile: MapTile

func _ready():
	
	if Engine.is_editor_hint():
		self.shape = RectangleShape2D.new()
		self.shape.extents = Vector2(256, 256)
		self.modulate = Color("00ff87")
		return
	
	generate_tile_data()
	yield(get_parent(), "ready")
	
	area = Area2D.new()
	self.get_parent().add_child(area)
	Global.reparent_child(self, area)
	
	area.connect("body_entered", Map, "samus_entered_chunk", [self])
	
	if Map.tiles == null:
		yield(Map, "tiles_loaded")
	tile = Map.get_tile(grid_position)

func generate_tile_data():
	var data: Dictionary = Global.load_json(Map.tile_data_path)
	
	var x = str(grid_position.x)
	var y = str(grid_position.y)
	
	if not x in data:
		data[x] = {}
		
	data[x][y] = {"w": [top_wall, right_wall, bottom_wall, left_wall], "i": icon, "c": colour}
	
	Global.save_json(Map.tile_data_path, data, false)
