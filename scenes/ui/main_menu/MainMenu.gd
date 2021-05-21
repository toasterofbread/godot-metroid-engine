extends Control

func _ready():
	Loader.load_room("TEST2")
	yield(Loader, "room_loaded")
	self.queue_free()
