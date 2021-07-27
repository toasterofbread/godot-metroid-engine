extends SamusWeapon

onready var time_to_detonation: float = damage_values["time_to_detonation"]
onready var bomb_bounce_timer: Timer = Global.get_timer()
var bomb_bounce_limit: float

var morphball_physics_data: Dictionary
#onready var bomb_jump_speed: float = morphball_physics_data["bomb_jump_speed"]
#onready var bomb_jump_horiz_speed: float = morphball_physics_data["bomb_jump_horiz_speed"]
#onready var bomb_jump_time: float = morphball_physics_data["bomb_jump_time"]
#const samus_aerial_damage: int = 10

onready var bomb_amount_mini_upgrade: Array = [Samus.get_mini_upgrade("bomb_placement_cap_increase", 0), Samus.get_mini_upgrade("bomb_placement_cap_increase", 1)["data"]["increase_amount"]]
onready var max_bomb_amount: int = damage_values["max_bomb_amount"]
var projectiles: = []

func _ready():
	while Samus.Physics == null:
		yield(get_tree(), "idle_frame")
	morphball_physics_data = Samus.Physics.data["morphball"]

func get_fire_object(pos: Position2D, chargebeam_damage_multiplier):
	if not Weapons.fire_pos or Cooldown.time_left > 0 or len(projectiles) >= max_bomb_amount + (bomb_amount_mini_upgrade[0]["created"] * bomb_amount_mini_upgrade[1]) or chargebeam_damage_multiplier == 1.0:
		return false
	
	var projectiles = []
	
	if chargebeam_damage_multiplier == null:
		var projectile: SamusKinematicProjectile
		projectile = ProjectileNode["Kinematic"].duplicate()
		projectile.init(self, pos, chargebeam_damage_multiplier)
		projectiles.append(projectile)
		projectile.apply_damage = false
		return projectiles
	else:
		init_charge_bombs(chargebeam_damage_multiplier)
		return true

func init_charge_bombs(chargebeam_damage_multiplier: float):
#	var props = ["moving", "affected_by_world", "visible"]
#	for prop in props:
#		projectile.set(prop, false)
	
#	var samus_initial_position = Samus.global_position
	
	var amplitude = 0.5
	var timer: GDScriptFunctionState = Global.wait(0.5)

	while timer.is_valid() and Input.is_action_pressed("fire_weapon") and Samus.current_state.id in ["morphball", "spiderball"]:
		var delta: float = yield(Global, "physics_frame")
		amplitude += delta
	
#	var samus_final_position = Samus.global_position
	var projectiles = []
	var pad_vector = Shortcut.get_pad_vector("pressed")
	if pad_vector.y == 1 and pad_vector.x == 0 and Samus.is_on_floor():
		
		var pos = Weapons.fire_pos.duplicate()
		for i in range(5):
			if i != 0:
				yield(Global.wait(0.05*i), "completed")
			var projectile: SamusKinematicProjectile = ProjectileNode["Kinematic"].duplicate()
			projectile.init(self, pos, chargebeam_damage_multiplier, {"position": i})
			projectile.affected_by_world = true
			projectile.velocity = Vector2(0, -500*i)
			GlobalAnchor.add_child(projectile)
			fired(projectile)
	else:
		for i in range(5):
			var projectile: SamusRigidProjectile = ProjectileNode["Rigid"].duplicate()
			projectile.init(self, Weapons.fire_pos, chargebeam_damage_multiplier, {"position": i, "charge_profile": "scatter"})
			var impulse = Vector2(50*(i-2), -200) + Vector2(200*pad_vector.x, -40*abs(pad_vector.x)*(abs(i-4) if pad_vector.x > 0 else i))
			projectile.apply_central_impulse(impulse*amplitude)
			GlobalAnchor.add_child(projectile)
			fired(projectile)
