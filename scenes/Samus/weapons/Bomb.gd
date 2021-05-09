extends SamusWeapon

const bomb_detonation_time: float = 0.6
const bomb_bounce_amount: float = 325.0
const bomb_horiz_bounce_amount: float = 200.0
const samus_aerial_damage: int = 10

func _ready():
	pass

func projectile_fired(projectile: Projectile):
	
	var samus_start_pos = Samus.global_position
	yield(Global.wait(bomb_detonation_time), "completed")
	
	var area: Area2D = projectile.get_node("Area2D")
	
	var processed_bodies = []
	
	var burst: AnimatedSprite = projectile.burst_end(false)
	while burst.frame < burst.frames.get_frame_count("collide") - 1:
		for body in area.get_overlapping_bodies():
			
			if body in processed_bodies:
				continue
			processed_bodies.append(body)
			
			if body == Samus:
				if Samus.current_state.id == "morphball":
					
					Samus.current_state.bounce(bomb_bounce_amount)
					
					var offset: float = Samus.global_position.x - samus_start_pos.x
					if offset != 0:
						
						var direction: int = Enums.dir.RIGHT
						if offset < 0:
							direction = Enums.dir.LEFT
						
						morphball_horiz_bounce(bomb_horiz_bounce_amount, direction)
					
					if not Samus.is_on_floor():
						Samus.damage(samus_aerial_damage)
			else:
				if body.has_method("damage"):
					body.damage(damage_type, damage_amount)
		yield(Global, "process_frame")
	
	burst.queue_free()
	projectile.kill()

func morphball_horiz_bounce(offset, direction):
	var timer: Timer = Global.timer()
	timer.start(0.2)
	while timer.time_left > 0:
		Samus.Physics.accelerate_x(offset/10, offset, direction)
		yield(Global, "process_frame")
	timer.queue_free()
