extends Node2D

onready var samus: KinematicBody2D = get_parent()
var Animation = preload("res://scenes/Samus/classes/Animation.gd")

onready var sprites = {
	Global.dir.UP: [$LeftStackedSprite/TopSprite, $RightStackedSprite/TopSprite], 
	Global.dir.DOWN: [$LeftStackedSprite/BottomSprite, $RightStackedSprite/BottomSprite], 
	Global.dir.NONE: [$LeftSprite, $RightSprite]}
onready var stacked_sprites = [$LeftStackedSprite, $RightStackedSprite]
var current_animation = {Global.dir.UP: null, Global.dir.DOWN: null, Global.dir.NONE: null}

var armed = false
var suits = {
	"power": [preload("res://scenes/Samus/animations/power.tres"), preload("res://scenes/Samus/animations/power_armed.tres")]
}
var current_suit = "power"

func _process(_delta):
	
	if transitioning() or "transition_cooldown" in Global.timers:
		return
	for dir in current_animation.keys():
		if current_animation[dir] == null:
			continue
		for sprite in sprites[dir]:
			sprite.playing = !current_animation[dir].paused

func animation_id(stacked: int = Global.dir.NONE):
	if current_animation[stacked] == null:
		return ""
	return current_animation[stacked].animation_id

func transitioning(stacked: int = Global.dir.NONE):
	if current_animation[stacked] == null:
		return false
	return current_animation[stacked].transitioning

func set_armed(armed: bool):
	if armed == self.armed:
		return
	
	self.armed = armed
	for set in sprites.values():
		for sprite in set:
			sprite.frames = suits[current_suit][int(armed)]
	
