tool
extends Sprite

export var update_ice = false setget update_ice
var fluid: = Fluid.new()

func _ready():
	if Engine.editor_hint:
		return
	update()
	fluid.type = fluid.TYPES.WATER
	$IceBox.visible = false
	$IceBox/Ice.material.set("shader_param/dissolve_value", 0)

func update_ice(_value=false):
	update_ice = false
	get_material().set_shader_param("zoom", get_viewport_transform().y.y)
	get_material().set_shader_param("scale", scale)
	$IceBox/Ice.rect_scale = (Vector2.ONE / scale) * Vector2(0.2, 0.2)
#	$IceBox/Ice.rect_size.x = $Ice.rect_size.x * $IceBox/Ice.rect_scale.x
	$IceBox/StaticBody2D/CollisionShape2D.shape.extents.x = $IceBox.rect_size.x / 2
	$IceBox/StaticBody2D/CollisionShape2D.shape.extents.y = $IceBox/Ice.texture.get_height() / 2 * $IceBox/Ice.rect_scale.y
	$IceBox/StaticBody2D/CollisionShape2D.position = $IceBox/StaticBody2D/CollisionShape2D.shape.extents

func _on_Area2D_body_entered(body):
	return
	if body is SamusKinematicProjectile and not $IceBox.visible and body.Weapon.id == Enums.Upgrade.POWERBEAM:
		body.collision()
		if Enums.Upgrade.ICEBEAM in body.Weapon.current_types:
			update_ice()
			$IceBox.rect_global_position.y = body.global_position.y
			form_ice()

func form_ice():
	if $IceBox/Tween.is_active():
		return
	$IceBox.visible = true
	$IceBox/Tween.interpolate_property($IceBox/Ice.material, "shader_param/dissolve_value", $IceBox/Ice.material.get("shader_param/dissolve_value"), 1, 0.5)
	$IceBox/Tween.start()

func melt_ice():
	if $IceBox/Tween.is_active():
		return
	$IceBox/Tween.interpolate_property($IceBox/Ice.material, "shader_param/dissolve_value", $IceBox/Ice.material.get("shader_param/dissolve_value"), 0, 0.5)
	$IceBox/Tween.start()
	yield($IceBox/Tween, "tween_completed")
	$IceBox.visible = false
