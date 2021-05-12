extends AnimatedSprite

var grid_position setget set_grid_position
var moving: bool = false setget set_moving

func set_grid_position(value):
	if value != null:
		if not self.get_parent():
			Map.Grid.Tiles.add_child(self)
		self.position = value*8
	else:
		if self.get_parent():
			Map.Grid.Tiles.remove_child(self)
	grid_position = value

func set_moving(value: bool):
	$MovementOverlay.visible = value
	moving = value

func save_data():
	if grid_position != null:
		Loader.Save.set_data_key(["map", "marker"], Global.vector2array(grid_position))
	else:
		Loader.Save.set_data_key(["map", "marker"], null)

func load_data():
	var data = Loader.Save.get_data_key(["map", "marker"])
	if data != null:
		set_grid_position(Global.array2vector(data))
