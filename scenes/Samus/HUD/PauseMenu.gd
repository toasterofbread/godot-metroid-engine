extends Control

const menu_open_duration: float = 0.25
const map_move_speed = 100
const map_move_acceleration = 2.5
var map_grid_parent: Node

var map_move_velocity = Vector2.ZERO
var transitioning = false

func _ready():
	$CanvasLayer/MapGridPosition.visible = false
	$CanvasLayer/MenuBG.visible = false

func pause():
	get_tree().paused = true

func open_menu():
	
	transitioning = true
	
	$AnimationPlayer.play("open_menu", -1, 1/menu_open_duration)
	
	if not map_grid_parent:
		map_grid_parent = Map.Grid.get_parent()
	
	Map.Grid.visible = false
	map_grid_parent.remove_child(Map.Grid)
	$CanvasLayer.add_child(Map.Grid)
	
	for property in ["rect_size", "rect_scale", "rect_position"]:
		Map.Grid.set(property, $CanvasLayer/MapGridPosition.get(property))
	
	$Tween.interpolate_property(Map.Grid, "rect_position:y", Map.Grid.rect_position.y - Map.Grid.rect_size.y*4, $CanvasLayer/MapGridPosition.rect_position.y, menu_open_duration)
	Map.Grid.visible = true
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	transitioning = false

func resume():
	if not get_tree().paused:
		return
	get_tree().paused = false
	transitioning = true
	
	$AnimationPlayer.play("close_menu", -1, 1/menu_open_duration)
	
	$Tween.interpolate_property(Map.Grid, "rect_position:y", Map.Grid.rect_position.y, Map.Grid.rect_position.y - Map.Grid.rect_size.y*4, menu_open_duration)
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	$CanvasLayer.remove_child(Map.Grid)
	map_grid_parent.add_child(Map.Grid)
	Map.Grid.reset_minimap_properties()
#	Map.Grid.set_focus_position(Map.current_tile.position, true)

	transitioning = false

func _process(delta):
	
	if not get_tree().paused or transitioning:
		return
	
	if Input.is_action_just_pressed("pause"):
		resume()
	
	
	if Input.is_action_pressed("pad_left"):
		map_move_velocity.x = min(map_move_speed, map_move_velocity.x + map_move_acceleration)
	elif Input.is_action_pressed("pad_right"):
		map_move_velocity.x = max(-map_move_speed, map_move_velocity.x - map_move_acceleration)
	else:
		map_move_velocity.x = lerp(map_move_velocity.x, 0, 0.1)
	
	if Input.is_action_pressed("pad_up"):
		map_move_velocity.y = min(map_move_speed, map_move_velocity.y + map_move_acceleration)
	elif Input.is_action_pressed("pad_down"):
		map_move_velocity.y = max(-map_move_speed, map_move_velocity.y - map_move_acceleration)
	else:
		map_move_velocity.y = lerp(map_move_velocity.y, 0, 0.1)
	
	Map.Grid.Tiles.position += map_move_velocity * delta
	
