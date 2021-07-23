extends Node2D

var variants = {}
const bg_colour = Color("c3000000")
const accent_colour = Color("b8005694")

func _ready():
#	var dir: = Directory.new()
#	assert(dir.open(variants_path) == OK, "Room directory couldn't be opened")
#	dir.list_dir_begin(true, true)
#	var file_name = dir.get_next()
#	while file_name != "":
#		if dir.current_is_dir():
#			if dir.file_exists(file_name + "/variant.tscn"):
#				variants[file_name] = load(variants_path + file_name + "/variant.tscn")
#			else:
#				push_warning("Notification variant directory contains an invalid folder: " + file_name)
#		elif file_name != "BaseVariant.gd":
#			push_warning("Notification variant directory contains a file: " + file_name)
#		file_name = dir.get_next()
#
#	for variant in variants:
#		var instance = variants[variant].instance()
#		$CanvasLayer.add_child(instance)
#		variants[variant] = instance
#
	z_as_relative = false
	z_index = Enums.Layers.NOTIFICATION
	$CanvasLayer.layer = Enums.CanvasLayers.NOTIFICATION

func add_notification(notification: BaseNotification):
	var visual: Control = notification.get_node("CanvasLayer/Visual")
	Global.reparent_child(visual, $CanvasLayer)
	variants[notification.id] = notification
