extends KinematicBody2D
class_name SamusKinematicProjectile

var base_velocity: float
var velocity: Vector2
var moving: bool = true
var affected_by_world: bool = true
var Weapon: SamusWeapon
var data: Dictionary
var travel_distance: = 0.0
var chargebeam_damage_multiplier
var fire_pos: Position2D
var burst_sprite: AnimatedSprite
var apply_damage: = true

const screen_exit_delay = 5.0
var screen_exit_delay_timer: Timer

func init(_Weapon, _fire_pos: Position2D, _chargebeam_damage_multiplier, _data:={}):
	Weapon = _Weapon
	data = _data
	chargebeam_damage_multiplier = _chargebeam_damage_multiplier
	fire_pos = _fire_pos
	
	base_velocity = Weapon.damage_values["speed"] if "speed" in Weapon.damage_values else 0
	
	burst_sprite = get_node_or_null("Burst")
	if burst_sprite:
		burst_sprite.position = Vector2.ZERO
		burst_sprite.z_as_relative = false
		burst_sprite.z_index = Enums.Layers.PROJECTILE
	
	z_as_relative = false
	z_index = Enums.Layers.PROJECTILE
	
	visible = true
	if has_node("Light2D"):
		$Light2D.texture = $Sprite.frames.get_frame($Sprite.animation, 0)
	
	screen_exit_delay_timer = Timer.new()
	self.add_child(screen_exit_delay_timer)
	screen_exit_delay_timer.connect("timeout", self, "queue_free")
	
	var visibility_notifier: VisibilityNotifier2D = self.get_node_or_null("VisibilityNotifier2D")
	if visibility_notifier:
		visibility_notifier.connect("screen_exited", self, "screen_exited")
		visibility_notifier.connect("screen_entered", self, "screen_entered")
		
	global_position = fire_pos.global_position# + Vector2(0, -10).rotated(fire_pos.rotation)
	rotation = fire_pos.rotation
	velocity = Vector2(0, -base_velocity).rotated(rotation)
	
#	# Apply Samus's velocity to the projectile
#	if Weapon.Samus.Physics.apply_velocity:
#		var velocity_modifier = Weapon.Samus.Physics.vel
#
#		# Comparing velocity against 0.01 instead of 0 to account for earlier rotated() function inaccuracy
#		if self.velocity.x > 0.01 and velocity_modifier.x > 0:
#			self.velocity.x += velocity_modifier.x
#		elif self.velocity.x < -0.01 and velocity_modifier.x < 0:
#			self.velocity.x += velocity_modifier.x
#
#		if self.velocity.y > 0.01 and velocity_modifier.y > 0:
#			self.velocity.y += velocity_modifier.y
#		elif self.velocity.y < -0.01 and velocity_modifier.y < 0:
#			self.velocity.y += velocity_modifier.y

func _physics_process(delta):
	
	if not moving:
		Weapon.projectile_physics_process(self, [], delta)
		return
	
	travel_distance += (velocity*delta).length()
	
	var colliders: Array = []
	var collision: KinematicCollision2D
	if affected_by_world:
		collision = move_and_collide(velocity * delta)
	else:
		collision = move_and_collide(velocity * delta, true, true, true)
		position += velocity*delta
	
	if collision:
		colliders.append(collision.collider)
	
	var collisionArea = get_node_or_null("CollisionArea")
	if collisionArea:
		colliders += $CollisionArea.get_overlapping_bodies() 
	
	if apply_damage:
		for body in colliders:
			if body.has_method("damage"):
				body.damage(
					Weapon.damage_type, 
					Weapon.damage_amount * (chargebeam_damage_multiplier if chargebeam_damage_multiplier != null else 1.0) * Loader.loaded_save.difficulty_data["outgoing_damage_multiplier"],
					get_node("ImpactPosition").global_position
					)
	
	Weapon.projectile_physics_process(self, colliders, delta)

func burst_start(queue_free:=true, animation_name:="start"):
	var burst = burst_sprite.duplicate()
	burst.visible = true
	Weapon.LocalAnchor.add_child(burst)
	burst.play(animation_name)
	if queue_free:
		yield(burst, "animation_finished")
		burst.queue_free()
	else:
		return burst

func burst_end(queue_free:=true, animation_name:="end"):
	var burst = burst_sprite.duplicate()
	burst.visible = true
	Weapon.GlobalAnchor.add_child(burst)
	burst.global_position = position
	burst.play(animation_name)
	if queue_free:
		yield(burst, "animation_finished")
		burst.queue_free()
	else:
		return burst

func fluid_splash(type: int):
	if Weapon.has_method("fluid_splash"):
		return Weapon.fluid_splash(self, type)
	else:
		return true

func screen_exited():
	if screen_exit_delay_timer.is_inside_tree():
		screen_exit_delay_timer.start(screen_exit_delay)

func screen_entered():
	screen_exit_delay_timer.stop()
