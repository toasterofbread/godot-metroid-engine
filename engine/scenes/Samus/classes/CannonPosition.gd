extends Position2D
class_name SamusCannonPosition

# DEBUG
const debug_visible: bool = true

func _ready():
#	visible = debug_visible and get_parent().name == "grapple"
	visible = get_tree().debug_collisions_hint
	if debug_visible:
		var indicator: Sprite = Sprite.new()
		indicator.texture = preload("res://godot.png")
		add_child(indicator)
		indicator.scale = Vector2(0.1, 0.1)

var default_values: Dictionary = {
	"position": position,
	"rotation": rotation
}

export var can_fire_chargebeam: bool = true
export var left: bool = true
export var right: bool = true

func reset():
	for value in default_values:
		set(value, default_values[value])
