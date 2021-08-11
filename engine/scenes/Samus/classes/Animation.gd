extends Node
class_name SamusAnimation

signal finished

# Constants set on initialisation
var id: String
var state_id: String
var transition: bool
var overlay: bool
var overlay_above: bool
var sprites: Dictionary
var positions: Dictionary
var directional: bool
var animation_keys: Dictionary
var animation_length: float
var full: bool
var position_node_path: String
var step_frames: Array
var no_trail: bool
var rotation_degrees: float

# Nodes
var Animator: Node2D
var Samus: KinematicBody2D

# Status variables
var playing: bool = false
var transitioning: bool = false
var cooldown: bool = false
var cache = {}

# Constants
const _default_args = {
	"transition": false,
	"overlay": false,
	"overlay_above": false,
	"leftPos": Vector2(0, 0),
	"rightPos": Vector2(0, 0),
	"directional": true,
	"full": true,
	"state_id": null,
	"position_node_path": null,
	"step_frames": [],
	"no_trail": false,
	"rotation_degrees": 0.0,
}
const cooldown_time: float = 0.04
var frames: SpriteFrames

func process():
	var frame = sprites[Samus.facing].frame
	if frame in step_frames:
		Samus.footstep(frame)

func _init(_animator: Node2D, _id: String, args: Dictionary = {}):
	
	# Required args
	Animator = _animator
	Samus = Animator.Samus
	id = _id
	
	for arg in _default_args:
		if not arg in args:
			args[arg] = _default_args[arg]
			set(arg, _default_args[arg])
		else:
			set(arg, args[arg])
	
	sprites = Animator.sprites[overlay]
	
	positions = {
		Enums.dir.LEFT: args["leftPos"],
		Enums.dir.RIGHT: args["rightPos"]
	}
	
	# Store animation key
	animation_keys = {
		Enums.dir.LEFT: state_id + "_" + id + ("_left" if directional else ""),
		Enums.dir.RIGHT: state_id + "_" + id + ("_right" if directional else "")
	}
	
	if sprites[Enums.dir.LEFT].frames.get_animation_speed(animation_keys[Enums.dir.LEFT]) == 0:
		animation_length = 0
	else:
		animation_length = sprites[Enums.dir.LEFT].frames.get_frame_count(animation_keys[Enums.dir.LEFT]) / sprites[Enums.dir.LEFT].frames.get_animation_speed(animation_keys[Enums.dir.LEFT])
	
	frames = sprites.values()[0].frames
	
func play(retain_frame:=false, speed:=1.0, ignore_paused:bool=false):
	
#	if Animator.paused[overlay]:
#		if ignore_pasued:
#			return
#		else:
#			Animator.paused[overlay] = false
	
	var new_cache = {
		"facing": Animator.Samus.facing,
		"speed": speed
	}
	
	if Animator.current[overlay] == self and false:
		var skip_animation = true
		for key in new_cache:
			if new_cache[key] != cache[key]:
				skip_animation = false
				break
		if skip_animation:
			return
	cache = new_cache
	
	if overlay:
		Animator.overlay_above = overlay_above
	Samus.set_collider(self)
	
	for dir in sprites:
		
		var sprite: AnimatedSprite = sprites[dir]
		
		# Set position
		sprite.position = positions[dir]
		
		# Set rotation
		sprite.rotation_degrees = rotation_degrees
		if dir == Enums.dir.LEFT:
			sprite.rotation_degrees *= -1
		
		# Set visibility
		sprite.visible = Samus.facing == dir
		if not Animator.current[!overlay] or (full and !overlay):
			for s in Animator.sprites[!overlay].values():
				s.visible = false
		
		if not retain_frame:
			for s in sprites.values():
				s.frame = 0
		
		# Set trail emission flag
		sprite.set_meta("no_trail", no_trail)
		
		# Play animation
		var frame = sprites[dir].frame
		sprite.play(animation_keys[dir], speed<0)
		sprite.pause_mode = Node.PAUSE_MODE_PROCESS if ignore_paused else Node.PAUSE_MODE_STOP
		sprite.speed_scale = abs(speed)
		if retain_frame:
			sprite.frame = frame
		if sprite.frame == 0 and speed<0:
			sprite.frame = frames.get_frame_count(animation_keys[dir]) - 1
	
	if not Animator.transitioning():
		Animator.current[overlay] = self
	Animator.queued[overlay] = self
	transitioning = transition
	playing = true
	
	yield(Global.wait(animation_length, ignore_paused), "completed")
	transitioning = false
	emit_signal("finished")
	
	if Animator.current[overlay] == self and transition:
		cooldown = true
		yield(Global.wait(cooldown_time, ignore_paused), "completed")
		cooldown = false
	
	playing = false
