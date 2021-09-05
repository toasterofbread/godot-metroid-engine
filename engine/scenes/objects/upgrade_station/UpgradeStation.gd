extends Area2D

"""

Upgrade ideas:
	Speedbooster/shinespark opens doors on collision
	Grapple beam penetrates solid objects
	Grapple beam attaches to any surface

"""

onready var Samus: KinematicBody2D = Loader.Samus
signal hide_prompt
var prompt = null
var samus_entered: = false

# Menu
#var camera_original_limits: Dictionary
#var camera_original_position: Vector2
onready var menu_scale: Vector2 = $Menu.rect_scale
enum MENU_STATES {CLOSED, SELECTION, CONFIRMATION, TRANSITION}
var menu_state: int = MENU_STATES.CLOSED
var selected_item: = 0 
var selected_group: = 0
var groups: Array
var upgrades: Dictionary
onready var data: Dictionary = Data.data["mini_upgrades"]
onready var upgradeInfoScene: PackedScene = preload("res://engine/scenes/ui/upgrade_station_menu/UpgradeInfo.tscn")

func _ready():
	z_as_relative = false
	z_index = Enums.Layers.BACKGROUND_ELEMENT
	
	$ScreenMask.modulate.a = 0
	
	$Menu/AnimationPlayer.play("close_cofirmation")
	$Menu.rect_scale.x = 0
	$Menu.visible = false
	for item in $Menu/Items/VBoxContainer.get_children():
		item.queue_free()

func _on_UpgradeStation_body_entered(body):
	if body != Samus:
		return
	
	samus_entered = true

func _on_UpgradeStation_body_exited(body):
	if body != Samus:
		return
	
	samus_entered = false
	emit_signal("hide_prompt")
	prompt = null

func _process(delta):
	
	if menu_state != MENU_STATES.CLOSED:
		process_menu()
	else:
		if prompt != null:
			if not Samus.current_state.id in ["neutral", "crouch", "run"]:
				emit_signal("hide_prompt")
				prompt = null
			elif prompt.just_pressed():
				prompt = null
				samus_entered = false
				open_menu()
		else:
			emit_signal("hide_prompt")
			if samus_entered and not Samus.paused and Samus.Physics.vel.x == 0 and Samus.is_on_floor() and Samus.current_state.id in ["neutral", "crouch"]:
#				prompt = $ButtonPopup.trigger("ui_accept", "Access upgrade station", 0.25, [self, "hide_prompt"])
				prompt = Notification.types["buttonprompt"].instance().init("Access upgrade station", Notification.moving_interaction_button, [self, "hide_prompt"])

