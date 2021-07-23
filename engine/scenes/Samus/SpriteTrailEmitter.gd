extends Node2D
class_name SpriteTrailEmitter

onready var trail_sprite_script = preload()

export var trail_enabled: bool = false setget set_trail_enabled
export var emissions_per_second: int = 1
export var linger_time: float = 1.0
export var fade_out: bool = false
export(Array, NodePath) var sprites: = []

export var ModulateNodePath: NodePath
export var MaterialNodePath: NodePath
var ModulateNode
var MaterialNode

onready var TrailAnchor: Node2D = Global.get_anchor("SpriteTrailEmitters/0")
onready var DeletionTimerTemplate: Timer = $DeletionTimer

func _ready():
	$EmissionTimer.wait_time = 1.0 / emissions_per_second
	remove_child(DeletionTimerTemplate)
	DeletionTimerTemplate.autostart = true
	DeletionTimerTemplate.wait_time = linger_time
	
	if ModulateNodePath != null:
		ModulateNode = get_node_or_null(ModulateNodePath)
	if MaterialNodePath != null:
		MaterialNode = get_node_or_null(MaterialNodePath)
	
	var spritepaths = sprites.duplicate()
	sprites.clear()
	for spritepath in spritepaths:
		var sprite = get_node_or_null(spritepath)
		if sprite != null:
			sprites.append(sprite)
	
	set_trail_enabled(trail_enabled)

func set_trail_enabled(value: bool):
	if value == trail_enabled:
		return
	trail_enabled = value
	if trail_enabled:
		$EmissionTimer.start()
	else:
		$EmissionTimer.stop()

func clear_trail():
	for node in TrailAnchor.get_children():
		node.queue_free()

func emit_trail():
	for sprite in sprites:
		if not sprite.visible:
			continue
		var TrailSprite: Node = sprite.duplicate()
		if TrailSprite is AnimatedSprite:
			TrailSprite.playing = false
		TrailAnchor.add_child(TrailSprite)
		TrailSprite.global_position = sprite.global_position
		var DeletionTimer: Timer = DeletionTimerTemplate.duplicate()
		DeletionTimer.connect("timeout", TrailSprite, "queue_free")
		TrailSprite.add_child(DeletionTimer)
		
		if ModulateNode:
			TrailSprite.modulate = ModulateNode.modulate
		if MaterialNode:
			TrailSprite.material = MaterialNode.material.duplicate()
			TrailSprite.use_parent_material = false
