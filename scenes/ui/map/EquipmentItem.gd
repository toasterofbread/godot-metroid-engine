extends Control

const data_path = ["samus", "upgrades"]

var sprites: Dictionary

var id: int
var value: bool
var data: Dictionary
var selected = false setget set_selected
var unobtained = false setget set_unobtained
var on_left: bool

func set_selected(value: bool, animate=true, same_group=false):
	selected = value
	
	if value:
		$Background.visible = true
		show_line(animate, same_group)
	else:
		hide_line(animate, same_group)
	$Tween.stop_all()
	$Tween.interpolate_property($Background, "modulate:a", $Background.modulate.a, int(value), 0.1)
	$Tween.start()
	yield($Tween, "tween_completed")
	if not value and $Background.modulate.a == int(value):
		$Background.visible = false

func set_unobtained(value: bool):
	pass

func toggle():
	value = !value
	$TextureRect.texture = sprites[value]
	Loader.Save.set_data_key(["samus", "upgrades", id, "active"], value)

func init(upgrade_id: int, upgrade_data: Dictionary, sprites):
	id = upgrade_id
	data = upgrade_data
	self.sprites = sprites
	
	value = Loader.Save.get_data_key(["samus", "upgrades", id, "active"])
	$Label.text = Data.logbook[Enums.Upgrade.keys()[id]]["name"]
	$TextureRect.texture = sprites[value]
	set_selected(selected)
	
	on_left = get_parent().get_parent().get_parent().name == "Left"
	if on_left:
		$Lines.position = Vector2(199, 7)
		$Lines/Line.points[1].x *= -1
	else:
		$Lines.position = Vector2(-2, 7)
	$Lines/Line.points[2] = $Lines/Line.points[1]
	
	$Lines.visible = false

func set_point_1(position: Vector2):
	$Lines/Line.points[1] = position

func set_point_2(position: Vector2):
	$Lines/Line.points[2] = position

func show_line(animate: bool, same_group: bool):
	if not data:
		return
	
	$Lines.visible = true
#	if animate and false:
##		$Lines/Tween.interpolate_method(self, "set_point_A", Vector2(0, 0), Vector2(50 if on_left else -50, 0), 0.025)
##		$Lines/Tween.start()
##		yield($Lines/Tween, "tween_completed")
##		$Lines/B.points[0] = $Lines/A.points[1]
#		$Lines/Tween.interpolate_method(self, "set_point_2", $Lines/Line.points[1], $Lines.to_local(data["point"].global_position), 0.15)
#		if same_group:
#			$Lines/Point.modulate.a = 1
#		else:
#			$Lines/Tween.interpolate_property($Lines/Point, "modulate:a", 0, 1, 0.2)
#		$Lines/Point.position = $Lines.to_local(data["point"].global_position)
#		$Lines/Point.visible = true
#		$Lines/Tween.start()
##		yield($Lines/Tween, "tween_completed")
##		$Lines/Tween.start()
#	else:
	$Lines/Line.points[1] = Vector2(50 if on_left else -50, 0)
	$Lines/Line.points[2] = $Lines.to_local(data["point"].global_position)
	$Lines/Point.position = $Lines.to_local(data["point"].global_position)
	$Lines/Point.position = $Lines.to_local(data["point"].global_position)
	$Lines/Point.modulate.a = 1
	$Lines/Point.visible = true

func hide_line(animate: bool, same_group: bool):
	if not data:
		return
	
#	if animate and false:
#		if same_group:
#			$Lines/Point.modulate.a = 0
#			$Lines/Point.visible = false
#		else:
#			$Lines/Tween.interpolate_property($Lines/Point, "modulate:a", 1, 0, 0.1)
#		$Lines/Tween.interpolate_method(self, "set_point_2", $Lines/Line.points[2], $Lines/Line.points[1], 0.15)
#		$Lines/Tween.start()
#		yield($Lines/Tween, "tween_completed")
#		$Lines/Point.visible = false
#		yield($Lines/Tween, "tween_completed")
##		$Lines/Tween.interpolate_method(self, "set_point_A", $Lines/A.points[1], Vector2(0, 0), 0.025)
##		$Lines/Tween.start()
##		yield($Lines/Tween, "tween_completed")
	$Lines/Point.visible = false
	$Lines.visible = false

func closed():
	$Lines.visible = false

func opened():
	show_line(false, false)
