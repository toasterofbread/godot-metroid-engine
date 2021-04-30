extends Node2D
class_name SamusWeapon

var samus: KinematicBody2D

export var id: String
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


class Projectile extends Area2D:
	var velocity: float
	var active: bool = true
	var Weapon: SamusWeapon
	var Burst: AnimatedSprite
	
	func _init(BaseProjectile: Area2D, Weapon: SamusWeapon, vel: float, pos: Position2D):
		for node in BaseProjectile.get_children():
			self.add_child(node.duplicate())
		
		self.velocity = vel
		self.Weapon = Weapon
		self.Burst = self.get_node("Burst")
		self.Burst.visible = false
		
		self.collision_layer = BaseProjectile.collision_layer
		self.collision_mask = BaseProjectile.collision_mask
	
		self.rotation = pos.rotation
		self.global_position = pos.global_position
		self.get_node("VisibilityNotifier").connect("screen_exited", Weapon, "on_projectile_screen_exited", [self])
		self.get_node("WorldCollider").connect("body_entered", Weapon, "on_projectile_collision_with_world", [self])
		
		return self
	
	func burst_start(pos: Position2D):
		var burst: AnimatedSprite = self.Burst.duplicate()
		burst.visible = true
		Weapon.AnchorBurst.add_child(burst)
		burst.global_position = pos.global_position
		burst.play("fire")
		yield(burst, "animation_finished")
		burst.queue_free()
	
	func burst_end():
		var burst: AnimatedSprite = self.Burst.duplicate()
		burst.visible = true
		burst.global_position = self.get_node("WorldCollider").global_position
		Weapon.AnchorBurst.add_child(burst)
		burst.play("collide")
		self.active = false
		for child in self.get_children():
			child.queue_free()
		yield(burst, "animation_finished")
		burst.queue_free()
		self.kill()
	
	func kill():
		self.queue_free()

func _ready():
	for child in self.get_children():
		if child is SamusWeaponIcon:
			self.Icon = child
			self.remove_child(self.Icon)
			samus.hud.add_weapon(self.Icon)
			samus.weapons.update_weapon_icons()
		else:
			child.visible = false
	
	self.Cooldown.one_shot = true 
	self.add_child(Cooldown)

func _physics_process(_delta):
	for projectile in self.Anchor.get_children():
		if not projectile.active:
			continue
		projectile.global_position += Vector2(0, -projectile.velocity).rotated(projectile.rotation)

func on_projectile_screen_exited(projectile: Area2D):
	yield(Global.wait(2), "completed")
	if is_instance_valid(projectile):
		projectile.kill()

func on_projectile_collision_with_world(_body, projectile: Projectile):
	projectile.burst_end()

func get_fire_pos():
	var pos: Position2D = samus.animator.get_node("CannonPositions").get_node_or_null(samus.animator.current[false].state_id + "/" + samus.animator.current[false].id)
	if pos == null:
		return -1
	pos = pos.duplicate()
	AnchorBurst.add_child(pos)
	
	if samus.facing == Global.dir.RIGHT:
		pos.position.x  = pos.position.x * -1 + 8
	
	# For some reason the default global_position is the same as the relative position
	pos.global_position = samus.global_position + pos.position
	
	if samus.facing == Global.dir.RIGHT:
		pos.rotation = (Vector2(-1, 0).rotated(pos.rotation) * Vector2(-1, 1)).angle()
	
	return pos

