extends Area2D

export(Enums.DamageType) var damage_type: int = Enums.DamageType.SPIKE
export var damage_amount: float = 10.0
export var position_expression: String = "Vector2(body_position.x, self_position.y)"
var expression: = Expression.new()

func _ready():
	
	# Parse position expression and check validity
	var error = expression.parse(position_expression, ["body_position", "self_position"])
	# DEBUG
	assert(error == OK)
	assert(expression.execute([Vector2.ZERO, Vector2.ZERO]) is Vector2)

func _on_DamageArea_body_entered(body):
	if body.has_method("damage"):
		body.damage(damage_type, damage_amount, expression.execute([body.global_position, self.global_position]))
