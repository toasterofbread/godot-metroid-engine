extends Node2D
class_name MapTile

enum wall_types {none, door, wall}
enum icons {none, save, mapstation, obtained_item, unobtained_item}
const valid_export_icons = [icons.save, icons.mapstation]

var flash: bool = true setget set_flash

var x: String
var y: String

var hidden: bool = false
var icon: int = icons.none setget set_icon
var area_index: int
var revealed: bool = false setget set_revealed
var entered: bool = false setget set_entered

var colour_values = {
	"entered": Color("004aa0"),
	"revealed": Color("696969"), # nice
	"hidden": Color.green
}
var grid_position: Vector2

var walls: Dictionary = {
	
}

func _ready():
	$AnimationPlayer.play("reset")
	Loader.loaded_save.add_save_function(funcref(self, "save"))

var is_current_tile: bool = false setget set_is_current_tile
func set_is_current_tile(value: bool):
	is_current_tile = value
	if is_current_tile:
		Map.Grid.focus_position = position
	update_flash()

func set_flash(value: bool):
	flash = value
	update_flash()

func update_flash():
	if flash and is_current_tile:
		$AnimationPlayer.play("current_tile")
	elif $AnimationPlayer.current_animation == "current_tile":
		$AnimationPlayer.play("reset")

func set_icon(value: int):
	icon = value
	
	match icon:
		icons.none: $Icon.visible = false
		icons.save: $Icon.play("save")
		icons.mapstation: $Icon.play("mapstation")
		icons.obtained_item: $Icon.play("obtained_item")
		icons.unobtained_item: $Icon.play("unobtained_item")
		_: push_error("Unknown MapTile icon")
	
	set_entered(entered)

func set_revealed(value: bool):
	revealed = value
	visible = revealed
	update_colour()
	if revealed:
		check_for_wall_overlap()

func set_entered(value: bool):
	entered = value
	if icon in [icons.obtained_item, icons.unobtained_item]:
		$Icon.visible = entered
	update_colour()
	if entered and not revealed:
		set_revealed(true)

func load_data(data: Dictionary, x: String, y: String):
	
	self.x = x
	self.y = y
	
	var wall_rotation: int = 0
	for wall in data["w"]:
		
		var wall_sprite: Sprite
		match int(wall):
			wall_types.wall: wall_sprite = $Lines/Wall.duplicate()
			wall_types.door: wall_sprite = $Lines/Door.duplicate()
		
		if wall_sprite:
			$Lines.add_child(wall_sprite)
			wall_sprite.rotation_degrees = wall_rotation
			walls[wall_rotation] = wall_sprite
		
		wall_rotation += 90
	
	if data["i"] in valid_export_icons:
		set_icon(int(data["i"]))
	elif len(data["u"]) > 0:
		var set: bool = false
		for upgradePickup_id in data["u"]:
			if not upgradePickup_id in Loader.loaded_save.get_data_key(["rooms", Loader.current_room.id, "acquired_upgradepickups"]):
				set_icon(icons.unobtained_item)
				set = true
				break
		if not set:
			set_icon(icons.obtained_item)
	else:
		set_icon(icons.none)
	
#	if int(data["c"]) in colour_data:
#		$ColorRect.color = colour_data[int(data["c"])]
	
	var room_id: String = data["r"]
#	area_index = Enums.MapAreas.keys().find(room_id.split("/")[0].to_upper())
	area_index = Data.data["map"].keys().find(room_id.split("/")[0])
#	assert(area_index in Enums.MapAreas.values())
	
	grid_position = Vector2(int(x), int(y))
	
	var entered_chunks: Dictionary = Map.savedata["entered_chunks"]
	set_entered(x in entered_chunks and y in entered_chunks[x])
	var revealed_chunks: Dictionary = Map.savedata["revealed_chunks"]
	set_revealed(x in revealed_chunks and y in revealed_chunks[x])
	
	hidden = data["h"]
	update_colour()
	
	$Lines/Wall.queue_free()
	$Lines/Door.queue_free()

func update_colour():
	if hidden:
		if entered:
			$ColorRect.color = colour_values["hidden"]
	elif entered:
		$ColorRect.color = colour_values["entered"]
	elif revealed: 
		$ColorRect.color = colour_values["revealed"]

# DEBUG
func save_icon():
	var current_data: Dictionary = Global.load_json(Map.tile_data_path)
	current_data[x][y]["i"] = icon
	Global.save_json(Map.tile_data_path, current_data)

func save():
	if revealed:
		var revealed_chunks: Dictionary = Map.savedata["revealed_chunks"]
		if not grid_position.x in revealed_chunks:
			revealed_chunks[x] = [y]
		elif not y in revealed_chunks[x]:
			revealed_chunks[x].append(y)
	if entered:
		var entered_chunks: Dictionary = Map.savedata["entered_chunks"]
		if not grid_position.x in entered_chunks:
			entered_chunks[x] = [y]
		elif not y in entered_chunks[x]:
			entered_chunks[x].append(y)

func get_adjacent_tile(direction):
	
	if direction is float or direction is int:
		direction = Vector2(0, -1).rotated(deg2rad(direction))
	elif not direction is Vector2:
		assert(false, "Invalid type for direction")
		return null
	
	return Map.get_tile(grid_position + direction)

# If adjacent tiles have a wall or door overlapping with this one, remove one of them
func check_for_wall_overlap():
	
	var to_remove: Array = []
	for wall_rotation in walls:
		
		# Get the tile adjacent to this one in the direction of the wall
		var target_tile: MapTile = get_adjacent_tile(wall_rotation)
		if not target_tile:
			continue
		
		# Check if the adjacent tile has a wall facing this tile
		var target_wall_rotation: int = int(Global.invert_angle(wall_rotation, true))
		if not target_wall_rotation in target_tile.walls:
			continue
		
		# If both tiles have walls, the wall with more connecting walls 
		# is kept, while the one with less is removed
		var priority: int = 0
		
		# Check walls to the left and right of the wall on this tile, and the target tile
		var tile: MapTile
		for direction in [90, -90]:
			# Target tile
			tile = target_tile.get_adjacent_tile(target_wall_rotation + direction)
			if tile and target_wall_rotation in tile.walls:
				priority -= 1
			
			# This tile
			tile = get_adjacent_tile(wall_rotation + direction)
			if tile and wall_rotation in tile.walls:
				priority += 1
		
		if target_tile.icon != icons.none:
			priority += 1
		if icon != icons.none:
			priority -= 1
		
		# If priority is above 0 remove the wall from the target tile (and vice-versa)
		if priority <= 0:
			to_remove.append(wall_rotation)
		else:
			target_tile.walls[target_wall_rotation].queue_free()
			target_tile.walls.erase(target_wall_rotation)
	
	for wall_rotation in to_remove:
		walls[wall_rotation].queue_free()
		walls.erase(wall_rotation)
