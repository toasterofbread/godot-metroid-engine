tool
extends EditorPlugin

var menu: Control
var current_editor_main_screen: String

func _enter_tree():
	menu = preload("room_loader.tscn").instance()
	menu.init(self)
	add_control_to_container(CONTAINER_TOOLBAR, menu)
	menu.get_parent().move_child(menu, menu.get_position_in_parent() - 1)
	
	connect("main_screen_changed", self, "editor_main_screen_changed")
	
	var children: Array = menu.get_parent().get_children()
	
	# Remove "Play Custom Scene" button
	if children[4].get_child_count() != 6:
		return
	for i in children[4].get_child_count():
		if not children[4].get_child(i).get_class() == ["ToolButton", "ToolButton", "ToolButton", "EditorRunNative", "ToolButton", "ToolButton"][i]:
			return
	children[4].get_children()[5].visible = false
	
	# Remove renderer selection menu
	if children[5].get_child_count() != 2:
		return
	for i in children[5].get_child_count():
		if not children[5].get_child(i).get_class() == ["OptionButton", "MenuButton"][i]:
			return
	children[5].visible = false

#	print(get_editor_interface().get_base_control().theme.get_icon_list("EditorIcons"))

func _exit_tree():
	if menu:
		remove_control_from_container(CONTAINER_TOOLBAR, menu)
		menu.queue_free()

func get_icon(name: String, node_type: String) -> Texture:
	return get_editor_interface().get_base_control().get_icon(name, node_type)

func load_json(path: String):
	var f = File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data).result

func iterate_directory(dir: Directory) -> Array:
	var ret = []
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		ret.append(file_name)
		file_name = dir.get_next()
	return ret

func editor_main_screen_changed(screen_name: String):
	current_editor_main_screen = screen_name
