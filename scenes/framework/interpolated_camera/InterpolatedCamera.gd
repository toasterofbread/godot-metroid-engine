extends Camera2D
class_name InterpolatedCamera2D

onready var resolution = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

export var apply_limits: = true
export var apply_limits_h: = true
export var apply_limits_v: = true
export var limits = {
	Enums.dir.LEFT: INF,
	Enums.dir.RIGHT: INF,
	Enums.dir.UP: INF,
	Enums.dir.DOWN: INF
}

export var camera_offset = Vector2.ZERO

func center() -> Vector2:
	return get_camera_screen_center()
	return global_position + offset

func test_limits(_limits=null) -> Dictionary:
	
	var adjusted_position: Vector2
	
	if _limits == null:
		adjusted_position = get_camera_screen_center()
	else:
		
		var cam = self.duplicate()
		get_parent().add_child(cam)
		cam.current = true
		
		cam.limits = _limits
		
		if get_tree().paused:
			yield(Global.wait(0.03, true), "completed")
		else:
			yield(Global.wait(0.01, true), "completed")
		
		adjusted_position = cam.get_camera_screen_center()
		current = true
		cam.queue_free()
	
	var size = (resolution*zoom)/2
	var result_bounds = {}
	
	result_bounds[Enums.dir.UP] = adjusted_position.y - size.y
	result_bounds[Enums.dir.DOWN] = adjusted_position.y + size.y
	result_bounds[Enums.dir.LEFT] = adjusted_position.x - size.x
	result_bounds[Enums.dir.RIGHT] = adjusted_position.x + size.x
	
	return result_bounds
	
#	return get_limit_bounds(adjusted_position, _limits)

func get_limit_bounds(center:=center(), limits=null) -> Dictionary:
	
	if limits == null:
		limits = self.limits
	
	var bounds = limits.duplicate()
	
	while INF in bounds.values():
		bounds.erase(bounds.keys()[bounds.values().find(INF)])
	
	return bounds

func get_current_bounds(center:=center()) -> Dictionary:
	
	var bounds = {
		Enums.dir.LEFT: INF,
		Enums.dir.RIGHT: INF,
		Enums.dir.UP: INF,
		Enums.dir.DOWN: INF
	}
	
	var size = (resolution*zoom)/2
	bounds[Enums.dir.LEFT] = center.x - size.x
	bounds[Enums.dir.RIGHT] = center.x + size.x
	bounds[Enums.dir.UP] = center.y - size.y
	bounds[Enums.dir.DOWN] = center.y + size.y
	
	return bounds

func interpolate_limits(target_limits: Dictionary, duration: float, trans_type:=Tween.TRANS_LINEAR, ease_type:=Tween.EASE_IN_OUT):
	
	var center = center()
	
	var current_limits_adjusted = test_limits()
	var target_limits_adjusted = yield(test_limits(target_limits), "completed")
	
	for dir in target_limits:
		
		if target_limits[dir] == limits[dir]:
			continue
		
		var initial: float
		var target: float = target_limits_adjusted[dir]
		
#		if dir in current_limits:
		initial = current_limits_adjusted[dir]
#		else:
#			initial = current_bounds[dir]
		
		$LimitTween.interpolate_method(self, "set_limit_" + Enums.dir.keys()[dir].to_lower(), initial, target, duration, trans_type, ease_type)
	
	$LimitTween.start()
	yield(Global.wait(duration+0.05, true), "completed")
	
	limits = target_limits

var previous_center = Vector2.ZERO
func _process(delta):
	
	var limit = get_limit_bounds()
	var keys = limit.keys().duplicate()
	for key in keys:
		limit[Enums.dir.keys()[key]] = limit[key]
		limit.erase(key)
	
	var current = get_current_bounds()
	for key in current.keys():
		current[Enums.dir.keys()[key]] = current[key]
		current.erase(key)
	
	vOverlay.SET("CAMERA LIMITS", limit)
	vOverlay.SET("CAMERA BOUNDS", current)
	
	offset = Vector2.ZERO
	
	var center = center()
	if true or center != previous_center:
		var limit_bounds = get_limit_bounds(center)
		var current_bounds = get_current_bounds(center)
		
		for dir in limit_bounds:
			if dir in [Enums.dir.LEFT, Enums.dir.UP]:
				if current_bounds[dir] < limit_bounds[dir]:
					adjust_offset_to_limit(dir, current_bounds[dir], limit_bounds[dir])
			elif current_bounds[dir] > limit_bounds[dir]:
				adjust_offset_to_limit(dir, current_bounds[dir], limit_bounds[dir])
		
		previous_center = center

func adjust_offset_to_limit(dir: int, current: float, limit: float):
	if dir in [Enums.dir.LEFT, Enums.dir.RIGHT]:
		offset.x -= current - limit
	else:
		offset.y -= current - limit

func set_limit_up(value: float):
	limits[Enums.dir.UP] = value
func set_limit_down(value: float):
	limits[Enums.dir.DOWN] = value
func set_limit_left(value: float):
	limits[Enums.dir.LEFT] = value
func set_limit_right(value: float):
	limits[Enums.dir.RIGHT] = value
