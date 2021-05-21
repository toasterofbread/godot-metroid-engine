extends Node2D

var data: Dictionary
const data_path = "res://scenes/ui/settings/settings_information.json"

var index = 0

func _ready():
	
	for node in $Categories.get_children():
		node.queue_free()
	data = Global.load_json(data_path)
	
	var max_label_width = 0
	for category in data:
		if len(data[category]) == 0:
			continue
		
		var node = $Template.duplicate()
		node.get_node("Title").text = category.capitalize()
		node.get_node("Description").text = " - " + data[category]["description"]
		node.name = category
		$Categories.add_child(node)
		node.visible = true
		max_label_width = max(max_label_width, node.get_node("Description").rect_size.x)
	
	for category in data:
		if len(data[category]) == 0:
			continue
		$Categories.get_node(category).get_node("Title/Background").rect_size.x += max_label_width
	
	for i in range($Categories.get_child_count()):
		update_index(-1, i)

func update_index(index: int, previous_index: int = -1):
	
	if index >= 0:
		var current_node: Control = $Categories.get_children()[index].get_node("Description")
		$Tween.interpolate_property(current_node, "percent_visible", current_node.percent_visible, 1, 0.15)
		current_node = $Categories.get_children()[index].get_node("Title/Background")
		$Tween.interpolate_property(current_node, "rect_position:x", current_node.rect_position.x, -176, 0.1)
	if previous_index >= 0:
		var previous_node: Control = $Categories.get_children()[previous_index].get_node("Description")
		$Tween.interpolate_property(previous_node, "percent_visible", previous_node.percent_visible, 0, 0.05)
		previous_node = $Categories.get_children()[previous_index].get_node("Title/Background")
		$Tween.interpolate_property(previous_node, "rect_position:x", previous_node.rect_position.x, -1000, 0.1)
	
	$Tween.start()

func start():
	update_index(0, -1)

func end():
	update_index(-1, index)
	index = 0

func current_category():
	return $Categories.get_children()[index].name

func process():
	
	var pad_vector = Shortcut.get_pad_vector("just_pressed").y
	
	var previous_index = index
	if pad_vector != 0:
		index += pad_vector
		if index >= $Categories.get_child_count():
			index = 0
		elif index < 0:
			index = $Categories.get_child_count() - 1
		update_index(index, previous_index)
	
