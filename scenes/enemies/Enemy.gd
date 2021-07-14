extends KinematicBody2D
class_name Enemy

export var id: String
onready var data: Dictionary = Data.data["damage_values"][id]
onready var health: float = data["health"]
onready var effective_types: Array = data["effective_types"] if "effective_types" in data else []
onready var ineffective_types: Array = data["ineffective_types"] if "ineffective_types" in data else []

func _ready():
	
	z_as_relative = false
	z_index = Enums.Layers.ENEMY

func death(_type: int):
	pass

func damage(type: int, amount: float, _impact_position):
	if type in effective_types or not type in ineffective_types:
		health = max(0, health - amount)
		if health == 0:
			death(type)
