extends Control

onready var logbook_data: Dictionary = Data.data["logbook"]
onready var template_key = $List/template
var data = {}

var current_key: String
var current_group: int

var grabbing_focus_manually: = false

func update_info():
	$Info/Title.text = data.values()[current_group][current_key]["name"]
	$Info/Profile.text = data.values()[current_group][current_key]["profile"]
	
	var dir = Directory.new()
	dir.open(Data.logbook_images_path)
	if dir.file_exists(current_key + ".png"):
		$Info/Image.visible = true
		$Info/Image.texture = load(Data.logbook_images_path + current_key + ".png")
#	elif dir.dir_exists(current_key):
#		var anim = SpriteFrames.new()
#		dir.open(images_path + current_key)
#		dir.list_dir_begin(true, true)
#		var file_name = dir.get_next()
#		while file_name != "":
#			if not dir.current_is_dir():
#				if file_name.ends_with(".png"):
#					pass
#			file_name = dir.get_next()
	else:
		$Info/Image.visible = false

func update_group():
	$List/Group.text = data.keys()[current_group]
	
	for child in $List/ScrollContainer/Keys.get_children():
		child.queue_free()
	
	for key in data.values()[current_group]:
		var node = template_key.duplicate()
#		node.connect("focus_entered", self, "_on_key_focus_entered", [key])
		$List/ScrollContainer/Keys.add_child(node)
		node.text = data.values()[current_group][key]["name"]

func process():
	var pad_y: int = Shortcut.get_pad_vector("just_pressed").y
	
	var pad_x: int = 0
	if Input.is_action_just_pressed($List/ButtonIcons/Previous.action_key):
		pad_x = -1
	elif Input.is_action_just_pressed($List/ButtonIcons/Next.action_key):
		pad_x = 1
	
	if pad_y != 0:
		
		var i = data.values()[current_group].keys().find(current_key) + pad_y
		
		if i < 0:
			i = len(data.values()[current_group]) - 1
		elif i >= len(data.values()[current_group]):
			i = 0
		
		current_key = data.values()[current_group].keys()[i]
		$List/ScrollContainer/Keys.get_child(i).grab_focus()
		update_info()
		
	elif pad_x != 0:
		var original_group = current_group
		current_group += pad_x
		if current_group < 0:
			current_group = len(data) - 1
		elif current_group >= len(data):
			current_group = 0
		if current_group != original_group:
			update_group()

func save_value_set(path: Array, value):
	if path != ["logbook", "recorded_entries"]:
		return
	set_data(value)

func set_data(data_value=null):
	var recorded_entries
	if data_value != null:
		recorded_entries = data_value
	else:
		recorded_entries = Loader.loaded_save.get_data_key(["logbook", "recorded_entries"])
	
	# TODO | Add starting entries to the default savegame
	for key in recorded_entries:
		var group_index: String = logbook_data[key]["group"]["name"]
		if not group_index in data:
			data[group_index] = {}
		data[group_index][key] = logbook_data[key]
	
	visible = false
	current_group = 0
	current_key = data.values()[current_group].keys()[0]
	
	update_info()

func _ready():
	Loader.loaded_save.connect("value_set", self, "save_value_set")
	template_key.set_focus_mode(Control.FOCUS_ALL)
	$List.remove_child(template_key)
	set_data()

func open():
	$AnimationPlayer.play("open")
	update_group()

func close(instant: bool = false):
	$AnimationPlayer.play("close", -1, INF if instant else 1.0)
