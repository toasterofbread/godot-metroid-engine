extends AnimatedSprite

const sizes = [16, 12, 8, 4]

# Called when the node enters the scene tree for the first time.
func _ready():
	play(str(Global.random_array_item(sizes)))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
