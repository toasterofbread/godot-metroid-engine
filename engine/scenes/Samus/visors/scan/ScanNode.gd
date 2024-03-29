extends Node2D
class_name ScanNode

const scan_end_value: float = 0.619

enum LENGTH {long, normal, short}
const length_durations = {
	LENGTH.long: 5.0,
	LENGTH.normal: 2.5,
	LENGTH.short: 1.0
}
var length = LENGTH.normal
var scan_duration: float

export var data_key: String setget set_data_key
export(Array, NodePath) var material_nodes: Array = []
export var hidden: bool = false

onready var scan_material: Material = material.duplicate()
onready var scan_beam_size: float = scan_material.get("shader_param/dissolve_beam_size")

var scanned: bool = false
func set_data_key(value: String):
#	if not Loader.is_a_parent_of(self):
#		return
	if Loader.loaded_save == null:
		yield(Loader, "save_loaded")
	data_key = value
	scanned = data_key in Loader.loaded_save.get_data_key(["logbook", "recorded_entries"])

#func get_global_position():
#	return $CollisionShape2D.global_position

func _ready():
	if Loader.loaded_save == null:
		yield(Loader, "save_loaded")
	
	Enums.add_node_to_group(self, Enums.Groups.SCANNODE)
	Loader.loaded_save.connect("value_set", self, "save_value_set")
	
	yield(get_parent(), "ready")
	if not Loader.Samus.is_inside_tree():
		yield(Loader.Samus, "ready")
		yield(Loader.Samus.Weapons.all_visors[Enums.Upgrade.SCANVISOR], "ready")
	scan_duration = length_durations[length]
	
	material = null
	for path in material_nodes:
		var node: CanvasItem = get_node(path)
		node.use_parent_material = false
		node.material = scan_material
	
	# DEBUG
	$TestSprite.queue_free()

func save_value_set(path: Array, value):
	if path == ["logbook", "recorded_entries"]:
		scanned = data_key in value
		if scanned:
			end_scan()

func scanned():
	scanned = true
	var data = Loader.loaded_save.get_data_key(["logbook", "recorded_entries"])
	data.append(data_key)
	Loader.loaded_save.set_data_key(["logbook", "recorded_entries"], data)

func start_scan():
	set_scan_beam(true, false)
	scan_material.set("shader_param/dissolve_enabled", true)
	$Tween.interpolate_property(scan_material, "shader_param/dissolve_progress", 0.0, scan_end_value, scan_duration)
	$Tween.start()
	yield($Tween, "tween_completed")# != [scan_material, "shader_param/dissolve_progress"]
	if scan_material.get("shader_param/dissolve_progress") != scan_end_value:
		return false
	
	scan_material.set("shader_param/dissolve_enabled", false)
	scan_material.set("shader_param/dissolve_value", 0)
	
	return true

func end_scan():
	$Tween.stop_all()
	yield(set_scan_beam(false, true), "completed")

func set_scan_beam(on: bool, animate: bool):
	var size: float = scan_beam_size if on else 0.0
	if animate:
		$Tween.interpolate_property(scan_material, "shader_param/dissolve_beam_size", scan_material.get("shader_param/dissolve_beam_size"), size, 0.1)
		$Tween.start()
		return yield($Tween, "tween_completed") == [scan_material, "shader_param/dissolve_beam_size"] and scan_material.get("shader_param/dissolve_beam_size") == size
	else:
		scan_material.set("shader_param/dissolve_beam_size", size)

func get_length():
	return scan_duration

func can_be_scanned():
	return not scanned and $VisibilityNotifier2D.is_on_screen() and not hidden
