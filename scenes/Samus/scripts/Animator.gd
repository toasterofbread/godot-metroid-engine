extends Node2D

onready var samus: Node2D = get_parent()
const data_json_path = "res://scenes/Samus/animations/data.json"

onready var sprites = {
	false: { # Main
		Enums.dir.LEFT: $sMainLeft,
		Enums.dir.RIGHT: $sMainRight
	},
	true: { # Overlay
		Enums.dir.LEFT: $sOverlayLeft,
		Enums.dir.RIGHT: $sOverlayRight
	}
}

onready var colliders = {
	false: {
		Enums.dir.LEFT: samus.get_node("cMainLeft"),
		Enums.dir.RIGHT: samus.get_node("cMainRight")
	},
	true: {
		Enums.dir.LEFT: samus.get_node("cOverlayLeft"),
		Enums.dir.RIGHT: samus.get_node("cOverlayRight")
	}
}

var current: Dictionary = {
	true: null, # Overlay
	false: null # Main
}

var paused: Dictionary = {
	true: false, # Overlay
	false: false # Main
}

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


func load_from_json(state_id: String, json_key = null) -> Dictionary:
	if json_key == null:
		json_key = state_id
	
	var data = Global.load_json(data_json_path)[json_key]
	
	for animation in data:
		if not "state_id" in data[animation]:
			data[animation]["state_id"] = state_id
		var id = animation
		data[animation]["position_node_path"] = json_key + "/" + animation
		if "id" in data[animation]:
			id = data[animation]["id"]
		
		if "leftPos" in data[animation]:
			data[animation]["leftPos"] = Vector2(data[animation]["leftPos"][0], data[animation]["leftPos"][1])
		if "rightPos" in data[animation]:
			data[animation]["rightPos"] = Vector2(data[animation]["rightPos"][0], data[animation]["rightPos"][1])
		
		data[animation] = SamusAnimation.new(self, id, data[animation])
	return data
