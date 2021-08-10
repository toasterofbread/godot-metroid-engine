extends PanelContainer
class_name MultipleChoicePrompt

signal _result

onready var choiceContainer: VBoxContainer = $VSplitContainer/VSplitContainer/ScaleContainer/ChoiceContainer
onready var buttonAccept: ButtonPrompt = $VSplitContainer/VSplitContainer/ButtonPrompts/Accept
onready var buttonCancel: ButtonPrompt = $VSplitContainer/VSplitContainer/ButtonPrompts/Cancel

var cancellable: bool
var selected_option: int = 0

func _ready():
	set_process(false)
	visible = false
	modulate.a = 0.0
	for node in choiceContainer.get_children():
		node.queue_free()
	$Node2D/TemplateChoice.visible = false
	$Node2D/TemplateChoice.get_child(0).flat = true

func _process(_delta: float):
	
	if cancellable and buttonCancel.just_pressed():
		emit_signal("_result", null)
	elif buttonAccept.just_pressed() and selected_option >= 0:
		emit_signal("_result", selected_option)
	else:
		var pad_y: int = Shortcut.get_pad_y("just_pressed")
		if pad_y != 0:
			if selected_option < 0:
				selected_option = 0
			else:
				choiceContainer.get_child(selected_option).get_child(0).flat = true
				selected_option = wrapi(selected_option+pad_y, 0, choiceContainer.get_child_count())
			choiceContainer.get_child(selected_option).get_child(0).flat = false

func choice_clicked_on(choice_node: Label):
	emit_signal("_result", choice_node.get_position_in_parent())

func choice_mouse_interacted(choice_node: Label, mouse_entered: bool):
	if not mouse_entered and choice_node.get_position_in_parent() == selected_option:
#		choiceContainer.get_child(selected_option).modulate = choice_modulate_unselected
		choiceContainer.get_child(selected_option).get_child(0).flat = true
		selected_option = -1
	elif mouse_entered and choice_node.get_position_in_parent() != selected_option:
		if selected_option >= 0:
#			choiceContainer.get_child(selected_option).modulate = choice_modulate_unselected
			choiceContainer.get_child(selected_option).get_child(0).flat = true
		selected_option = choice_node.get_position_in_parent()
#		choiceContainer.get_child(selected_option).modulate = choice_modulate_selected
		choiceContainer.get_child(selected_option).get_child(0).flat = false

func show_prompt(choices: PoolStringArray, title: String, starting_option: int = 0, _cancellable: bool = true):
	cancellable = _cancellable
	buttonCancel.set_visibility(cancellable, false)
	selected_option = starting_option
	
	$VSplitContainer/TitleLabel.text = title
	for choice_text in choices:
		var choice_node: Label = $Node2D/TemplateChoice.duplicate()
		choice_node.text = choice_text
		choice_node.visible = true
		choice_node.mouse_filter = Control.MOUSE_FILTER_STOP
		choice_node.get_child(0).connect("pressed", self, "choice_clicked_on", [choice_node])
		choice_node.get_child(0).connect("mouse_entered", self, "choice_mouse_interacted", [choice_node, true])
		choice_node.get_child(0).connect("mouse_exited", self, "choice_mouse_interacted", [choice_node, false])
		choiceContainer.add_child(choice_node)
	choiceContainer.get_child(selected_option).get_child(0).flat = false
	
	visible = true
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.2)
	$Tween.start()
	
	set_process(true)
	var result = yield(self, "_result")
	set_process(false)
	
	$Tween.stop_all()
	$Tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_completed")
	visible = false
	for node in choiceContainer.get_children():
		node.queue_free()
	return result
