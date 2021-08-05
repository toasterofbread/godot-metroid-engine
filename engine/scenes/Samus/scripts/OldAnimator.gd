extends Node2D

onready var samus: KinematicBody2D = get_parent()
var Animation = preload("res://engine/scenes/Samus/classes/Animation.gd")

onready var sprites = {
	Enums.dir.UP: [$LeftStackedSprite/TopSprite, $RightStackedSprite/TopSprite], 
	Enums.dir.DOWN: [$LeftStackedSprite/BottomSprite, $RightStackedSprite/BottomSprite], 
	Enums.dir.NONE: [$LeftSprite, $RightSprite]}
onready var stacked_sprites = [$LeftStackedSprite, $RightStackedSprite]
var current_animation = null

onready var cooldown_timer = Timer.new()

var suits = {
	"power": [preload("res://engine/scenes/Samus/animations/power.tres"), preload("res://engine/scenes/Samus/animations/power_armed.tres")]
}
var current_suit = "power"

func _ready():
	cooldown_timer.one_shot = true
	self.add_child(cooldown_timer)

func _process(delta):
	
	var to_check = []
	if current_animation is Dictionary:
		for animation in current_animation.values():
			to_check.append(animation)
	else:
		to_check.append(current_animation)
	
	for animation in to_check:
		for sprite in sprites[animation.stacked]:
			sprite.playing = !animation.paused

#func _process(_delta):
##	return
#	if transitioning():
#		return
#	for dir in sprites.keys():
#		if current_animation[dir] == null:
#			continue
#		for sprite in sprites[dir]:
#			sprite.playing = !current_animation[dir].paused

func current(stacked: int = Enums.dir.UP) -> SamusAnimation:
	
	if current_animation == null:
		return null

	if current_animation is Dictionary:
		if stacked in current_animation:
			return current_animation[stacked]
		else:
			return current_animation.values()[0]
	else:
		return current_animation

func transitioning(stacked: int = Enums.dir.UP, cooldown: bool = true) -> bool:
	
	if current_animation == null:
		return false
	else:
		return current().transitioning or (cooldown_timer.time_left > 0 and cooldown)

func set_armed(set_to_armed: bool):
	if samus.armed == set_to_armed:
		return
	
	samus.armed = set_to_armed
	
	for set in sprites.values():
		for sprite in set:
			sprite.frames = suits[current_suit][int(set_to_armed)]
	
	samus.weapons.update_weapon_icons()
