extends PopupDialog
tool

onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel

var progress: float setget setProgress, getProgress

func setProgress(value: float):
	progress_bar.value = value

func getProgress():
	return progress_bar.value

func onAboutToShow():
	progress_bar.value = 0
	progress_label.text = ""

func updateProgress(progress: float, step: String):
	progress_label.text = step + "..."
	
	$Tween.stop_all()
	$Tween.interpolate_property(progress_bar, "value", progress_bar.value, progress, 0.5)
	$Tween.start()
	yield($Tween, "tween_completed")
	yield(get_tree().create_timer(0.25), "timeout")
