extends Control

signal map_reveal_completed
signal menu_closed

onready var Samus: KinematicBody2D = Loader.Samus

const menu_open_duration: float = 0.45
const map_move_speed: float = 100.0
const map_move_acceleration: float = 750.0
const map_zoom_speed: float = 0.75
var map_grid_parent: Node
var mapGrid: Control

var map_move_velocity: Vector2 = Vector2.ZERO
var transitioning: bool = false

onready var Buttons: Node2D = $CanvasLayer2/ButtonPrompts
enum MODES {CLOSED, MAP, MAPMARKER, SETTINGS, SETTINGSOPTION, EQUIPMENT, LOGBOOK, MAPREVEAL}
var mode: int = MODES.CLOSED

func _ready():
	
#	$CanvasLayer/MapGridPosition.visible = false
	$CanvasLayer/MapGridContainer/ColorRect.queue_free()
	
	# Why on earth did I think this was a good idea
#	for animation_name in $AnimationPlayer.get_animation_list():
#		var animation = $AnimationPlayer.get_animation(animation_name)
#		for track in animation.get_track_count():
#			animation.track_set_path(track, str(animation.track_get_path(track)).replace("CanvasLayer/MapGridPosition", "CanvasLayer/MapGrid"))
	
	$CanvasLayer.layer = Enums.CanvasLayers.MENU
	$CanvasLayer2.layer = Enums.CanvasLayers.MENU
	
	$AnimationPlayer.play("reset")

func pause():
	
	if transitioning:
		return
	
	get_tree().paused = true
	Samus.paused = true
	transitioning = true
	
	if not mapGrid:
		mapGrid = Map.Grid
		map_grid_parent = mapGrid.get_parent()
	
	yield(mapGrid.fade(false, 0.1), "completed")
	
#	mapGrid.visible = false
	Global.reparent_child(mapGrid, $CanvasLayer/MapGridContainer)
	mapGrid.map_offset_offset = Vector2(0, 0) + mapGrid.rect_position
	mapGrid.rect_position = Vector2.ZERO
	mapGrid.map_size = $CanvasLayer/MapGridContainer.rect_size
	mapGrid.map_offset_offset = Vector2(4, -2)
	mapGrid.modulate.a = 1
	if Map.current_chunk != null:
		mapGrid.set_focus_position(Map.current_chunk.tile.position, true)
#	$AnimationPlayer.clear_caches()
	$AnimationPlayer.play("open_menu")
	yield($AnimationPlayer, "animation_finished")
	
	transitioning = false
	mode = MODES.MAP

func resume():
	
	if transitioning:
		return
	
#	transitioning = true
	$AnimationPlayer.play("close_menu" if mode == MODES.MAP else "fade_out")
	yield($AnimationPlayer, "animation_finished")
	
	get_tree().paused = false
	Samus.paused = false
	mode = MODES.CLOSED
	emit_signal("menu_closed")
	
	$AnimationPlayer.play("reset")
	Map.Marker.moving = false
	Map.Marker.editable_name = false
	Shortcut.text_input_active = false
	yield($AnimationPlayer, "animation_finished")
	mapGrid.reset_minimap_properties()
#	transitioning = false

func reset_minimap():
	mapGrid.modulate.a = 0
	Global.reparent_child(mapGrid, map_grid_parent)
	mapGrid.reset_minimap_properties()
	if Map.current_chunk != null:
		mapGrid.set_focus_position(Map.current_chunk.tile.position, true)
	mapGrid.fade(true, 0.25)

func _process(delta: float):
	
	if transitioning:
		mapGrid.update_minimap()
		return
	elif mode == MODES.CLOSED or mode == MODES.MAPREVEAL:
		return
	
	var resuming: bool = Buttons.get_node("LeftBoxContainer/CloseMenu").just_pressed() or (mode == MODES.MAP and Input.is_action_just_pressed("ui_cancel"))
	
	if mode == MODES.MAP:
		if Buttons.get_node("MarkerContainer/Main").just_pressed():
