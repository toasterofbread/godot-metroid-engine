extends Node2D

onready var bg: ColorRect = self.get_parent().get_node("Background")
onready var icon: AnimatedSprite = self.get_parent().get_node("Icon")
const digit_width = 7

onready var digit_node = AnimatedSprite.new()
func _ready():
	digit_node.frames = preload("res://sprites/ui/mainhud/numerals/numerals.tres")
	digit_node.playing = false

func add_digit():
	var new_digit = digit_node.duplicate()
	self.add_child(new_digit)
	bg.rect_size.x += digit_width
	self.rect_min_size = bg.rect_size

func remove_digit():
	if len(self.get_children()) == 0:
		return
	self.get_children()[len(self.get_children()) - 1].queue_free()
	bg.rect_size.x -= digit_width
	self.rect_min_size = bg.rect_size

func update_digits():
	var i = 0
	for digit in self.get_children():
		digit.frame = int(str(get_parent().amount)[i])
		i += 1
