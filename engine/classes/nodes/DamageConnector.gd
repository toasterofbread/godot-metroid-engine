extends Node2D
signal damage

func damage(type: int, amount: int, impact_position):
	emit_signal("damage", type, amount, impact_position)
