extends Control
class_name NotificationBaseVariant

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = false
	ready()

func ready():
	pass

func trigger(_data: Dictionary):
	pass
