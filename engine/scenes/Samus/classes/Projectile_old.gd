extends SamusWeapon

export var velocity: float
export var falls_to_ground: bool
export var move_by_velocity: bool = true
export var burst_start: bool = true

var Burst: AnimatedSprite
onready var AnchorBurst: Node2D = Global.get_anchor("Samus/Weapons/" + str(self.id) + "_burst")
onready var BaseProjectile: Area2D = $Projectile

class Projectile extends KinematicBody2D:
	var velocity: Vector2
	var active: bool = true
	var falling: bool = false
	var Weapon: SamusKinematicProjectile
	var Burst: AnimatedSprite
	var AnimationPlayer
	var base_velocity: float
	var damage_type: int
	var travel_distance: = 0.0
	var Sprite: AnimatedSprite
	var move_and_collide: = true
	
	func _init(_Weapon: SamusKinematicProjectile, vel: float, pos: Position2D):
		self.Weapon = _Weapon
		
		for node in Weapon.BaseProjectile.get_children():
			self.add_child(node.duplicate())
		
		damage_type = Weapon.damage_type
		
		self.Burst = self.get_node_or_null("Burst")
		self.Sprite = self.get_node_or_null("Sprite")
		if self.Burst:
			self.Burst.visible = false
		self.AnimationPlayer = self.get_node_or_null("AnimationPlayer")
		
		self.collision_layer = Weapon.BaseProjectile.collision_layer
		self.collision_mask = Weapon.BaseProjectile.collision_mask
		self.z_index = Enums.Layers.PROJECTILE
		self.z_as_relative = false
		
		self.global_position = pos.position
		
		if self.get_node_or_null("VisibilityNotifier"):
			self.get_node("VisibilityNotifier").connect("screen_exited", Weapon, "on_projectile_screen_exited", [self])
		
		if not Weapon.move_by_velocity:
			return self
		
		# Set projectile's vector velocity based on its rotation and passed velocity float
		self.velocity = Vector2(0, -vel).rotated(pos.rotation)
		self.base_velocity = vel
		
		# Apply Samus's velocity to the projectile
		if Weapon.Samus.Physics.apply_velocity:
			var velocity_modifier = Weapon.Samus.Physics.vel
			
			# Comparing velocity against 0.01 instead of 0 to account for earlier rotated() function innacuracy
			if self.velocity.x > 0.01 and velocity_modifier.x > 0:
				self.velocity.x += velocity_modifier.x
			elif self.velocity.x < -0.01 and velocity_modifier.x < 0:
				self.velocity.x += velocity_modifier.x

			if self.velocity.y > 0.01 and velocity_modifier.y > 0:
				self.velocity.y += velocity_modifier.y
			elif self.velocity.y < -0.01 and velocity_modifier.y < 0:
				self.velocity.y += velocity_modifier.y
		
		self.rotation = pos.rotation
		
		return self
	
	func burst_start(pos: Position2D):
		var burst: AnimatedSprite = self.Burst.duplicate()
		burst.visible = true
		Weapon.Samus.add_child(burst)
		burst.global_position = pos.position
		burst.play("fire")
		if self.AnimationPlayer:
			self.AnimationPlayer.play("start")
		yield(burst, "animation_finished")
		burst.queue_free()
	
	func burst_end(kill_self: bool = true):
		self.visible = false
		self.active = false
		
		var burst: AnimatedSprite = self.Burst.duplicate()
		burst.visible = true
		burst.global_position = self.global_position
		Weapon.AnchorBurst.add_child(burst)
		burst.play("collide")
		if self.AnimationPlayer:
			self.AnimationPlayer.play("end")

		if kill_self:
			yield(burst, "animation_finished")
			burst.queue_free()
			self.kill()
		else:
			return burst
	
	func fall_to_ground():
		self.falling = true
		var tween = Tween.new()
		self.add_child(tween)
		
		if get_node_or_null("Trail"):
			tween.interpolate_property(get_node("Trail"), "modulate", get_node("Trail").modulate, Color.transparent, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		if get_node_or_null("Flame"):
			tween.interpolate_property(get_node("Flame"), "modulate", get_node("Flame").modulate, Color.transparent, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
		
		tween.interpolate_property(self, "velocity:x", self.velocity.x, self.velocity.x / 10, 0.5, Tween.TRANS_SINE)
		tween.interpolate_property(self, "velocity:y", self.velocity.y, 350, 0.2, Tween.TRANS_SINE)
		tween.start()
	
	func _physics_process(delta):
		
		if not Weapon.move_by_velocity:
			return
		
		if self.active:
			travel_distance += (velocity*delta).length()
			
			var collision: KinematicCollision2D
			if move_and_collide:
				collision = move_and_collide(self.velocity * delta)
			else:
				collision = move_and_collide(self.velocity * delta, true, true, true)
				position += velocity*delta
			
			Weapon.projectile_physics_process(self, collision)
			if falling:
				self.rotation_degrees += Weapon.Global.rng.randf_range(20, 45)
			if collision:
				if collision.collider.has_method("damage"):
					collision.collider.damage(Weapon.damage_type, Weapon.damage_amount)
#				if collision.collider.is_in_group(Groups.immune_to_projectiles) and not falling and Weapon.falls_to_ground:
#					velocity = velocity.bounce(collision.normal) / 2
#					velocity = velocity.rotated(deg2rad(Weapon.Global.rng.randf_range(-10, 10)))
#					self.rotation = self.velocity.angle()
#					self.fall_to_ground()
				Weapon.projectile_collided(self, collision)
	
	
	func kill():
		self.queue_free()

func projectile_collided(projectile: Projectile, _collision: KinematicCollision2D):
	projectile.burst_end()

func projectile_fired(_projectile: Projectile):
	pass

func projectile_physics_process(_projectile: Projectile, _collision: KinematicCollision2D):
	pass

func on_projectile_screen_exited(projectile: Area2D):
	yield(Global.wait(2), "completed")
	if is_instance_valid(projectile):
		projectile.kill()

func fire():
	if Cooldown.time_left > 0 or (self.ammo == 0 and not self.unlimited_ammo):
		return
	
	var pos = get_fire_pos()
	if pos == null:
		return
	
	var projectile = Projectile.new(self, velocity, pos)
	pos.queue_free()
	Anchor.add_child(projectile)
	if burst_start:
		projectile.burst_start(pos)
	projectile_fired(projectile)
	Cooldown.start(cooldown)
	
	set_ammo(ammo - 1)
