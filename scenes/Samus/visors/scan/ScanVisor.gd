extends SamusVisor

const scan_colour = Color("8000ff3a")
var IconProgressIndicator: ColorRect

func ready():
	IconProgressIndicator = Icon.get_node("ProgressIndicator")
	IconProgressIndicator.color = scan_colour
	
	$ScanInfo/Info.z_as_relative = false
	$ScanInfo/Info.z_index = Enums.Layers.MENU
	$ScanInfo.layer = Enums.CanvasLayers.MENU

func disabled():
	if lock_target != null:
		end_scan()

func enabled():
	if lock_target == null:
		check_for_scannodes()

func check_for_scannodes():
	for area in visor_state.scanner.get_node("Area2D").get_overlapping_areas():
		_on_Area2D_area_entered(area)

func start_scan(duration: = 2.0):
#	visor_state.movement_speed_multiplier = 0.25
	$ProgressTween.stop_all()
	$ProgressTween.interpolate_property(IconProgressIndicator, "rect_size:y", IconProgressIndicator.rect_size.y, 8, duration)
	$ProgressTween.start()
	yield($ProgressTween, "tween_completed")

func end_scan(duration: = 0.25):
	visor_state.movement_speed_multiplier = 1.0
	lock_target.end_scan()
	lock_target = null
	$ProgressTween.stop_all()
	$ProgressTween.interpolate_property(IconProgressIndicator, "rect_size:y", IconProgressIndicator.rect_size.y, 0, duration)
	$ProgressTween.start()
	yield($ProgressTween, "tween_completed")

func _on_Area2D_area_entered(area):
	if Weapons.current_visor != self or not area is ScanNode or lock_target != null:
		return
	
	if not area.enabled or area.data_key in Loader.Save.get_data_key(["logbook", "recorded_entries"]):
		return
	
	lock_target = area
	lock_target.start_scan()
	
	yield(start_scan(area.scan_duration), "completed")
	if lock_target == area:
#		if Weapons.current_visor == self:
		lock_target.save()
		display_info(lock_target.data_key)
		end_scan()
		check_for_scannodes()

func display_info(data_key: String):
	get_tree().paused = true
	Notification.trigger("BottomPopup", {"text": "RECORDED TO LOGBOOK", "animation_duration": 0.5, "show_duration": 2.0})
	
	$ScanInfo/Info/Panel/Title.text = Data.logbook[data_key]["name"]
	$ScanInfo/Info/Panel/Profile.text = Data.logbook[data_key]["profile"]
	
	var dir = Directory.new()
	dir.open(Data.logbook_images_path)
	if dir.file_exists(data_key + ".png"):
		$ScanInfo/Info/Image/TextureRect.visible = true
		$ScanInfo/Info/Image/TextureRect.texture = load(Data.logbook_images_path + data_key + ".png")
	else:
		$ScanInfo/Info/Image/TextureRect.visible = false
	
#	Global.dim_screen(0.25, 0.75, Enums.CanvasLayers.NOTIFICATION)
	$ScanInfo/AnimationPlayer.play("show")
	
	while not $ScanInfo/ColorRect2/ButtonPrompt.just_pressed():
		yield(Global, "process_frame")
	
	get_tree().paused = false
	$ScanInfo/AnimationPlayer.play("hide", -1, 1.5)
	

func _on_Area2D_area_exited(area):
	if Weapons.current_visor != self or area != lock_target:
		return
	
	visor_state.movement_speed_multiplier = 1
#	$Tween.interpolate_property(visor_state, "scanner_scale_multiplier", visor_state.scanner_scale_multiplier, Vector2(1, 1), 0.25)
#	if not $Tween.is_inside_tree():
#		yield($Tween, "tree_entered")
#	$Tween.start()
	
	end_scan()
