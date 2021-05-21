tool
extends CollisionShape2D
class_name CameraChunk

export var apply_left: = false
export var apply_right: = false
export var apply_top: = false
export var apply_bottom: = false

export var alt: = false

var area: Area2D
var room: Room

func _ready():
	
	if Engine.is_editor_hint() and self.shape == null:
		self.shape = RectangleShape2D.new()
		self.shape.extents = Vector2(1920, 1080)/5
		self.modulate = Color("00ff87")
		return
	
	yield(get_parent(), "ready")
	room = get_parent().get_parent()
	
	area = Area2D.new()
	area.pause_mode = Node.PAUSE_MODE_PROCESS
	self.get_parent().add_child(area)
	Global.reparent_child(self, area)
	
	area.connect("body_entered", self, "body_entered")
	area.connect("body_exited", self, "body_exited")

func get_limits():
	var limits = {
		"limit_left": -10000000,
		"limit_right": 10000000,
		"limit_top": -10000000,
		"limit_bottom": 10000000
	}
	
	var pos = global_position
	
	if apply_left:
		limits["limit_left"] = pos.x - shape.extents.x
	if apply_right:
		limits["limit_right"] = pos.x + shape.extents.x
	if apply_top:
		limits["limit_top"] = pos.y - shape.extents.y
	if apply_bottom:
		limits["limit_bottom"] = pos.y + shape.extents.y
	
	return limits

func body_entered(body):
	if body == Loader.Samus:
		body.camerachunk_entered(self)

func body_exited(body):
	if body == Loader.Samus:
		body.camerachunk_exited(self)
