extends Node

signal finished

var animation_id: String
var state_id: String
var directional: bool
var stacked: int
var stacked_position: Vector2

var animation_key: String

var playing: bool = false
var transitioning: bool = false

func _init(animation_id: String, state_id: String, directional: bool = true, stacked: int = Global.dir.NONE, stacked_position: Vector2 = Vector2.ZERO):
	self.animation_id = animation_id
	self.state_id = state_id
	self.directional = directional
	
	self.animation_key = state_id + "_" + animation_id

	self.stacked = stacked
	self.stacked_position = stacked_position

func play(animator, transition: bool = false, retain_frame: bool = false):
	
	if animator.current_animation[stacked] == self:
		return
	elif animator.transitioning(stacked):
		return
	
	var all_sprites = animator.sprites
	var sprites = all_sprites[stacked]
	sprites[0].visible = animator.samus.facing == Global.dir.LEFT
	sprites[1].visible = animator.samus.facing == Global.dir.RIGHT
	
	for spriteset in all_sprites.values():
		if spriteset == sprites:
			continue
		for sprite in spriteset:
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
		sprite.play(self.animation_key + direction)
		if retain_frame:
			sprite.frame = frame
	
	animator.current_animation[stacked] = self
	self.playing = true
	self.transitioning = transition

	yield(sprites[0], "animation_finished")
	emit_signal("finished")
	self.playing = false
	self.transitioning = false
	if animator.current_animation[stacked] == self:
		animator.current_animation[stacked] = null
	
	
