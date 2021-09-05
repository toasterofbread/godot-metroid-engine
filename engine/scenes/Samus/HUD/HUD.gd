extends Control

#const etank_row_size = 10
var ETank: Control = preload("res://engine/scenes/Samus/HUD/ETank.tscn").instance()
onready var rows = $CanvasLayer/Control/Control/TopBar/ETanks.get_children()
onready var Modulate: CanvasModulate = $CanvasLayer/CanvasModulate
var current_visor = null

func _ready():
	
	$DeathScreen/AnimationPlayer.play("reset")
	Modulate.color = Color.white
	$CanvasLayer.layer = Enums.CanvasLayers.HUD
	Map.Grid = $CanvasLayer/Control/Control/MapGrid
	rows.invert()
#	$CanvasLayer.scale = Vector2(ProjectSettings.get_setting("display/window/size/height")/288, ProjectSettings.get_setting("display/window/size/height")/288)
	
	set_process(false)
	Notification.set_preset("SamusHUD", false)

func add_weapon(weapon_icon: SamusHUDIcon):
	$CanvasLayer/Control/Control/TopBar/WeaponIcons.add_child(weapon_icon)

func remove_weapon(weapon_icon: SamusHUDIcon):
	if weapon_icon in $CanvasLayer/Control/Control/TopBar/WeaponIcons.get_children():
		$CanvasLayer/Control/Control/TopBar/WeaponIcons.remove_child(weapon_icon)
		return true
	return false

func add_visor(visor_icon: SamusHUDIcon):
	$CanvasLayer/Control/Control/VisorIcons.add_child(visor_icon)

func remove_visor(visor_icon: SamusHUDIcon):
	if visor_icon in $CanvasLayer/Control/Control/VisorIcons.get_children():
		$CanvasLayer/Control/Control/VisorIcons.remove_child(visor_icon)
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
		$CanvasLayer/Control/Control/TopBar/AnimationPlayer.play("energy_low_warning")
	else:
		$CanvasLayer/Control/Control/TopBar/AnimationPlayer.stop()
	
	#warning-ignore:integer_division
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
	$CanvasLayer/Control/Control/TopBar/EnergyDigits/Digit0.frame = int(str_energy[0])
	$CanvasLayer/Control/Control/TopBar/EnergyDigits/Digit1.frame = int(str_energy[1])

func _process(_delta: float):
	if $DeathScreen/Buttons/RespawnButton.just_pressed():
		pass
	elif $DeathScreen/Buttons/HBoxContainer/ExitButton.just_pressed():
		pass

func display_death_screen(_real: bool):
	$DeathScreen/AnimationPlayer.play("open")
	set_process(true)

func death_screen_reload():
	pass
func death_screen_exit():
	pass

func set_visibility(value: bool):
	for child in $CanvasLayer.get_children():
		child.visible = value
	
func _on_Control_resized():
	$CanvasLayer/Control/Control.rect_size = $CanvasLayer/Control.rect_size / $CanvasLayer.scale
