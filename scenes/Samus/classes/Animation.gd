extends Node

signal finished

var animation_id: String
var state_id: String
var directional: bool
var stacked: int
var stacked_position: Vector2
var sprites: Array = []
var animator

var animation_key: String
var prev_direction = Global.dir.NONE

var paused: bool = false
var transitioning: bool = false

func _init(animator, animation_id: String, state_id: String, directional: bool = true, stacked: int = Global.dir.NONE, stacked_position: Vector2 = Vector2.ZERO):
	self.animator = animator
	self.animation_id = animation_id
	self.state_id = state_id
	self.directional = directional
	
	self.animation_key = state_id + "_" + animation_id

	self.stacked = stacked
	self.stacked_position = stacked_position

func play(transition: bool = false, retain_frame: bool = false, ignore_transition: bool = false):
	if animator.current_animation[stacked] == self and not paused and animator.samus.facing == prev_direction:
		retain_frame = true
	elif animator.transitioning(stacked) and not ignore_transition:
		return
	
	prev_direction = animator.samus.facing
	
	sprites = animator.sprites[stacked]
	sprites[0].visible = animator.samus.facing == Global.dir.LEFT
	sprites[1].visible = animator.samus.facing == Global.dir.RIGHT

	if stacked != Global.dir.NONE:
		sprites[0].position = self.stacked_position
		sprites[1].position = self.stacked_position
	
	match stacked:
		Global.dir.NONE:
			for sprite in animator.sprites[Global.dir.UP] + animator.sprites[Global.dir.DOWN]:
				sprite.visible = false
		_:
			for sprite in animator.sprites[Global.dir.NONE]:
				sprite.visible = false
	
	var direction = ""
	if self.directional:
		match animator.samus.facing:
			Global.dir.LEFT:
				direction = "_left"
			Global.dir.RIGHT:
				direction = "_right"
		
	for sprite in sprites:
		var frame = sprite.frame
		sprite.playing = true
		sprite.play(self.animation_key + direction)
		if retain_frame:
			sprite.frame = frame
	
	animator.current_animation[stacked] = self
	self.paused = false
	self.transitioning = transition

	yield(sprites[0], "animation_finished")
	emit_signal("finished")
	self.transitioning = false
	if animator.current_animation[stacked] == self:
		animator.current_animation[stacked] = null
