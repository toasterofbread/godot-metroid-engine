extends Node2D

var velocity: float = 0.0
const speed: float = 750.0
const acceleration: float = 5.0

var max_length = 450
var length = 0.0 setget set_length
var moving = true

var fire_pos = null
var anchor: Node2D

onready var parent = get_parent()

func set_length(value: float, half=false):
	length = min(max(value, 8), max_length/2 if half else max_length)
	$Texture.rect_size.y = length
	return length == max_length

func _process(delta):
	
	if not moving:
		if anchor:
			$Line2D.points[0] = to_local(anchor.global_position)
			if fire_pos:
				fire_pos.queue_free()
			fire_pos = parent.get_fire_pos()
			if fire_pos:
				$Line2D.points[1] = to_local(fire_pos.global_position)
		return
		
	velocity = speed
	$Area2D.position.y -= velocity*delta
	
	if set_length(-$Area2D.position.y / $Texture.rect_scale.y) or not Input.is_action_pressed("fire_weapon"):
		self.queue_free()

func _ready():
	$Area2D.connect("body_entered", self, "collided")
	z_as_relative = false
	z_index = Enums.Layers.PROJECTILE

func collided(body):
	if not moving:
		return
	if body.has_method("damage"):
		body.damage(parent.damage_type, parent.damage_amount, $Area2D.get_child(0).global_position)
	if body.has_method("attach_grapple"):
		fire_pos = parent.get_fire_pos()
		moving = false
		anchor = body.attach_grapple()
		length = global_position.distance_to(anchor.global_position)
		parent.attach(anchor, self)
		$Texture.visible = false
		$Line2D.add_point(to_local(anchor.global_position))
		$Line2D.add_point(Vector2(0, 0))
	else:
		self.queue_free()
