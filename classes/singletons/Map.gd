extends Node

signal tiles_loaded
const tile_data_path = "res://scenes/ui/map/tile_data.json"

signal samus_entered_chunk

onready var TileScene: PackedScene = preload("res://scenes/ui/map/MapTile.tscn")
var Grid: Control
var Marker: Node2D = preload("res://scenes/ui/map/MapMarker.tscn").instance()
var tiles = null
var current_chunk: MapChunk

func _ready():
	yield(Loader.Samus, "ready")
	Marker.load_data()
	load_tiles()

func get_tile(tile_position: Vector2):
	var x = str(tile_position.x)
	var y = str(tile_position.y)
	return tiles[x][y]

func samus_entered_chunk(body, chunk: MapChunk):
	if body != Loader.Samus:
		return
	
	emit_signal("samus_entered_chunk", chunk)
	if not tiles:
		yield(self, "ready")
	
	if is_instance_valid(current_chunk) and current_chunk != null:
		current_chunk.tile.current_tile = false
		
	current_chunk = chunk
	current_chunk.tile.current_tile = true

func samus_exited_chunk(body, chunk: MapChunk):
	pass

func load_tiles():
	
	var tile_data = {}
	var data: Dictionary = Global.load_json(tile_data_path)
	
	for x in data:
		if x == "marker":
			continue
		for y in data[x]:
			var tile = TileScene.instance()
			tile.load_data(data[x][y])
			Grid.Tiles.add_child(tile)
			tile.position = Vector2(int(x), int(y))*8
			
			if not x in tile_data:
				tile_data[x] = {}
			tile_data[x][y] = tile
	
	tiles = tile_data
	emit_signal("tiles_loaded")
