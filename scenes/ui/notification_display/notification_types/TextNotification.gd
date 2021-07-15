tool
extends PanelContainer

export var update_size: bool = false setget update_size

func update_size(_value: bool = false):
	rect_size = rect_min_size

func init(text: String, clear):
	$Label.text = text
	Notification.add(self, clear)
	return self

func _ready():
	update_size()

func get_size():
	return rect_size * rect_scale
