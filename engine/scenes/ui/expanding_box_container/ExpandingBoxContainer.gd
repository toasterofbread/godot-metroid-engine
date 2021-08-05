tool
extends BoxContainer
class_name ExpandingBoxContainer

const expand_margin: float = 5.0

export var update: bool = false setget _update
export var background_expand_margin: Vector2 = Vector2.ZERO
export var background_colour: Color = Color("c3000000") setget set_background_colour

func set_background_colour(value: Color):
	if not has_node("Background/ColorRect"):
		return
	
	background_colour = value
	$Background/ColorRect.color = background_colour

func _update(value: bool = false):
	$Background/ColorRect.rect_position = (-background_expand_margin/2) + Vector2(1, 1)
	$Background/ColorRect.rect_size = rect_size + background_expand_margin

func _ready():
	_update()
	
	if not Engine.editor_hint:
		connect("sort_children", self, "children_sorted")

func children_sorted():
	rect_size = Vector2.ZERO
	if abs(rect_size.length() - $Background/ColorRect.rect_size.length()) > expand_margin:
		$Tween.stop_all()
		$Tween.interpolate_property($Background/ColorRect, "rect_size", $Background/ColorRect.rect_size, rect_size + background_expand_margin, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$Tween.start()
