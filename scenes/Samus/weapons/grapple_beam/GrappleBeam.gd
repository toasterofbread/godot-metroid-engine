extends SamusWeapon

onready var Projectile = preload("res://scenes/Samus/weapons/grapple_beam/Projectile.tscn")

func on_projectile_screen_exited(projectile: Area2D):
	yield(Global.wait(2), "completed")
	if is_instance_valid(projectile):
		projectile.kill()

func get_fire_pos():
	var pos: Position2D = Samus.Weapons.CannonPositions.get_node_or_null(Samus.Animator.current[false].position_node_path)
	if pos == null:
		return null
	var ret = pos.duplicate()
	
	Samus.add_child(ret)
	ret.global_position = Samus.global_position + ret.position
	ret.position = pos.position
	if Samus.facing == Enums.dir.RIGHT:
		ret.position.x += (pos.position.x * -1 + 8) - pos.position.x
	
	return ret

func fire(_chargebeam_damage_multiplier):
	if Cooldown.time_left > 0:
		return false
	
	var pos = Weapons.fire_pos
	if not pos:
		return false
	
	var projectile = Projectile.instance()
	
	self.add_child(projectile)
	projectile.visible = true
	
	projectile.global_position = pos.position
	projectile.rotation = pos.rotation
	
	Cooldown.start(cooldown)
	
	return false

func attach(anchor: Node2D, beam):
	Samus.current_state.change_state("grapple", {"anchor": anchor, "beam": beam})
