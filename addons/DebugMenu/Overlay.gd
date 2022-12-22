extends Node

var PLUGIN_DIR: String = get_script().resource_path.get_base_dir()

onready var InputLabel: Label = $HBoxContainer/LogColumn/InputLabel
onready var ValueLabel: Label = $HBoxContainer/LogColumn/ValueLabel
onready var LogLabel: Label = $HBoxContainer/InfoColumn/LogLabel

var monitoring_properties: Dictionary = {}
var display_inputs: bool = true

func _ready():
	var font: DynamicFont = DynamicFont.new()
	font.font_data = load(PLUGIN_DIR + "/NotoSans.ttf")
	font.size = 48
	
	for label in [InputLabel, ValueLabel, LogLabel]:
		label.set("custom_fonts/font", font)

func _process(delta):
	ValueLabel.text = ""
	for i in len(monitoring_properties):
		var object: Object = monitoring_properties.keys()[i]
		
		if not is_instance_valid(object):
			monitoring_properties.erase(object)
			continue
		
		for label in monitoring_properties[object]:
			ValueLabel.text += label + ": " + str(object.get(monitoring_properties[object][label])) + "\n"

func _input(event: InputEvent):
	if event is InputEventMouse:
		return
	
	if not event.is_pressed():
		return
	
	InputLabel.text = event.as_text() + "\n" + InputLabel.text

func displayObjectProperty(object: Object, property: String, label: String = null):
	assert(object != null)
	assert(property != null)
	
	if label == null:
		label = property
	
	if not object in monitoring_properties:
		monitoring_properties[object] = {}
	
	monitoring_properties[object][label] = property

func stopDisplayingObjectProperty(object: Object, property: String, label: String = null):
	assert(object != null)
	assert(property != null)
	
	if label == null:
		label = property
	
	var properties: Dictionary = monitoring_properties.get(object)
	if properties != null:
		properties.erase(label)

func log(msg, newline: bool = true):
	LogLabel.text = str(msg) + ("\n" if newline else "") + LogLabel.text
