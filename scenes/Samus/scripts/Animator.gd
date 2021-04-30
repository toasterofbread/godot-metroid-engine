extends Node2D

onready var samus: Node2D = get_parent()

onready var sprites = {
	true: { # Overlay
		Global.dir.LEFT: $sMainLeft,
		Global.dir.RIGHT: $sMainRight
	},
	false: { # Main
		Global.dir.LEFT: $sOverlayLeft,
		Global.dir.RIGHT: $sOverlayRight
	}
}

onready var default_positions = {
	true: $sOverlayLeft.position, # Overlay
	false: $sMainLeft.position # Main
}

var current: Dictionary = {
	true: null, # Overlay
	false: null # Main
}

var paused: Dictionary = {
	true: false, # Overlay
	false: false # Main
}

onready var Animation = preload("res://scenes/Samus/classes/Animation.gd")

var suits = {
	"power": [preload("res://scenes/Samus/animations/power.tres"), preload("res://scenes/Samus/animations/power_armed.tres")]
}
var current_suit = "power"

func _ready():
	for set in sprites.values():
		for sprite in set.values():
			sprite.visible = false
			sprite.connect("animation_finished", self, "sprite_animation_finished", [sprite])

func sprite_animation_finished(sprite: AnimatedSprite):
	pass

func pause(overlay: bool = false):
	
	if paused[overlay]:
		return
	
	for sprite in sprites[overlay].values():
		sprite.stop()

func resume(overlay: bool = false):
	
	if not paused[overlay]:
		return
	
	for sprite in sprites[overlay].values():
		sprite.play()

func set_armed(set_to_armed: bool):
	if samus.armed == set_to_armed:
		return
	
	samus.armed = set_to_armed
	
	for set in sprites.values():
		for sprite in set.values():
			sprite.frames = suits[current_suit][int(set_to_armed)]
	
	samus.weapons.update_weapon_icons()

func transitioning(overlay: bool = false, ignore_cooldown: bool = false):
	if current[overlay] == null:
		return false
	else:
		return current[overlay].transitioning or (current[overlay].cooldown and not ignore_cooldown)

#func facing_changed():
#	for set in sprites.values():
#		for dir in set:
#			set[dir].visible = dir == samus.facing
