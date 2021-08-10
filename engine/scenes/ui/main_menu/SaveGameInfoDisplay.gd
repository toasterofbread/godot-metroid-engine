extends Control

var saveGame: SaveGame
var current: bool = false setget set_current

var preparing_to_copy: bool = false setget set_preparing_to_copy

func set_preparing_to_copy(value: bool):
	preparing_to_copy = value
	# TODO

func set_current(value: bool):
	if current == value:
		return
	
	current = value
	$Tween.stop_all()
	
	$Tween.interpolate_property($Container, "rect_position:x", $Container.rect_position.x, -$Container/Number.rect_size.x if current else 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()

func init(_saveGame: SaveGame):
	saveGame = _saveGame
	
	$Container/VBoxContainer.visible = saveGame.file_exists
	$Container/VBoxContainer2.visible = saveGame.file_exists
	$Container/Empty.visible = !saveGame.file_exists
	
	$Container/Number/Label.text = str(get_position_in_parent() + 1)
	if saveGame.file_exists:
		var time: int = saveGame.get_data_key(["statistics", "playtime"])
		var hours: String = str((time / 60) / 60).pad_zeros(2)
		var minutes: String = str((time/60) % 60).pad_zeros(2)
		var seconds: String = str(time % 60).pad_zeros(2)
		$Container/VBoxContainer/PlayTime.text = tr("titlescreen_playtime_text") + ": " + hours + ":" + minutes + ":" + seconds
		$Container/VBoxContainer/HBoxContainer/Completion.text = tr("titlescreen_completion_text") + ": " + str(saveGame.get_overall_percentage() * 100).pad_decimals(1)
		$Container/VBoxContainer2/Difficulty.text = tr("titlescreen_difficulty_text") + ": " + tr("difficulty_" + str(saveGame.get_data_key(["difficulty", "level"])))
		$Container/VBoxContainer2/Created.text = tr("titlescreen_created_date_text") + ": " + Global.get_date_as_string(OS.get_datetime_from_unix_time(saveGame.get_data_key(["statistics", "creation_date"])))
	else:
		$Container/Empty.text = tr("titlescreen_savefile_empty")
