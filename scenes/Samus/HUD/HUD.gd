extends Control

const etank_row_size = 10
var ETank: Control = preload("res://scenes/Samus/HUD/ETank.tscn").instance()
onready var rows = $CanvasLayer/TopBar/ETanks.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	rows.invert()
	$CanvasLayer.scale = Vector2(ProjectSettings.get_setting("display/window/size/height")/288, ProjectSettings.get_setting("display/window/size/height")/288)

func add_weapon(weapon_icon: SamusWeaponIcon):
	print(weapon_icon)
	$CanvasLayer/TopBar/WeaponIcons.add_child(weapon_icon)

func remove_weapon(weapon_icon: SamusWeaponIcon):
	if weapon_icon in $CanvasLayer/TopBar/WeaponIcons.get_children():
		$CanvasLayer/TopBar/WeaponIcons.remove_child(weapon_icon)

func set_etanks(etanks: int):
	for _i in range(etanks):
		add_etank()

func add_etank():
	for row in rows:
		if len(row.get_children()) < etank_row_size:
			row.add_child(ETank.duplicate())
			return

func set_energy(energy):
	
	var etanks = int(energy / 100)
	for row in rows:
		for etank in row.get_children():
			etank.get_child(0).frame = 1 if etanks > 0 else 0
			etanks -= 1
	
	energy = str(energy)
	if len(energy) == 1:
		energy = "0" + energy
	$CanvasLayer/TopBar/EnergyDigits/Digit0.frame = int(energy[0])
	$CanvasLayer/TopBar/EnergyDigits/Digit1.frame = int(energy[1])
