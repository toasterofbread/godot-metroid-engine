extends Control

onready var Samus: KinematicBody2D = Loader.Samus

const menu_open_duration: float = 0.45
const map_move_speed = 100
const map_move_acceleration = 500
var map_grid_parent: Node
var mapGrid: Control

var map_move_velocity = Vector2.ZERO
var transitioning = false

onready var Buttons = $CanvasLayer2/ButtonPrompts
enum MODES {CLOSED, MAP, MAPMARKER, MAPAREA, SETTINGS, SETTINGSOPTION, EQUIPMENT, LOGBOOK, MAPREVEAL}
var mode: int = MODES.CLOSED

signal menu_closed

func _ready():
	
	$CanvasLayer/MapGridPosition.visible = false
	
	for animation_name in $AnimationPlayer.get_animation_list():
		var animation = $AnimationPlayer.get_animation(animation_name)
		for track in animation.get_track_count():
			animation.track_set_path(track, str(animation.track_get_path(track)).replace("CanvasLayer/MapGridPosition", "CanvasLayer/MapGrid"))
	
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
	
	mapGrid.visible = false
	Global.reparent_child(mapGrid, $CanvasLayer)
	mapGrid.map_offset_offset = Vector2(4, -2)
	mapGrid.background_size = $CanvasLayer/MapGridPosition.rect_size
	$AnimationPlayer.clear_caches()
	$AnimationPlayer.play("open_menu")
	yield($AnimationPlayer, "animation_finished")
	
	transitioning = false
	mode = MODES.MAP

func resume():
	
	if transitioning:
		return
	
	transitioning = true
	$AnimationPlayer.play("close_menu" if mode == MODES.MAP else "fade_out")
	yield($AnimationPlayer, "animation_finished")
	
	get_tree().paused = false
	Samus.paused = false
	mode = MODES.CLOSED
	
	$AnimationPlayer.play("reset")
	yield($AnimationPlayer, "animation_finished")
	transitioning = false
	
	emit_signal("menu_closed")

func reset_minimap():
	mapGrid.modulate.a = 0
	Global.reparent_child(mapGrid, map_grid_parent)
	mapGrid.reset_minimap_properties()
	if Map.current_chunk != null:
		mapGrid.set_focus_position(Map.current_chunk.tile.position, true)
	mapGrid.fade(true, 0.25)

func _process(delta: float):
	
	if transitioning:
		mapGrid.update_background()
		return
	elif mode == MODES.CLOSED or mode == MODES.MAPREVEAL:
		return
	
	var resuming = false
	if Buttons.get_node("Close").just_pressed():
		resuming = true
	
	if mode == MODES.MAP:
		if Buttons.get_node("Marker/ButtonPrompts/Main").just_pressed():
			if Buttons.get_node("Marker").expand_to_point(1):
				mode = MODES.MAPMARKER
				for button in Buttons.get_node("Marker/ButtonPrompts").get_children():
					button.set_enabled(true, 0.5)
				Buttons.get_node("Marker/ButtonPrompts/Rename").switch_to_index(0, 0)
				Buttons.get_node("Marker/ButtonPrompts/Main").switch_to_index(1, 0.25)
				
				Buttons.get_node("Settings").enabled = false
				Buttons.get_node("Equipment").enabled = false
				
				process_marker(true, resuming)
				return
		elif Buttons.get_node("Areas/ButtonPrompts/Open").just_pressed():
			if Buttons.get_node("Areas").expand_to_point(1):
				mode = MODES.MAPAREA
				Buttons.get_node("Areas/ButtonPrompts/Open").switch_to_index(1)
				Buttons.get_node("Areas/ButtonPrompts/Cancel").enabled = true
				
				Buttons.get_node("Settings").enabled = false
				Buttons.get_node("Equipment").enabled = false
			
		elif Buttons.get_node("Settings").just_pressed() and $AnimationPlayer.current_animation == "":
			$AnimationPlayer.play("open_settings")
			mode = MODES.SETTINGS
		elif Buttons.get_node("Equipment").just_pressed() and $AnimationPlayer.current_animation == "":
			$AnimationPlayer.play("open_equipment")
			mode = MODES.EQUIPMENT
		else:
			var pad_vector = -Shortcut.get_pad_vector("pressed")
			map_move_velocity.x = move_toward(map_move_velocity.x, map_move_speed*pad_vector.x, map_move_acceleration*delta)
			map_move_velocity.y = move_toward(map_move_velocity.y, map_move_speed*pad_vector.y, map_move_acceleration*delta)
			if map_move_velocity != Vector2.ZERO:
				mapGrid.Tiles.position += map_move_velocity * delta
				mapGrid.update_background()
	else:
		match mode:
			MODES.MAPMARKER: process_marker(false, resuming)
			MODES.MAPAREA: process_area(resuming)
			MODES.SETTINGS: process_settings(resuming)
			MODES.SETTINGSOPTION: process_settings_option(resuming)
			MODES.EQUIPMENT: process_equipment(resuming)
			MODES.LOGBOOK: process_logbook(resuming)
	
	if resuming:
		resume()

