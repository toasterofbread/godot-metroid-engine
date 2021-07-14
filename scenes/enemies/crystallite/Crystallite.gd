tool
extends ZoomerTemplate

export var detection_range: float = 0 setget set_detection_range
export var only_extend_on_flat_floor: = false
onready var spike_data: Dictionary = data["spike"]
onready var base_speed: float = speed
#const spike_range: float = 75.0
#var spike_velocity: Vector2 = Vector2.ZERO
#var attached_body = null
#onready var SpikeRaycast: RayCast2D = $Visual/Control/Spike/RayCast2D
var extended: = false

func _ready():
	if Engine.editor_hint:
		return
	._ready()
	$Visual/Control/Spike.position = $Visual/Control/SpikeOrigin.position

func set_detection_range(value: float):
	detection_range = max(0, value)
	$Visual/SamusRaycast.cast_to.y = detection_range

#func extend_spike():
#	extended = true
#	$Visual/Control/Spike/Tween.stop_all()
#	$Tween.interpolate_property(self, "speed", speed, 0, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
#	$Tween.start()
#	yield($Tween, "tween_completed")
#
#	$Visual/Control/Spike.position = $Visual/Control/SpikeOrigin.position
#
#	$Visual/AttachedBodyRaycast.force_raycast_update()
#	attached_body = $Visual/AttachedBodyRaycast.get_collider()
#	if attached_body == null:
#		return false
#
#	var spike_destination: float
#	for i in range(spike_range/10):
#		$Visual/Control/Spike.position.y += 10
#		if not $Visual/Control/Spike.overlaps_body(attached_body):
#			SpikeRaycast.force_raycast_update()
#			spike_destination = $Visual.to_local(SpikeRaycast.get_collision_point()).y - $Visual/Control/Spike/Bottom.position.y
#			break
#		yield(Global, "process_frame")
#	$Visual/Control/Spike.position = $Visual/Control/SpikeOrigin.position
#	if spike_destination == null:
#		return false
#	extended = true
#	$Visual/Control/Spike.visible = true
#	$Visual/Control/Spike/Tween.interpolate_property($Visual/Control/Spike, "position:y", $Visual/Control/Spike.position.y, spike_destination, 0.15, Tween.TRANS_EXPO, Tween.EASE_OUT)
#	$Visual/Control/Spike/Tween.start()
#
#func retract_spike():
#	$Visual/Control/Spike/Tween.stop_all()
#	$Visual/Control/Spike/Tween.interpolate_property($Visual/Control/Spike, "position:y", $Visual/Control/Spike.position.y, $Visual/Control/SpikeOrigin.position.y, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
#	$Visual/Control/Spike/Tween.start()
#	yield($Visual/Control/Spike/Tween, "tween_completed")
#	$Visual/Control/Spike.visible = false
#	attached_body = null
#	$Tween.interpolate_property(self, "speed", speed, base_speed, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
#	$Tween.start()
#	yield($Tween, "tween_completed")
#	extended = false

func extend_spike():
	extended = true
	$Visual/Control/Spike/Tween.stop_all()
	$Tween.interpolate_property(self, "speed", speed, 0, 0.25, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	$Visual/Control/Spike/Tween.interpolate_property($Visual/Control/Spike, "position:y", $Visual/Control/Spike.position.y, $Visual/Control/SpikeDestination.position.y, 0.15, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Visual/Control/Spike/Tween.start()
	yield($Visual/Control/Spike/Tween, "tween_completed")

func retract_spike():
	$Visual/Control/Spike/Tween.stop_all()
	$Visual/Control/Spike/Tween.interpolate_property($Visual/Control/Spike, "position:y", $Visual/Control/Spike.position.y, $Visual/Control/SpikeOrigin.position.y, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Visual/Control/Spike/Tween.start()
	yield(Global.wait(0.1), "completed")
	$Tween.interpolate_property(self, "speed", speed, base_speed, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween, "tween_completed")
	extended = false

func _physics_process(delta):
	if Engine.editor_hint:
		return
	._physics_process(delta)
	if extended == $Visual/SamusRaycast.enabled:
		$Visual/SamusRaycast.enabled = !extended
		return
	if not extended and (not only_extend_on_flat_floor or int(abs(rad2deg(FLOOR.angle()))) in [0, 90, 180]) and $Visual/SamusRaycast.get_collider() == Samus:
		yield(extend_spike(), "completed")
		yield(Global.wait(1), "completed")
		retract_spike()


func _on_Spike_body_entered(body):
	if not extended:
		return
	
	if body.has_method("damage"):
		body.damage(Enums.DamageTypeDict[spike_data["type"]], spike_data["amount"], $Visual/Control/Spike.global_position)
