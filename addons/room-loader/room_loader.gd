tool
extends HBoxContainer

const engine_config_dir: String = "res://engine_config.json"
var rooms: Array = []

var plugin: EditorPlugin
var recent_room = null

func init(_plugin: EditorPlugin):
	plugin = _plugin
	plugin.get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "_on_filesystem_changed")

func _ready():
	$LoadRecentButton.icon = plugin.get_icon("Navigation2D", "EditorIcons")
	$SelectRoomButton.icon = plugin.get_icon("Folder", "EditorIcons")

func _on_filesystem_changed():
	reload_rooms()

func reload_rooms():
	print(plugin)
	if not is_instance_valid(plugin):
		return
	
	$RoomSelectionMenu.clear()
	rooms.clear()
	
	var areas: Dictionary = {}
	var dir: Directory = Directory.new()
	
	var room_directories: Array = plugin.load_json(engine_config_dir)["room_directories"]
	for dir_path in room_directories:
		dir.open(dir_path)
		
		for area in plugin.iterate_directory(dir):
			var area_submenu: PopupMenu
			if area in areas:
				area_submenu = areas[area]
			else:
				area_submenu = PopupMenu.new()
				areas[area] = area_submenu
				area_submenu.name = area
				$RoomSelectionMenu.add_child(area_submenu)
				$RoomSelectionMenu.add_submenu_item(area.capitalize(), area)
			
			dir.open(dir_path.plus_file(area))
			for room in plugin.iterate_directory(dir):
				if not dir.file_exists(room.plus_file("room.tscn")):
					continue
				
				area_submenu.add_item(room.capitalize(), len(rooms))
				rooms.append(dir_path.plus_file(area).plus_file(room).plus_file("room.tscn"))
				print(rooms)
	
	$RoomSelectionMenu.add_separator()
	$RoomSelectionMenu.add_item("Cancel", len(rooms))

func _on_LoadRecentButton_pressed():
	if not recent_room:
		var prompt_result = yield(get_room_from_user(), "completed")
		if prompt_result == null:
			return
		recent_room = prompt_result
		
	# Ensure that main screen remains the same
	var main_screen: String = plugin.current_editor_main_screen
	
	plugin.get_editor_interface().open_scene_from_path(recent_room)
	plugin.get_editor_interface().play_current_scene()
	yield(get_tree(), "idle_frame")
	plugin.get_editor_interface().set_main_screen_editor(main_screen)

func _on_SelectRoomButton_pressed():
	var prompt_result = yield(get_room_from_user(), "completed")
	if prompt_result == null:
		return
	recent_room = prompt_result
	plugin.get_editor_interface().open_scene_from_path(recent_room)

func get_room_from_user():
	$RoomSelectionMenu.popup_centered()
	var id: int = yield($RoomSelectionMenu, "submenu_id_pressed")[0]
	
	# User pressed cancel
	if id == len(rooms):
		return null
	else:
		# Return room filepath
		return rooms[id]
