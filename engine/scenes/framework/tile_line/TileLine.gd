tool
extends Node2D

export var tile_data: PackedScene
export var length: float = 1.0 setget set_length
export var generation_seed: int = 0
export var generate_with_random_seed: bool setget generate_random
export var _generate: bool setget generate_tiles
export var guideline_visible: bool = true setget set_guideline_visible

func set_guideline_visible(value: bool):
	guideline_visible = value
	$Line2D.visible = guideline_visible

func _ready():
	generate_tiles(true, generation_seed)
	if Engine.editor_hint:
		return
	set_guideline_visible(false)
	$Line2D.queue_free()

func generate_random(setter:bool=true):
	if not setter:
		return
	
	var sd: int = randi()
	print("Seed: ", sd)
	generate_tiles(true, sd)

func set_length(value: float):
	
	length = value
	
	if not is_inside_tree():
		return
	
	if len($Line2D.points) != 2:
		$Line2D.points = [
			Vector2(0, 0),
			Vector2(1, 0)
		]
	
	$Line2D.points[1].x = length*100

func generate_tiles(setter:bool=true, sd: int = generation_seed):
	if not setter:
		return
	
	set_length(length)
	seed(sd)
	
	for sprite in $Sprites.get_children():
		sprite.queue_free()
		yield(sprite, "tree_exited")
	
	var tile_data_instance: Node2D = tile_data.instance()
	var target_length: float = $Line2D.points[1].x
	var origin: Vector2 = $Line2D.global_position
	
	var sprites: Array = tile_data_instance.get_node("Sprites").get_children()
	var current_sprite: Sprite = sprites[randi() % len(sprites)].duplicate()
	current_sprite.set_meta("name", current_sprite.name)
	
	current_sprite.position = Vector2(current_sprite.texture.get_width()/2, 0)
	current_sprite.visible = true
	current_sprite.flip_h = bool(randi() % 2)
	$Sprites.add_child(current_sprite)
	
	var combinations: Node2D = tile_data_instance.get_node("Combinations")
	var combinations_flipped: Node2D = tile_data_instance.get_node("CombinationsFlipped")
	var current_length: float = current_sprite.position.x + current_sprite.texture.get_width()
	while current_length < target_length:
		var next_sprite: Sprite = get_random_sprite_by_weight(sprites, combinations, combinations_flipped, current_sprite)
		
		if next_sprite.flip_h:
			pass
		
		next_sprite.set_meta("name", next_sprite.name)
		$Sprites.add_child(next_sprite)
		next_sprite.position += current_sprite.position
		next_sprite.visible = true
		current_sprite = next_sprite
		current_length = current_sprite.position.x + current_sprite.texture.get_width()

func get_random_sprite_by_weight(all_sprites: Array, combinations: Node2D, combinations_flipped: Node2D, current_sprite: Sprite):
	
	var flip: bool = bool(randi() % 2)
	var allowed_sprites_container: Node2D
	if not current_sprite.flip_h:
		allowed_sprites_container = [combinations, combinations_flipped][int(flip)].get_node(current_sprite.get_meta("name")[0])
		var allowed_names: Array = []
		for sprite in allowed_sprites_container.get_children():
			allowed_names.append(sprite.name[0])
		
		var possible: Array = []
		for sprite in all_sprites:
			if sprite.name[0] in allowed_names:
				for i in range(sprite.name[1] if len(sprite.name) > 1 else 1):
					possible.append(sprite.name[0])
		
		return allowed_sprites_container.get_node(possible[randi() % len(possible)]).duplicate()
	else:
		
		var possible_ids: Array = []
		var current_combinations: Node2D = [combinations, combinations_flipped][int(flip)]
		for sprite in current_combinations.get_children():
			for subsprite in sprite.get_children():
				if subsprite.name[0] == current_sprite.get_meta("name")[0]:
					possible_ids.append(sprite.name[0])
					break
		
		var possible: Array = []
		for sprite in all_sprites:
			if sprite.name[0] in possible_ids:
				for i in range(sprite.name[1] if len(sprite.name) > 1 else 1):
					possible.append(sprite.name[0])
		
		var ret: Sprite = current_combinations.get_node(possible[randi() % len(possible)]).duplicate()
		
		ret.position.x = (current_sprite.texture.get_width()/2) + (ret.texture.get_width()/2)
#		ret.position.x += ret.get_node(current_sprite.get_meta("name")[0]).position.x# - (ret.get_node(current_sprite.get_meta("name")[0]).texture.get_width()/2)
		#ret.position.x += ret.texture.get_width()/2
		for child in ret.get_children():
			child.queue_free()
		ret.flip_h = flip
		return ret
