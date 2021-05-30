extends RigidBody2D
class_name SamusRigidProjectile

#export var base_velocity: float
#var velocity: Vector2
#var moving: bool = true
#var affected_by_world: bool = true
var Weapon: Node2D
#var travel_distance: = 0.0
var data: Dictionary
var chargebeam_damage_multiplier
var fire_pos: Position2D
var burst_sprite: AnimatedSprite
var apply_damage: = true
#var act_as_kinematic: bool setget set_act_as_kinematic

#func set_act_as_kinematic(value: bool):
#	act_as_kinematic = value
#	if act_as_kinematic:
##		mode = RigidBody2D.MODE_KINEMATIC
#		mass = 0
#	else:
#		mass = 1
##		mode = RigidBody2D.MODE_RIGID

const screen_exit_delay = 5.0
var screen_exit_delay_timer: Timer

func init(_Weapon, _fire_pos: Position2D, _chargebeam_damage_multiplier, _data:={}):
	Weapon = _Weapon
	data = _data
	chargebeam_damage_multiplier = _chargebeam_damage_multiplier
	fire_pos = _fire_pos
#	set_act_as_kinematic(_act_as_kinematic)
	
	burst_sprite = get_node_or_null("Burst")
	if burst_sprite:
		burst_sprite.position = Vector2.ZERO
	
	z_index = Enums.Layers.PROJECTILE
	z_as_relative = false
	
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
		
	global_position = fire_pos.position + Vector2(0, -10).rotated(fire_pos.rotation)
	rotation = fire_pos.rotation
#	velocity = Vector2(0, -base_velocity).rotated(rotation)
#
#	# Apply Samus's velocity to the projectile
#	if Weapon.Samus.Physics.apply_velocity:
#		var velocity_modifier = Weapon.Samus.Physics.vel
#
#		# Comparing velocity against 0.01 instead of 0 to account for earlier rotated() function innacuracy
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
	
#	if not moving or not act_as_kinematic:
#		Weapon.projectile_physics_process(self, null, delta)
#		return
#
#	travel_distance += (velocity*delta).length()
#
#	var collision: KinematicCollision2D
#	if affected_by_world:
##		add_central_force()
#		applied_force = self.velocity# * delta
#		print("nani")
##		position += velocity*delta
#	else:
##		add_central_force(self.velocity * delta)
#		applied_force = self.velocity# * delta
##		position += velocity*delta
	
#	if collision:
#		if collision.collider.has_method("damage") and apply_damage:
#			collision.collider.damage(Weapon.damage_type, Weapon.damage_amount*(chargebeam_damage_multiplier if chargebeam_damage_multiplier != null else 1.0))
	
	Weapon.projectile_physics_process(self, null, delta)

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

func screen_exited():
	if screen_exit_delay_timer.is_inside_tree():
		screen_exit_delay_timer.start(screen_exit_delay)

func screen_entered():
	screen_exit_delay_timer.stop()
