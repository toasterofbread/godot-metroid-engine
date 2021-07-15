extends Control

onready var logbook_data: Dictionary = Data.data["logbook"]
const show_duration: float = 0.25

var sounds = {
	"major_fanfare": Sound.new("res://audio/objects/upgade_pickup/Metroid Prime Music - Item Acquisition Fanfare.wav", Sound.TYPE.MUSIC)
}


func _ready():
	for node in $CanvasLayer.get_children():
		node.visible = false

func trigger(upgrade_type: int, added: int, total: int):
	
	var upgrade_type_string = Enums.Upgrade.keys()[upgrade_type]
	
	get_tree().paused = true
	sounds["major_fanfare"].play(false, true)
	
	var upgrade_name: String
	if "pickup_name" in logbook_data[upgrade_type_string]:
		upgrade_name = logbook_data[upgrade_type_string]["pickup_name"]
	else:
		upgrade_name = logbook_data[upgrade_type_string]["name"]
	
	$CanvasLayer/Added.text = "Added: " + str(added)
	$CanvasLayer/Total.text = "Total: " + str(total)
	
	Global.dim_screen(show_duration*2, 0.75, 5)
	
	$CanvasLayer/Icon.play(upgrade_type_string.to_lower())
	$CanvasLayer/Label.text = upgrade_name + "\nacquired"
	$CanvasLayer/Label.percent_visible = 0
	
	self.visible = true
	$AnimationPlayer.play("show", -1, 1/show_duration)
	
	var button_pressed_count: int = 0
	while true:
		if Input.is_action_just_pressed("ui_accept"):
			button_pressed_count += 1
			if button_pressed_count >= 5 or sounds["major_fanfare"].status == Sound.STATE.FINISHED:
				yield(get_tree(), "idle_frame")
				break
		yield(get_tree(), "idle_frame")
	$AnimationPlayer.play("hide", -1, 1/show_duration)
	
	Global.undim_screen(show_duration*2)
	yield($AnimationPlayer, "animation_finished")
	
	if $Tween.is_active():
		yield($Tween, "tween_all_completed")
	
	get_tree().paused = false


# TODO | This (whole script) is painful to look at now...
func _show_element(element_name: String):
	var label: Label
	if element_name == "Label":
		label = $CanvasLayer/Label
	else:
		label = $CanvasLayer/Total
		label = $CanvasLayer/Added
	label.visible = true
	$Tween.interpolate_property(label, "percent_visible", label.percent_visible, 1, show_duration/2)
	$Tween.start()

func _hide_element(element_name: String):
	var label: Label
	if element_name == "Label":
		label = $CanvasLayer/Label
	else:
		label = $CanvasLayer/Total
		label = $CanvasLayer/Added
	
	$Tween.interpolate_property(label, "percent_visible", label.percent_visible, 0, show_duration/2)
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	label.visible = false

