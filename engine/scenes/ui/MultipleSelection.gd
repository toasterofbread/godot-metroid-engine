extends Node2D

export(Array, String) var choices: Array = [] setget set_choices

func set_choices(value: Array):
	choices = value
	generate_choices()

func generate_choices():
	for child in $Container.get_children():
		child.queue_free()
	
	var i = 0
	for choice in choices:
		var node = $Template.duplicate()
		node.name = str(i)
		i += 1
