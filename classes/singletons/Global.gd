extends Node2D

signal process_frame
signal physics_frame

var global_timers: Dictionary = {}
#var hold_actions = {}
onready var Timers = Node2D.new()
onready var AnchorContainer = Node2D.new()

onready var dimLayer: ColorRect = $DimLayer/DimZLayer/ColorRect
var rng = RandomNumberGenerator.new()

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
#	add_child(DimLayer)
#	DimLayer.texture = preload("res://sprites/flat.png")
#	DimLayer.scale = Vector2(1920, 1080)/64
#	DimLayer.position = Vector2(1920, 1080)/2
#	DimLayer.visible = false
#	DimLayer.modulate = Color.black
#	DimLayer.modulate.a = 0
#	DimLayer.z_as_relative = false
	
	dimLayer.visible = false
	
	rng.randomize()
	Timers.name = "Timers"
	add_child(Timers)
	add_child(AnchorContainer)
	AnchorContainer.name = "AnchorContainer"
	AnchorContainer.pause_mode = Node.PAUSE_MODE_STOP
	
	yield(Settings, "ready")
#	Settings.connect("settings_changed", self, "settings_changed")
	OS.window_fullscreen = Settings.get("display/fullscreen")

func _process(delta):
	emit_signal("process_frame", delta)
#	for action in hold_actions:
#		if Input.is_action_pressed(action):
#			hold_actions[action] += delta
#		else:
#			hold_actions[action] = 0
	
#	yield(Loader, "ready")
#	DimLayer.global_position = Loader.Samus.camera.global_position
	
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	elif Input.is_action_just_pressed("take_screenshot"):
		
		var dir = Directory.new()
		dir.open("res://")
		if not dir.dir_exists("screenshots"):
			dir.make_dir("screenshots")
		
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		var date = OS.get_datetime()
		image.save_png("res://screenshots/" + str(date["year"]) + "-" + str(date["month"]) + "-" + str(date["day"]) + "_" + str(date["hour"]) + "." + str(date["minute"]) + "." + str(date["second"]) + ".png")


func _physics_process(delta):
	emit_signal("physics_frame", delta)

#func start_timer(timer_id: String, seconds: float, data: Dictionary = {}, connect=[self, "clear_timer"]):
#
#	clear_timer(timer_id)
#	var timer = Timer.new()
#	self.add_child(timer)
#	timer.one_shot = true
#	timer.pause_mode = Node.PAUSE_MODE_STOP
#	timers[timer_id] = [timer, data]
#	if connect != null:
#		timer.connect("timeout", connect[0], connect[1], [timer_id])
#	timer.start(seconds)
#
#	return timer

func get_timer(timeout_connect=null, started_connect=null, parent=null):
	var timer = ExTimer.new()
	timer.one_shot = true
	
	if parent != null:
		parent.add_child(timer)
	else:
		add_child(timer)
	
	if timeout_connect != null:
		timer.connect("timeout", timeout_connect[0], timeout_connect[1], timeout_connect[2])
	if started_connect != null:
		timer.connect("started", started_connect[0], started_connect[1], started_connect[2])
	
	timer.pause_mode = Node.PAUSE_MODE_STOP
	return timer

func add_global_timer(id: String, timer: Timer):
	global_timers[id] = timer

func get_global_timer(id: String, create_if_not_found: bool = false):
	if id in global_timers:
		return global_timers[id]
	elif create_if_not_found:
		var timer: Timer = get_timer()
		add_global_timer(id, timer)
		return timer
	else:
		return null
func wait(seconds: float, ignore_pause: bool = false, function_call=null):
	if seconds > 0:
		var timer: = Timer.new()
		Timers.add_child(timer)
		timer.pause_mode = Node.PAUSE_MODE_PROCESS if ignore_pause else Node.PAUSE_MODE_STOP
		timer.start(seconds)
		yield(timer, "timeout")
		timer.queue_free()
	
	if function_call != null:
		function_call[0].callv(function_call[1], function_call[2])

#func erase(container, value):
#	return container.erase(value)

#func clear_timer(timer_id: String):
#	if not timer_id in timers:
#		return -1
#
#	timers[timer_id][0].queue_free()
#	timers.erase(timer_id)

func get_tween(ignore_paused:bool=false, parent:Node=self) -> Tween:
	var tween = Tween.new()
	tween.pause_mode = Node.PAUSE_MODE_PROCESS if ignore_paused else Node.PAUSE_MODE_STOP
	parent.add_child(tween)
	return tween

#func create_hold_action(action: String):
#	if not action in hold_actions:
#		hold_actions[action] = 0

#func remove_hold_action(action: String):
#	if action in hold_actions:
#		hold_actions.erase(action)

#func is_action_held(action: String, seconds: float, reset_hold_time: bool = true):
#
#	if not action in hold_actions:
#		return false
#
#	var ret = hold_actions[action] >= seconds
#	if reset_hold_time and ret:
#		hold_actions[action] = 0
#	return ret

func time():
	return OS.get_ticks_msec()

func get_anchor(anchor_path: String) -> Node2D:
	
	var anchor_path_strings = anchor_path.split("/")
	
	var parent: Node2D = AnchorContainer
	for name in anchor_path_strings:
		var set = false
		for node in parent.get_children():
			if node.name == name:
				parent = node
				set = true
				break
		if not set:
			var node = Node2D.new()
			node.name = name
			parent.add_child(node)
			parent = node
	
	parent.pause_mode = Node.PAUSE_MODE_STOP
	return parent

