extends Control

onready var overlay = preload("res://engine/classes/autoload/Var_Overlay/overlay.tscn").instance()

var _labels = {}

func get_as_text(property: String, value):
	return property + ": " + str(value)

func SET(property: String, value):
	if property in _labels:
		_labels[property].text = get_as_text(property, value)
	else:
		var label = Label.new()
		label.text = get_as_text(property, value)
		_labels[property] = label
		overlay.add_child(label)

func _ready():
	self.add_child(overlay)
	overlay = overlay.get_child(0)
