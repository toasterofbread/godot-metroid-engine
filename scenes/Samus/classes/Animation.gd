extends Node
class_name SamusAnimation

# Constants set on initialisation
var id: String
var state_id: String
var transition: bool
var overlay: bool
var sprites: Dictionary
var positions: Dictionary
var position: Vector2
var directional: bool
var animation_keys: Dictionary
var animation_length: float
var full: bool

# Nodes
var animator: Node2D

# Status variables
var playing: bool = false
var transitioning: bool = false
var cooldown: bool = false

# Constants
const _default_args = {
	"transition": false,
	"overlay": false,
	"position": Vector2.ZERO,
	"directional": true,
	"full": true
}
const cooldown_time: float = 0.04


func _init(_animator: Node2D, _id: String, _state_id: String, args: Dictionary = {}):
	
	# Required args
	self.animator = _animator
	self.id = _id
	self.state_id = _state_id
	
	# Optional args
	if args == null:
		args = _default_args
	
	for arg in _default_args:
		if not arg in args:
			self.set(arg, _default_args[arg])
		else:
			self.set(arg, args[arg])
	
	self.sprites = self.animator.sprites[self.overlay]
	
	self.positions = {
		Global.dir.LEFT: self.position,
		Global.dir.RIGHT: self.position + Vector2(7, 0)
	}
	
	# Store animation key
	self.animation_keys = {
		Global.dir.LEFT: self.state_id + "_" + self.id + ("_left" if self.directional else ""),
		Global.dir.RIGHT: self.state_id + "_" + self.id + ("_right" if self.directional else "")
	}
	
	if sprites[Global.dir.LEFT].frames.get_animation_speed(animation_keys[Global.dir.LEFT]) == 0:
		self.animation_length = 0
	else:
		self.animation_length = sprites[Global.dir.LEFT].frames.get_frame_count(animation_keys[Global.dir.LEFT]) / sprites[Global.dir.LEFT].frames.get_animation_speed(animation_keys[Global.dir.LEFT])
#	if self.state_id == "jump":
#		print(str(animation_length) + self.id)
func play(retain_frame: bool = false, ignore_pasued: bool = false):
	
#	if animator.transitioning(overlay):
#		return
	if animator.paused[overlay]:
		if ignore_pasued:
			return
		else:
			animator.paused[overlay] = false
	
	for dir in sprites:
		
		# Set position
		sprites[dir].position = positions[dir]
	
		# Set visibility
		sprites[dir].visible = animator.samus.facing == dir
		if not animator.current[!overlay] or (self.full and !overlay):
			for sprite in animator.sprites[!overlay].values():
				sprite.visible = false
	
		# Play animation
		var frame = sprites[dir].frame
		sprites[dir].play(self.animation_keys[dir])
		if retain_frame:
			sprites[dir].frame = frame
	
	if not animator.transitioning():
		animator.current[overlay] = self
	self.transitioning = self.transition
	self.playing = true
	
#	if self.id == "legs_start":
#		print("YIELD START")
	yield(Global.wait(animation_length), "completed")
#	if self.id == "legs_start":
#		print("YIELD END")
	
	self.transitioning = false
	
	if animator.current[overlay] == self and self.transition:
		self.cooldown = true
		yield(Global.wait(cooldown_time), "completed")
		self.cooldown = false
	
	self.playing = false
