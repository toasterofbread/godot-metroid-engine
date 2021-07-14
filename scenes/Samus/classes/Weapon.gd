extends Node2D
class_name SamusWeapon

onready var Samus: KinematicBody2D = Loader.Samus
var Weapons: Node2D

export(Enums.Upgrade) var id: int
export(Enums.DamageType) var damage_type
onready var damage_values: Dictionary = Data.data["damage_values"]["samus"]["weapons"][Enums.Upgrade.keys()[id].to_lower()]
onready var damage_amount: float = damage_values["damage"]
onready var cooldown: float = damage_values["cooldown"]
export var is_morph_weapon: bool
export var is_base_weapon: bool
export var can_charge: bool = true

var ammo: int setget set_ammo
var amount: int

var Icon: SamusHUDIcon
var ProjectileNode
onready var GlobalAnchor: Node2D = Global.get_anchor("Samus/Weapons/" + str(self.id))
var LocalAnchor: Node2D
var Cooldown: Timer = Timer.new()
var index: int

func set_ammo(value: int):
	if Icon:
		Icon.update_digits(value)
	ammo = value

func _save_value_set(path: Array, _value):
	if len(path) != 4 or path[0] != "samus" or path[1] != "upgrades" or not path[2] == self.id:
		return
	set_enabled()

func save_value_set(_path: Array, _value):
	pass

func set_enabled():
	if Samus.is_upgrade_active(self.id):
		Weapons.add_weapon(self)
	else:
		Weapons.remove_weapon(self)

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
		if child is SamusHUDIcon:
			Icon = child
			self.remove_child(Icon)
	
	for child in self.get_children():
		if child != Icon and "visible" in child:
			child.visible = false
	
	self.Cooldown.one_shot = true 
	self.add_child(Cooldown)
	
	Loader.Save.connect("value_set", self, "_save_value_set")
	
	yield(Samus, "ready")
	Weapons = Samus.Weapons
	set_enabled()
	LocalAnchor = Weapons.CannonPositionAnchor
	
	ready()

func ready():
	pass

func projectile_physics_process(_projectile, _colliding_bodies, _delta: float):
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
	
	if not projectile is bool:
		if not projectile is Array:
			projectile = [projectile]
		for p in projectile:
			GlobalAnchor.add_child(p)
			fired(p)
	
	if cooldown > 0:
		Cooldown.start(cooldown)
	
	return true
