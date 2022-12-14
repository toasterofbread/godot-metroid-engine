extends Camera2D
class_name ExCamera2D

onready var dimColorRectContainer: Node2D = Node2D.new()
onready var dimColorRect: ColorRect = ColorRect.new()
var overlay_colour: Color = Color.transparent setget set_overlay_colour
var dim_layer: int = 0 setget set_dim_layer
onready var tween: Tween = Global.get_tween(true, self)
var current_limit_interpolation: int = null

const limit_paths = ["limit_top", "limit_bottom", "limit_left", "limit_right"]

var current_tween_data = {
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

func _set(property, value):
	if property == "current":
		current = value
		if current:
			Global.current_camera = self
		return true
	return false

func _ready():
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	dimColorRectContainer.z_as_relative = true
	z_index = 0
	z_as_relative = true
	
	add_child(dimColorRectContainer)
	dimColorRectContainer.add_child(dimColorRect)
	set_overlay_colour(overlay_colour)
	dimColorRect.rect_size = Vector2(480, 270)
	
	_set("current", current)

func set_dim_layer(z_index: int):
	dim_layer = z_index
	dimColorRectContainer.z_index = z_index

func set_overlay_colour(colour: Color):
	dimColorRect.rect_global_position = get_center() - (dimColorRect.rect_size / 2)
	overlay_colour = colour
	dimColorRect.color = colour
	dimColorRectContainer.visible = colour.a > 0

func get_center() -> Vector2:
	return get_camera_screen_center()

func _process(_delta: float):
	
	# Yes, I'm moving a ColorRect every frame to match the camera
	# instead of just using a CanvasLayer.
	
	# The ColorRect needs to be in specific z_index layers, so putting it 
	# into a separate CanvasLayer makes that impossible because for some reason
	# CanvasLayers with the same layer value aren't merged, but stacked.
	
	if dimColorRectContainer.visible:
		dimColorRect.rect_global_position = get_center() - (dimColorRect.rect_size / 2)

func get_adjusted_limits(_limits=null) -> Dictionary:
	
	var adjusted_position: Vector2
	var limits: = {}
	
	if _limits == null:
		adjusted_position = get_camera_screen_center()
	else:
		
		var cam = self.duplicate()
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
		set("current", true)
		cam.queue_free()
	
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
#	if tween.is_active():
	tween.stop_all()
	
	var starting_position = global_position
	var original_smoothing: = {
	}
	if get_tree().paused:
		original_smoothing["smoothing_enabled"] = smoothing_enabled
		original_smoothing["smoothing_speed"] = smoothing_speed
		smoothing_enabled = true
		smoothing_speed = 1
	
	if target_limits == null:
		target_limits = max_limits
	
	var current_limits = get_limits()
	var adjusted_current_limits = get_adjusted_limits()
	var adjusted_target_limits = yield(get_adjusted_limits(target_limits), "completed")
	
	for limit in target_limits:
		
		if target_limits[limit] == current_limits[limit]:
			continue
		
		if get_tree().paused:
			tween.interpolate_property(self, limit, adjusted_current_limits[limit], target_limits[limit], duration, trans_type, ease_type)
		else:
			current_tween_data[limit] = {"initial": current_limits, "target": target_limits}
			tween.interpolate_method(self, "update_limit_offset", starting_position, starting_position, duration, trans_type, ease_type)
			tween.interpolate_method(self, "_interpolate_process", 0, 1, duration, trans_type, ease_type)
	
	var time: int = OS.get_ticks_msec()
	current_limit_interpolation = time
	tween.start()
#	yield(tween, "tween_all_completed")
	yield(Global.wait(duration+0.1, true), "completed")
	
	if current_limit_interpolation != time:
		return
	
	for limit in current_tween_data:
		current_tween_data[limit] = null
	
	previous_position = null
	for limit in target_limits:
		set(limit, target_limits[limit])
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

	var offset = global_position - previous_position

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

func set_limit_left(value: float):
	limit_left = value + limit_offset["limit_left"]

func set_limit_right(value: float):
	limit_right = value + limit_offset["limit_right"]
