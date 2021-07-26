extends Node2D

signal room_loaded
signal room_transitioning

var room_is_loaded: bool = false

var current_room: Room
var Samus: KinematicBody2D = preload("res://engine/scenes/Samus/Samus.tscn").instance()
var room_container: Node2D = self
onready var Save: SaveGame = SaveGame.new(Data.get_from_user_dir("/saves/0.json"))
var transitioning: bool = false

var rooms = {}
var samuses: Dictionary = {}

func _ready():
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Register all rooms to the room variable
	var room_dirs: Array = []
	for dir in Data.data["engine_config"]["room_directories"]:
		room_dirs.append(Global.dir2dict(dir, true, ["room.tscn"]))
	rooms = Global.combine_dicts(room_dirs)
	
	# DEBUG
	if true:
		Global.save_json(Map.tile_data_path, {})
		for room in rooms.values():
			load(room).instance().generate_maptiles()
	
	register_commands()

func load_room(room_id: String, set_samus_position: bool = true, data: Dictionary = {}):
	
	assert("/" in room_id and len(room_id.split("/")) == 2)
	var room: Room = load(rooms[room_id]).instance()
	
	if current_room != null:
		current_room.queue_free()
		yield(current_room, "tree_exited")
	
	current_room = room
	current_room.init(data)
	room_container.add_child(room)
	
	if set_samus_position and room.spawnPosition != null:
		Samus.global_position = room.spawnPosition.global_position
	
	if not Samus.is_inside_tree():
		add_child(Samus)
	
	emit_signal("room_loaded")
	room_is_loaded = true
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
	current_room.init({})
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
	
	emit_signal("room_transitioning")
	
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
#	get_tree().paused = false
#	yield(Global.wait(0.1, true), "completed")
	
	# DEBUG | Should be get_node instead of get_node_or_null
	# Also, the if statement shouldn't be needed
	var destination_cameraChunk = destination_door.get_node_or_null(destination_door.cameraChunk)
	if destination_cameraChunk != null:
		destination_cameraChunk = destination_cameraChunk.get_child(0)
		Samus.z_index = Enums.Layers.MENU
		
		var tween: Tween = Global.get_tween(true)
		tween.interpolate_property(origin_door, "modulate:a", origin_door.modulate.a, 0, 0.25)
#		yield(Global.dim_screen(0.25, 1.0, 0, Enums.Layers.WORLD + 1), "completed")
#		tween.interpolate_method(Samus.Animator, "set_dim", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.25)
		Samus.camera.dim_colour = Color(0, 0, 0, 0)
		Samus.camera.set_dim_layer(-1)
		tween.interpolate_property(Samus.camera, "dim_colour:a", 0, 1, 0.25)
		tween.start()
		yield(tween, "tween_all_completed")
		destination_door.visible = false
		
		previous_room.queue_free()
		current_room.visible = true
		
		yield(Samus.camerachunk_entered(destination_cameraChunk, true, 0.45), "completed")
		
		tween.interpolate_property(destination_door, "modulate:a", destination_door.modulate.a, 1, 0.25)
#		tween.interpolate_method(Samus.Animator, "set_dim", Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.25)
		tween.interpolate_property(Samus.camera, "dim_colour:a", 1, 0, 0.25)
		tween.start()
		destination_door.visible = true
		yield(tween, "tween_all_completed")
#		destination_door.fade_in(0.25)
#		yield(Global.undim_screen(0.25), "completed")
		
		tween.queue_free()
		
		Samus.z_index = Enums.Layers.SAMUS
		
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
		.set_description("Reloads the current room without repositioning Samus.")\
		.register()
	
	Shortcut.register_debug_shortcut("DEBUG_reload_room", "Reload room", {"just_pressed": funcref(self, "command_reload_room")})
	Shortcut.register_debug_shortcut("DEBUG_reset_samus_position", "Reset Samus's position", {"just_pressed": funcref(self, "command_reset_samus_position")})

func command_load_room(room_id: String):
	var result = load_room(room_id)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result == true:
		Console.write_line("Loaded room: " + room_id)
	else:
		Console.write_line("An error occurred while loading room of ID [" + room_id + "]")
		Console.write_line(result)

func command_reload_room():
	
	var room_position = current_room.position
	
	var room_id: String = current_room.id
	var result = load_room(room_id, false)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	if result == true:
		Console.write_line("Reloaded room: " + room_id)
		Notification.types["text"].instance().init("Reloaded room: " + room_id, Notification.lengths["short"])
	else:
		Console.write_line("An error occurred while reloading room of ID [" + room_id + "]")
		Console.write_line(result)

func command_reset_samus_position():
	if current_room.spawnPosition == null:
		Notification.types["text"].instance().init("No SpawnPosition registered to current room", Notification.lengths["short"])
	else:
		Samus.global_position = current_room.spawnPosition.global_position
		Notification.types["text"].instance().init("Samus's position set to " + str(Samus.global_position), Notification.lengths["short"])

func kill_game():
	get_tree().quit()
