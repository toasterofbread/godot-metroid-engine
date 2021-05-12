extends Node2D

signal room_loaded

var current_room: Room
var Samus: KinematicBody2D = preload("res://scenes/Samus/Samus.tscn").instance()
var room_container: Node2D = self
var Save: SaveGame = SaveGame.new(SaveGame.debug_save_path)
var transitioning: bool = false

func add_samus():
	while current_room == null:
		yield(Global, "process_frame")
	if not Samus in current_room.get_children():
		current_room.add_child(Samus)
		Samus.global_position = Vector2(-256, -240)

func load_room(room: Room):
	current_room = room
	room_container.add_child(room)
	room.add_child(Samus)
	
	var samus_spawn_position: Vector2
	for node in room.get_children():
		if node.is_in_group("SamusSpawnPositions"):
			samus_spawn_position = node.global_position
			break
	
	if samus_spawn_position:
		Samus.global_position = samus_spawn_position
	else:
		assert(false, "No SamusSpawnPosition node registered to room")
		
	emit_signal("room_loaded")

func transition(origin_door: Door):
	
	if transitioning:
		return
	
	transitioning = true
	Samus.paused = true
	
	yield(origin_door.load_target_room(), "completed")
	var room = origin_door.target_room_instance
	var destination_door = origin_door.destination_door
	
	# Move Samus to new loaded room and reposition her
	var samus_position = Samus.global_position
	Global.reparent_child(Samus, room)
	Samus.global_position = samus_position# + Vector2(-50, 0).rotated(deg2rad(origin_door.rotation_degrees))
	yield(Global.wait(0.1), "completed")
	Samus.paused = false
	
	current_room.queue_free()
	current_room = room
	transitioning = false
	
	yield(Global.wait(1.0), "completed")
	destination_door.close()
