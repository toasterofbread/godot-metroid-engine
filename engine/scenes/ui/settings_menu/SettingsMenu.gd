extends Control

signal category_mode_changed

const visible_items: int = 4

export var description_label_path: NodePath
onready var description_label: Label = get_node(description_label_path)
export var value_label_path: NodePath
onready var value_label: Label = get_node(value_label_path)

export var top_buttonicon_path: NodePath
onready var top_buttonicon: ButtonIcon = get_node(top_buttonicon_path)
export var bottom_buttonicon_path: NodePath
onready var bottom_buttonicon: ButtonIcon = get_node(bottom_buttonicon_path)

export var confirm_button_path: NodePath
export var cancel_button_path: NodePath
export var save_button_path: NodePath
export var reset_button_path: NodePath
onready var confirm_button: ButtonPrompt = get_node(confirm_button_path)
onready var cancel_button: ButtonPrompt = get_node(cancel_button_path)
onready var save_button: ButtonPrompt = get_node(save_button_path)
onready var reset_button: ButtonPrompt = get_node(reset_button_path)

onready var data: Dictionary = Data.data["settings_information"]
onready var ItemContainer: VBoxContainer = $Control/ScrollContainer/HBoxContainer/ItemContainer

var selected_item: int = 0
onready var MenuItem: PackedScene = preload("res://engine/scenes/ui/settings_menu/SettingsMenuItem.tscn")

var transitioning: bool = false
var current_category = null
var mouse_mode: bool = false

func _ready():
	
	top_buttonicon.visible = false
	top_buttonicon.keyboard_mode_override = false
	bottom_buttonicon.visible = false
	bottom_buttonicon.keyboard_mode_override = true
	value_label.align = Label.ALIGN_CENTER
	
	connect("category_mode_changed", self, "category_mode_changed")
	
	# DEBUG
	$ValuePanelTemplate.queue_free()

func init(animate: bool):
	
	for menuItem in ItemContainer.get_children():
		menuItem.queue_free()
		yield(menuItem, "tree_exited")
	
	selected_item = 0
	current_category = null
	
	var i: int = 0
	for category in data:
		if len(data[category]) == 0:
			continue
		
		var menuItem: Control = MenuItem.instance()
		menuItem.connect("current_set", self, "menu_item_current_set")
		menuItem.init(data, category, null, value_label, top_buttonicon, bottom_buttonicon, $ButtonSelectionPrompt)
		
		if animate:
			menuItem.visible = false
		
		ItemContainer.add_child(menuItem)
		menuItem.connect("pressed", self, "category_item_selected", [menuItem.get_position_in_parent()])
		if i == selected_item:
			menuItem.set_current(true, false)
			description_label.text = data[category]["description"]
		
		if animate:
			menuItem.slide(true, (i*0.1) + 0.05)
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
func process(delta: float, pad: Vector2):
	
	if transitioning or $ButtonSelectionPrompt.visible:
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
		ItemContainer.get_child(selected_item).option_process(delta, pad, confirm_button)
	
	if confirm_button.just_pressed() and current_category == null:
		category_item_selected(selected_item)
	elif cancel_button.just_pressed():
		if current_category == null:
			return true
		else:
			transitioning = true
			emit_signal("category_mode_changed", false)
			current_category = null
			var i: int = -1
			for menuItem in ItemContainer.get_children():
				i += 1
				
				if i < visible_items:
					menuItem.slide(false, i*0.05)
				else:
					menuItem.slide(false, visible_items*0.05)
				
			yield(Global.wait(visible_items*0.05, true), "completed")
			yield(init(true), "completed")
			transitioning = false
	elif current_category != null:
		if save_button.just_pressed():
			if not changes_made():
				Notification.types["text"].instance().init(tr("settings_save_nochanges"), Notification.lengths["short"])
				save_button.cancel_hold()
			else:
				for menuItem in ItemContainer.get_children():
					menuItem.save_value()
				var error: int = Settings.save_file()
				if error != OK:
					Notification.types["text"].instance().init(tr("error_code") + " " + str(error), Notification.lengths["normal"])
				else:
					Notification.types["text"].instance().init(tr("settings_save_successful"), Notification.lengths["short"])
#		elif reset_button.just_pressed():
#			if not changes_made():
#				Notification.types["text"].instance().init(tr("settings_save_nochanges"), Notification.lengths["short"])
#				reset_button.cancel_hold()
		elif reset_button.hold_completed():
#			if not changes_made():
#				Notification.types["text"].instance().init(tr("settings_save_nochanges"), Notification.lengths["short"])
#			else:
			for menuItem in ItemContainer.get_children():
				menuItem.reset_value()
				menuItem.save_value()
			var error: int = Settings.save_file()
			if error != OK:
				Notification.types["text"].instance().init(tr("error_code") + " " + str(error), Notification.lengths["normal"])
			else:
				Notification.types["text"].instance().init(tr("settings_reset_completed"), Notification.lengths["short"])
	
	return false

func changes_made():
	var ret: bool = false
	for menuItem in ItemContainer.get_children():
		if menuItem.changes_made():
			ret = true
			break
	return ret

func category_item_selected(index: int):
	
	if transitioning:
		return
	transitioning = true
	selected_item = 0
	
	current_category = ItemContainer.get_child(index).category
	
	var i: int = -1
	for menuItem in ItemContainer.get_children():
		i += 1
		menuItem.slide(false, i*0.05)
	yield(Global.wait((i*0.05) + 0.05, true), "completed")
	for menuItem in ItemContainer.get_children():
		menuItem.queue_free()
	
	i = -1
	for option in data[current_category]["options"]:
		
		if not can_option_be_displayed(data[current_category]["options"][option]):
			continue
		
		i += 1
		var menuItem: Control = MenuItem.instance()
		menuItem.visible = false
		menuItem.connect("current_set", self, "menu_item_current_set")
		
		menuItem.init(data, current_category, option, value_label, top_buttonicon, bottom_buttonicon, $ButtonSelectionPrompt)
		ItemContainer.add_child(menuItem)
		if i == selected_item:
			menuItem.set_current(true, false)
		
		if i < visible_items:
			menuItem.slide(true, i*0.05)
		else:
			menuItem.slide(true, 4*0.05)
	
	emit_signal("category_mode_changed", true)
	yield(Global.wait(visible_items*0.1, true), "completed")
	transitioning = false


func _on_ButtonSelectionPrompt_status_changed(shown: bool):
	for buttonPrompt in [confirm_button, cancel_button, save_button, reset_button]:
		buttonPrompt.pause_mode = PAUSE_MODE_PROCESS
		buttonPrompt.set_visibility(!shown, true)

func category_mode_changed(category_mode: bool):
	save_button.set_visibility(category_mode, true)
	reset_button.set_visibility(category_mode, true)

func can_option_be_displayed(option_data: Dictionary):
	if "required_settings" in option_data:
		var required_settings: Dictionary = option_data["required_settings"]
		for setting_key in required_settings:
			if str(Settings.get(setting_key)) != str(required_settings[setting_key]):
				return false
	return true
