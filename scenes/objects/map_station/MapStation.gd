extends Node2D

onready var Samus: KinematicBody2D = Loader.Samus

const transfer_wait_time: float = 2.0

export var flip: bool = false
onready var used_data: Array = Loader.Save.get_data_key(["map", "used_maprooms"])
onready var used: bool = Loader.current_room.area_index in used_data setget set_used

func _ready():
	$Console.play("retracted")
	$Screen.play("default")
	set_used(used, false)

func set_used(value: bool, animate: bool = true):
	used = value
	$TriggerArea/CollisionShape2D.disabled = used
	if animate:
		$Screen/Tween.interpolate_property($Screen, "self_modulate:a", $Screen.self_modulate.a, int(!used), 0.5)
		$Screen/Tween.start()
		yield($Screen/Tween, "tween_completed")
	else:
		$Screen.self_modulate.a = int(!used)
	$Screen.visible = !used

func _process(_delta):
	
	if used or not $TriggerArea.overlaps_body(Samus) or Samus.facing != (Enums.dir.RIGHT if flip else Enums.dir.LEFT) or Samus.current_state.id != "neutral":
		return
	
	var sprite: AnimatedSprite = Samus.Animator.current[false].sprites[Samus.facing]
	if not sprite.animation.begins_with("neutral_aim_front_"):
		return
	
	used = true
	Samus.paused = true
	Samus.Physics.vel = Vector2.ZERO
	
	var diff: float = $SpritePosition.global_position.x - sprite.global_position.x
	$Tween.interpolate_property(Samus, "global_position:x", Samus.global_position.x, Samus.global_position.x + diff, 0.1)
	$Tween.start()
	
	var original_layer: int = z_index
	z_index = Enums.Layers.SAMUS + 1
	
	if $Screen/Tween.is_active():
		yield($Screen/Tween, "tween_all_completed")
	
	$Console.play("extend")
	yield($Console, "animation_finished")
	yield(Global.wait(0.5), "completed")
	
	$Sparks.visible = true
	$Sparks.play("default")
	yield(Global.wait(transfer_wait_time), "completed")
	$Sparks.visible = false
	yield(Global.wait(0.5), "completed")
	
	yield(Samus.PauseMenu.map_station_activated(Loader.current_room.area_index), "completed")
	yield(Global.wait(0.5), "completed")
	
	$Console.play("retract")
	yield($Console, "animation_finished")
	z_index = original_layer
	set_used(true)
	Samus.paused = false
	
