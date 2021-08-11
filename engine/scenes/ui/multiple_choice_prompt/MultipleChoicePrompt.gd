extends Control
class_name MultipleChoicePrompt

signal _result

onready var choiceContainer: VBoxContainer = $PanelContainer/VSplitContainer/VSplitContainer/VBoxContainer/ScaleContainer/ChoiceContainer
onready var buttonAccept: ButtonPrompt = $PanelContainer/VSplitContainer/VSplitContainer/ButtonPrompts/Accept
onready var buttonCancel: ButtonPrompt = $PanelContainer/VSplitContainer/VSplitContainer/ButtonPrompts/Cancel
onready var descriptionLabel: Label = $PanelContainer/VSplitContainer/VSplitContainer/VBoxContainer/Description

var cancellable: bool
var selected_option: int = 0 setget set_selected_option

func _ready():
	set_process(false)
	visible = false
	modulate.a = 0.0
	for node in choiceContainer.get_children():
		node.queue_free()
	$PanelContainer/Node2D/TemplateChoice.visible = false
	$PanelContainer/Node2D/TemplateChoice.get_child(0).flat = true

func _process(_delta: float):
	
	if cancellable and buttonCancel.just_pressed():
		emit_signal("_result", null)
	elif buttonAccept.just_pressed() and selected_option >= 0:
		emit_signal("_result", selected_option)
	else:
		var pad_y: int = InputManager.get_pad_y("just_pressed")
		if pad_y != 0:
			if selected_option < 0:
				set_selected_option(0)
			else:
				set_selected_option(wrapi(selected_option+pad_y, 0, choiceContainer.get_child_count()))

func choice_clicked_on(choice_node: Label):
	emit_signal("_result", choice_node.get_position_in_parent())

func choice_mouse_interacted(choice_node: Label, mouse_entered: bool):
#	if not mouse_entered and choice_node.get_position_in_parent() == selected_option:
#		set_selected_option(-1)
	InputManager.using_keyboard = true
	if mouse_entered and choice_node.get_position_in_parent() != selected_option:
		set_selected_option(choice_node.get_position_in_parent())

func set_selected_option(value: int):
	if selected_option >= 0:
		choiceContainer.get_child(selected_option).get_child(0).flat = true
	selected_option = value
	if selected_option >= 0:
		var choice_node: Label = choiceContainer.get_child(selected_option)
		choice_node.get_child(0).flat = false
		if choice_node.has_meta("description"):
			descriptionLabel.text = choice_node.get_meta("description")
			return
	descriptionLabel.text = ""

func show_prompt(choices: PoolStringArray, descriptions: Array, title: String, starting_option: int = 0, _cancellable: bool = true):
	cancellable = _cancellable
	buttonCancel.set_visibility(cancellable, false)
	selected_option = starting_option
	
	$PanelContainer/VSplitContainer/TitleLabel.text = title
	for i in range(len(choices)):
		var choice_text: String = choices[i]
		var choice_node: Label = $PanelContainer/Node2D/TemplateChoice.duplicate()
		choice_node.text = choice_text
		if len(descriptions) > i and descriptions[i] is String:
			choice_node.set_meta("description", descriptions[i])
		choice_node.visible = true
		choice_node.mouse_filter = Control.MOUSE_FILTER_STOP
		choice_node.get_child(0).connect("pressed", self, "choice_clicked_on", [choice_node])
		choice_node.get_child(0).connect("mouse_entered", self, "choice_mouse_interacted", [choice_node, true])
		choice_node.get_child(0).connect("mouse_exited", self, "choice_mouse_interacted", [choice_node, false])
		choiceContainer.add_child(choice_node)
	choiceContainer.get_child(selected_option).get_child(0).flat = false
	
	visible = true
	$PanelContainer/Tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.2)
	$PanelContainer/Tween.start()
	
	set_process(true)
	var result = yield(self, "_result")
	set_process(false)
	
	$PanelContainer/Tween.stop_all()
	$PanelContainer/Tween.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.2)
	$PanelContainer/Tween.start()
	yield($PanelContainer/Tween, "tween_completed")
	visible = false
	for node in choiceContainer.get_children():
		node.queue_free()
	return result
