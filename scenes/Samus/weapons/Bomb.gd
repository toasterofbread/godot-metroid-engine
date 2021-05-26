extends SamusWeapon

const bomb_detonation_time: float = 0.6
const bomb_bounce_amount: float = 325.0
const bomb_horiz_bounce_amount: float = 200.0
const samus_aerial_damage: int = 10

func get_fire_object(pos: Position2D, chargebeam_damage_multiplier):
	if Cooldown.time_left > 0 or chargebeam_damage_multiplier == 1.0:
		return null
	
	var projectiles = []
	
	var projectile: SamusRigidProjectile
	if chargebeam_damage_multiplier == null:
		projectile = ProjectileNode.duplicate()
		projectile.init(self, pos, chargebeam_damage_multiplier, true, {"position": null})
		projectiles.append(projectile)
		projectile.apply_damage = false
	else:
		for i in range(5):
			projectile = ProjectileNode.duplicate()
			projectile.init(self, pos, chargebeam_damage_multiplier, false, {"position": i})
			projectile.sleeping = true
#			projectile.apply_damage = false
#			projectile.velocity = Vector2(0, -500*i)
			projectiles.append(projectile)
			init_charge_bomb(i, projectile)
			
	return projectiles

func init_charge_bomb(i: int, projectile: SamusRigidProjectile):
	var props = ["moving", "affected_by_world", "visible"]
	for prop in props:
		projectile.set(prop, false)
	
	var samus_initial_position = Samus.global_position
	
	var amplitude: = 1.0
	var timer: GDScriptFunctionState = Global.wait(0.5)
	
	while timer.is_valid() and Input.is_action_pressed("fire_weapon"):
		var delta: float = yield(Global, "physics_frame")
		amplitude += delta*10
		print(amplitude)
	
	var samus_final_position = Samus.global_position
	
	if Input.is_action_pressed("pad_down"):
		projectile.act_as_kinematic = true
		projectile.velocity = Vector2(0, -500*i)
		yield(Global.wait(0.1*(i+1)), "completed")
	else:
		
#		projectile.velocity.x = (i-2)*500
#		projectile.velocity.y = 200*sin((i-2))
		projectile.sleeping = false
#		projectile.velocity = Vector2((i-2)*300, -100-(200*(2 - abs(i-2))))
		yield(Global.wait(0.05+(0.05*abs(i-2))), "completed")
	
	for prop in props:
		projectile.set(prop, true)
	
	fired(projectile)
	projectile.position += samus_final_position - samus_initial_position

func projectile_physics_process(projectile: SamusRigidProjectile, collision: KinematicCollision2D, delta: float):
	if projectile.moving:
		projectile.velocity = projectile.velocity.linear_interpolate(Vector2.ZERO, 0.25)

func fired(projectile: SamusRigidProjectile):
	if not projectile.visible:
		return
	
	yield(Global.wait(bomb_detonation_time), "completed")
	if is_instance_valid(projectile) and projectile.visible:
		explode(projectile)

func explode(projectile: SamusRigidProjectile):
	projectile.visible = false
	var processed_bodies = []
	var burst: AnimatedSprite = projectile.burst_end(false)
	var area: Area2D = projectile.get_node("Area2D")
	while burst.frame < burst.frames.get_frame_count("end") - 1:
		for body in area.get_overlapping_bodies():
			
			if body in processed_bodies:
				continue
			processed_bodies.append(body)
			
			if body == Loader.Samus:
				if Loader.Samus.current_state.id in ["morphball", "spiderball"]:
					
					Loader.Samus.current_state.bounce(bomb_bounce_amount)
					
					var offset: float = projectile.global_position.x - Loader.Samus.global_position.x
					if offset != 0:
						
						var direction: int = Enums.dir.RIGHT
						if offset < 0:
							direction = Enums.dir.LEFT
						
						morphball_horiz_bounce(bomb_horiz_bounce_amount, direction)
					
					if not Loader.Samus.is_on_floor():
						Loader.Samus.damage(Enums.DamageType.BOMB, samus_aerial_damage)
			else:
				if body.has_method("damage"):
					body.damage(damage_type, damage_amount)
		yield(Global, "process_frame")
	projectile.queue_free()
	burst.queue_free()

func morphball_horiz_bounce(offset, direction):
	var timer: Timer = Global.timer()
	timer.start(0.2)
	while timer.time_left > 0:
		Samus.Physics.accelerate_x(offset/10, offset, direction)
		yield(Global, "process_frame")
	timer.queue_free()
