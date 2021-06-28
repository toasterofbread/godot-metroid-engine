extends RigidBody2D

signal collapse
#var original_rect_size: Vector2

func damage(type: int, amount: float, impact_position):
	
#	if not original_rect_size:
#		original_rect_size = $Control.rect_size
	
	if type in [Enums.DamageType.FIRE, Enums.DamageType.POWERBOMB] and not $Tween.is_active():
#		if $Control.rect_size.length() < (original_rect_size * 0.5).length():
		melt()
#		else:
#			$Control.rect_size = $Control.rect_size.linear_interpolate(Vector2.ZERO, 0.1)
	elif type == Enums.DamageType.SUPERMISSILE:
		emit_signal("collapse", impact_position)

func melt():
	
	if $Tween.is_active():
		return
	
	$Tween.interpolate_property($Control, "rect_size", $Control.rect_size, Vector2.ZERO, 0.1)
	$Tween.start()
	yield($Tween, "tween_completed")
	queue_free()

func _on_Shard_body_entered(body):
	if mode != MODE_RIGID or not body.get_collision_layer_bit(19):
		return
	melt()
