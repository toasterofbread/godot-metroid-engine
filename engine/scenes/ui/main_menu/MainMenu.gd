extends Control

enum STATES {TITLE, SAVE_SELECTION, SETTINGS, CREDITS, QUIT_CONFIRM}
var state: int = STATES.TITLE

# Title state
const title_option_selected_modulate: Color = Color(1, 1, 1, 1)
const title_option_unselected_modulate: Color = Color(1, 1, 1, 0.25)
var title_selected_option: int = 0 

func _process(delta: float):
	var pad_vector: Vector2 = Shortcut.get_pad_vector("just_pressed")
	$Background/bg_planet.rotation_degrees += delta * 0.5
	
	match state:
		STATES.TITLE: process_title(delta, pad_vector)
		STATES.SAVE_SELECTION: process_saveselection(delta, pad_vector)

func process_title(delta: float, pad: Vector2):
	
	if pad.y != 0:
		if title_selected_option < 0:
			title_selected_option = 0
		else:
			$Title/Options.get_child(title_selected_option).self_modulate = title_option_unselected_modulate
			title_selected_option += pad.y
			if title_selected_option < 0:
				title_selected_option = $Title/Options.get_child_count() - 1
			elif title_selected_option >= $Title/Options.get_child_count():
				title_selected_option = 0
		
		$Title/Options.get_child(title_selected_option).self_modulate = title_option_selected_modulate
	
	if $Title/AcceptButtonPrompt.just_pressed():
		$Title/Options.get_child(title_selected_option).get_node("Button").emit_signal("pressed")

func title_option_mouse_hover(entered: bool, option: int):
	print(option, " | ", title_selected_option)
	if entered and option != title_selected_option:
		if title_selected_option >= 0:
			$Title/Options.get_child(title_selected_option).self_modulate = title_option_unselected_modulate
		title_selected_option = option
		$Title/Options.get_child(title_selected_option).self_modulate = title_option_selected_modulate
	elif not entered and option == title_selected_option:
		$Title/Options.get_child(title_selected_option).self_modulate = title_option_unselected_modulate
		title_selected_option = -1

func selectsave_button_pressed():
	
#	$AnimationPlayer.play("to_saveselection")
#	yield($AnimationPlayer, "animation_finished")
	
	$Tween.interpolate_property($Title, "modulate:a", 1.0, 0.0, 0.25)
	$Tween.start()
	yield($Tween, "tween_completed")
	$Title.visible = false
	yield(Global.wait(0.1, false), "completed")
	
	
	for save in $SaveSelection/SaveContainer.get_children():
		save.modulate.a = 0.0
	$SaveSelection.visible = true
	for save in $SaveSelection/SaveContainer.get_children():
		save.margin_left = rect_size.x - $SaveSelection/SaveContainer.rect_global_position.x
		save.modulate.a = 1.0
		$Tween.interpolate_property(save, "margin_left", save.margin_left, 0.0, 0.3, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$Tween.start()
		yield($Tween, "tween_completed")
	
	return
	
	visible = false
	var save_point: Dictionary = Loader.Save.get_data_key(["save_point"])
	Loader.load_room(save_point["room_id"], true, {"preview": true})
	yield(play_spawn_animation(save_point), "completed")
	queue_free()
func settings_button_pressed():
	print("Settings | TODO")
func docs_button_pressed():
	print("Docs | TODO")
func quit_button_pressed():
	get_tree().quit()

func process_saveselection(_delta: float, pad: Vector2):
	pass

func _ready():
	
	$AnimationPlayer.play("reset")
	
	for save in $SaveSelection/SaveContainer.get_children():
		save.init(Loader.Save)
	for option in $Title/Options.get_children():
		option.get_node("Button").connect("mouse_entered", self, "title_option_mouse_hover", [true, option.get_position_in_parent()])
		option.get_node("Button").connect("mouse_exited", self, "title_option_mouse_hover", [false, option.get_position_in_parent()])
	
	
	for option in $Title/Options.get_children():
		if option.get_position_in_parent() == title_selected_option:
			option.self_modulate = title_option_selected_modulate
		else:
			option.self_modulate = title_option_unselected_modulate
	
	$Title/Options/SelectSave/Button.connect("pressed", self, "selectsave_button_pressed")
	$Title/Options/Settings/Button.connect("pressed", self, "settings_button_pressed")
	$Title/Options/Docs/Button.connect("pressed", self, "docs_button_pressed")
	$Title/Options/Quit/Button.connect("pressed", self, "quit_button_pressed")
	
	return
	var save_point: Dictionary = Loader.Save.get_data_key(["save_point"])
	Loader.load_room(save_point["room_id"], true, {"preview": true})
#	yield(play_spawn_animation(save_point), "completed")
	queue_free()

func play_spawn_animation(save_point: Dictionary):
	Notification.allow_new_notifications = false
	Notification.clear_all()
	var Samus: KinematicBody2D = Loader.Samus
	Samus.visible = false
	Samus.paused = true
	
	yield(Loader.current_room.save_stations[save_point["save_station_id"]].spawn_samus(), "completed")
	Notification.allow_new_notifications = true
