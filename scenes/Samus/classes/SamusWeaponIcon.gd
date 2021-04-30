extends Control
class_name SamusWeaponIcon

const digit_width = 7

onready var digit_node = AnimatedSprite.new()
func _ready():
	digit_node.frames = preload("res://sprites/ui/mainhud/numerals/numerals.tres")
	self.rect_min_size = $Background.rect_size

func add_digit():
	var new_digit = digit_node.duplicate()
	$Digits.add_child(new_digit)
	$Background.rect_size.x += digit_width
	self.rect_min_size = $Background.rect_size

func remove_digit():
	if len($Digits.get_children()) == 0:
		return
	$Digits.get_children()[len($Digits.get_children()) - 1].queue_free()
	$Background.rect_size.x -= digit_width
	self.rect_min_size = $Background.rect_size

func update_digits(amount: int):
	var i = 0
	for digit in $Digits.get_children():
		digit.frame = int(str(amount)[i])
		i += 1

func update_icon(selected_weapon, armed: bool = false):
	if selected_weapon.Icon == self:
		$Icon.frame = 2 if armed else 1
	else:
		$Icon.frame = 0
