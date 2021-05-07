extends Control

func _ready():
	Loader.load_room(preload("res://scenes/rooms/TEST/TestLevel.tscn").instance())
	yield(Loader, "room_loaded")
	self.queue_free()
