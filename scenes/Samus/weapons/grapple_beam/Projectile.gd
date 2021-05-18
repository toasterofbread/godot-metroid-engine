extends Node2D

var velocity: float = 0.0
const speed: float = 750.0
const acceleration: float = 5.0

var max_length = 450
var length = 0.0 setget set_length
var moving = true

var anchor: Node2D

func set_length(value: float):
	length = max(value, 8)
	$Texture.rect_size.y = length

func _process(delta):
	
	if not moving:
		if anchor:
			$Line2D.points[0] = to_local(anchor.global_position)
		return
		
	velocity = speed
	$Area2D.position.y -= velocity*delta
	set_length(-$Area2D.position.y / $Texture.rect_scale.y)
	
	if length >= max_length or not Input.is_action_pressed("fire_weapon"):
		self.queue_free()

func _ready():
	$Area2D.connect("body_entered", self, "collided")

func collided(body):
	if not moving:
		return
	if body.has_method("damage"):
		body.damage(get_parent().damage_type, get_parent().damage_amount)
	if body.has_method("attach_grapple"):
		moving = false
		anchor = body.attach_grapple()
		length = global_position.distance_to(anchor.global_position)
		get_parent().attach(anchor, self)
		$Texture.visible = false
		$Line2D.add_point(to_local(anchor.global_position))
		$Line2D.add_point(Vector2.ZERO)
	else:
		self.queue_free()
