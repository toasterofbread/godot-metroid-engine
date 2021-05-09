extends Node2D
class_name MapTile

enum wall_types {none, door, wall}
enum icons {none, save, obtained_item, unobtained_item}
enum colours {blue, green, red}

var colour_data = {
	colours.blue: Color.darkcyan,
	colours.green: Color.darkgreen,
	colours.red: Color.darkred
}

var current_tile: bool = false setget set_current_tile
func set_current_tile(value: bool):
	current_tile = value
	
	if current_tile:
		$AnimationPlayer.play("current_tile")
		Map.Grid.focus_position = self.position
	else:
		$AnimationPlayer.stop()
		$CurrentTileOverlay.visible = false

func load_data(data: Dictionary):
	
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
	
	match int(data["i"]):
		icons.none: $Icon.queue_free()
		icons.save: $Icon.play("save")
		icons.obtained_item: $Icon.play("obtained_item")
		icons.unobtained_item: $Icon.play("unobtained_item")
		_: push_error("Unknown MapTile icon name")
	
	if int(data["c"]) in colour_data:
		$ColorRect.color = colour_data[int(data["c"])]
	
	$Lines/Wall.queue_free()
	$Lines/Door.queue_free()
