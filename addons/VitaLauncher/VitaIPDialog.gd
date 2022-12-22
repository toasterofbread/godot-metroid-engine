extends ConfirmationDialog
tool

signal COMPLETED(text, remember)

func onAboutToShow():
	$VBoxContainer/LineEdit.text = ""

func onHide():
	yield(get_tree(), "idle_frame")
	emit_signal("COMPLETED", "", false)

func onTextEntered(text: String):
	emit_signal("COMPLETED", text, $VBoxContainer/CheckBox.pressed)
	hide()

func onConfirmed():
	emit_signal("COMPLETED", $VBoxContainer/LineEdit.text, $VBoxContainer/CheckBox.pressed)
