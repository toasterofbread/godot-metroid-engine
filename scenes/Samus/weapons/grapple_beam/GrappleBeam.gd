extends Node2D

onready var Samus: KinematicBody2D = Loader.Samus

const id: int = Enums.Upgrade.GRAPPLEBEAM
const damage_type: int = Enums.DamageType.BEAM
const cooldown: float = 0.01
export var damage_amount: float
export var is_morph_weapon: bool
export var is_base_weapon: bool

const unlimited_ammo = true
var amount = 0

onready var Projectile = preload("res://scenes/Samus/weapons/grapple_beam/Projectile.tscn")
var Icon: SamusWeaponIcon
var Cooldown: Timer = Timer.new()

func _ready():
	
	for child in self.get_children():
		if child is SamusWeaponIcon:
			self.Icon = child
			self.remove_child(self.Icon)
			Samus.HUD.add_weapon(self.Icon)
			Samus.Weapons.update_weapon_icons()
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
		return null
	pos = pos.duplicate()
	
	if Samus.facing == Enums.dir.RIGHT:
		pos.position.x  = pos.position.x * -1 + 8
	
	# For some reason the default global_position is the same as the relative position
	pos.global_position = Samus.global_position + pos.position
	
	if Samus.facing == Enums.dir.RIGHT:
		pos.rotation = (Vector2(-1, 0).rotated(pos.rotation) * Vector2(-1, 1)).angle()
	
	return pos

func fire():
	if Cooldown.time_left > 0:
		return
	
	var pos = get_fire_pos()
	if pos == null:
		return
	
	var projectile = Projectile.instance()
	
	self.add_child(projectile)
	projectile.visible = true
	
	projectile.global_position = pos.position
	projectile.rotation = pos.rotation
	
	Cooldown.start(cooldown)

func attach(anchor: Node2D, beam):
	Samus.current_state.change_state("grapple", {"anchor": anchor, "beam": beam})
