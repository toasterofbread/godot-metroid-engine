extends Node

signal animation_finished

var samus: Node2D
onready var sprites = self.get_children()

var animation_key: String = ""
var animation_id: String = ""
var animation_state: String = ""
var playing_transition = false

func _ready():
	samus = get_parent()

# Format the provided animation id with Samus's state and facing direction
# Returns a string that can be provided to the AnimatedSprite
func get_animation_key(animation_id: String, state_id = null):
	if state_id == null:
		state_id = samus.current_state.id
	var key = state_id + "_" + animation_id
	if samus.facing == samus.face.LEFT:
		key = key + "_left"
	elif samus.facing == samus.face.RIGHT:
		key = key + "_right"
	return key
	
func _process(_delta):
	
	# Set playing_transition to false if Samus's animation has finished
	# Workaround because using the sprite's finished signal is inaccurate for some reason
	if $LeftSprite.frame == $LeftSprite.frames.get_frame_count($LeftSprite.animation) - 1 and playing_transition:
		playing_transition = false
		Global.start_timer("transition_cooldown", 0.05, {})

# Plays an animation based on Samus's state and facing direction
# Will not play the animation if the same one is already playing or a transition is playing
func play(id: String, args: Dictionary):
	if playing_transition:
		return
	
	var default_args = {"yield": false, "transition": false, "state_id": null, "retain_frame": false}
	for key in default_args:
		if not key in args:
			args[key] = default_args[key]

	playing_transition = args["transition"]
	
	var key = get_animation_key(id, args["state_id"])
	if animation_key == key:
		return
	
	animation_key = key
	animation_id = id
	animation_state = samus.current_state.id
	
	if samus.facing == samus.face.LEFT:
		$LeftSprite.visible = true
		$RightSprite.visible = false
	elif samus.facing == samus.face.RIGHT:
		$RightSprite.visible = true
		$LeftSprite.visible = false
	
	var frame = $LeftSprite.frame
	for sprite in sprites:
		sprite.play(animation_key)
		if args["retain_frame"]:
			sprite.frame = frame
	
	if args["yield"]:
		yield($LeftSprite, "animation_finished")
		emit_signal("animation_finished")
