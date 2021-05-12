extends Node

signal process_frame
signal physics_frame

var timers = {}
var hold_actions = {}
onready var Timers = Node2D.new()
onready var Anchor = Node2D.new()

onready var DimLayer: CanvasLayer = CanvasLayer.new()
onready var DimRect: ColorRect = ColorRect.new()
onready var RNG = RandomNumberGenerator.new()

func _ready():
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	
	self.add_child(DimLayer)
	DimLayer.add_child(DimRect)
	DimRect.visible = false
	DimRect.rect_size = Vector2(1920, 1080)
	DimRect.color = Color.black
	
	RNG.randomize()
	Timers.name = "Timers"
	self.add_child(Timers)
	self.add_child(Anchor)
	Anchor.name = "Anchor"
	Anchor.pause_mode = Node.PAUSE_MODE_STOP

func _process(delta):
	emit_signal("process_frame")
	for action in hold_actions:
		if Input.is_action_pressed(action):
			hold_actions[action] += delta
		else:
			hold_actions[action] = 0
	
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



func _physics_process(_delta):
	emit_signal("physics_frame")

func random_array_item(rng: RandomNumberGenerator, array: Array):
	return array[rng.randi_range(0, len(array) - 1)]

func start_timer(timer_id: String, seconds: float, data: Dictionary = {}, connect=[self, "clear_timer"]):
	
	clear_timer(timer_id)
	var timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = true
	timer.pause_mode = Node.PAUSE_MODE_STOP
	timers[timer_id] = [timer, data]
	if connect != null:
		timer.connect("timeout", connect[0], connect[1], [timer_id])
	timer.start(seconds)
	
	return timer

func timer(connect = null):
	
	var timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = true
	if connect != null:
		timer.connect("timeout", connect[0], connect[1], connect[2])
	timer.pause_mode = Node.PAUSE_MODE_STOP
	return timer

func wait(seconds: float):
	var timer = Timer.new()
	Timers.add_child(timer)
	timer.pause_mode = Node.PAUSE_MODE_STOP
	timer.start(seconds)
	yield(timer, "timeout")
	timer.queue_free()

func clear_timer(timer_id: String):
	if not timer_id in timers:
		return -1
	
	timers[timer_id][0].queue_free()
	timers.erase(timer_id)
	
func create_hold_action(action: String):
	if not action in hold_actions:
		hold_actions[action] = 0
	
func remove_hold_action(action: String):
	if action in hold_actions:
		hold_actions.erase(action)
	
func is_action_held(action: String, seconds: float, reset_hold_time: bool = true):
	
	if not action in hold_actions:
		return false
	
	var ret = hold_actions[action] >= seconds
	if reset_hold_time and ret:
		hold_actions[action] = 0
	return ret

func time():
	return OS.get_ticks_msec()

func get_anchor(anchor_path: String) -> Node2D:
	
	var anchor_path_strings = anchor_path.split("/")
	
	var parent: Node2D = Anchor
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

func shake(camera: Camera2D, normal_offset: Vector2, intensity: float, duration: float, shake_frequency: float = 0.05):
	var timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = true
	var tween = Tween.new()
	self.add_child(tween)
	timer.start(duration)
	
	while timer.time_left > shake_frequency:
		var rand = Vector2(RNG.randf_range(-intensity, intensity), RNG.randf_range(-intensity, intensity))
		tween.interpolate_property(camera, "offset", camera.offset, rand, shake_frequency, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.start()
		yield(tween, "tween_completed")
	
	tween.interpolate_property(camera, "offset", camera.offset, normal_offset, shake_frequency, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")

	timer.queue_free()
	tween.queue_free()


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
	if child.get_parent():
		child.get_parent().remove_child(child)
	new_parent.add_child(child)

func array2vector(array: Array) -> Vector2:
	return Vector2(array[0], array[1])

func vector2array(vector: Vector2) -> Array:
	return [vector.x, vector.y]

func text_fade_in(label: RichTextLabel, time: float):
	var tween: Tween = Tween.new()
	self.add_child(tween)
	tween.interpolate_property(label, "percent_visible", 0, 1, time)
	tween.start()
	yield(tween, "tween_all_completed")
	tween.queue_free()
	
func text_fade_out(label: RichTextLabel, time: float):
	var tween: Tween = Tween.new()
	self.add_child(tween)
	tween.interpolate_property(label, "percent_visible", label.percent_visible, 0, time)
	tween.start()
	yield(tween, "tween_all_completed")
	tween.queue_free()
	label.visible = false

func dim_screen(percent_opacity: float, duration: float, layer: int):
	var tween: Tween = Tween.new()
	self.add_child(tween)
	DimLayer.layer = layer
	tween.interpolate_property(DimRect, "color:a", 0, percent_opacity, duration)
	tween.start()
	DimRect.visible = true
	yield(tween, "tween_all_completed")
	tween.queue_free()

func undim_screen(duration: float):
	var tween: Tween = Tween.new()
	self.add_child(tween)
	tween.interpolate_property(DimRect, "color:a", DimRect.color.a, 0, duration)
	tween.start()
	yield(tween, "tween_all_completed")
	DimRect.visible = false
	tween.queue_free()
