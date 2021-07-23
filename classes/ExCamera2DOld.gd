extends Camera2D
#class_name ExCamera2D

onready var tween: = Tween.new()

const limit_paths = ["limit_top", "limit_bottom", "limit_left", "limit_right"]

var current_tween_data = {
	"limit_top": null,
	"limit_bottom": null,
	"limit_left": null,
	"limit_right": null
}
var current_tween_directions = {
	"limit_top": null,
	"limit_bottom": null,
	"limit_left": null,
	"limit_right": null
}
var current_tween_targets = {
	"limit_top": null,
	"limit_bottom": null,
	"limit_left": null,
	"limit_right": null
}
var max_limits = {
	"limit_top": -10000000,
	"limit_left": -10000000,
	"limit_right": 10000000,
	"limit_bottom": 10000000
}
var tween_duration = 0.0

func _ready():
	add_child(tween)
	tween.pause_mode = Node.PAUSE_MODE_PROCESS
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	pause_mode = Node.PAUSE_MODE_PROCESS

func get_center() -> Vector2:
	return get_camera_screen_center()

func get_adjusted_limits(_limits=null) -> Dictionary:
	
	var adjusted_position: Vector2
	var limits: = {}
	
	if _limits == null:
		adjusted_position = get_camera_screen_center()
	else:
		
		var cam = self.duplicate()
#		var viewport = Viewport.new()
#		viewport.size = get_viewport().size
#		viewport.world_2d = get_viewport().world_2d
#		get_parent().add_child(viewport)
#		viewport.add_child(cam)
		get_parent().add_child(cam)
		cam.current = true
		
		limits = _limits.duplicate()
		for limit in limits:
			cam.set(limit, limits[limit])
		
		if get_tree().paused:
			yield(Global.wait(0.02, true), "completed")
		else:
			yield(Global.wait(0.01, true), "completed")
		
		adjusted_position = cam.get_camera_screen_center()
		current = true
		cam.queue_free()
#		viewport.queue_free()
	
	var size = (Vector2(1920, 1080)*zoom)/2
	
	limits["limit_top"] = adjusted_position.y - size.y
	limits["limit_bottom"] = adjusted_position.y + size.y
	limits["limit_left"] = adjusted_position.x - size.x
	limits["limit_right"] = adjusted_position.x + size.x
	
	return limits

func get_limits() -> Dictionary:
	var ret = {}
	for limit in limit_paths:
		ret[limit] = get(limit)
	return ret

func set_limits(limits):
	
	if limits == null:
		for limit in limit_paths:
			set(limit, max_limits[limit])
	elif limits is Dictionary:
		for limit in limits:
			if limits[limit] == null:
				limits[limit] = max_limits[limit]
			set(limit, limits[limit])
	elif limits is int or limits is float:
		for limit in limit_paths:
			set(limit, limits)

