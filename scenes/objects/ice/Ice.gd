tool
extends Control

onready var shard = $Shard

var textures = [
	load("res://sprites/objects/ice/sIceShard_0.png"),
	load("res://sprites/objects/ice/sIceShard_1.png"),
	load("res://sprites/objects/ice/sIceShard_2.png"),
	load("res://sprites/objects/ice/sIceShard_3.png"),
]
var texture_sizes = [
	Vector2(14, 15),
	Vector2(12, 10),
	Vector2(13, 14),
	Vector2(10, 19),
]
const h_separation = -6

export var sd: = 0
export var update_size = false setget update_size

func _ready():
	
	if Engine.editor_hint:
		return
	
	update_size()
	remove_child(shard)
#	$StaticBody2D.connect("damage", self, "damage")

func update_size(value:=false):
	update_size = false
	
	var rng = RandomNumberGenerator.new()
	if sd != 0:
		seed(sd)
		if Engine.editor_hint:
			print("Seed: " + str(sd))
	else:
		rng.randomize()
		if Engine.editor_hint:
			print("Seed: " + str(rng.get_seed()))
	
	var current_size = Vector2.ZERO
	var target_size = rect_size.abs()*2
	for hbox in $VBoxContainer.get_children():
		hbox.queue_free()
	
	while current_size.y <= target_size.y:
		current_size.y += 19 - $VBoxContainer.get("custom_constants/separation")
		current_size.x = 0
		
		var hbox = HBoxContainer.new()
		$VBoxContainer.add_child(hbox)
		hbox.set("custom_constants/separation", h_separation)
		
		if randi() % 2:
			var spacer = Control.new()
			spacer.rect_min_size = textures[rng.randi_range(0, len(textures) - 1)].get_size()
			hbox.add_child(spacer)
			
		while current_size.x <= target_size.x:
			var texture = TextureRect.new()
			texture.texture = textures[rng.randi_range(0, len(textures) - 1)]
			hbox.add_child(texture)
			current_size.x += texture.texture.get_width() - h_separation
	
	for node in $Shards.get_children():
		node.queue_free()
	
	if Engine.editor_hint:
		return
	
	yield(Global.wait(0.35), "completed")
	
	for hbox in $VBoxContainer.get_children():
		for texture in hbox.get_children():
			
			if not texture is TextureRect:
				continue
			
			var shard_instance = shard.duplicate()
			
			$Shards.add_child(shard_instance)
			var collisionshape: CollisionPolygon2D = $CollisionShapes.get_node(str(textures.find(texture.texture))).duplicate()
			shard_instance.add_child(collisionshape)
			collisionshape.name = "CollisionPolygon2D"
#			shard_instance.get_node("CollisionShape2D").shape.extents = texture_sizes[textures.find(texture.texture)]/2
#			collisionshape.position = shard_instance.get_node("CollisionShape2D").shape.extents
			shard_instance.get_node("Control").rect_size = texture.rect_size
			
			shard_instance.global_position = texture.rect_global_position
			Global.reparent_child(texture, shard_instance.get_node("Control"))
			texture.rect_position = Vector2.ZERO
			
			shard_instance.connect("collapse", self, "collapse")
	
	$VBoxContainer.queue_free()

func collapse(impact_position):
	for shard_instance in $Shards.get_children():
		shard_instance.mode = RigidBody2D.MODE_RIGID
		shard_instance.apply_central_impulse(shard_instance.get_node("CollisionPolygon2D").to_local(impact_position).rotated(deg2rad(180)) * (randi() % 50 + 5))
	
	yield(Global.wait(2), "completed")
	
	var tween: Tween
	for shard_instance in $Shards.get_children():
		if shard_instance.get_node("Tween").is_active():
			continue
		shard_instance.melt()
		tween = shard_instance.get_node("Tween")
	
	if tween:
		yield(tween, "tween_completed")
	
	queue_free()
	
	

	
#	elif type != Enums.DamageType.FIRE:
#		return -1
