extends Node2D

const BLINK_INTERVAL: Array = [1.0, 3.0]
const DOUBLE_BLINK_CHANCE = 0.1
const SPIKE: PackedScene = preload("res://engine/scenes/enemies/kraid/Spike.tscn")

var mouth_open: bool = false setget setMouthOpen
var dominant_foot: bool = true

var sprites: Dictionary = {}
var blink_timer: Timer = Global.get_timer([self, "blink", [true]], null, self)
onready var spike_positions: Node2D = $Sprites/Body/Belly/SpikePositions

func _ready():
	for sprite in $Sprites.get_children():
		sprites[sprite.name.to_lower()] = sprite
	
	onHeadFrameChanged()
	blink_timer.start(Global.rng.randi_range(BLINK_INTERVAL[0], BLINK_INTERVAL[1]))

func _process(delta):
	if Input.is_action_just_pressed("jump"):
		walk(Enums.dir.LEFT, 20)
	elif Input.is_action_just_pressed("arm_weapon"):
		walk(Enums.dir.RIGHT, 20)
	elif Input.is_action_just_pressed("fire_weapon"):
		fireSpike(Global.rng.randi_range(0, spike_positions.get_child_count() - 1))

func setMouthOpen(value: bool):
	mouth_open = value
	sprites["head"].frame = 1 if mouth_open else 0

func walk(direction: int, distance: float):
	assert(direction == Enums.dir.LEFT or direction == Enums.dir.RIGHT)
	
	if $LegAnimationPlayer.is_playing():
		return
	
	var dir = -1 if direction == Enums.dir.LEFT else 1
	
	$MovementTween.interpolate_property(self, "position:x", position.x, position.x + distance * dir, 0.2, Tween.TRANS_SINE)
	
	var animation: String
	if dir == -1:
		animation = "walk_front" if not dominant_foot else "walk_rear"
		animation += "_reverse"
	else:
		animation = "walk_front" if dominant_foot else "walk_rear"
	
	$LegAnimationPlayer.play(animation)
	yield($LegAnimationPlayer, "animation_finished")
	
	dominant_foot = !dominant_foot
	Global.shake_camera(Loader.Samus.camera, 10, 0.2)

func fireSpike(slot: int):
	assert(slot >= 0 and slot < spike_positions.get_child_count())
	
	var spike = SPIKE.instance()
	add_child(spike)
	spike.spawn(spike_positions.get_child(slot).global_position)
	
	pulseBelly()

func blink(start_timer: bool = false):
	$Sprites/Body/Head/MouthOpenEyes.frame = 0
	$Sprites/Body/Head/MouthOpenEyes.play()
	$Sprites/Body/Head/MouthClosedEyes.frame = 0
	$Sprites/Body/Head/MouthClosedEyes.play()
	yield($Sprites/Body/Head/MouthOpenEyes, "animation_finished")
	
	if Global.rng.randf() <= DOUBLE_BLINK_CHANCE:
		yield(blink(false), "completed")
	
	if start_timer:
		blink_timer.start(Global.rng.randi_range(BLINK_INTERVAL[0], BLINK_INTERVAL[1]))

func pulseBelly():
	$Sprites/Body/Belly.frame = 0
	$Sprites/Body/Belly.play()
	$Sprites/Body/Belly/Overlay.frame = 0
	$Sprites/Body/Belly/Overlay.play()

func onHeadFrameChanged():
	var mouth_open = $Sprites/Body/Head.frame == 1
	$Sprites/Body/Head/MouthOpenEyes.visible = mouth_open
	$Sprites/Body/Head/MouthClosedEyes.visible = !mouth_open