func process_logbook(last_frame: bool):
	
	if Buttons.get_node("Settings").just_pressed():
		$AnimationPlayer.play("close_logbook")
		mode = MODES.MAP
	elif Buttons.get_node("Equipment").just_pressed():
		$AnimationPlayer.play("logbook_to_equipment")
		mode = MODES.EQUIPMENT
	else:
		$CanvasLayer2/LogbookScreen.process()

func process_equipment(last_frame: bool):
	
	if Buttons.get_node("Settings").just_pressed():
		$AnimationPlayer.play("close_equipment")
		mode = MODES.MAP
	elif Buttons.get_node("Equipment").just_pressed():
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
	
	if Buttons.get_node("Marker").transitioning:
		return
	
	if Buttons.get_node("Marker/ButtonPrompts/Main").just_pressed():
		mode = MODES.MAP
	elif Buttons.get_node("Marker/ButtonPrompts/Delete").just_pressed():
		Map.Marker.grid_position = null
		mode = MODES.MAP
	elif Buttons.get_node("Marker/ButtonPrompts/Rename").just_pressed():
		if Buttons.get_node("Marker/ButtonPrompts/Rename").switch_to_index(!Map.Marker.editable_name, 0.25):
			Map.Marker.editable_name = !Map.Marker.editable_name
			Map.Marker.moving = !Map.Marker.editable_name
	
	if mode != MODES.MAPMARKER or last_frame:
		
		Map.Marker.moving = false
		Map.Marker.editable_name = false
		Map.Marker.save_data()
		Map.Marker.load_data()
		
		Buttons.get_node("Marker").expand_to_point(0)
		Buttons.get_node("Marker/ButtonPrompts/Main").switch_to_index(0, 0.25)
		
		Buttons.get_node("Settings").enabled = true
		Buttons.get_node("Equipment").enabled = true
		
		Buttons.get_node("Marker/ButtonPrompts/Delete").set_enabled(false, 0.1)
		Buttons.get_node("Marker/ButtonPrompts/Rename").set_enabled(false, 0.1)
		
func process_area(last_frame: bool):
	
	if Buttons.get_node("Areas/ButtonPrompts/Open").just_pressed():
		pass
	elif Buttons.get_node("Areas/ButtonPrompts/Cancel").just_pressed():
		mode = MODES.MAP
	
	if mode != MODES.MAPAREA or last_frame:
		Buttons.get_node("Areas").expand_to_point(0)
		Buttons.get_node("Areas/ButtonPrompts/Open").switch_to_index(0, 0.25)
		
		Buttons.get_node("Settings").enabled = true
		Buttons.get_node("Equipment").enabled = true
		
		Buttons.get_node("Areas/ButtonPrompts/Cancel").set_enabled(false, 0.1)