#			if Buttons.get_node("Marker").expand_to_point(1):
			mode = MODES.MAPMARKER
			for button in Buttons.get_node("MarkerContainer").get_children():
				if button is ButtonPrompt:
					button.set_visibility(true, true)
			Buttons.get_node("MarkerContainer/Main").set_text("pausemenu_button_place_marker", false)
			Buttons.get_node("MarkerContainer/Rename").set_text("pausemenu_button_rename_marker", false)
			
			Buttons.get_node("RightBoxContainer/Settings").set_visibility(false, true)
			Buttons.get_node("RightBoxContainer/Equipment").set_visibility(false, true)
			
			process_marker(true, resuming)
			return
			
		elif Buttons.get_node("RightBoxContainer/Settings").just_pressed() and $AnimationPlayer.current_animation == "":
			$AnimationPlayer.play("open_settings")
			Buttons.get_node("RightBoxContainer/Settings").set_text("settings_button_save", true)
			Buttons.get_node("RightBoxContainer/Settings").set_visibility(false, true)
			Buttons.get_node("RightBoxContainer/Equipment").set_text("settings_button_reset", true)
			Buttons.get_node("RightBoxContainer/Equipment").set_hold_time(ButtonPrompt.HOLD_TIMES.MEDIUM)
			Buttons.get_node("RightBoxContainer/Equipment").set_visibility(false, true)
			Buttons.get_node("LeftBoxContainer/Accept").set_visibility(true, true)
			Buttons.get_node("LeftBoxContainer/Cancel").set_visibility(true, true)
			$CanvasLayer2/Settings/SettingsMenu.init(false)
			yield($AnimationPlayer, "animation_finished")
			mode = MODES.SETTINGS
		elif Buttons.get_node("RightBoxContainer/Equipment").just_pressed() and $AnimationPlayer.current_animation == "":
			$AnimationPlayer.play("open_equipment")
			Buttons.get_node("RightBoxContainer/Equipment").set_text("pausemenu_button_logbook", false)
			Buttons.get_node("RightBoxContainer/Settings").set_visibility(false, true)
			Buttons.get_node("LeftBoxContainer/Accept").set_visibility(true, true)
			Buttons.get_node("LeftBoxContainer/Cancel").set_visibility(true, true)
			mode = MODES.EQUIPMENT
		else:
			var update: bool = false
			var pad_vector: Vector2 = -Shortcut.get_pad_vector("pressed")
			map_move_velocity.x = move_toward(map_move_velocity.x, map_move_speed*pad_vector.x, map_move_acceleration*delta)
			map_move_velocity.y = move_toward(map_move_velocity.y, map_move_speed*pad_vector.y, map_move_acceleration*delta)
			if map_move_velocity != Vector2.ZERO:
				mapGrid.Tiles.position += map_move_velocity * delta
				update = true
			
			
			if Buttons.get_node("ZoomContainer/ZoomIn").pressed():
				mapGrid.map_scale += Vector2.ONE*map_zoom_speed*delta
				update = true
			elif Buttons.get_node("ZoomContainer/ZoomOut").pressed():
				mapGrid.map_scale -= Vector2.ONE*map_zoom_speed*delta
				update = true
			
			if update:
				mapGrid.update_minimap()
	else:
		match mode:
			MODES.MAPMARKER: process_marker(false, resuming)
			MODES.SETTINGS: process_settings(resuming, delta)
#			MODES.SETTINGSOPTION: process_settings_option(resuming)
			MODES.EQUIPMENT: process_equipment(resuming)
			MODES.LOGBOOK: process_logbook(resuming)
	
	if resuming:
		resume()

func process_logbook(last_frame: bool):
	
	if Buttons.get_node("LeftBoxContainer/Cancel").just_pressed():
		$AnimationPlayer.play("close_logbook")
		Buttons.get_node("LeftBoxContainer/Accept").set_visibility(false, true)
		Buttons.get_node("LeftBoxContainer/Cancel").set_visibility(false, true)
		Buttons.get_node("RightBoxContainer/Settings").set_visibility(true, true)
		Buttons.get_node("RightBoxContainer/Equipment").set_text("pausemenu_button_equipmentlogbook", false)
		mode = MODES.MAP
	elif Buttons.get_node("RightBoxContainer/Equipment").just_pressed():
		$AnimationPlayer.play("logbook_to_equipment")
		mode = MODES.EQUIPMENT
	else:
		$CanvasLayer2/LogbookScreen.process()

func process_equipment(last_frame: bool):
	
	if Buttons.get_node("LeftBoxContainer/Cancel").just_pressed():
		$AnimationPlayer.play("close_equipment")
		Buttons.get_node("RightBoxContainer/Equipment").set_text("pausemenu_button_equipmentlogbook", false)
		Buttons.get_node("RightBoxContainer/Settings").set_visibility(true, true)
		Buttons.get_node("LeftBoxContainer/Accept").set_visibility(false, true)
		Buttons.get_node("LeftBoxContainer/Cancel").set_visibility(false, true)
		mode = MODES.MAP
	elif Buttons.get_node("RightBoxContainer/Equipment").just_pressed():
		$AnimationPlayer.play("equipment_to_logbook")
		mode = MODES.LOGBOOK
	else:
		$CanvasLayer2/EquipmentScreen.process()

