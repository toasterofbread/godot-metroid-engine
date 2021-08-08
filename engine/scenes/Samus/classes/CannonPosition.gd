extends Position2D
class_name SamusCannonPosition

export var can_fire_chargebeam: bool = true
export var display_armed_sprite: bool = true
export var left: bool = true
export var right: bool = true

var default_values: Dictionary = {
	"position": position,
	"rotation": rotation
}

var allowed_facing_directions: Array = []
var is_current: bool

#onready var debug_enabled: bool = get_tree().debug_collisions_hint
func _ready():
	visible = false
	
	if left:
		allowed_facing_directions.append(Enums.dir.LEFT)
	if right:
		allowed_facing_directions.append(Enums.dir.RIGHT)

func reset():
	for value in default_values:
		set(value, default_values[value])
