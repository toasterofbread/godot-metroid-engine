extends Control

const id = "missile"
const hud_icon = true
var capacity: int = 10
var amount: int = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_cap(cap: int):
	capacity = cap
	
	if len(str(capacity)) > len($Digits.get_children()):
		add_digit()
	elif len(str(capacity)) < len($Digits.get_children()):
		remove_digit()
	
	amount = min(amount, capacity)

func add_digit():
	var new_digit = get_node("Digits/0").duplicate()
	$Digits.add_child(new_digit)

func remove_digit():
	if len($Digits.get_children()) == 1:
		return

func update_digits():
	pass
