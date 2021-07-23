extends Node2D
class_name SamusVisor

onready var Samus: KinematicBody2D = Loader.Samus
onready var Weapons: Node2D = Samus.Weapons

export var background_tint: Color = Color("a6000000")
export(Enums.Upgrade) var id: int = Enums.Upgrade.SCANVISOR

var Icon: SamusHUDIcon
var Light: Node2D

onready var visor_state: Node = Samus.states["visor"]
var lock_target = null

func _process(delta: float):
	if Weapons.current_visor == self:
		Icon.frame = 2 if visor_state.enabled else 1

func visor_mode_changed(visor: SamusVisor):
	if visor == self:
		Icon.frame = 2 if Samus.current_state.id == "visor" else 1
	else:
		Icon.frame = 0

func _ready():
	assert(id in Enums.UpgradeTypes["visor"], "Must be a valid visor ID")
	Loader.Save.connect("value_set", self, "save_value_set")
	
	for child in get_children():
		if child is SamusHUDIcon:
			Icon = child
			remove_child(child)
		elif child.name == "Light":
			Light = child
			child.visible = false
			remove_child(child)
			print(1)
#			yield(visor_state, "ready")
			print(2)
			visor_state.scanner.get_node("Lights").add_child(child)
			child.name = str(id)
			for node in child.get_children():
				if node is Light2D:
					node.range_layer_max = Enums.CanvasLayers.HUD - 1
			
	set_enabled()
	Weapons.connect("visor_mode_changed", self, "visor_mode_changed")

func save_value_set(path: Array, _value):
	if len(path) != 4 or path[0] != "samus" or path[1] != "upgrades" or not path[2] == self.id:
		return
	set_enabled()

func set_enabled():
	if Samus.is_upgrade_active(id):
		Weapons.add_visor(self)
	else:
		Weapons.remove_visor(self)

func _on_Area2D_area_entered(_area):
	pass

func _on_Area2D_area_exited(_area):
	pass

func enabled():
	pass

func disabled():
	pass
