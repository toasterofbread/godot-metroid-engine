extends CanvasLayer

const separation: float = 10.0
const slide_time: float = 0.35
const reorder_time: float = 0.1

var allow_new_notifications: bool = true

onready var container: Control = $Container/Notifications
const moving_interaction_button: String = "pad_up"

var node_data: Dictionary = {}
onready var types = {
	"text": preload("res://engine/scenes/ui/notification_display/notification_types/TextNotification.tscn"),
	"largetext": preload("res://engine/scenes/ui/notification_display/notification_types/LargeTextNotification.tscn"),
	"buttonprompt": preload("res://engine/scenes/ui/notification_display/notification_types/ButtonPromptNotification.tscn"),
}
const lengths = {
	"long": 5.0,
	"normal": 3.0,
	"short": 1.0
}

func _ready():
	layer = Enums.CanvasLayers.NOTIFICATION
	$LayoutPresets.visible = false

func add(node: Control, clear):
	
	if not allow_new_notifications:
		node.queue_free()
		return
	
	var tween: Tween = Tween.new()
	tween.pause_mode = Node.PAUSE_MODE_PROCESS
	node.add_child(tween)
	node_data[node] = {"tween": tween, "clear": clear}
	
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
	
	var last_notification = get_last_notification()
	container.add_child(node)
	node.rect_position.x = container.rect_size.x
	
	node.rect_position.y = 0 if last_notification == null else last_notification.rect_position.y + last_notification.get_size().y + separation
	
	tween.interpolate_property(node, "rect_position:x", node.rect_position.x, node.rect_position.x - node.get_size().x, slide_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	
	if clear is float:
		yield(Global.wait(clear, true), "completed")
		clear_single(node)
	elif clear is Array:
		clear[0].connect(clear[1], self, "clear_single", [node])
#		yield(clear[0], clear[1])
	else:
		push_error("Invalid clear type for notification")
		node_data.erase(node)
		node.queue_free()
		return
	

func reposition_notifications():
	var destinations: Array = []
	for i in range(container.get_child_count()):
		
		if i >= container.get_child_count():
			break
		
		var node: Control = container.get_child(i)
		if i == 0:
			destinations.append(0.0)
		else:
			destinations.append(destinations[i - 1] + container.get_child(i - 1).get_size().y + separation)
		
		var tween: Tween = node_data[node]["tween"]
		tween.interpolate_property(node, "rect_position:y", node.rect_position.y, destinations[i], reorder_time)
		tween.start()
#		yield(Global.wait(0.5, true), "completed")

func clear_all():
	for node in container.get_children():
		clear_single(node)
		yield(Global.wait(0.1, true), "completed")

func clear_single(node: Control):
	
	var clear = node_data[node]["clear"]
	if clear is Array:
		clear[0].disconnect(clear[1], self, "clear_single")
	
	var tween: Tween = node_data[node]["tween"]
	tween.interpolate_property(node, "rect_position:x", node.rect_position.x, container.rect_size.x, slide_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	node.queue_free()
	if node.is_inside_tree():
		yield(node, "tree_exited")
	reposition_notifications()

func get_last_notification():
	return container.get_children()[-1] if container.get_child_count() > 0 else null

func set_preset(preset_name: String, animate: bool):
	var preset: Control = $LayoutPresets.get_node(preset_name)
	if animate:
		for property in ["rect_size", "rect_global_position", "rect_clip_content"]:
			$LayoutPresets/Tween.interpolate_property(container, property, container.get(property), preset.get(property), 1.0, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
		$LayoutPresets/Tween.start()
	else:
		for property in ["rect_size", "rect_global_position", "rect_clip_content"]:
			container.set(property, preset.get(property))
