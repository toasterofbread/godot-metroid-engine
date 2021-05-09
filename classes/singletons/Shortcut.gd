extends Node

var new_aiming
var new_facing


func get_facing():
	if Input.is_action_just_pressed("secondary_pad_left"):
		return Enums.dir.LEFT
	elif Input.is_action_just_pressed("secondary_pad_right"):
		return Enums.dir.RIGHT
	else:
		return null

func get_aiming(Samus: KinematicBody2D):
	
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
	else:
		return null

func _physics_process(delta):
	
	new_facing = null
	new_aiming = null
	

