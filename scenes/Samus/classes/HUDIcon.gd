extends Control
class_name SamusHUDIcon

const digit_width = 7
onready var Digits = get_node_or_null("Digits")
onready var Icon = $Icon

var frame = 0 setget set_frame, get_frame

func set_frame(value):
	$Icon.frame = value
	frame = $Icon.frame

func get_frame():
	frame = $Icon.frame
	return frame

onready var digit_node = AnimatedSprite.new()
func _ready():
	$Icon.playing = false
	$Icon.frame = 0
	digit_node.frames = preload("res://sprites/ui/mainhud/numerals/numerals.tres")
	digit_node.play("fontB")
	self.rect_min_size = $Background.rect_size

func add_digit():
	var new_digit = digit_node.duplicate()
	new_digit.position = Digits.get_children()[len(Digits.get_children()) - 1].position + Vector2(digit_width, 0)
	new_digit.frame = 0
	Digits.add_child(new_digit)
	$Background.rect_size.x += digit_width
	self.rect_min_size = $Background.rect_size

func remove_digit():
	if len(Digits.get_children()) == 0:
		return
	var digit_to_remove = Digits.get_children()[len(Digits.get_children()) - 1]
	Digits.remove_child(digit_to_remove)
	digit_to_remove.queue_free()

func update_digits(amount: int):
	if not Digits:
		return
	
	var i = 0
	
	while len(Digits.get_children()) < len(str(amount)):
		add_digit()
	while len(Digits.get_children()) > len(str(amount)):
		remove_digit()
	
	for digit in Digits.get_children():
		digit.frame = int(str(amount)[i])
		i += 1

func update_icon(selected_weapon, armed: bool):
	if selected_weapon and selected_weapon.Icon == self:
		Icon.frame = 2 if armed else 1
	else:
		Icon.frame = 0
