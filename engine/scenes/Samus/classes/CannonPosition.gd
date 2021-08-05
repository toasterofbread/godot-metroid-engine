extends Position2D
class_name SamusCannonPosition

export var can_fire_chargebeam: bool = true
export var left: bool = true
export var right: bool = true
var default_values: Dictionary = {
	"position": position,
	"rotation": rotation
}

var allowed_facing_directions: Array = []
var is_current: bool = false setget set_is_current

# DEBUG
onready var debug_enabled: bool = get_tree().debug_collisions_hint

func _ready():
	
	if left:
		allowed_facing_directions.append(Enums.dir.LEFT)
	if right:
		allowed_facing_directions.append(Enums.dir.RIGHT)
	
	# DEBUG
	visible = false
	if debug_enabled:
		var indicator: Sprite = Sprite.new()
		indicator.texture = preload("res://godot.png")
		add_child(indicator)
		indicator.scale = Vector2(0.1, 0.1)

func set_is_current(value: bool):
	is_current = value
	if debug_enabled:
		visible = is_current

func reset():
	for value in default_values:
		set(value, default_values[value])
