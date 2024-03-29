extends AnimatedSprite

var grid_position setget set_grid_position
var moving: bool = false setget set_moving

var editable_name: bool = false setget set_editable_name
var transitioning = false

onready var tween: Tween = Global.get_tween(true)

func set_editable_name(value: bool, instant: bool = false):
	if transitioning or not tween:
		return
	transitioning = true
	if value:
		set_moving(false)
		$LineEdit.text = $CustomName.text
		$LineEdit.visible = true
		$LineEdit.grab_focus()
	else:
		$CustomName.text = $LineEdit.text
	editable_name = value
#	tween.stop_all()
	tween.interpolate_property($LineEdit, "modulate:a", int(!value), int(value), 0 if instant else 0.25)
	tween.start()
	yield(tween, "tween_all_completed")
	if not value:
		$LineEdit.visible = false
	transitioning = false

func set_grid_position(value):
	if value != null:
		if not self.get_parent():
			Map.Grid.Tiles.add_child(self)
		self.position = value*8
	else:
		if self.get_parent():
			Map.Grid.Tiles.remove_child(self)
	grid_position = value

func _process(_delta):
	if editable_name:
		$LineEdit.rect_position.x = -(($LineEdit.rect_size.x*$LineEdit.rect_scale.x)/2)

func set_moving(value: bool):
	$MovementOverlay.visible = value
	moving = value

func save_data():
	if grid_position != null:
		Loader.loaded_save.set_data_key(["map", "marker"], {"position": Global.vector2array(grid_position), "name": $CustomName.text})
	else:
		Loader.loaded_save.set_data_key(["map", "marker"], null)

func load_data():
	var data = Map.savedata["marker"]
	if data != null:
		set_grid_position(Global.array2vector(data["position"]))
		$CustomName.text = data["name"]
	else:
		$CustomName.text = ""
	
		
