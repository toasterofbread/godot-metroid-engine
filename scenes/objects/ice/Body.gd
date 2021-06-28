extends StaticBody2D

signal damage

func damage(type, amount, impact_position):
	emit_signal("damage", type, amount, impact_position)
