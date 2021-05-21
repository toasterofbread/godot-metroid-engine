extends AnimatedSprite

var grid_position setget set_grid_position
var moving: bool = false setget set_moving

var editable_name: bool = false setget set_editable_name
var transitioning = false

onready var tween: Tween = $Tween

func _ready():
	Global.reparent_child(tween, Global)

func set_editable_name(value: bool, instant: bool = false):
	if transitioning:
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
		Loader.Save.set_data_key(["map", "marker"], {"position": Global.vector2array(grid_position), "name": $CustomName.text})
	else:
		Loader.Save.set_data_key(["map", "marker"], null)

func load_data():
	var data = Loader.Save.get_data_key(["map", "marker"])
	if data != null:
		set_grid_position(Global.array2vector(data["position"]))
		$CustomName.text = data["name"]
	else:
		$CustomName.text = ""
	
		
