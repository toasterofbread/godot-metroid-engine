extends Node

signal process_frame
signal physics_frame

var timers = {}
var hold_actions = {}

var config = {"spiderball_hold": false, "spin_from_jump": true, "zm_weapons": true}

enum dir {NONE, LEFT, RIGHT, UP, DOWN}

func _process(delta):
	emit_signal("process_frame")
	for action in hold_actions:
		if Input.is_action_pressed(action):
			hold_actions[action] += delta
		else:
			hold_actions[action] = 0
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func _physics_process(delta):
	emit_signal("process_frame")

func random_array_item(rng: RandomNumberGenerator, array: Array):
	return array[rng.randi_range(0, len(array) - 1)]

func start_timer(timer_id: String, seconds: float, data: Dictionary = {}, connect=[self, "clear_timer"]):
	
	clear_timer(timer_id)
	var timer = Timer.new()
	self.add_child(timer)
	timer.one_shot = true
	timers[timer_id] = [timer, data]
	if connect != null:
		timer.connect("timeout", connect[0], connect[1], [timer_id])
	timer.start(seconds)
	
	return timer

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
