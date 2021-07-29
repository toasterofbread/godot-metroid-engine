extends Control

export var description_label_path: NodePath
onready var description_label: Label = get_node(description_label_path)

export var value_label_path: NodePath
onready var value_label: Label = get_node(value_label_path)

onready var data: Dictionary = Data.data["settings_information"]
onready var ItemContainer: VBoxContainer = $Control/ScrollContainer/ItemContainer

var selected_item: int = 0
onready var MenuItem: PackedScene = preload("res://engine/scenes/ui/settings_menu/SettingsMenuItem.tscn")

var transitioning: bool = false
var current_category = null
var mouse_mode: bool = false

func _ready():
	# DEBUG
	$ValuePanelTemplate.queue_free()

func init(animate: bool):
	
	for menuItem in ItemContainer.get_children():
		menuItem.queue_free()
		yield(menuItem, "tree_exited")
	
	selected_item = 0
	
	var i: int = 0
	for category in data:
		if len(data[category]) == 0:
			continue
		
		var menuItem: Control = MenuItem.instance()
		menuItem.connect("current_set", self, "menu_item_current_set")
		menuItem.init(data, category, null, value_label)
		
		if animate:
			menuItem.visible = false
		
		ItemContainer.add_child(menuItem)
		menuItem.connect("pressed", self, "category_item_selected", [menuItem.get_position_in_parent()])
		if i == selected_item:
			menuItem.set_current(true, false)
			description_label.text = data[category]["description"]
		
		if animate:
			menuItem.slide(true, (i*0.1) + 0.15)
		i += 1

func menu_item_current_set(menuItem: Control, current: bool, set_by_mouse: bool):
	mouse_mode = set_by_mouse
	if menuItem.get_position_in_parent() == selected_item and not current:
		selected_item = -1
	elif current:
		if menuItem.get_position_in_parent() != selected_item:
			if selected_item >= 0:
				ItemContainer.get_child(selected_item).set_current(false, false)
			selected_item = menuItem.get_position_in_parent()
		
		if menuItem.option == null:
			description_label.text = data[menuItem.category]["description"]
		else:
			description_label.text = data[menuItem.category]["options"][menuItem.option]["description"]

# Returns false if exiting
func process(
	delta: float, pad: Vector2, 
	confirm_button_just_pressed: bool, 
	cancel_button_just_pressed: bool,
	save_button_just_pressed: bool,
	reset_button_just_pressed: bool
	):
	
	if transitioning:
		return false
	
	if selected_item >= 0 and not mouse_mode:
		var selected_menuItem: Control = ItemContainer.get_child(selected_item)
		var target_scroll_position: float = selected_menuItem.rect_position.y - (selected_menuItem.rect_size.y * 1.5) - ItemContainer.get("custom_constants/separation")
		$Control/ScrollContainer.scroll_vertical = lerp($Control/ScrollContainer.scroll_vertical, target_scroll_position, delta*10)
	
	if pad.y != 0:
		mouse_mode = false
		if selected_item == -1:
			selected_item = 0
		elif wrapi(selected_item + pad.y, 0, ItemContainer.get_child_count()) != selected_item:
			ItemContainer.get_child(selected_item).set_current(false, false)
			selected_item = wrapi(selected_item + pad.y, 0, ItemContainer.get_child_count())
		ItemContainer.get_child(selected_item).current = true
	
	if current_category != null and selected_item >= 0:
		ItemContainer.get_child(selected_item).option_process(delta, pad, confirm_button_just_pressed)
	
	if confirm_button_just_pressed and current_category == null:
		category_item_selected(selected_item)
	elif cancel_button_just_pressed:
		if current_category == null:
			return true
		else:
			transitioning = true
			current_category = null
			var i: int = -1
			for menuItem in ItemContainer.get_children():
				i += 1
				menuItem.slide(false, i*0.05)
			yield(Global.wait((i*0.05) + 0.2), "completed")
			yield(init(true), "completed")
			transitioning = false
	elif save_button_just_pressed:
		for menuItem in ItemContainer.get_children():
			menuItem.save_value()
		Settings.save_file()
	elif reset_button_just_pressed:
		for menuItem in ItemContainer.get_children():
			menuItem.reset_value()
			menuItem.save_value()
		Settings.save_file()
	
	return false

func category_item_selected(index: int):
	
	if transitioning:
		return
	transitioning = true
	selected_item = 0
	
	current_category = ItemContainer.get_child(index).category
	
	var i: int = -1
	for menuItem in ItemContainer.get_children():
		i += 1
		menuItem.slide(false, i*0.1)
	yield(Global.wait((i*0.1) + 0.2), "completed")
	for menuItem in ItemContainer.get_children():
		menuItem.queue_free()
	
	i = -1
	for option in data[current_category]["options"]:
		i += 1
		var menuItem: Control = MenuItem.instance()
		menuItem.visible = false
		menuItem.connect("current_set", self, "menu_item_current_set")
		menuItem.init(data, current_category, option, value_label)
		ItemContainer.add_child(menuItem)
		if i == selected_item:
			menuItem.set_current(true, false)
		menuItem.slide(true, i*0.1)
	
	yield(Global.wait((i*0.1) + 0.2), "completed")
	transitioning = false
