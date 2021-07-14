tool
extends Node2D
class_name ScanNode

enum LENGTH {long, normal, short}
const length_durations = {
	LENGTH.long: 5.0,
	LENGTH.normal: 2.5,
	LENGTH.short: 1.0
}

var scan_duration: float
export(LENGTH) var length = LENGTH.normal
#export var major_scan: bool = false setget set_major
export var data_key: String
export var dynamic_data_key: = false

var enabled = true setget set_enabled

func set_enabled(value: bool):
	if value == enabled or Engine.editor_hint:
		return
	if data_key in Loader.Save.get_data_key(["logbook", "recorded_entries"]):
		value = false
	enabled = value
	visible = value

func get_global_position():
	return $CollisionShape2D.global_position

#func set_major(value: bool):
#	$AnimatedSprite.modulate = Color("ff4200") if value else Color.white
#	major_scan = value

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.editor_hint:
		return
	
#	if not get_parent().is_inside_tree():
	yield(get_parent(), "ready")
	if not Loader.Samus.is_inside_tree():
		yield(Loader.Samus, "ready")
		yield(Loader.Samus.Weapons.all_visors[Enums.Upgrade.SCANVISOR], "ready")
	assert(data_key in Data.data["logbook"])
	scan_duration = length_durations[length]
	set_enabled(not data_key in Loader.Save.get_data_key(["logbook", "recorded_entries"]))
	
	var extents = $CollisionShape2D.shape.extents
	$CollisionShape2D/ScanCursor.rect_size.y = extents.x*2
	$CollisionShape2D/ScanCursor.rect_position = -extents
	
	$CollisionShape2D/ScanCursor.modulate.a = 0
	$CollisionShape2D/ScanCursor.visible = false

func save():
	var data = Loader.Save.get_data_key(["logbook", "recorded_entries"])
	data.append(data_key)
	Loader.Save.set_data_key(["logbook", "recorded_entries"], data)

func start_scan():
	$CollisionShape2D/Tween.stop_all()
	$CollisionShape2D/ScanCursor.rect_position = -$CollisionShape2D.shape.extents
	$CollisionShape2D/ScanCursor.visible = true
	$CollisionShape2D/Tween.interpolate_property($CollisionShape2D/ScanCursor, "modulate:a", 0, 1, 0.1)
	$CollisionShape2D/Tween.interpolate_property($CollisionShape2D/ScanCursor, "rect_position:y", $CollisionShape2D/ScanCursor.rect_position.y, $CollisionShape2D.shape.extents.y-1, scan_duration)
	$CollisionShape2D/Tween.start()
#	yield($CollisionShape2D/Tween, "tween_completed")
#	yield($CollisionShape2D/Tween, "tween_completed")
	
#	$CollisionShape2D/Tween.interpolate_property($CollisionShape2D/ScanCursor, "modulate:a", 1, 0, 0.1)
#	$CollisionShape2D/Tween.start()
#	yield($CollisionShape2D/Tween, "tween_completed")
#	$CollisionShape2D/ScanCursor.visible = false

func end_scan():
	$CollisionShape2D/Tween.stop_all()
	$CollisionShape2D/Tween.interpolate_property($CollisionShape2D/ScanCursor, "modulate:a", $CollisionShape2D/ScanCursor.modulate.a, 0, 0.1)
	$CollisionShape2D/Tween.start()
	yield($CollisionShape2D/Tween, "tween_completed")
	$CollisionShape2D/ScanCursor.visible = false

#func lock():
#	$Tween.stop_all()
#	locked = true
#	self.visible = true
#	$ModulateTween.interpolate_property(self, "modulate:a", 0, 1, 0.15)
#	$ModulateTween.start()
##	yield($ModulateTween, "tween_completed")
#	$Tween.interpolate_property($OuterRing, "scale", Vector2(2.0, 2.0), Vector2(1.25, 1.25), 0.25)
#	$Tween.interpolate_property($InnerRing, "scale", Vector2(2.5, 2.5), Vector2(1, 1), 0.25)
#	$Tween.start()
##	yield($Tween, "tween_completed")
#
#func unlock():
#	locked = false
#	$Tween.interpolate_property($OuterRing, "scale", Vector2(1.25, 1.25), Vector2(2.0, 2.0), 0.25)
#	$Tween.interpolate_property($InnerRing, "scale", Vector2(1, 1), Vector2(2.5, 2.5), 0.25)
#	$Tween.start()
#	$ModulateTween.interpolate_property(self, "modulate:a", 1, 0, 0.25)
#	$ModulateTween.start()
#	yield($ModulateTween, "tween_completed")
#	if not locked:
#		self.visible = false
