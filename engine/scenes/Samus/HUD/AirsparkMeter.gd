extends Node2D

const segment_size: float = 35.0

var total_segments: int = 1.0 setget set_total_segments
var full_segments: int = 1.0 setget set_full_segments

# Amount of time the node reveals itself for when a value changes
const visible_time: float = 1.0
var visible_time_remaining: float = 0.0

var SplitterTemplate: ColorRect

var shown: bool = false setget set_shown

func _ready():
	visible = false
	SplitterTemplate = $ProgressBar/HBoxContainer.get_child(0)
	Global.reparent_child(SplitterTemplate, self)
	SplitterTemplate.visible = false
	
	for splitter in $ProgressBar/HBoxContainer.get_children():
		splitter.queue_free()
	
	position = Vector2(15, 20)

func _process(delta: float):
	if not shown:
		if visible_time_remaining > 0.0:
			set_shown(true)
		else:
			return
	
#	var animation = Loader.Samus.Animator.current[false]
#	if animation != null:
#		var sprite: AnimatedSprite = animation.sprites[Loader.Samus.facing]
#		var frame: Texture = sprite.frames.get_frame(sprite.animation, sprite.frame)
#		global_position = sprite.global_position + (frame.get_size() / 2)
	
	visible_time_remaining -= delta
	
	if visible_time_remaining <= 0.0:
		set_shown(false)

func set_shown(value: bool):
	if shown == value:
		return
	shown = value
	modulate.a = float(!shown)
	if value:
		visible = true
	$VisibilityTween.stop_all()
	$VisibilityTween.interpolate_property(self, "modulate:a", modulate.a, float(shown), 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$VisibilityTween.start()
	yield($VisibilityTween, "tween_completed")
	
	if not shown:
		visible = false

func set_total_segments(value: int, animate: bool = false):
	total_segments = value
	$ProgressBar.max_value = total_segments
	
	$SplitterVisibilityTween.stop_all()
	if animate:
		visible_time_remaining = visible_time
		for splitter in $ProgressBar/HBoxContainer.get_children():
			$SplitterVisibilityTween.interpolate_property(splitter, "modulate:a", splitter.modulate.a, 0.0, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$SplitterVisibilityTween.start()
		yield($SplitterVisibilityTween, "tween_completed")
	else:
		for splitter in $ProgressBar/HBoxContainer.get_children():
			splitter.queue_free()
	
	$ProgressBar/HBoxContainer.set("custom_constants/separation", $ProgressBar/HBoxContainer.rect_size.x / (total_segments + 1))
	for i in range(total_segments):
		var splitter: ColorRect = SplitterTemplate.duplicate()
		$ProgressBar/HBoxContainer.add_child(splitter)
		if animate:
			splitter.modulate.a = 0.0
		splitter.visible = true
	
	if animate:
		for splitter in $ProgressBar/HBoxContainer.get_children():
			$SplitterVisibilityTween.interpolate_property(splitter, "modulate:a", 0.0, SplitterTemplate.modulate.a, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$SplitterVisibilityTween.start()
		yield($SplitterVisibilityTween, "tween_completed")

func set_full_segments(value: int, animate: bool = false):
	full_segments = value
	
	$ValueTween.stop_all()
	if animate:
		visible_time_remaining = visible_time
		$ValueTween.interpolate_property($ProgressBar, "value", $ProgressBar.value, full_segments, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$ValueTween.start()
		yield($ValueTween, "tween_completed")
	else:
		$ProgressBar.value = full_segments
