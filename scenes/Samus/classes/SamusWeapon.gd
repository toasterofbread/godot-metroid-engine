extends Node2D
class_name SamusWeapon

var samus: KinematicBody2D

export var id: String
export(Enums.DamageType) var damage_type = Enums.DamageType.NONE
export var velocity: float
export var cooldown: float
export var amount: int
export var capacity: int
export var is_morph_weapon: bool
export var is_base_weapon: bool

var Icon: SamusWeaponIcon
var Burst: AnimatedSprite
onready var Anchor: Node2D = Global.get_anchor("Samus/Weapons/" + self.id)
onready var AnchorBurst: Node2D = Global.get_anchor("Samus/Weapons/" + self.id + "_burst")
var Cooldown: Timer = Timer.new()
onready var BaseProjectile = $Projectile

class Projectile extends Area2D:
	var velocity: Vector2
	var active: bool = true
	var Weapon: SamusWeapon
	var Burst: AnimatedSprite
	var AnimationPlayer
	
	func _init(BaseProjectile: Area2D, Weapon: SamusWeapon, vel: float, pos: Position2D):
		for node in BaseProjectile.get_children():
			self.add_child(node.duplicate())
		
		# Set projectile's vector velocity based on its rotation and passed velocity float
		self.velocity = Vector2(0, -vel).rotated(pos.rotation)
		
		# Apply Samus's velocity to the projectile
		var velocity_modifier = Weapon.samus.physics.vel / 75
		
		# Comparing velocity against 0.0001 instead of 0 to account for earlier rotated() function innacuracy
		if self.velocity.x > 0.0001 and velocity_modifier.x > 0:
			self.velocity.x += velocity_modifier.x
		elif self.velocity.x < -0.0001 and velocity_modifier.x < 0:
			self.velocity.x += velocity_modifier.x
		
		if self.velocity.y > 0.0001 and velocity_modifier.y > 0:
			self.velocity.y += velocity_modifier.y
		elif self.velocity.y < -0.0001 and velocity_modifier.y < 0:
			self.velocity.y += velocity_modifier.y
		
		self.Weapon = Weapon
		self.Burst = self.get_node("Burst")
		self.Burst.visible = false
		self.AnimationPlayer = self.get_node_or_null("AnimationPlayer")
		
		self.collision_layer = BaseProjectile.collision_layer
		self.collision_mask = BaseProjectile.collision_mask
	
		self.rotation = pos.rotation
		self.global_position = pos.global_position
		self.get_node("VisibilityNotifier").connect("screen_exited", Weapon, "on_projectile_screen_exited", [self])
		self.connect("body_entered", Weapon, "on_projectile_collision", [self])
		
		return self
	
	func burst_start(pos: Position2D):
		var burst: AnimatedSprite = self.Burst.duplicate()
		burst.visible = true
		Weapon.samus.add_child(burst)
		burst.global_position = pos.global_position
		burst.play("fire")
		if self.AnimationPlayer:
			self.AnimationPlayer.play("start")
		yield(burst, "animation_finished")
		burst.queue_free()
	
	func burst_end():
		self.visible = false
		self.active = false
		
		var burst: AnimatedSprite = self.Burst.duplicate()
		burst.visible = true
		burst.global_position = self.global_position
		Weapon.AnchorBurst.add_child(burst)
		burst.play("collide")
		if self.AnimationPlayer:
			self.AnimationPlayer.play("end")
		yield(burst, "animation_finished")
		burst.queue_free()
		self.kill()
	
	func kill():
		self.queue_free()

func projectile_collided(_projectile: Projectile):
	pass

func projectile_fired(_projectile: Projectile):
	pass

func _ready():
	
	add_to_group(Groups.damages_world, true)
	
	for child in self.get_children():
		if child is SamusWeaponIcon:
			self.Icon = child
			self.remove_child(self.Icon)
			samus.hud.add_weapon(self.Icon)
			samus.weapons.update_weapon_icons()
			Icon.update_digits(self.amount)
		else:
			child.visible = false
	
	self.Cooldown.one_shot = true 
	self.add_child(Cooldown)

func _physics_process(_delta):
	for projectile in self.Anchor.get_children():
		if not projectile.active:
			continue
		projectile.global_position += projectile.velocity

func on_projectile_screen_exited(projectile: Area2D):
	yield(Global.wait(2), "completed")
	if is_instance_valid(projectile):
		projectile.kill()

func on_projectile_collision(body: Node2D, projectile: Projectile):
	if body.has_method("collision"):
		body.call("collision", self)
	projectile_collided(projectile)
	projectile.burst_end()

func get_fire_pos():
	var pos: Position2D = samus.animator.get_node("CannonPositions").get_node_or_null(samus.animator.current[false].position_node_path)
	if pos == null:
		return -1
	pos = pos.duplicate()
	AnchorBurst.add_child(pos)
	
	if samus.facing == Enums.dir.RIGHT:
		pos.position.x  = pos.position.x * -1 + 8
	
	# For some reason the default global_position is the same as the relative position
	pos.global_position = samus.global_position + pos.position
	
	if samus.facing == Enums.dir.RIGHT:
		pos.rotation = (Vector2(-1, 0).rotated(pos.rotation) * Vector2(-1, 1)).angle()
	
	return pos

func fire():
	if Cooldown.time_left > 0 or self.amount == 0:
		return
	
	var pos = get_fire_pos()
	match pos:
		-1: return
	
	var projectile = Projectile.new(BaseProjectile, self, velocity, pos)
	Anchor.add_child(projectile)
	projectile.burst_start(pos)
	projectile_fired(projectile)
	Cooldown.start(cooldown)
	
	self.amount -= 1
	if Icon:
		Icon.update_digits(self.amount)
