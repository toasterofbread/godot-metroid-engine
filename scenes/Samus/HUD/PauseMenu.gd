extends Control

const menu_open_duration: float = 0.45
const map_move_speed = 100
const map_move_acceleration = 2.5
var map_grid_parent: Node

var map_move_velocity = Vector2.ZERO
var transitioning = false

onready var Buttons = $CanvasLayer2/ButtonPrompts
enum MODES {CLOSED, MAP, MAPMARKER, MAPAREA, SETTINGS, SETTINGSOPTION}
var mode: int = MODES.CLOSED

func _ready():
	
	$CanvasLayer/MapGridPosition.visible = false
	
	for animation_name in $AnimationPlayer.get_animation_list():
		var animation = $AnimationPlayer.get_animation(animation_name)
		for track in animation.get_track_count():
			animation.track_set_path(track, str(animation.track_get_path(track)).replace("CanvasLayer/MapGridPosition", "CanvasLayer/MapGrid"))

func pause():
	get_tree().paused = true
	Loader.Samus.paused = true

func open_menu():
	
	if transitioning:
		return
	
	transitioning = true
	yield(Map.Grid.fade(false, 0.15), "completed")
	
	if not map_grid_parent:
		map_grid_parent = Map.Grid.get_parent()
	
	Map.Grid.visible = false
	Global.reparent_child(Map.Grid, $CanvasLayer)
	Map.Grid.map_offset_offset = Vector2(4, -2)
	Map.Grid.background_size = $CanvasLayer/MapGridPosition.rect_size
	$AnimationPlayer.clear_caches()
	$AnimationPlayer.play("open_menu")
	yield($AnimationPlayer, "animation_finished")

	transitioning = false
	mode = MODES.MAP

func resume():
	
	if transitioning or $AnimationPlayer.current_animation != "":
		return
	
	get_tree().paused = false
	Loader.Samus.paused = false
	transitioning = true
	
	$AnimationPlayer.play("close_menu", -1, 0.5)
	yield($AnimationPlayer, "animation_finished")
	
	mode = MODES.CLOSED
	transitioning = false

func reset_minimap():
	Map.Grid.modulate.a = 0
	Global.reparent_child(Map.Grid, map_grid_parent)
	Map.Grid.reset_minimap_properties()
	if Map.current_tile != null:
		Map.Grid.set_focus_position(Map.current_tile.position, true)
	Map.Grid.fade(true, 0.25)

func _process(delta: float):
	
	if mode == MODES.CLOSED or transitioning:
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
		else:
			var pad_vector = -Shortcut.get_pad_vector("pressed")
			map_move_velocity.x = Shortcut.add_to_limit(map_move_velocity.x, map_move_acceleration, map_move_speed * pad_vector.x)
			map_move_velocity.y = Shortcut.add_to_limit(map_move_velocity.y, map_move_acceleration, map_move_speed * pad_vector.y)
			Map.Grid.Tiles.position += map_move_velocity * delta
	else:
		match mode:
			MODES.MAPMARKER: process_marker(false, resuming)
			MODES.MAPAREA: process_area(resuming)
			MODES.SETTINGS: process_settings(resuming)
			MODES.SETTINGSOPTION: process_settings_option(resuming)
	
	if resuming:
		resume()

func process_marker(first_frame: bool, last_frame: bool):
	
	if first_frame:
		if not Map.Marker.grid_position:
			Map.Marker.grid_position = Map.current_tile.position/8
		Map.Marker.moving = true
		return
	
	if Map.Marker.moving:
		Map.Marker.grid_position += Shortcut.get_pad_vector("just_pressed")
		Map.Grid.set_focus_position(Map.Marker.position, false)
	
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
