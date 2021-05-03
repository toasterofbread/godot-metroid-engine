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
var size
var position_node_path: String

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
	"leftPos": Vector2(0, 0),
	"rightPos": Vector2(0, 0),
	"directional": true,
	"full": true,
	"state_id": null,
	"position_node_path": null
}
const cooldown_time: float = 0.04

func get_texture_size(texture: Texture):

	# mask is initially an empty array
	var mask = []

	# get image data
	var image = texture.get_data()

	# lock the image so get_pixel() can be called on it
	image.lock()

	var max_coord = Vector2.ZERO
	var min_coord = Vector2.ZERO

	# add non-transparent pixel coordinates to mask
	for x in image.get_width():
		for y in image.get_height():
			if image.get_pixel(x,y)[3] != 0:
				
				max_coord.x = max(x, max_coord.x)
				max_coord.y = max(y, max_coord.y)
				
				min_coord.x = min(x, min_coord.x)
				min_coord.y = min(y, min_coord.y)

	return (max_coord - min_coord) / 2

func _init(_animator: Node2D, _id: String, args: Dictionary = {}):
	
	# Required args
	self.animator = _animator
	self.id = _id
	
	for arg in _default_args:
		if not arg in args:
			args[arg] = _default_args[arg]
			self.set(arg, _default_args[arg])
		else:
			self.set(arg, args[arg])
	
	self.sprites = self.animator.sprites[self.overlay]
	
	self.positions = {
		Enums.dir.LEFT: args["leftPos"],
		Enums.dir.RIGHT: args["rightPos"]
	}
	
	# Store animation key
	self.animation_keys = {
		Enums.dir.LEFT: self.state_id + "_" + self.id + ("_left" if self.directional else ""),
		Enums.dir.RIGHT: self.state_id + "_" + self.id + ("_right" if self.directional else "")
	}
	
	# Get sprite size
#	if sprites[Enums.dir.LEFT].frames.get_frame(self.animation_keys[Enums.dir.LEFT], 0):
#		self.size = get_texture_size(sprites[Enums.dir.LEFT].frames.get_frame(self.animation_keys[Enums.dir.LEFT], 0))
	
	if sprites[Enums.dir.LEFT].frames.get_animation_speed(animation_keys[Enums.dir.LEFT]) == 0:
		self.animation_length = 0
	else:
		self.animation_length = sprites[Enums.dir.LEFT].frames.get_frame_count(animation_keys[Enums.dir.LEFT]) / sprites[Enums.dir.LEFT].frames.get_animation_speed(animation_keys[Enums.dir.LEFT])
	
	
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
#			for collider in animator.colliders[!overlay].values():
#				collider.disabled = true
	
		if not retain_frame:
			for sprite in sprites.values():
				sprite.frame = 0
	
		# Play animation
		var frame = sprites[dir].frame
		sprites[dir].play(self.animation_keys[dir])
		if retain_frame:
			sprites[dir].frame = frame
		
#		if self.size:
#			animator.colliders[overlay][dir].shape.extents = self.size
#		animator.colliders[overlay][dir].position = positions[dir]
#		animator.colliders[overlay][dir].disabled = animator.samus.facing != dir
	
	if not animator.transitioning():
		animator.current[overlay] = self
	self.transitioning = self.transition
	self.playing = true
	
	
	yield(Global.wait(animation_length), "completed")
	
	self.transitioning = false
	emit_signal("finished")
	
	if animator.current[overlay] == self and self.transition:
		self.cooldown = true
		yield(Global.wait(cooldown_time), "completed")
		self.cooldown = false
	
	self.playing = false
