extends Node

signal tiles_loaded
const tile_data_path = "res://engine/scenes/ui/map/tile_data.json"

signal samus_entered_chunk

onready var TileScene: PackedScene = preload("res://engine/scenes/ui/map/MapTile.tscn")
var Grid: Control
var Marker: Node2D = preload("res://engine/scenes/ui/map/MapMarker.tscn").instance()
var tiles: Dictionary
var tiles_by_area: Dictionary = {}
var tile_data: Dictionary
onready var savedata: Dictionary = Loader.Save.get_data_key(["map"])

var current_chunk: MapChunk
var previous_chunk = null
var current_tile: MapTile

func _ready():
	
	yield(Loader.Samus, "ready")
	Marker.load_data()
	load_tiles()

func get_tile(tile_position: Vector2):
	var x = str(tile_position.x)
	var y = str(tile_position.y)
	
	if not x in tiles or not y in tiles[x]:
		return null
	
	return tiles[x][y]

func samus_entered_chunk(body, chunk: MapChunk):
	if body != Loader.Samus or chunk == current_chunk:
		return
	
	emit_signal("samus_entered_chunk", chunk)
	if not tiles:
		yield(self, "ready")
	
	chunk.tile.discovered = true
	chunk.tile.explored = true
	
	if is_instance_valid(current_chunk) and current_chunk != null:
		current_chunk.tile.is_current_tile = false
		previous_chunk = current_chunk
	elif current_tile != null:
		current_tile.is_current_tile = false
	
	current_chunk = chunk
	current_tile = current_chunk.tile
	current_tile.is_current_tile = true

func samus_exited_chunk(body, chunk: MapChunk):
	if is_instance_valid(previous_chunk) and previous_chunk != null and body == Loader.Samus:
		if chunk == current_chunk:
			current_chunk.tile.is_current_tile = false
			current_chunk = previous_chunk
			emit_signal("samus_entered_chunk", current_chunk)
			previous_chunk = chunk
			current_chunk.tile.is_current_tile = true
		elif chunk == previous_chunk:
			previous_chunk = null

func load_tiles():
	
	tile_data = Global.load_json(tile_data_path)
	tiles.clear()
	tiles_by_area.clear()
	
	for x in tile_data:
		if x == "areas":
			continue
		for y in tile_data[x]:
			var tile = TileScene.instance()
			tile.load_data(tile_data[x][y], x, y)
			Grid.Tiles.add_child(tile)
			tile.position = Vector2(int(x), int(y))*8
			
			if not x in tiles:
				tiles[x] = {}
			tiles[x][y] = tile
			
			if not tile.area_index in tiles_by_area:
				tiles_by_area[tile.area_index] = [tile]
			else:
				tiles_by_area[tile.area_index].append(tile)
	
#	for tile in Grid.Tiles.get_children():
#		tile.check_for_wall_overlap()
	
	emit_signal("tiles_loaded")
