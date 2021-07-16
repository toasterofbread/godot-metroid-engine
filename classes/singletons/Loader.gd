extends Node2D

signal room_loaded

var current_room: Room
var Samus: KinematicBody2D = preload("res://scenes/Samus/Samus.tscn").instance()
var room_container: Node2D = self
var Save: SaveGame = SaveGame.new(SaveGame.debug_save_path)
var transitioning: bool = false

var rooms = {}
const room_directory = "res://scenes/rooms/"

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Register all rooms to the room variable
	var dir = Directory.new()
	assert(dir.open(room_directory) == OK, "Room directory couldn't be opened")
	for file in Global.iterate_directory(dir):
		if dir.dir_exists(file):
			var subdir = Directory.new()
			subdir.open(room_directory + file)
			for subfile in Global.iterate_directory(subdir):
				if subdir.dir_exists(subfile):
					if subdir.file_exists(subfile + "/room.tscn"):
						rooms[file + "/" + subfile] = load(room_directory + file + "/" + subfile + "/room.tscn")
#					else:
#						push_warning("Room subdirectory '" + file + "' contains an invalid folder")
#				else:
#					push_warning("Room subdirectory '" + file + "' contains a file: " + subfile)
#					
#		else:
#			push_warning("Room directory contains a file: " + file)
	
	# DEBUG
	if true:
		Global.save_json(Map.tile_data_path, {})
		for room in rooms.values():
			room.instance().generate_maptiles()
	
	register_commands()
	

func load_room(room_id: String, set_position: bool = true):
	
	assert("/" in room_id and len(room_id.split("/")) == 2)
	var room: Room = rooms[room_id].instance()
	
	if current_room != null:
		current_room.queue_free()
		yield(current_room, "tree_exited")
		
	current_room = room
	room_container.add_child(room)
	
	if set_position:
		var spawn_positions = get_tree().get_nodes_in_group("SpawnPosition")
		if len(spawn_positions) >= 1:
			Samus.global_position = spawn_positions[0].global_position
		else:
			assert(false, "No SpawnPositions found in room")
			return "No SpawnPositions found in room"
	
	if not Samus.is_inside_tree():
		add_child(Samus)
	
	emit_signal("room_loaded")
	return true

func door_transition(origin_door: Door):
	
	if transitioning:
		return
	
	transitioning = true
	get_tree().paused = true
	Samus.paused = true
	
	var previous_room = current_room
	current_room = origin_door.target_room_scene.instance()
	
#	yield(previous_room.transitioning() "completed")
	
	# DEBUG | Map tiles don't need to be reloaded on room change normally
	Loader.room_container.call_deferred("add_child", current_room)
	yield(current_room, "ready")
	
	var destination_door: Door
	for door in current_room.doors:
		if door.name == origin_door.target_door_id:
			destination_door = door
			break
	# DEBUG
	if not destination_door:
		assert(false, "No destination door found in room")
		return
	
	destination_door.set_locked(true, false)
	destination_door.set_open(true, false)
	
	var spawn_point = origin_door.targetSpawnPosition.global_position
	var offset = current_room.global_position - destination_door.global_position
	current_room.global_position = spawn_point + offset
	current_room.visible = false
#	current_room.World.visible = false
	
	# Why tf did I originally add Samus to the room rather than the Loader???
#	# Move Samus to new loaded room and reposition her
#	var samus_position = Samus.global_position
#	Global.reparent_child(Samus, current_room)
#	Samus.global_position = samus_position
	
	# If Samus entered a CameraChunk, animate the transition
	get_tree().paused = false
	yield(Global.wait(0.1, true), "completed")
	if Samus.camerachunk_set_while_paused:
		get_tree().paused = true
		
		Samus.z_index = Enums.Layers.WORLD + 1
		origin_door.fade_out(0.25)
		destination_door.fade_out(0)
		yield(Global.dim_screen(0.25, 1, Enums.Layers.WORLD+1), "completed")
		
		previous_room.queue_free()
		current_room.visible = true
		
		yield(Samus.camerachunk_entered(Samus.current_camerachunk, true, 0.45), "completed")
		
		destination_door.fade_in(0.25)
		yield(Global.undim_screen(0.25), "completed")
		
		Samus.z_index = Enums.Layers.SAMUS
		Samus.camerachunk_set_while_paused = false
		
		get_tree().paused = false
	else:
		previous_room.queue_free()
		current_room.visible = true
	
	Samus.paused = null
	transitioning = false
	emit_signal("room_loaded")
	destination_door.door_entered()

# DEBUG
func register_commands():
	# Registering command
	# 1. argument is command name
	# 2. arg. is target (target could be a funcref)
	# 3. arg. is target name (name is not required if it is the same as first arg or target is a funcref)
	Console.add_command("loadroom", self, "command_load_room")\
		.set_description("Frees the current room and loads the specified one.")\
		.add_argument("room_id", TYPE_STRING)\
		.register()
	Console.add_command("reloadroom", self, "command_reload_room")\
		.set_description("Reloads the current room. Inputting 'yes' will reset Samus's position, while inputting 'no' will keep it unaltered.")\
		.add_argument("reset_position", TYPE_STRING)\
		.register()

func command_load_room(room_id: String):
	var result = load_room(room_id)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result == true:
		Console.write_line("Loaded room: " + room_id)
	else:
		Console.write_line("An error occurred while loading room of ID [" + room_id + "]")
		Console.write_line(result)

func command_reload_room(reset_position: String):
	
	var set_position: bool
	if reset_position.to_lower() in ["y", "yes"]:
		set_position = true
	elif reset_position.to_lower() in ["n", "no"]:
		set_position = false
	else:
		Console.write_line("Invalid input. Must match one of the following: [y, yes, n, no]")
		return
	
	var room_position = current_room.position
	
	var room_id: String = current_room.id
	var result = load_room(room_id, set_position)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result == true:
		Console.write_line("Reloaded room: " + room_id)
	else:
		Console.write_line("An error occurred while reloading room of ID [" + room_id + "]")
		Console.write_line(result)
	
	if not set_position:
		current_room.position = room_position

func kill_game():
	get_tree().quit()