func process_settings(last_frame: bool):
	
	if Buttons.get_node("Settings").just_pressed() and $AnimationPlayer.current_animation == "":
		mode = MODES.MAP
		$AnimationPlayer.play("close_settings")
	elif Input.is_action_just_pressed("ui_accept") and $AnimationPlayer.current_animation == "":
		mode = MODES.SETTINGSOPTION
		Buttons.get_node("Marker").expand_to_point(2, true)
		Buttons.get_node("Areas").expand_to_point(2, true)
		Buttons.get_node("Marker/ButtonPrompts/Main").switch_to_index(2, 0)
		Buttons.get_node("Areas/ButtonPrompts/Open").switch_to_index(2, 0)
		$AnimationPlayer.play("settings_to_options")
		var category: String = $CanvasLayer2/Settings/CategoryDisplay.current_category()
		$CanvasLayer2/MainLabel.set_text("Settings" + " - " + category)
		$CanvasLayer2/Settings/OptionDisplay.load_category(category)
	else:
		$CanvasLayer2/Settings/CategoryDisplay.process()
	
#	if mode != MODES.SETTINGS or last_frame:
#		$AnimationPlayer2.play("close_settings")

func process_settings_option(last_frame: float):
	
	if Buttons.get_node("Settings").just_pressed() and $AnimationPlayer.current_animation == "":
		mode = MODES.SETTINGS
		$CanvasLayer2/MainLabel.set_text("Settings")
		$AnimationPlayer.play("options_to_settings")
		Buttons.get_node("Marker").expand_to_point(0)
		Buttons.get_node("Areas").expand_to_point(0)
		Buttons.get_node("Marker/ButtonPrompts/Main").switch_to_index(0)
		Buttons.get_node("Areas/ButtonPrompts/Open").switch_to_index(0)
	elif Buttons.get_node("Marker/ButtonPrompts/Main").just_pressed():
		$CanvasLayer2/Settings/OptionDisplay.save()
	elif Buttons.get_node("Areas/ButtonPrompts/Open").just_pressed():
		$CanvasLayer2/Settings/OptionDisplay.reset()
	else:
		$CanvasLayer2/Settings/OptionDisplay.process()

func map_station_activated(area_index: int):
	Map.current_chunk.tile.flash = false
	yield(pause(), "completed")
	mode = MODES.MAPREVEAL
	
	var tiles_to_reveal: Array = Map.tiles_by_area[area_index]
	Map.Grid.show_all_tiles(tiles_to_reveal)
	yield(Global.wait(0.5, true), "completed")
	
	var temporaryMapGrid: Control = Map.Grid.duplicate(4)
	$CanvasLayer.add_child(temporaryMapGrid)
	Global.reparent_child(Map.Grid, $CanvasLayer/MapRevealContainer/Container)
	Map.Grid.get_node("Background").visible = false
	Map.Grid.rect_size = temporaryMapGrid.rect_size
	
	$CanvasLayer.move_child($CanvasLayer/MapRevealContainer, $CanvasLayer.get_child_count() - 1)
	$CanvasLayer.move_child($CanvasLayer/MapRevealCursor, $CanvasLayer.get_child_count() - 1)
	
	for tile in tiles_to_reveal:
		tile.discovered = true
	
	$AnimationPlayer.play("mapreveal", -1, 1.0/3.5)
	yield($AnimationPlayer, "animation_finished")
	
	Global.reparent_child(Map.Grid, $CanvasLayer)
	Map.Grid.rect_size = temporaryMapGrid.rect_size
	Map.Grid.get_node("Background").visible = true
	temporaryMapGrid.queue_free()
	
	yield(Global.wait(0.5, true), "completed")
	Map.current_chunk.tile.flash = true
	mode = MODES.MAP
	
	yield(self, "menu_closed")
