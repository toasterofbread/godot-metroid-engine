extends Node

func get_facing(pad_name: String = "secondary_pad"):
	if Input.is_action_just_pressed(pad_name + "_left"):
		return Enums.dir.LEFT
	elif Input.is_action_just_pressed(pad_name + "_right"):
		return Enums.dir.RIGHT
	else:
		return null

func get_aiming(Samus: KinematicBody2D, include_front: bool = false):
	
	if Input.is_action_pressed("secondary_pad_up"):
		if Input.is_action_pressed("secondary_pad_left") or Input.is_action_pressed("secondary_pad_right"):
			return Samus.aim.UP
		else:
			return Samus.aim.SKY
	elif Input.is_action_pressed("secondary_pad_down"):
		if Input.is_action_pressed("secondary_pad_left") or Input.is_action_pressed("secondary_pad_right"):
			return Samus.aim.DOWN
		else:
			return Samus.aim.FLOOR
	elif include_front and (Input.is_action_pressed("secondary_pad_left") or Input.is_action_pressed("secondary_pad_right")):
		return Samus.aim.FRONT
	else:
		return null

func get_pad_vector(method: String) -> Vector2:
	var ret = Vector2.ZERO
	method = "is_action_" + method
	
	if Input.call(method, "pad_left"):
		ret.x = -1
	elif Input.call(method, "pad_right"):
		ret.x = 1
	if Input.call(method, "pad_up"):
		ret.y = -1
	elif Input.call(method, "pad_down"):
		ret.y = 1
	return ret

func get_joystick_vector(joystick_name: String):
	var vector = Vector2.ZERO
	vector.x = Input.get_action_strength(joystick_name + "_right") - Input.get_action_strength(joystick_name + "_left")
	vector.y = Input.get_action_strength(joystick_name + "_down") - Input.get_action_strength(joystick_name + "_up")
	return vector.normalized()

func add_to_limit(value: float, amount: float, limit: float):
	
	if amount == 0:
		return value
	
	amount = abs(amount)
	
	if value > limit:
		value = max(limit, value - amount)
	elif value < limit:
		value = min(limit, value + amount)
	
	return value
