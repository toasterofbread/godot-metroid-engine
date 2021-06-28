extends StaticBody2D

onready var Samus: KinematicBody2D = Loader.Samus
var samus_entered_timestamp = null
var samus_exited_timestamp = null
onready var tractorbeam_start_pos = $TractorBeam.position

func _process(delta):
	if Input.is_action_just_pressed("pad_up") and Samus.current_state.id in ["neutral", "crouch"] and $SaveArea.overlaps_body(Samus):
		Samus.change_state("facefront")
		Samus.paused = true
		
		samus_entered_timestamp = null
		samus_exited_timestamp = null
		if $TractorBeam.position == tractorbeam_start_pos or $AnimationPlayer.current_animation == "retract_beam":
			$AnimationPlayer.play("deploy_beam")
		
		var sprite: AnimatedSprite = Samus.Animator.current[false].sprites[Samus.facing]
		var offset = $SaveArea.global_position.x - sprite.global_position.x
		$Tween.interpolate_property(Samus, "global_position:x", Samus.global_position.x, Samus.global_position.x + offset, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
		$Tween.start()
		yield($Tween, "tween_completed")
		
		if $AnimationPlayer.current_animation != "":
			yield($AnimationPlayer, "animation_finished")
		
		var samus_start_position = Samus.global_position
		$Tween.interpolate_property(Samus, "global_position:y", samus_start_position.y, to_global(tractorbeam_start_pos).y, 1.0)
		$Tween.start()
		yield($Tween, "tween_completed")
		
		$AnimationPlayer.play("retract_beam")
		yield($AnimationPlayer, "animation_finished")
		
		Loader.Save.save_file()
		yield(Global.wait(3), "completed")
		$BottomPopup.trigger("Save completed", 2.0)
		
		$AnimationPlayer.play("deploy_beam")
		yield($AnimationPlayer, "animation_finished")
		
		$Tween.interpolate_property(Samus, "global_position:y", Samus.global_position.y, samus_start_position.y, 1.0)
		$Tween.start()
		yield($Tween, "tween_completed")
		
		Samus.paused = false

func _on_SaveArea_body_entered(body):
	if samus_entered_timestamp != null:
		return
	if body == Samus:
		var time = Global.time()
		samus_entered_timestamp = time
		samus_exited_timestamp = null
		
		yield(Global.wait(0.5), "completed")
		if samus_entered_timestamp == time:
			
			if $AnimationPlayer.current_animation == "retract_beam":
				yield($AnimationPlayer, "animation_finished")
			elif $AnimationPlayer.current_animation != "":
				return
			
			$AnimationPlayer.play("deploy_beam")


func _on_SaveArea_body_exited(body):
	if samus_entered_timestamp == null:
		return
	if body == Samus:
		var time = Global.time()
		samus_entered_timestamp = null
		samus_exited_timestamp = time
		
		yield(Global.wait(0.5), "completed")
		if samus_exited_timestamp == time:
			
			if $TractorBeam.position == tractorbeam_start_pos:
				return
			
			if $AnimationPlayer.current_animation == "deploy_beam":
				yield($AnimationPlayer, "animation_finished")
			elif $AnimationPlayer.current_animation != "":
				return
			
			$AnimationPlayer.play("retract_beam")
