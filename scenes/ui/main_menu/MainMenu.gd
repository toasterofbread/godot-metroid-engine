extends Control

var generate_tile_data = false

func _ready():
	
	if generate_tile_data:
		Loader.generate_tile_data()
	else:
		Loader.load_room(Loader.Save.get_data_key(["current_room_id"]))
		yield(Loader, "room_loaded")
		self.queue_free()

