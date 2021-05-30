extends Node2D

onready var Samus: KinematicBody2D = Loader.Samus
var visor_state: Node

var enabled: bool = false
var last_emit_pos: Position2D
onready var GhostAnchor: Node2D = Global.get_anchor("Samus/Visors/Scan")
onready var scanner: Light2D = $Scanner
var angle: float = 90
const angle_move_speed: float = 1.0

func _ready():
	yield(Samus, "ready")

	visor_state = Samus.states["visor"]
# Called every frame while this visor is enabled
func process():
	
	var pos = get_emit_pos()
	if pos != null:
		scanner.global_position = get_emit_pos().global_position
	spawn_ghost()
	
	
	if not visor_state.analog_visor:
		if Samus.facing == Enums.dir.LEFT:
			scanner.rotation_degrees = -visor_state.angle - 90
		else:
			scanner.rotation_degrees = visor_state.angle - 90
			
	else:
		scanner.rotation_degrees = -visor_state.angle - 90

func spawn_ghost():
	return
	var tween = Tween.new()
	scanner.add_child(tween)
	var ghost = $Scanner.duplicate()
	scanner.add_child(ghost)
	ghost.global_position = scanner.global_position
	ghost.rotation = scanner.rotation
	ghost.color = $Scanner.color
	ghost.color.a = 0.1
	tween.interpolate_property(ghost, "modulate:a", 0, 0.1, 0.1)
	tween.start()
	tween.interpolate_property(ghost, "modulate:a", ghost.modulate.a, 0, 0.1)
	yield(tween, "tween_completed")
	yield(Global.wait(0.01), "completed")
	tween.start()
	yield(tween, "tween_completed")
	ghost.queue_free()
	tween.queue_free()
	

func get_emit_pos():
	var pos: Position2D = Samus.Weapons.VisorPositions.get_node_or_null(Samus.Animator.current[false].position_node_path)
	if pos == null:
		return null
	pos = pos.duplicate()
	Samus.add_child(pos)
	
	if Samus.facing == Enums.dir.RIGHT:
		pos.position.x  = pos.position.x * -1 + 8
	
	# For some reason the default global_position is the same as the relative position
	pos.global_position = Samus.global_position + pos.position
	
	return pos

func set_overlay(value: bool):
	
	if value:
		$CanvasLayer/AnimationPlayer.play("fade_in")
	else:
		$CanvasLayer/AnimationPlayer.play("fade_out")

func enable():
	enabled = true
	$AnimationPlayer.play("enable_scanner")

func disable():
	enabled = false
	$AnimationPlayer.play("disable_scanner")
	yield($AnimationPlayer, "animation_finished")
