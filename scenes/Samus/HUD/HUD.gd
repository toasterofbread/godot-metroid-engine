extends Control

#const etank_row_size = 10
var ETank: Control = preload("res://scenes/Samus/HUD/ETank.tscn").instance()
onready var rows = $CanvasLayer/TopBar/ETanks.get_children()
onready var Modulate: CanvasModulate = $CanvasLayer/CanvasModulate

var current_visor = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$DeathScreen/AnimationPlayer.play("reset")
	Modulate.color = Color.white
	$CanvasLayer.layer = Enums.CanvasLayers.HUD
	Map.Grid = $CanvasLayer/MapGrid
	rows.invert()
	$CanvasLayer.scale = Vector2(ProjectSettings.get_setting("display/window/size/height")/288, ProjectSettings.get_setting("display/window/size/height")/288)

func add_weapon(weapon_icon: SamusHUDIcon):
	$CanvasLayer/TopBar/WeaponIcons.add_child(weapon_icon)

func remove_weapon(weapon_icon: SamusHUDIcon):
	if weapon_icon in $CanvasLayer/TopBar/WeaponIcons.get_children():
		$CanvasLayer/TopBar/WeaponIcons.remove_child(weapon_icon)
		return true
	return false

func add_visor(visor_icon: SamusHUDIcon):
	$CanvasLayer/VisorIcons.add_child(visor_icon)

func remove_visor(visor_icon: SamusHUDIcon):
	if visor_icon in $CanvasLayer/VisorIcons.get_children():
		$CanvasLayer/VisorIcons.remove_child(visor_icon)
		return true
	return false

func set_etanks(etanks: int):
	for _i in range(etanks):
		add_etank()

func add_etank():
	if rows[0].get_child_count() > rows[1].get_child_count():
		rows[1].add_child(ETank.duplicate())
	else:
		rows[0].add_child(ETank.duplicate())

func set_energy(energy: int):
	
	if energy <= 30:
		$CanvasLayer/TopBar/AnimationPlayer.play("energy_low_warning")
	else:
		$CanvasLayer/TopBar/AnimationPlayer.stop()
	
	var etanks = int(energy / 100)
	for row in rows:
		for etank in row.get_children():
			etank.get_child(0).frame = 1 if etanks > 0 else 0
			etanks -= 1
	
	var str_energy: String = str(energy)
	if len(str_energy) == 1:
		str_energy = "0" + str_energy
	elif len(str_energy) > 2:
		str_energy = str_energy[len(str_energy) - 2] + str_energy[len(str_energy) - 1]
	$CanvasLayer/TopBar/EnergyDigits/Digit0.frame = int(str_energy[0])
	$CanvasLayer/TopBar/EnergyDigits/Digit1.frame = int(str_energy[1])

func display_death_screen(real: bool):
	$DeathScreen/AnimationPlayer.play("open")
