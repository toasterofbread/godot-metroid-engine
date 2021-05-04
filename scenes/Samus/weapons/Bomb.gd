extends SamusWeapon

const bomb_detonation_time: float = 0.5
const bomb_bounce_amount: float = 400.0
const bomb_horiz_bounce_amount: float = 200.0
const samus_aerial_damage: int = 10

func _ready():
	pass

func projectile_fired(projectile: Projectile):
	
	var samus_start_pos = samus.global_position
	yield(Global.wait(bomb_detonation_time), "completed")
	
	var area: Area2D = projectile.get_node("Area2D")
	
	var processed_bodies = []
	
	var burst: AnimatedSprite = projectile.burst_end(false)
	while burst.frame < burst.frames.get_frame_count("collide") - 1:
		for body in area.get_overlapping_bodies():
			
			if body in processed_bodies:
				continue
			processed_bodies.append(body)
			
			if body == samus:
				if samus.current_state.id == "morphball":
					
					samus.current_state.bounce(bomb_bounce_amount)
					
					var offset: float = samus.global_position.x - samus_start_pos.x
					print(offset)
					if offset != 0:
#						var tween: Tween = Tween.new()
						
						var direction: int = Enums.dir.RIGHT
						if offset < 0:
							direction = Enums.dir.LEFT
						
						morphball_horiz_bounce(bomb_horiz_bounce_amount, direction)
#						tween.interpolate_method(samus.physics, "accelerate_x", offset/100, offset, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT_IN)
#						AnchorBurst.add_child(tween)
#						tween.start()
					
					if not samus.is_on_floor():
						samus.damage(samus_aerial_damage)
			else:
				if body.has_method("collide"):
					body.collide(projectile)
		yield(Global, "process_frame")
	
	burst.queue_free()
	projectile.kill()

func morphball_horiz_bounce(offset, direction):
	var timer: Timer = Global.timer()
	timer.start(0.2)
	while timer.time_left > 0:
		samus.physics.accelerate_x(offset/10, offset, direction)
		yield(Global, "process_frame")
	timer.queue_free()
