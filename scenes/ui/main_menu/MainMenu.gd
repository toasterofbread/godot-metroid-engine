extends Control

func _ready():
	Loader.load_room("TEST")
	yield(Loader, "room_loaded")
	self.queue_free()
