extends Node

var timers = {}

func random_array_item(rng: RandomNumberGenerator, array: Array):
	return array[rng.randi_range(0, len(array) - 1)]

func start_timer(timer_id: String, seconds: float, data: Dictionary = {}, connect=[self, "clear_timer"]):
	
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
