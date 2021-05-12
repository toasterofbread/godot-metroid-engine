extends Control

const menu_open_duration: float = 0.25
const map_move_speed = 100
const map_move_acceleration = 2.5
var map_grid_parent: Node

var map_move_velocity = Vector2.ZERO
var transitioning = false
var menu_open = false

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
	Global.reparent_child(Map.Grid, $CanvasLayer)
	
	for property in ["rect_size", "rect_scale", "rect_position"]:
		Map.Grid.set(property, $CanvasLayer/MapGridPosition.get(property))
	
	$Tween.interpolate_property(Map.Grid, "rect_position:y", Map.Grid.rect_position.y - Map.Grid.rect_size.y*4, $CanvasLayer/MapGridPosition.rect_position.y, menu_open_duration)
	Map.Grid.visible = true
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	transitioning = false
	menu_open = true

func resume():
	
	menu_open = false
	if Map.Marker.moving:
		Map.Marker.moving = false
		Map.Marker.grid_position = null
		Map.Marker.save_data()
	
	get_tree().paused = false
	transitioning = true
	
	$AnimationPlayer.play("close_menu", -1, 1/menu_open_duration)
	
	$Tween.interpolate_property(Map.Grid, "rect_position:y", Map.Grid.rect_position.y, Map.Grid.rect_position.y - Map.Grid.rect_size.y*4, menu_open_duration)
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	$CanvasLayer.remove_child(Map.Grid)
	map_grid_parent.add_child(Map.Grid)
	Map.Grid.reset_minimap_properties()
	Map.Grid.set_focus_position(Map.current_tile.position, true)

	transitioning = false

func _process(delta):
	
	if not menu_open or transitioning:
		return
	
	if Input.is_action_just_pressed("pause"):
		resume()
	
	if Input.is_action_just_pressed("select_weapon") and not Map.Marker.moving:
		if not Map.Marker.grid_position:
			Map.Marker.grid_position = Map.current_tile.position/8
		Map.Marker.moving = true
	elif Input.is_action_just_pressed("ui_accept") and Map.Marker.moving:
		Map.Marker.moving = false
		Map.Marker.save_data()
	elif Map.Marker.moving and Input.is_action_pressed("ui_cancel"):
		Map.Marker.moving = false
		Map.Marker.grid_position = null
		Map.Marker.save_data()
	elif Map.Marker.moving:
		Map.Marker.grid_position += Shortcut.get_pad_vector("just_pressed")
		Map.Grid.focus_position = Map.Marker.position
	else:
		var pad_vector = -Shortcut.get_pad_vector("pressed")
		
		map_move_velocity.x = Shortcut.add_to_limit(map_move_velocity.x, map_move_acceleration, map_move_speed * pad_vector.x)
		map_move_velocity.y = Shortcut.add_to_limit(map_move_velocity.y, map_move_acceleration, map_move_speed * pad_vector.y)
		
		Map.Grid.Tiles.position += map_move_velocity * delta
	
