tool
extends PanelContainer

export var update_size: bool = false setget update_size
func update_size(_value: bool = false):
	rect_size = rect_min_size

var action_key: String
func init(text: String, action_key: String, clear):
	$HBoxContainer/Label.text = text
	$HBoxContainer/ButtonIcon.action_key = action_key
	self.action_key = action_key
	
	if Notification.left_to_right:
		var style: StyleBoxFlat = get("custom_styles/panel")
		style.expand_margin_left = style.expand_margin_right
		style.expand_margin_right = 0
	
	Notification.add(self, clear)
	return self

func _ready():
	update_size()

func get_size():
	return rect_size * rect_scale

func just_pressed():
	return Input.is_action_just_pressed(action_key)

func pressed():
	return Input.is_action_pressed(action_key)

func just_released():
	return Input.is_action_pressed(action_key)
