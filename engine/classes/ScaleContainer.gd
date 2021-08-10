tool
extends Container
class_name ScaleContainer

export var child_to_scale_with: NodePath

func _process(_delta: float):
	if has_node(child_to_scale_with):
		var child: CanvasItem = get_node(child_to_scale_with)
#		child.set("size" if child is Node2D else "rect_size", Vector2.ZERO)
		var size: Vector2 = child.size if child is Node2D else child.rect_size
		var scale: Vector2 = child.scale if child is Node2D else child.rect_scale
		rect_min_size = size*scale

func _ready():
	if Engine.editor_hint:
		return
	set_process(false)
	_process(0)
