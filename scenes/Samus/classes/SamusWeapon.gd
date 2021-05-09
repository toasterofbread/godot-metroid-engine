extends Node2D
class_name SamusWeapon

var Samus: KinematicBody2D

export var id: String
export(Enums.DamageType) var damage_type
export var damage_amount: float = 0
export var velocity: float
export var cooldown: float
export var falls_to_ground: bool
export var move_by_velocity: bool = true
export var amount: int
export var capacity: int
export var is_morph_weapon: bool = false
export var is_base_weapon: bool = false

var Icon: SamusWeaponIcon
var Burst: AnimatedSprite
onready var Anchor: Node2D = Global.get_anchor("Samus/Weapons/" + self.id)
onready var AnchorBurst: Node2D = Global.get_anchor("Samus/Weapons/" + self.id + "_burst")
var Cooldown: Timer = Timer.new()
onready var BaseProjectile: Area2D = $Projectile

class Projectile extends KinematicBody2D:
	var velocity: Vector2
	var active: bool = true
	var falling: bool = false
	var Weapon: SamusWeapon
	var Burst: AnimatedSprite
	var AnimationPlayer
	var base_velocity: float
	var damage_type: int
	
	func _init(_Weapon: SamusWeapon, vel: float, pos: Position2D):
		self.Weapon = _Weapon
		
		for node in Weapon.BaseProjectile.get_children():
			self.add_child(node.duplicate())
		
		damage_type = Weapon.damage_type
		
		self.Burst = self.get_node("Burst")
		self.Burst.visible = false
		self.AnimationPlayer = self.get_node_or_null("AnimationPlayer")
		
		self.collision_layer = Weapon.BaseProjectile.collision_layer
		self.collision_mask = Weapon.BaseProjectile.collision_mask
		
		self.global_position = pos.global_position
		
		if self.get_node_or_null("VisibilityNotifier"):
			self.get_node("VisibilityNotifier").connect("screen_exited", Weapon, "on_projectile_screen_exited", [self])
		
		if not Weapon.move_by_velocity:
			return self
		
		# Set projectile's vector velocity based on its rotation and passed velocity float
		self.velocity = Vector2(0, -vel).rotated(pos.rotation)
		self.base_velocity = vel
		
		# Apply Samus's velocity to the projectile
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
		burst.global_position = pos.global_position
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
			var collision: KinematicCollision2D = move_and_collide(self.velocity * delta)
			if falling:
				self.rotation_degrees += Weapon.Samus.rng.randf_range(20, 45)
			if collision:
				if collision.collider.has_method("damage"):
					collision.collider.damage(Weapon.damage_type, Weapon.damage_amount)
#				if collision.collider.is_in_group(Groups.immune_to_projectiles) and not falling and Weapon.falls_to_ground:
#					velocity = velocity.bounce(collision.normal) / 2
#					velocity = velocity.rotated(deg2rad(Weapon.Samus.rng.randf_range(-10, 10)))
#					self.rotation = self.velocity.angle()
#					self.fall_to_ground()
				Weapon.projectile_collided(self)
				self.burst_end()
	
	
	func kill():
		self.queue_free()

func projectile_collided(_projectile: Projectile):
	pass

func projectile_fired(_projectile: Projectile):
	pass

func _ready():
	
	for child in self.get_children():
		if child is SamusWeaponIcon:
			self.Icon = child
			self.remove_child(self.Icon)
			Samus.HUD.add_weapon(self.Icon)
			Samus.Weapons.update_weapon_icons()
			Icon.update_digits(self.amount)
		else:
			child.visible = false
	
	self.Cooldown.one_shot = true 
	self.add_child(Cooldown)


func on_projectile_screen_exited(projectile: Area2D):
	yield(Global.wait(2), "completed")
	if is_instance_valid(projectile):
		projectile.kill()

func get_fire_pos():
	var pos: Position2D = Samus.Weapons.CannonPositions.get_node_or_null(Samus.Animator.current[false].position_node_path)
	if pos == null:
		return -1
	pos = pos.duplicate()
	AnchorBurst.add_child(pos)
	
	if Samus.facing == Enums.dir.RIGHT:
		pos.position.x  = pos.position.x * -1 + 8
	
	# For some reason the default global_position is the same as the relative position
	pos.global_position = Samus.global_position + pos.position
	
	if Samus.facing == Enums.dir.RIGHT:
		pos.rotation = (Vector2(-1, 0).rotated(pos.rotation) * Vector2(-1, 1)).angle()
	
	return pos

func fire():
	if Cooldown.time_left > 0 or self.amount == 0:
		return
	
	var pos = get_fire_pos()
	match pos:
		-1: return
	
	var projectile = Projectile.new(self, velocity, pos)
	Anchor.add_child(projectile)
	projectile.burst_start(pos)
	projectile_fired(projectile)
	Cooldown.start(cooldown)
	
	self.amount -= 1
	if Icon:
		Icon.update_digits(self.amount)
