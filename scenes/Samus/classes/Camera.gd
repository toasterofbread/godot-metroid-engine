extends Camera2D
class_name SamusCamera

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	self.zoom = Vector2(0.25, 0.25)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
