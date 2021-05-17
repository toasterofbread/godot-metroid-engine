extends Node2D

var data: Dictionary
const data_path = "res://scenes/ui/settings/settings_information.json"

var index = 0
onready var option_node = preload("res://scenes/ui/settings/option_types/Option.tscn")

func _ready():
	data = Global.load_json(data_path)
	$Description.visible = false

func load_category(category: String):
	for node in $Categories.get_children():
		node.queue_free()
	while $Categories.get_child_count() > 0:
		yield(Global, "process_frame")
	
	var options = data[category]["options"]
	
	var max_label_width = 0
	for option in options:
		var type: int
		var node: HBoxContainer
		
		node = option_node.instance()
		if node.init(data, [category, option]) == false:
			node.queue_free()
			continue
		
		$Categories.add_child(node)
		max_label_width = max(max_label_width, node.get_node("Value").rect_size.x + node.get_node("Title").rect_size.x)
	
	for option in options:
		if len(data[category]) == 0:
			continue
		if $Categories.get_node_or_null(option) != null:
			$Categories.get_node(option).get_node("Title/Background").rect_size.x += max_label_width
	
	
	for i in range($Categories.get_child_count()):
		update_index(-1, i)

func update_index(index: int, previous_index: int = -1):
	
	if index >= 0:
		var current_node = $Categories.get_children()[index].get_node("Title/Background")
		$Tween.interpolate_property(current_node, "rect_position:x", current_node.rect_position.x, -192, 0.1)
#		current_node = $Categories.get_children()[index].get_node("Value")
#		$Tween.interpolate_property(current_node, "percent_visible", current_node.percent_visible, 1, 0.15)
		$Description.text = $Categories.get_children()[index].option_data["description"]
#		if not $Description.visible:
#			$Tween.interpolate_property($Description, "percent_visible", 0, 1, 0.2)
#			$Description.visible = true
	if previous_index >= 0:
		var previous_node = $Categories.get_children()[previous_index].get_node("Title/Background")
		$Tween.interpolate_property(previous_node, "rect_position:x", previous_node.rect_position.x, -1500, 0.1)
#		previous_node = $Categories.get_children()[previous_index].get_node("Value")
#		$Tween.interpolate_property(previous_node, "percent_visible", previous_node.percent_visible, 0, 0.05)
	
	$Tween.start()

func start():
	update_index(0, -1)

func end():
	update_index(-1, index)
	index = 0
	$Tween.interpolate_property(self, "modulate:a", 1, 0, 0.25)
	$Tween.start()
	yield(Global.wait(0.26, true), "completed")
	visible = false
	modulate.a = 1

func save():
	for node in $Categories.get_children():
		node.save_value()
	Settings.save_file()

func reset():
	for node in $Categories.get_children():
		node.reset()

func process():
	
	var pad_vector = Shortcut.get_pad_vector("just_pressed").y
	
	var previous_index = index
	if pad_vector != 0 and $Categories.get_child_count() > 1:
		index += pad_vector
		if index >= $Categories.get_child_count():
			index = 0
		elif index < 0:
			index = $Categories.get_child_count() - 1
		update_index(index, previous_index)
	$Categories.get_children()[index].process()
	
