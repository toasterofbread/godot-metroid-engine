extends Node2D

var head_open: bool = false setget setHeadOpen
var dominant_foot: bool = true # false = rear, true = front

var sprites: Dictionary = {}

func _ready():
	for sprite in $Sprites.get_children():
		sprites[sprite.name.to_lower()] = sprite

func _process(delta):
	if Input.is_action_just_pressed("jump"):
		walk(Enums.dir.LEFT, 20)
	elif Input.is_action_just_pressed("arm_weapon"):
		walk(Enums.dir.RIGHT, 20)

func setHeadOpen(value: bool):
	head_open = value
	sprites["head"].frame = 1 if head_open else 0

func walk(direction: int, distance: float):
	assert(direction == Enums.dir.LEFT or direction == Enums.dir.RIGHT)
	
	if $LegAnimationPlayer.is_playing():
		return
	
	var dir = -1 if direction == Enums.dir.LEFT else 1
	
	$MovementTween.interpolate_property(self, "position:x", position.x, position.x + distance * dir, 0.2, Tween.TRANS_SINE)
	
	var animation = "walk_front" if dominant_foot else "walk_rear"
	if dir == -1:
		animation += "_reverse"
	
	$LegAnimationPlayer.play(animation)
	yield($LegAnimationPlayer, "animation_finished")
	
	Global.shake_camera(Loader.Samus.camera, 10, 0.2)
