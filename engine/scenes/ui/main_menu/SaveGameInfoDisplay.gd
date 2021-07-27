extends ColorRect

func init(saveGame: SaveGame):
	
	var time: int = saveGame.get_data_key(["statistics", "playtime"])
	var hours: String = str((time / 60) / 60).pad_zeros(2)
	var minutes: String = str((time/60) % 60).pad_zeros(2)
	var seconds: String = str(time % 60).pad_zeros(2)
	$PlayTime.text = tr("titlescreen_playtime_text") + " " + hours + ":" + minutes + ":" + seconds
	$Completion.text = tr("titlescreen_completion_text") + " " + str(saveGame.get_upgrade_percentage() * saveGame.get_scan_percentage() * 100).pad_decimals(1)
	
	$Number/Label.text = str(get_position_in_parent() + 1)
