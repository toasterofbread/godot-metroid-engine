extends Position2D

func _physics_process(delta):
	
	vOverlay.SET("Position2D", global_position)
	vOverlay.SET("Sprite", get_child(0).global_position)
	
