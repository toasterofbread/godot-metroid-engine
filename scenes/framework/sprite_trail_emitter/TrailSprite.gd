extends Node2D

var sprite: Node2D

func init(sprite: Node2D, data: Dictionary):
	self.sprite = sprite
	if sprite is AnimatedSprite:
		sprite.playing = false
	elif data["sprite"] != null:
		sprite.texture = data["sprite"]
	
	var _modulate = data["modulate"]
	if _modulate != null: 
		sprite.modulate = _modulate if _modulate is Color else _modulate.modulate
	
	var _material = data["material"]
	if _material != null:
		sprite.material = _material if _material is Material else _material.material.duplicate()
		sprite.use_parent_material = false
	
	if data["fade_out"]:
		$Tween.interpolate_property(sprite, "self_modulate:a", 1, 0, $DeletionTimer.wait_time)
		$Tween.start()

func _physics_process(delta):

	sprite.global_position = lerp(sprite.global_position, Loader.Samus.global_position, delta)
	

func _on_DeletionTimer_timeout():
	queue_free()
