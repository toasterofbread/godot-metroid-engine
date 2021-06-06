extends Node
class_name SamusAnimation

signal finished

# Constants set on initialisation
var id: String
var state_id: String
var transition: bool
var overlay: bool
var sprites: Dictionary
var positions: Dictionary
var directional: bool
var animation_keys: Dictionary
var animation_length: float
var full: bool
var position_node_path: String


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
	"leftPos": Vector2(0, 0),
	"rightPos": Vector2(0, 0),
	"directional": true,
	"full": true,
	"state_id": null,
	"position_node_path": null
}
const cooldown_time: float = 0.04
var frames: SpriteFrames

func _init(_animator: Node2D, _id: String, args: Dictionary = {}):
	
	# Required args
	self.Animator = _animator
	self.Samus = Animator.Samus
	self.id = _id
	
	for arg in _default_args:
		if not arg in args:
			args[arg] = _default_args[arg]
			self.set(arg, _default_args[arg])
		else:
			self.set(arg, args[arg])
	
	self.sprites = self.Animator.sprites[self.overlay]
	
	self.positions = {
		Enums.dir.LEFT: args["leftPos"],
		Enums.dir.RIGHT: args["rightPos"]
	}
	
	# Store animation key
	self.animation_keys = {
		Enums.dir.LEFT: self.state_id + "_" + self.id + ("_left" if self.directional else ""),
		Enums.dir.RIGHT: self.state_id + "_" + self.id + ("_right" if self.directional else "")
	}
	
	if sprites[Enums.dir.LEFT].frames.get_animation_speed(animation_keys[Enums.dir.LEFT]) == 0:
		self.animation_length = 0
	else:
		self.animation_length = sprites[Enums.dir.LEFT].frames.get_frame_count(animation_keys[Enums.dir.LEFT]) / sprites[Enums.dir.LEFT].frames.get_animation_speed(animation_keys[Enums.dir.LEFT])
	
	frames = sprites.values()[0].frames
	
func play(retain_frame:=false, speed:=1.0):
	
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
	
	Samus.set_collider(self)
	
	for dir in sprites:
		
		# Set position
		sprites[dir].position = positions[dir]
	
		# Set visibility
		sprites[dir].visible = Samus.facing == dir
		if not Animator.current[!overlay] or (self.full and !overlay):
			for sprite in Animator.sprites[!overlay].values():
				sprite.visible = false
	
		if not retain_frame:
			for sprite in sprites.values():
				sprite.frame = 0
	
		# Play animation
		var frame = sprites[dir].frame
		sprites[dir].play(self.animation_keys[dir], speed<0)
		sprites[dir].speed_scale = abs(speed)
		if retain_frame:
			sprites[dir].frame = frame
		if sprites[dir].frame == 0 and speed<0:
			sprites[dir].frame = frames.get_frame_count(animation_keys[dir]) - 1
	
	if not Animator.transitioning():
		Animator.current[overlay] = self
	self.transitioning = self.transition
	self.playing = true
	
	
	yield(Global.wait(animation_length), "completed")
	
	self.transitioning = false
	emit_signal("finished")
	
	if Animator.current[overlay] == self and self.transition:
		self.cooldown = true
		yield(Global.wait(cooldown_time), "completed")
		self.cooldown = false
	
	self.playing = false
