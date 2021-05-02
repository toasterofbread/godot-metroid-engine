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
	true: Vector2(0, 0), # Overlay
	false: Vector2(0, 0) # Main
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

onready var suits = {
	"power": [preload("res://scenes/Samus/animations/power.tres"), preload("res://scenes/Samus/animations/power_armed.tres")]
}
var current_suit = "power"

func _ready():
	if Global.config["turn_speed"] is int or Global.config["turn_speed"] is float:
		for suit in suits.values():
			for frames in suit:
				for anim in frames.get_animation_names():
					if frames.get_animation_speed(anim) == 60 and "turn" in anim.to_lower():
						frames.set_animation_speed(anim, Global.config["turn_speed"])
	for set in sprites.values():
		for sprite in set.values():
			sprite.frames = suits.values()[0][0]
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

func transitioning(overlay: bool = false, ignore_cooldown: bool = false, DEBUG_output_id: bool = false):
	if current[overlay] == null:
		return false
	else:
		if DEBUG_output_id:
			print(current[overlay].id)
		return current[overlay].transitioning or (current[overlay].cooldown and not ignore_cooldown)

#func facing_changed():
#	for set in sprites.values():
#		for dir in set:
#			set[dir].visible = dir == samus.facing