#			yield(Global.wait(0.05+(0.05*abs(i-2))), "completed")
#		projectile.velocity.x = (i-2)*500
#		projectile.velocity.y = 200*sin((i-2))
#		projectile.velocity = Vector2((i-2)*300, -100-(200*(2 - abs(i-2))))
	
#	for prop in props:
#		projectile.set(prop, true)
	
#	for projectile in projectiles:
#		GlobalAnchor.add_child(projectile)
#		fired(projectile)
	
#	projectile.position += samus_final_position - samus_initial_position

func projectile_physics_process(projectile: PhysicsBody2D, collision: KinematicCollision2D, delta: float):
	if projectile is SamusKinematicProjectile and projectile.moving:
#		yield(Global.wait(0.05*i), "completed")
		projectile.velocity = projectile.velocity.linear_interpolate(Vector2.ZERO, 0.25)
	elif projectile is SamusRigidProjectile:
		projectile.linear_velocity.x = min(abs(projectile.linear_velocity.x), 500)*sign(projectile.linear_velocity.x)
		projectile.linear_velocity.y = min(abs(projectile.linear_velocity.y), 300)*sign(projectile.linear_velocity.y)

func fired(projectile: PhysicsBody2D):
	if not projectile or not projectile.visible:
		return
	
	projectiles.append(projectile)
	
	if "charge_profile" in projectile.data:
		var profile = projectile.data["charge_profile"]
		if profile == "scatter":
			yield(projectile, "body_entered")
			yield(Global.wait(time_to_detonation), "completed")
	else:
		yield(Global.wait(time_to_detonation), "completed")
	
	if is_instance_valid(projectile) and projectile.visible:
		explode(projectile)

func explode(projectile: PhysicsBody2D):
	projectile.visible = false
	var processed_bodies = []
	var burst: AnimatedSprite = projectile.burst_end(false)
	var area: Area2D = projectile.get_node("Area2D")
	
	var samus_start_pos = Samus.global_position.x
	
	while burst.frame < burst.frames.get_frame_count("end") - 1:
		for body in area.get_overlapping_bodies():
			if body in processed_bodies:
				continue
			processed_bodies.append(body)
			
			if body == Samus:
				if Samus.current_state.id in ["morphball", "spiderball"]:
					
					var offset: float = projectile.global_position.x - Samus.global_position.x - (2 if Samus.facing == Enums.dir.LEFT else 6)
					if abs(offset) > 2.5: 
#						morphball_horiz_bounce(offset)
						bomb_bounce_timer.start(morphball_physics_data["bomb_jump_time"])
						bomb_bounce_limit = morphball_physics_data["bomb_jump_horiz_speed"] * -sign(offset)
					
					if not Samus.is_on_floor():
						if Samus.current_fluid == Fluid.TYPES.NONE:
							Samus.current_state.bounce(morphball_physics_data["bomb_jump_speed"])
							
							# TODO | Should this be a thing? Probably not.
#							Samus.damage(Enums.DamageType.BOMB, samus_aerial_damage, projectile.global_position)
					else:
						Samus.current_state.bounce(morphball_physics_data["bomb_jump_speed"])
			elif not body.name == "Samus":
				if body.has_method("damage"):
					body.damage(damage_type, damage_amount, projectile.global_position)
		yield(get_tree(), "idle_frame")
	projectiles.erase(projectile)
	projectile.queue_free()
	burst.queue_free()

func _process(delta):
	if bomb_bounce_timer.time_left > 0.0:
		Samus.Physics.move_x(bomb_bounce_limit, morphball_physics_data["bomb_jump_horiz_speed"]*30*delta)

#func morphball_horiz_bounce(offset: float):
##	var tween: Tween = Tween.new()
##	tween.interpolate_method(Samus.Physics, "move_x", )
#
#	var timer: GDScriptFunctionState = Global.wait(0.2)
#	while timer.is_valid():
#		var delta = yield(get_tree(), "idle_frame")
#		Samus.Physics.move_x(limit, bomb_horiz_bounce_amount*30*delta)
		
