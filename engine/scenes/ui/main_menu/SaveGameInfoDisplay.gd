extends ColorRect

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
	
	$Tween.interpolate_property($Container, "position:x", $Container.position.x, -$Container/Number.rect_size.x if current else 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()

func init(_saveGame: SaveGame):
	saveGame = _saveGame
	
	$Container/PlayTime.visible = saveGame.file_exists
	$Container/Completion.visible = saveGame.file_exists
	$Container/Empty.visible = !saveGame.file_exists
	
	$Container/Number/Label.text = str(get_position_in_parent() + 1)
	if saveGame.file_exists:
		var time: int = saveGame.get_data_key(["statistics", "playtime"])
		var hours: String = str((time / 60) / 60).pad_zeros(2)
		var minutes: String = str((time/60) % 60).pad_zeros(2)
		var seconds: String = str(time % 60).pad_zeros(2)
		$Container/PlayTime.text = tr("titlescreen_playtime_text") + " " + hours + ":" + minutes + ":" + seconds
		$Container/Completion.text = tr("titlescreen_completion_text") + " " + str(saveGame.get_overall_percentage() * 100).pad_decimals(1)
	else:
		$Container/Empty.text = tr("titlescreen_savefile_empty")
