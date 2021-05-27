extends Node2D
class_name SamusWeapon

onready var Samus: KinematicBody2D = Loader.Samus
onready var Weapons: Node2D = Loader.Samus.Weapons

export(Enums.Upgrade) var id: int
export(Enums.DamageType) var damage_type
export var damage_amount: float
export var cooldown: float
export var is_morph_weapon: bool
export var is_base_weapon: bool

var ammo: int setget set_ammo
var amount: int

var Icon: SamusWeaponIcon
var ProjectileNode
onready var GlobalAnchor: Node2D = Global.get_anchor("Samus/Weapons/" + str(self.id))
onready var LocalAnchor: Node2D = Samus.Weapons.CannonPositionAnchor
var Cooldown: Timer = Timer.new()

func set_ammo(value: int):
	if Icon:
		Icon.update_digits(value)
	ammo = value

func _ready():
	
	if has_node("Projectile"):
		ProjectileNode = $Projectile
		remove_child(ProjectileNode)
	elif has_node("Projectiles"):
		ProjectileNode = {}
		for Projectile in $Projectiles.get_children():
			ProjectileNode[Projectile.name] = Projectile
			$Projectiles.remove_child(Projectile)
		$Projectiles.queue_free()
	
	for child in get_children():
		if child is SamusWeaponIcon:
			Icon = child
			self.remove_child(Icon)
			Samus.HUD.add_weapon(Icon)
			Samus.Weapons.update_weapon_icons()
			Icon.update_digits(ammo)
	
	for child in self.get_children():
		if child != Icon and "visible" in child:
			child.visible = false
	
	self.Cooldown.one_shot = true 
	self.add_child(Cooldown)

func projectile_physics_process(_projectile, _collision: KinematicCollision2D, _delta: float):
	pass

func get_fire_object(_pos: Position2D, _chargebeam_damage_multiplier):
	return null

func fired(_projectile):
	pass

func fire(chargebeam_damage_multiplier):
	
	if not Weapons.fire_pos:
		return false
	
	var projectile = get_fire_object(Weapons.fire_pos, chargebeam_damage_multiplier)
	if not projectile:
		return false
	
	if not projectile is Array:
		projectile = [projectile]
	for p in projectile:
		GlobalAnchor.add_child(p)
		fired(p)
	
	Cooldown.start(cooldown)
	
	return true
