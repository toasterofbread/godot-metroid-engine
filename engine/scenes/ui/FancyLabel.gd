tool
extends Node2D

export var animation_duration: float = 0.75
export(ExTween.TransitionType) var transition_type: int
export(ExTween.EaseType) var ease_type: int
export var all_caps: bool = false
export var start_empty: bool = true
export var background_colour: = Color("c3000000") setget set_background_colour
export var font_colour: = Color("ffffff") setget set_font_colour

func set_background_colour(value: Color):
	background_colour = value
	$Background.color = value

func set_font_colour(value: Color):
	font_colour = value
	$Label.set("custom_colors/font_color", value)

func _ready():
	if Engine.editor_hint:
		return
	
	$Background.color = background_colour
	$Label.set("custom_colors/font_color", font_colour)
	if start_empty:
		$Label.text = ""
		$Label.rect_size.x = 0
		$Label.rect_position.x = 0
		$Background.rect_size.x = 0
		$Background.rect_position.x = 0
		visible = false

func _process(_delta):
	align()

func align():
	$Label.rect_size.x = 0
	$Label.rect_position.x = -(($Label.rect_size.x*$Label.rect_scale.x)/2)
	$Background.rect_size.x = $Label.rect_size.x + 24
	$Background.rect_position.x = -(($Background.rect_size.x*$Background.rect_scale.x)/2)

var current_i: int
func set_text(text: String, duration: float = animation_duration):
	
	duration *= 0.25
	text = tr(text)
	
	if all_caps:
		text = text.to_upper()
	current_i += 1
	var self_i = current_i
	visible = true
	if duration > 0:
		if len($Label.text) > 0:
			var wait_time = (duration/2)/len($Label.text)
			var label_text = $Label.text
			while $Label.text != "":
				label_text.erase(len($Label.text) - 1, 1)
				$Label.text = label_text
				$Timer.start(wait_time)
				yield($Timer, "timeout")
				if self_i != current_i:
					return
		
		if len(text) > 0:
			var wait_time = (duration/2)/len(text)
			while $Label.text != text:
				$Label.text = $Label.text + text[len($Label.text)]
				$Timer.start(wait_time)
				yield($Timer, "timeout")
				if self_i != current_i:
					return
	else:
		$Label.text = text
	
	if $Label.text == "":
		visible = false