func process_menu():
	
	if menu_state == MENU_STATES.TRANSITION:
		return
	
	if menu_state == MENU_STATES.CONFIRMATION:
		if $Menu/ConfirmationWindow/Buttons/Cancel.just_pressed():
			menu_state = MENU_STATES.SELECTION
			$Menu/AnimationPlayer.play("close_cofirmation")
		elif $Menu/ConfirmationWindow/Buttons/Create.just_pressed():
			menu_state = MENU_STATES.SELECTION
			$Menu/AnimationPlayer.play("close_cofirmation")
	else:
		if $Menu/Buttons/Cancel.just_pressed():
			close_menu()
		elif $Menu/Buttons/Create.just_pressed():
			menu_state = MENU_STATES.CONFIRMATION
			$Menu/AnimationPlayer.play("open_confirmation")
			$Menu/ConfirmationWindow/CostLabel.text = $Menu/Data/CostLabel.text
			$Menu/ConfirmationWindow/CostLabel/OwnedLabel.text = $Menu/Data/CostLabel/OwnedLabel.text
		else:
			var pad: Vector2 = InputManager.get_pad_vector("just_pressed")
			if pad.y != 0 and $Menu/Items/VBoxContainer.get_child_count() > 1:
				$Menu/Items/VBoxContainer.get_child(selected_item).selected = false
				selected_item += pad.y
				if selected_item < 0:
					selected_item = $Menu/Items/VBoxContainer.get_child_count() - 1
				elif selected_item >= $Menu/Items/VBoxContainer.get_child_count():
					selected_item = 0
			elif pad.x != 0 and len(groups) > 1:
				
				if selected_item != 0:
					$Menu/Items/VBoxContainer.get_child(selected_item).selected = false
					
					var tween: Tween = $Menu/Items/SelectionIndicator/Tween
					tween.interpolate_property($Menu/Items/SelectionIndicator, "rect_global_position:y", $Menu/Items/SelectionIndicator.rect_global_position.y, $Menu/Items/ZeroPosition.global_position.y, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
					tween.start()
				
				$Menu/Data/CostLabel.text = "Cost:"
				$Menu/Data/CostLabel/OwnedLabel.text = "Owned:"
				$Menu/Data/CreatedLabel.text = "Created:"
				$Menu/Data/CreatedLabel/MaximumLabel.text = "Maximum:"
				
				$Menu/Data/Tween.interpolate_property($Menu/Data/Description, "percent_visible", $Menu/Data/Description.percent_visible, 0, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
				$Menu/Data/Tween.start()
				
				selected_group += pad.x
				if selected_group < 0:
					selected_group = len(groups) - 1
				elif selected_group >= len(groups):
					selected_group = 0
				selected_item = 0
				menu_state = MENU_STATES.TRANSITION
				yield(set_items(groups[selected_group], false), "completed")
				yield(Global.wait(0.2, true), "completed")
				menu_state = MENU_STATES.SELECTION
			else:
				return
			
			var item: Control = $Menu/Items/VBoxContainer.get_child(selected_item)
			$Menu/Items/VBoxContainer.get_child(selected_item).selected = true
			
			$Menu/Data/CostLabel.text = "Cost: " + str(item.data["cost"])
			$Menu/Data/CostLabel/OwnedLabel.text = "Owned: " + str(Loader.loaded_save.get_data_key(["samus", "upgrades", Enums.Upgrade.SCRAPMETAL, "amount"]))
			$Menu/Data/CreatedLabel.text = "Created: " + str(Loader.loaded_save.get_data_key(["samus", "mini_upgrades", item.data["key"], "created"]))
			$Menu/Data/CreatedLabel/MaximumLabel.text = "Maximum: " + str(item.data["maximum"])
			
			$Menu/Data/Description.text = item.data["description"]
			if $Menu/Data/Description.percent_visible == 0:
				$Menu/Data/Tween.interpolate_property($Menu/Data/Description, "percent_visible", 0, 1, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
				$Menu/Data/Tween.start()

func open_menu():
	selected_item = 0
	selected_group = 0
	
	$Menu/Data/Description.percent_visible = 0
	$Menu/Data/Description.text = ""
	$Menu/Data/CostLabel.text = "Cost:"
	$Menu/Data/CostLabel/OwnedLabel.text = "Owned:"
	$Menu/Data/CreatedLabel.text = "Created:"
	$Menu/Data/CreatedLabel/MaximumLabel.text = "Maximum:"
	$Menu/Items/Group.set_text("", 0.0)
	$Menu/Items/SelectionIndicator.rect_global_position.y = $Menu/Items/ZeroPosition.global_position.y
	
	Samus.change_state("facefront", {"face_back": true})
	Samus.paused = true
	
	$Tween.interpolate_property($ScreenMask, "modulate:a", $ScreenMask.modulate.a, 1, 0.5)
	$Tween.start()
	
	var camera: ControlledCamera2D = Samus.camera
	camera.follow_node_pos = false
	camera.follow_pos = $CameraPosition.global_position
	yield(camera, "stopped")
	
	get_tree().paused = true
	upgrades = Loader.loaded_save.get_data_key(["samus", "mini_upgrades"])
	groups = []
	for upgrade_key in upgrades:
		if not data[upgrade_key]["group"] in groups:
			groups.append(data[upgrade_key]["group"])
	
	$Menu.visible = true
	$MenuTween.interpolate_property($Menu, "rect_scale:x", $Menu.rect_scale.x, menu_scale.x, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$MenuTween.start()
	
	yield(set_items(groups[selected_group], true), "completed")
	
	var item: Control = $Menu/Items/VBoxContainer.get_child(selected_item)
	item.selected = true
	$Menu/Data/Description.text = item.data["description"]
	$Menu/Data/Tween.interpolate_property($Menu/Data/Description, "percent_visible", 0, 1, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Menu/Data/Tween.start()
	$Menu/Data/CostLabel.text = "Cost: " + str(item.data["cost"])
	$Menu/Data/CostLabel/OwnedLabel.text = "Owned: " + str(Loader.loaded_save.get_data_key(["samus", "upgrades", Enums.Upgrade.SCRAPMETAL, "amount"]))
	$Menu/Data/CreatedLabel.text = "Created: " + str(Loader.loaded_save.get_data_key(["samus", "mini_upgrades", item.data["key"], "created"]))
	$Menu/Data/CreatedLabel/MaximumLabel.text = "Maximum: " + str(item.data["maximum"])
	
	yield($MenuTween, "tween_completed")
	
	menu_state = MENU_STATES.SELECTION

func set_items(group: String, opening_menu: bool):
	
	$Menu/Items/Group.set_text(group.to_upper(), 0.25)
	
	var current_upgrades = upgrades.duplicate()
	for upgrade_key in upgrades:
		if not upgrades[upgrade_key]["blueprint"] or data[upgrade_key]["group"] != group or not is_upgrade_visible(data[upgrade_key]):
			current_upgrades.erase(upgrade_key)
	
	var i: = 0
	var await: = []
	for upgrade in $Menu/Items/VBoxContainer.get_children():
		await.append(upgrade.hide_info(i >= len(current_upgrades)))
		
		if upgrade.fading:
			upgrade.connect("fade_completed", upgrade, "queue_free")
		else:
			yield(Global.wait(0.05, true), "completed")
		i += 1
	
	for function in await:
		if function:
			yield(function, "completed")
	yield(get_tree(), "idle_frame")
	
	i = 0
	for upgrade_key in current_upgrades:
		
		var info: Control
		if i < $Menu/Items/VBoxContainer.get_child_count():
			info = $Menu/Items/VBoxContainer.get_child(i)
			info.init(data[upgrade_key], $Menu/Items/SelectionIndicator)
		else:
			info = upgradeInfoScene.instance()
			info.init(data[upgrade_key], $Menu/Items/SelectionIndicator)
			
			if not opening_menu:
				info.visible = false
				info.modulate.a = 0
			
			$Menu/Items/VBoxContainer.add_child(info)
		
		i += 1
	
	for upgrade in $Menu/Items/VBoxContainer.get_children():
		upgrade.show_info(!upgrade.visible)
		yield(Global.wait(0.05, true), "completed")

func close_menu():
	
	menu_state = MENU_STATES.CLOSED
	$MenuTween.interpolate_property($Menu, "rect_scale:x", $Menu.rect_scale.x, 0, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$MenuTween.start()
	
	var camera: ControlledCamera2D = Samus.camera
	camera.follow_node_pos = true
	yield(camera, "stopped")
	
	get_tree().paused = false
	Samus.paused = false
	$Menu.visible = false
	
	for upgrade in $Menu/Items/VBoxContainer.get_children():
		upgrade.queue_free()

func is_upgrade_visible(data: Dictionary):
	for upgrade in data["dependencies"]:
		if not Samus.is_upgrade_acquired(upgrade):
			return false
	return true