func shake_camera(camera: Camera2D, normal_offset: Vector2, intensity: float, duration: float, shake_frequency: float = 0.05):
	var timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = true
	var tween = Tween.new()
	self.add_child(tween)
	timer.start(duration)
	
	while timer.time_left > shake_frequency:
		var rand = Vector2(rng.randf_range(-intensity, intensity), rng.randf_range(-intensity, intensity))
		tween.interpolate_property(camera, "offset", camera.offset, rand, shake_frequency, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()
		yield(tween, "tween_completed")
	
	tween.interpolate_property(camera, "offset", camera.offset, normal_offset, shake_frequency, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")

	timer.queue_free()
	tween.queue_free()

func invert_angle(angle: float, absolute: bool = false) -> float:
	var ret: float = -(180 - angle)
	if absolute and ret < 0:
		return absolute_angle(ret)
	else:
		return ret

func absolute_angle(angle: float):
	if angle < 0:
		return 360 + angle
	else:
		return angle

# Load JSON file at the specified path and returns data as dict
func load_json(path: String):
	var f = File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data).result

func save_json(path: String, data, pretty: bool = false):
	var f = File.new()
	f.open(path, File.WRITE)
	f.store_string(JSON.print(data, "\t" if pretty else ""))
	f.close()

func reparent_child(child: Node, new_parent: Node):
#	var position: Vector2
#	if maintain_global_position:
#		if child is Node2D:
#			position = child.global_position
#		elif child is Control:
#			position = child.rect_global_position
	if child.get_parent():
		child.get_parent().remove_child(child)
#		yield(child, "tree_exited")
	new_parent.add_child(child)
#	if move_to_position >= 0:
#		new_parent.move_child(child, move_to_position)
#	yield(child, "tree_entered")
#	if maintain_global_position and position:
#		if child is Node2D:
#			child.global_position = position
#		elif child is Control:
#			child.rect_global_position = position
func array2vector(array: Array) -> Vector2:
	return Vector2(array[0], array[1])

func vector2array(vector: Vector2) -> Array:
	return [vector.x, vector.y]

func dir2vector(direction: int) -> Vector2:
	match direction:
		Enums.dir.LEFT: return Vector2(-1, 0)
		Enums.dir.RIGHT: return Vector2(1, 0)
		Enums.dir.UP: return Vector2(0, -1)
		Enums.dir.DOWN: return Vector2(0, 1)
		Enums.dir.TOPLEFT: return Vector2(-1, -1)
		Enums.dir.TOPRIGHT: return Vector2(1, -1)
		Enums.dir.BOTLEFT: return Vector2(-1, 1)
		Enums.dir.BOTRIGHT: return Vector2(1, 1)
		_: return Vector2.ZERO

func vector2dir(vector: Vector2) -> int:
	match vector:
		Vector2(1, 0): return Enums.dir.RIGHT
		Vector2(1, 1): return Enums.dir.BOTRIGHT
		Vector2(0, 1): return Enums.dir.DOWN
		Vector2(-1, 1): return Enums.dir.BOTLEFT
		Vector2(-1, 0): return Enums.dir.LEFT
		Vector2(-1, -1): return Enums.dir.TOPLEFT
		Vector2(0, 1): return Enums.dir.UP
		Vector2(1, -1): return Enums.dir.TOPRIGHT
		_: return Enums.dir.NONE

func axis2dir(axis_value, x_axis: bool = true):
	axis_value = sign(axis_value) 
	if x_axis:
		match axis_value:
			1: return Enums.dir.RIGHT
			-1: return Enums.dir.LEFT
	else:
		match axis_value:
			1: return Enums.dir.DOWN
			-1: return Enums.dir.UP
	return null

func dim_screen(duration: float, percent_opacity: float, layer: int, z_index: int, ignore_paused: bool = true):
	var tween: Tween = get_tween(ignore_paused)
	$DimLayer.layer = layer
	$DimLayer/DimZLayer.z_index = z_index
	$DimLayer/DimZLayer.z_as_relative = false
	tween.interpolate_property(dimLayer, "modulate:a", 0.0, percent_opacity, duration)
	tween.start()
	dimLayer.visible = true
	yield(tween, "tween_completed")
	tween.queue_free()

func undim_screen(duration: float, ignore_paused: bool = true):
	var tween: Tween = get_tween(ignore_paused)
	tween.interpolate_property(dimLayer, "modulate:a", dimLayer.modulate.a, 0, duration)
	tween.start()
	yield(tween, "tween_completed")
	dimLayer.visible = false
	tween.queue_free()

func random_array_item(array: Array, RNG=null):
	if RNG == null:
		RNG = rng
	return array[RNG.randi_range(0, len(array) - 1)]

func get_angle_difference(angle1, angle2):
	var diff = angle2 - angle1
	return diff if abs(diff) < 180 else diff + (360 * -sign(diff))

func iterate_directory(dir: Directory) -> Array:
	var ret = []
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		ret.append(file_name)
		file_name = dir.get_next()
	return ret

func call_connection_array(nodepath_origin: Node, connections: Array):
	for connection in connections:
		var node = nodepath_origin.get_node_or_null(connection[0])
		if node == null or not node.has_method(connection[1]):
			continue
		node.callv(connection[1], connection[2])

func get_string_timestamp():
	var date = OS.get_datetime()
	return str(date["year"]) + "-" + str(date["month"]) + "-" + str(date["day"]) + "_" + str(date["hour"]) + "." + str(date["minute"]) + "." + str(date["second"])
