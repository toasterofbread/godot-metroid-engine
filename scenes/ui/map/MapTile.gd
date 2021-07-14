extends Node2D
class_name MapTile

enum wall_types {none, door, wall}
enum icons {none, save, obtained_item, unobtained_item}
enum colours {default, blue, green, red}

var flash: bool = true setget set_flash

var x: String
var y: String

var icon: int = icons.none setget set_icon
var area_index: int
var discovered: bool = false setget set_discovered

var colour_data = {
	colours.default: Color.black,
	colours.blue: Color("004aa0"),
	colours.green: Color("075c00"),
}
var grid_position: Vector2

func _ready():
	$AnimationPlayer.play("reset")
	Loader.Save.add_save_function(funcref(self, "save"))

var current_tile: bool = false setget set_current_tile
func set_current_tile(value: bool):
	current_tile = value
	if current_tile:
		Map.Grid.focus_position = position
	update_flash()

func set_flash(value: bool):
	flash = value
	update_flash()

func update_flash():
	if flash and current_tile:
		$AnimationPlayer.play("current_tile")
	elif $AnimationPlayer.current_animation == "current_tile":
		$AnimationPlayer.play("reset")

func set_icon(value: int):
	icon = value
	
	$Icon.visible = true
	match icon:
		icons.none: $Icon.visible = false
		icons.save: $Icon.play("save")
		icons.obtained_item: $Icon.play("obtained_item")
		icons.unobtained_item: $Icon.play("unobtained_item")
		_: push_error("Unknown MapTile icon")

func set_discovered(value: bool):
	discovered = value
	visible = discovered

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
		
		wall_rotation += 90
	
	if data["i"]:
		set_icon(int(data["i"]))
	else:
		set_icon(icons.none)
	
	if int(data["c"]) in colour_data:
		$ColorRect.color = colour_data[int(data["c"])]
	
	area_index = int(data["a"])
	assert(area_index in Enums.MapAreas.values())
	
#	grid_position = Vector2(int(x), int(y))
	var discovered_chunks: Dictionary = Map.savedata["discovered_chunks"]
	set_discovered(x in discovered_chunks and y in discovered_chunks[x])
	
	$Lines/Wall.queue_free()
	$Lines/Door.queue_free()

func save():
	if discovered:
		var discovered_chunks: Dictionary = Map.savedata["discovered_chunks"]
		if not grid_position.x in discovered_chunks:
			discovered_chunks[x] = [y]
		else:
			discovered_chunks[x].append(y)
