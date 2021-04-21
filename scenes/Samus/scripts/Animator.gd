extends Node2D

signal animation_finished

var samus: Node2D
var Animation = preload("res://scenes/Samus/classes/Animation.gd")

onready var sprites = {
	Global.dir.UP: [$LeftStackedSprite/TopSprite, $RightStackedSprite/TopSprite], 
	Global.dir.DOWN: [$LeftStackedSprite/BottomSprite, $RightStackedSprite/BottomSprite], 
	Global.dir.NONE: [$LeftSprite, $RightSprite]}
var current_animation = {Global.dir.UP: null, Global.dir.DOWN: null, Global.dir.NONE: null}

func _ready():
	samus = get_parent()

func transitioning(stacked: int = Global.dir.NONE):
	if current_animation[stacked] == null:
		return false
	return current_animation[stacked].transitioning

func animation_id(stacked: int = Global.dir.NONE):
	if current_animation[stacked] == null:
		return ""
	return current_animation[stacked].animation_id
