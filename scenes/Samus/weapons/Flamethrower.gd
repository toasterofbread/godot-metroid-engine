extends SamusWeapon

onready var projectile = $Flame
onready var sprite = $Flame/AnimatedSprite

func ready():
	remove_child(projectile)
	projectile.z_index = Enums.Layers.PROJECTILE
	projectile.z_as_relative = false
	projectile.visible = true

func get_fire_object(pos: Position2D, _chargebeam_damage_multiplier):
	return projectile

func fired(projectile: Area2D):
	sprite.play("start")
	yield(sprite, "animation_finished")
	if sprite.animation == "start":
		sprite.play("loop")

func _process(delta):
	if not projectile.is_inside_tree():
		return
	if not Input.is_action_pressed("fire_weapon") and sprite.animation == "loop":
		sprite.play("end")
		yield(sprite, "animation_finished")
		GlobalAnchor.remove_child(projectile)
		return
	if not Weapons.fire_pos:
		projectile.visible = false
		return
	projectile.visible = true
	
	var lerp_weight = 0.75
	projectile.global_position = projectile.global_position.linear_interpolate(Weapons.fire_pos.position, lerp_weight)
#	projectile.rotation = Weapons.fire_pos.rotation
	projectile.rotation = lerp_angle(projectile.rotation, Weapons.fire_pos.rotation, lerp_weight)
	
	for body in projectile.get_overlapping_bodies():
		if body.has_method("damage"):
			body.damage(damage_type, damage_amount, null)
