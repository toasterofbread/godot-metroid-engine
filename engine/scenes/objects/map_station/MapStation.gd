extends Node2D

onready var Samus: KinematicBody2D = Loader.Samus

const transfer_wait_time: float = 2.0

export var flip: bool = false
onready var scanned_areas: Array = Loader.Save.get_data_key(["map", "scanned_areas"])
var used: bool = false setget set_used

func update_screenoverlay():
	$ScreenOverlay.visible = $Console.animation in ["extend", "retract"]

func _ready():
	
	yield(Loader, "room_loaded")
	set_used(Loader.current_room.area_index in scanned_areas)
	
	$ScreenOverlay.play("default")

func set_used(value: bool, animate: bool = true):
	used = value
	$TriggerArea/CollisionShape2D.disabled = used
	$Console.play("off")
	if animate:
		$ScreenOverlay/Tween.interpolate_property($ScreenOverlay, "self_modulate:a", int(used), int(!used), 0.5)
		$ScreenOverlay/Tween.start()
		yield($ScreenOverlay/Tween, "tween_completed")
	else:
		$ScreenOverlay.self_modulate.a = int(!used)
	$ScreenOverlay.visible = !used
	
	if used:
		scanned_areas.append(Loader.current_room.area_index)

func _process(_delta):
	
	if used or not $TriggerArea.overlaps_body(Samus) or Samus.facing != (Enums.dir.RIGHT if flip else Enums.dir.LEFT) or Samus.current_state.id != "neutral":
		return
	
	var sprite: AnimatedSprite = Samus.Animator.current[false].sprites[Samus.facing]
	if not sprite.animation.begins_with("neutral_aim_front_"):
		return
	
	used = true
	Samus.paused = true
	Samus.Physics.vel = Vector2.ZERO
	
	var diff: Vector2 = $SpritePosition.global_position - sprite.global_position
	$Tween.interpolate_property(Samus, "global_position", Samus.global_position, Samus.global_position + diff, 0.1)
	$Tween.start()
	var original_layer: int = z_index
	z_index = Enums.Layers.SAMUS + 1
	
	if $ScreenOverlay/Tween.is_active():
		yield($ScreenOverlay/Tween, "tween_all_completed")
	
	$Console.play("extend")
	update_screenoverlay()
	yield($Console, "animation_finished")
	yield(Global.wait(0.5), "completed")
	
	$Sparks.visible = true
	$Sparks.play("default")
	
	Notification.types["text"].instance().init(tr("mapstation_notification_start"), transfer_wait_time)
	yield(Global.wait(transfer_wait_time), "completed")
	
	$Sparks.visible = false
	yield(Global.wait(0.5), "completed")
	
	Notification.set_preset("Corner", true)
	Notification.types["text"].instance().init(tr("mapstation_notification_end"), [Samus.PauseMenu, "map_reveal_completed"])
	yield(Samus.PauseMenu.map_station_activated(Loader.current_room.area_index), "completed")
	Samus.paused = true
	Notification.set_preset("SamusHUD", true)
	yield(Global.wait(0.5), "completed")
	
	$Console.play("retract")
	yield($Console, "animation_finished")
	z_index = original_layer
	set_used(true)
	Samus.paused = false
