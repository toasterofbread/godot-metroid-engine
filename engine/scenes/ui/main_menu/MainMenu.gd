extends Control


func _ready():
	Loader.load_room(Loader.Save.get_data_key(["current_room_id"]))
	yield(Loader, "room_loaded")
	self.queue_free()

