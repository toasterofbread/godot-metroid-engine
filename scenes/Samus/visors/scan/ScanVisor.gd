extends SamusVisor

const scan_colour = Color("8000ff3a")
var IconProgressIndicator: ColorRect

var entered_scanNodes = []
var current_scanNode = null

func ready():
	IconProgressIndicator = Icon.get_node("ProgressIndicator")
	IconProgressIndicator.color = scan_colour
	
	$ScanInfo/Info.z_as_relative = false
	$ScanInfo/Info.z_index = Enums.Layers.MENU
	$ScanInfo.layer = Enums.CanvasLayers.MENU
	
	set_pulse()

func disabled():
	if current_scanNode != null:
		current_scanNode.end_scan()
		current_scanNode = null
		end_scan()
	entered_scanNodes = []

func enabled():
	if current_scanNode == null:
		check_for_scannodes()

func check_for_scannodes():
	for area in visor_state.scanner.get_node("Area2D").get_overlapping_areas():
		_on_Area2D_area_entered(area)

func start_scan(node: ScanNode):
	$ProgressTween.stop_all()
	$ProgressTween.interpolate_property(IconProgressIndicator, "rect_size:y", IconProgressIndicator.rect_size.y, 8, node.scan_duration)
	$ProgressTween.start()
	current_scanNode = node
	node.start_scan()
	yield($ProgressTween, "tween_completed")
	if current_scanNode != node:
		return
	node.set_enabled(false)
	node.save()
	display_info(node.data_key)
	node.end_scan()
	entered_scanNodes.erase(node)
	if len(entered_scanNodes) >= 1:
		start_scan(entered_scanNodes[0])
	else:
		current_scanNode = null
		end_scan()

func end_scan():
	$ProgressTween.stop_all()
	$ProgressTween.interpolate_property(IconProgressIndicator, "rect_size:y", IconProgressIndicator.rect_size.y, 0, 0.25)
	$ProgressTween.start()

func _on_Area2D_area_entered(area):
	if Weapons.current_visor != self or not area is ScanNode or area in entered_scanNodes:
		return
	if not area.enabled or area.data_key in Loader.Save.get_data_key(["logbook", "recorded_entries"]):
		return
	
	entered_scanNodes.append(area)
	if len(entered_scanNodes) == 1:
		start_scan(area)

func set_pulse():
	Icon.get_node("AnimationPlayer").play("reset")
	for scanNode in Loader.current_room.scanNodes:
		if scanNode.enabled:
			Icon.get_node("AnimationPlayer").play("pulse")
			break

func display_info(data_key: String):
	
	get_tree().paused = true
	$BottomPopup.trigger("RECORDED TO LOGBOOK", 0.5, 2.0)
	
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
	set_pulse()
	

func _on_Area2D_area_exited(area):
	if Weapons.current_visor != self or not area in entered_scanNodes:
		return
	entered_scanNodes.erase(area)
	
	if current_scanNode == area:
		current_scanNode = null
		area.end_scan()
		if len(entered_scanNodes) >= 1:
			start_scan(entered_scanNodes[0])
		else:
			end_scan()