func process_marker(first_frame: bool, last_frame: bool):
	
	if first_frame:
		if not Map.Marker.grid_position:
			Map.Marker.grid_position = Map.current_chunk.tile.position/8
		Map.Marker.moving = true
		return
	
	if Map.Marker.moving:
		Map.Marker.grid_position += Shortcut.get_pad_vector("just_pressed")
		mapGrid.set_focus_position(Map.Marker.position, false)
	
#	if Buttons.get_node("Marker").transitioning:
#		return
	
	if Buttons.get_node("MarkerContainer/Main").just_pressed():
		mode = MODES.MAP
	elif Buttons.get_node("MarkerContainer/Delete").just_pressed():
		Map.Marker.grid_position = null
		mode = MODES.MAP
	elif Buttons.get_node("MarkerContainer/Rename").just_pressed():
		Map.Marker.editable_name = !Map.Marker.editable_name
		if Map.Marker.editable_name:
			Buttons.get_node("MarkerContainer/Rename").set_text("pausemenu_button_confirm_rename_marker", true)
		else:
			Buttons.get_node("MarkerContainer/Rename").set_text("pausemenu_button_rename_marker", true)
		Map.Marker.moving = !Map.Marker.editable_name
		Shortcut.text_input_active = Map.Marker.editable_name
	
	if mode != MODES.MAPMARKER or last_frame:
		
		Map.Marker.moving = false
		Map.Marker.editable_name = false
		Map.Marker.save_data()
		Map.Marker.load_data()
		
#		Buttons.get_node("Marker").expand_to_point(0)
		Buttons.get_node("MarkerContainer/Main").set_text("pausemenu_button_edit_marker", true)
		
		Buttons.get_node("RightBoxContainer/Settings").set_visibility(true, true)
		Buttons.get_node("RightBoxContainer/Equipment").set_visibility(true, true)
		
		Buttons.get_node("MarkerContainer/Delete").set_visibility(false, true)
		Buttons.get_node("MarkerContainer/Rename").set_visibility(false, true)

func process_settings(last_frame: bool, delta: float):
	var close_menu = $CanvasLayer2/Settings/SettingsMenu.process(delta, Shortcut.get_pad_vector("just_pressed"))
	while close_menu is GDScriptFunctionState:
		close_menu = yield(close_menu, "completed")
	if close_menu:
		mode = MODES.MAP
		Buttons.get_node("RightBoxContainer/Equipment").set_hold_time(ButtonPrompt.HOLD_TIMES.NONE)
		Buttons.get_node("RightBoxContainer/Equipment").set_text("pausemenu_button_equipmentlogbook", false)
		Buttons.get_node("RightBoxContainer/Equipment").set_visibility(true, true)
		Buttons.get_node("RightBoxContainer/Settings").set_text("pausemenu_button_settings", false)
		Buttons.get_node("RightBoxContainer/Settings").set_visibility(true, true)
		Buttons.get_node("LeftBoxContainer/Accept").set_visibility(false, true)
		Buttons.get_node("LeftBoxContainer/Cancel").set_visibility(false, true)
		$AnimationPlayer.play("close_settings")

func map_station_activated(area_index: int):
	Map.current_chunk.tile.flash = false
	yield(pause(), "completed")
	mode = MODES.MAPREVEAL
	
	var tiles_to_reveal: Array = Map.tiles_by_area[area_index]
	Map.Grid.show_all_tiles(tiles_to_reveal)
	yield(Global.wait(0.5, true), "completed")
	
	var temporaryMapGrid: Control = Map.Grid.duplicate(4)
	Map.Grid.get_parent().add_child(temporaryMapGrid)
	Global.reparent_child(Map.Grid, $CanvasLayer/MapRevealContainer/Container)
	Map.Grid.Background.visible = false
	Map.Grid.rect_size = temporaryMapGrid.rect_size
	
	$CanvasLayer.move_child($CanvasLayer/MapRevealContainer, $CanvasLayer.get_child_count() - 1)
	$CanvasLayer.move_child($CanvasLayer/MapRevealCursor, $CanvasLayer.get_child_count() - 1)
	
	for tile in tiles_to_reveal:
		tile.revealed = true
	
	$AnimationPlayer.play("mapreveal", -1, 1.0/3.5)
	yield($AnimationPlayer, "animation_finished")
	
	Global.reparent_child(Map.Grid, temporaryMapGrid.get_parent())
	Map.Grid.rect_size = temporaryMapGrid.rect_size
	Map.Grid.Background.visible = true
	temporaryMapGrid.queue_free()
	
	yield(Global.wait(0.5, true), "completed")
	Map.current_chunk.tile.flash = true
	mode = MODES.MAP
	
	emit_signal("map_reveal_completed")
	yield(self, "menu_closed")
