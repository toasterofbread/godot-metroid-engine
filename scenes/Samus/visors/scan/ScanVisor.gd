extends SamusVisor

const scan_colour = Color("8000ff3a")
var IconProgressIndicator: ColorRect
onready var progressBar: ColorRect = $ProgressBar

func ready():
	IconProgressIndicator = Icon.get_node("ProgressIndicator")
	IconProgressIndicator.color = scan_colour
	
	yield(self, "ready")
	progressBar.get_node("Bar").rect_scale.x = 0
	progressBar.modulate.a = 0
	progressBar.visible = false

func start_scan(duration: = 2.0):
	visor_state.movement_speed_multiplier = 0.25
	$ProgressTween.interpolate_property(IconProgressIndicator, "rect_size:y", IconProgressIndicator.rect_size.y, 8, duration)
	$ProgressTween.start()
	yield($ProgressTween, "tween_completed")

func end_scan(duration: = 0.25):
	visor_state.movement_speed_multiplier = 1.0
	lock_target.end_scan()
	$ProgressTween.interpolate_property(IconProgressIndicator, "rect_size:y", IconProgressIndicator.rect_size.y, 0, duration)
	$ProgressTween.start()
	yield($ProgressTween, "tween_completed")

func _on_Area2D_area_entered(area):
	if Weapons.current_visor != self or not area is ScanNode:
		return
	
	if lock_target != null and lock_target.get_global_position().distance_to(visor_state.fire_pos.global_position) <= area.get_global_position().distance_to(visor_state.fire_pos.global_position):
		return
	
	if not area.start_scan():
		return
	
	lock_target = area
	
	yield(start_scan(area.scan_duration), "completed")
	if lock_target == area:
		area.save()
		end_scan()
		display_info(area)

func display_info(scannode: ScanNode):
#	get_tree().paused = true
	Notification.trigger("BottomPopup", {"text": "RECORDED TO LOGBOOK", "animation_duration": 0.5, "show_duration": 2.0})

func _on_Area2D_area_exited(area):
	if Weapons.current_visor != self or area != lock_target:
		return
	
	visor_state.movement_speed_multiplier = 1
#	$Tween.interpolate_property(visor_state, "scanner_scale_multiplier", visor_state.scanner_scale_multiplier, Vector2(1, 1), 0.25)
#	if not $Tween.is_inside_tree():
#		yield($Tween, "tree_entered")
#	$Tween.start()
	
	$ProgressTween.stop_all()
	$ProgressTween.interpolate_property(progressBar, "modulate:a", progressBar.modulate.a, 0, 0.1)
	yield(end_scan(), "completed")
	lock_target = null
	progressBar.visible = false
	progressBar.get_node("Bar").rect_scale.x = 0
