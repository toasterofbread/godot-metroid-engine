extends Node2D

export var action: String

# Called when the node enters the scene tree for the first time.
func _ready():
	if not InputMap.has_action(action):
		assert(false, "Action '" + action + "' doesn't seem to exist")
	
	var actions: Array = InputMap.get_action_list(action)
	
	print(actions)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
