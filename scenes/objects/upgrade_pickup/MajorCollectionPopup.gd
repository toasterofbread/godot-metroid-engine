extends Control

const show_duration: float = 0.25

var sounds = {
	"major_fanfare": Sound.new("res://audio/objects/upgade_pickup/Metroid Prime Music - Item Acquisition Fanfare.wav", false, Audio, true)
}

func _ready():
	
	for node in $CanvasLayer.get_children():
		node.visible = false

func trigger(upgrade_type: int):
	
	get_tree().paused = true
	sounds["major_fanfare"].play()
	
	var upgrade_name: String
	match upgrade_type:
		Enums.Upgrade.MISSILE: upgrade_name = "MISSILE TANK"
	
	Global.dim_screen(0.75, show_duration*2, 5)
	
	$CanvasLayer/Icon.play(Enums.Upgrade.keys()[upgrade_type].to_lower())
	$CanvasLayer/Label.bbcode_text = "[center]" + upgrade_name + "\nacquired[/center]"
	$CanvasLayer/Label.percent_visible = 0

	self.visible = true
	$AnimationPlayer.play("show", -1, 1/show_duration)
	
	
	var button_pressed_count: int = 0
	while true:
		if Input.is_action_just_pressed("ui_accept"):
			button_pressed_count += 1
			if button_pressed_count >= 5 or sounds["major_fanfare"].status == Sound.STATE.FINISHED:
				yield(Global, "physics_frame")
				break
		yield(Global, "physics_frame")
	$AnimationPlayer.play("hide", -1, 1/show_duration)
	
	Global.undim_screen(show_duration*2)
	yield($AnimationPlayer, "animation_finished")
	get_tree().paused = false
	

func _show_element(element_name: String):
	if element_name == "Label":
		Global.text_fade_in($CanvasLayer/Label, show_duration/2)
	else:
		Global.text_fade_in($CanvasLayer/Total, show_duration/2)
		Global.text_fade_in($CanvasLayer/Added, show_duration/2)

func _hide_element(element_name: String):
	if element_name == "Label":
		Global.text_fade_out($CanvasLayer/Label, show_duration/2)
	else:
		Global.text_fade_out($CanvasLayer/Total, show_duration/2)
		Global.text_fade_out($CanvasLayer/Added, show_duration/2)

