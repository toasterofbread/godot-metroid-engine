extends CollisionShape2D
class_name ExCollisionShape2D

func get_shape_size() -> Vector2:
	if not shape:
		return null
	
	match shape.get_class():
		"CapsuleShape2D":
			return Vector2(shape.radius, shape.height) * 0.5
		"RectShape2D":
			return shape.extents * 0.5
		"CircleShape2D":
			return Vector2.ONE * shape.radius * 0.5
		_:
			push_error("Requested size for unsupported Shape2D type: '" + shape.get_class() + "'")
			return null