func interpolate_position(pos: Vector2, return_time: = -1.0):
	
	if tween.is_active():
		return false
	
	var origin_position = global_position
	tween.interpolate_property(self, "global_position", global_position, pos, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	
	if return_time < 0:
		return true
	elif return_time > 0:
		yield(Global.wait(return_time), "completed")
	
	tween.interpolate_property(self, "global_position", global_position, origin_position, 0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
	yield(tween, "tween_completed")

func interpolate_limits(target_limits, duration: float, trans_type:=Tween.TRANS_LINEAR, ease_type:=Tween.EASE_IN_OUT):
	
	if tween.is_active():
#		yield(get_tree(), "idle_frame")
#		return false
		tween.stop_all()
	
	var starting_position = global_position
#	var original_smoothing = {
#		"drag_margin_h_enabled": drag_margin_h_enabled,
#		"drag_margin_v_enabled": drag_margin_v_enabled
#	}
#	drag_margin_h_enabled = false
#	drag_margin_v_enabled = false
	var original_smoothing: = {
#		"drag_margin_left": drag_margin_left,
#		"drag_margin_right": drag_margin_right,
#		"drag_margin_top": drag_margin_top,
#		"drag_margin_bottom": drag_margin_bottom,
	}
	
#	for margin in original_smoothing:
#		tween.interpolate_property(self, margin, get(margin), 0.0, 0.1)
#	tween.start()
#	drag_margin_left = 0.0
#	drag_margin_right = 0.0
#	drag_margin_top = 0.0
#	drag_margin_bottom = 0.0
	if get_tree().paused:
		original_smoothing["smoothing_enabled"] = smoothing_enabled
		original_smoothing["smoothing_speed"] = smoothing_speed
		smoothing_enabled = true
		smoothing_speed = 1
	
	tween.stop_all()
	
	if target_limits == null:
		target_limits = max_limits
	
	var current_limits = get_limits()
	var adjusted_current_limits = get_adjusted_limits()
	var adjusted_target_limits = yield(get_adjusted_limits(target_limits), "completed")
	
#	for limit in ["limit_left", "limit_right"]:
#
#		if not limit in target_limits or target_limits[limit] == current_limits[limit]:
#			continue
#
#		if get_tree().paused:
#			tween.interpolate_property(self, limit, adjusted_current_limits[limit], adjusted_target_limits[limit], duration, trans_type, ease_type)
#		else:
#			current_tween_data[limit] = {"initial": current_limits, "target": target_limits}
#			tween.interpolate_method(self, "update_limit_offset", starting_position, starting_position, duration, trans_type, ease_type)
#			tween.interpolate_method(self, "_interpolate_process", 0, 1, duration, trans_type, ease_type)
#	tween.start()
#	yield(Global.wait(duration+0.1, true), "completed")
#
#	for limit in ["limit_top", "limit_bottom"]:
#
#		if not limit in target_limits or target_limits[limit] == current_limits[limit]:
#			continue
#
#		if get_tree().paused:
#			tween.interpolate_property(self, limit, adjusted_current_limits[limit], adjusted_target_limits[limit], duration, trans_type, ease_type)
#		else:
#			current_tween_data[limit] = {"initial": current_limits, "target": target_limits}
#			tween.interpolate_method(self, "update_limit_offset", starting_position, starting_position, duration, trans_type, ease_type)
#			tween.interpolate_method(self, "_interpolate_process", 0, 1, duration, trans_type, ease_type)
#	tween.start()
#	yield(Global.wait(duration+0.1, true), "completed")
	
	for limit in target_limits:

		if target_limits[limit] == current_limits[limit]:
			continue

		if get_tree().paused:
			tween.interpolate_property(self, limit, adjusted_current_limits[limit], adjusted_target_limits[limit], duration, trans_type, ease_type)
		else:
			current_tween_data[limit] = {"initial": current_limits, "target": target_limits}
			tween.interpolate_method(self, "update_limit_offset", starting_position, starting_position, duration, trans_type, ease_type)
			tween.interpolate_method(self, "_interpolate_process", 0, 1, duration, trans_type, ease_type)
	tween.start()
#	yield(tween, "tween_all_completed")
	yield(Global.wait(duration+0.1, true), "completed")
#	set_limit_right(limit_right)
	for limit in current_tween_directions:
		current_tween_directions[limit] = null
		current_tween_targets[limit] = null
		current_tween_data[limit] = null
	previous_position = null
#	var center = get_camera_screen_center()
	for limit in target_limits:
		set(limit, target_limits[limit])
#	yield(Global.wait(0.05), "completed")
#	offset = center - get_camera_screen_center()
	for property in original_smoothing:
		set(property, original_smoothing[property])

func _interpolate_process(value: float):
	var adjusted_current_limits = get_adjusted_limits()
	var adjusted_target_limits = null
	
	for limit in current_tween_data:
		var data = current_tween_data[limit]
		if data == null:
			continue
		
		if adjusted_target_limits == null:
			adjusted_target_limits = yield(get_adjusted_limits(data["target"]), "completed")
		
		var to_set = adjusted_current_limits[limit] + ((adjusted_target_limits[limit] - adjusted_current_limits[limit]) * value)
		
		
		if sign(limit_offset[limit]) == sign(adjusted_target_limits[limit] - adjusted_current_limits[limit]):
			to_set += limit_offset[limit]
		
		set(limit, to_set)

var previous_position = null
func update_limit_offset(starting_position: Vector2):
	if previous_position == null:
		previous_position = starting_position
		return

#	offset = global_position - starting_position
	var offset = global_position - previous_position
#	previous_position = global_position

	limit_offset["limit_left"] = 0
	limit_offset["limit_right"] = 0
	if offset.x > 0:# and current_tween_directions["limit_right"] == -1:
		limit_offset["limit_right"] = offset.x
	elif offset.x < 0:# and current_tween_directions["limit_left"] == 1:
		limit_offset["limit_left"] = offset.x

	limit_offset["limit_top"] = 0
	limit_offset["limit_bottom"] = 0
	if offset.y > 0:# and current_tween_directions["limit_bottom"] == -1:
		limit_offset["limit_bottom"] = offset.y
	elif offset.y < 0:# and current_tween_directions["limit_top"] == 1:
		limit_offset["limit_top"] = offset.y

var limit_offset = {
	"limit_top": 0,
	"limit_bottom": 0,
	"limit_left": 0,
	"limit_right": 0,
}

func set_limit_top(value: float):
	limit_top = value + limit_offset["limit_top"]

func set_limit_bottom(value: float):
	limit_bottom = value + limit_offset["limit_bottom"]
#	if current_tween_directions["limit_bottom"] == 1:
#		limit_bottom = max(current_tween_targets["limit_bottom"], value + limit_offset["limit_bottom"])
#	else:
#		limit_bottom = min(current_tween_targets["limit_bottom"], value + limit_offset["limit_bottom"])

func set_limit_left(value: float):
	limit_left = value + limit_offset["limit_left"]

func set_limit_right(value: float):
	limit_right = value + limit_offset["limit_right"]

#var prev_top = 0.0
#func set_limit_top(value: float):
#	limit_top = value
#	if (value - prev_top) > 0 or value == current_target_limits["limit_top"]:
#		limit_top += limit_offset["limit_top"]
#	prev_top = value
#
#var prev_bottom = 0.0
#func set_limit_bottom(value: float):
#	limit_bottom = value
#	if (value - prev_bottom) < 0:
#		limit_bottom += limit_offset["limit_bottom"]
#	prev_bottom = value
#
#var prev_left = 0.0
#func set_limit_left(value: float):
#	limit_left = value
#	if (value - prev_left) < 0 or value == current_target_limits["limit_left"]:
#		limit_left += limit_offset["limit_left"]
#	prev_left = value
#
#var prev_right = 0.0
#var i = 0
#func set_limit_right(value: float):
#	limit_right = value
#	i += 1
#	if (value - prev_right) > 0 or tween.get_runtime() == tween.tell():
#		limit_right += limit_offset["limit_right"]
##		if tween.get_runtime() == tween.tell():
##			tween.stop_all()
#	prev_right = value
