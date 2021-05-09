extends Control

func _ready():
	Loader.load_room(preload("res://scenes/rooms/TEST2/TestLevel.tscn").instance())
	yield(Loader, "room_loaded")
	self.queue_free()
