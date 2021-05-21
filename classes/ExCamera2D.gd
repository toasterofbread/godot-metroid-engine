extends Camera2D
class_name ExCamera2D

func get_camera_center(camera=self):
#	var transform : Transform2D = get_viewport_transform()
#	var scale : Vector2 = transform.get_scale()
#	return (-transform.origin / scale + get_viewport_rect().size / scale / 2)# + (Loader.current_room.global_position*5)
	var vtrans = camera.get_canvas_transform()
	var top_left = -vtrans.get_origin() / vtrans.get_scale()
	var vsize = camera.get_viewport_rect().size
	return top_left + 0.5*vsize/vtrans.get_scale()
