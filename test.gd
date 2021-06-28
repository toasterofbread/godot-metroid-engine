tool
extends Sprite

func _process(delta):
	get_material().set_shader_param("zoom", get_viewport_transform().y.y)


func _on_Sprite_item_rect_changed():
	get_material().set_shader_param("scale", scale)
