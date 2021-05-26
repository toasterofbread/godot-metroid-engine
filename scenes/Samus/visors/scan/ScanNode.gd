tool
extends Node2D

export var major_scan: bool = false setget set_major

func set_major(value: bool):
	$AnimatedSprite.modulate = Color("ff4200") if value else Color.white
	major_scan = value

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.editor_hint:
		return
	scan_status_changed(false)

func scan_status_changed(engaged: bool):
	if engaged:
		$AnimationPlayer.play("passive")
		self.visible = true
	else:
		$AnimationPlayer.stop()
		self.visible = false

func _enter_tree():
	$AnimationPlayer.play("passive")
