extends Node2D
class_name BaseNotification

onready var visual: Control = $CanvasLayer/Visual
export var id: String

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = false
	visual.visible = false
	ready()
	Notification.add_notification(self)

func ready():
	pass
