extends Node2D
class_name SpriteTrailEmitter

onready var TrailSpriteTemplate: Node2D = $TrailSprite

export var profiles: Dictionary = {
	"default": {
		"frequency": 1, # int
		"linger_time": 1.0, # float
		"fade_out": false, # bool
		"modulate": null, # Color or NodePath or null
		"material": null # Material or NodePath or null
	}
}

var current_profile = null setget set_current_profile
var current_profile_data = null
export(Array, NodePath) var sprites: = []
export var trail_z_index: int = 0

onready var TrailAnchor: Node2D = Global.get_anchor("SpriteTrailEmitters/0")

func set_current_profile(value, force_update:=false):
	
	if not force_update and value == current_profile:
		return
	
	if current_profile == null:
		$EmissionTimer.start()
	
	current_profile = value
	if current_profile == null:
		current_profile_data = null
		$EmissionTimer.stop()
		return
	
	current_profile_data = profiles[current_profile]
	$EmissionTimer.wait_time = 1.0 / current_profile_data["frequency"]
	TrailSpriteTemplate.get_node("DeletionTimer").wait_time = current_profile_data["linger_time"]
	
	for property in ["modulate", "material"]:
		if current_profile_data[property] is NodePath:
			current_profile_data[property] = get_node_or_null(current_profile_data[property])

func _ready():
	
	remove_child(TrailSpriteTemplate)
	TrailSpriteTemplate.get_node("DeletionTimer").autostart = true
	TrailAnchor.z_as_relative = false
	
	var spritepaths = sprites.duplicate()
	sprites.clear()
	for spritepath in spritepaths:
		var sprite = get_node_or_null(spritepath)
		if sprite != null:
			sprites.append(sprite)
	
	set_current_profile(current_profile, true)


func clear_trail():
	for node in TrailAnchor.get_children():
		node.queue_free()

func emit_trail():
	
	for sprite in sprites:
		if not sprite.visible or (sprite.has_meta("no_trail") and sprite.get_meta("no_trail")):
			continue
		
		var SpriteContainer: Node2D = TrailSpriteTemplate.duplicate()
		var TrailSprite: Node2D = sprite.duplicate() if current_profile_data["sprite"] == null else Sprite.new()
		TrailSprite.z_index = trail_z_index
		SpriteContainer.add_child(TrailSprite)
		
		TrailAnchor.add_child(SpriteContainer)
		SpriteContainer.init(TrailSprite, current_profile_data)
		TrailSprite.global_position = sprite.global_position
