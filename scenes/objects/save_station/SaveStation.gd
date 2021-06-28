extends StaticBody2D

signal hide_save_prompt
var save_prompt = null

onready var Samus: KinematicBody2D = Loader.Samus
var exit_timestamp = null

var saved = false

func _on_Step_body_entered(body):
	if body != Loader.Samus or ($AnimatedSprite.animation == "down" and exit_timestamp == null):
		return
	exit_timestamp = null
	$AnimatedSprite.play("down")

func _on_Step_body_exited(body):
	if body != Loader.Samus or $AnimatedSprite.animation == "up":
		return
	
	var time = Global.time()
	exit_timestamp = time
	yield(Global.wait(0.02), "completed")
	if exit_timestamp == time:
		$AnimatedSprite.play("up")
		exit_timestamp = null
		if save_prompt != null:
			save_prompt = null
			emit_signal("hide_save_prompt")

func _process(delta):
	
	if saved:
		return
	
	if save_prompt != null:
		if not Samus.current_state.id in ["neutral", "crouch", "run"]:
			emit_signal("hide_save_prompt")
			save_prompt = null
		elif save_prompt.just_pressed():
			save_prompt = null
			
			Loader.Save.set_data_key(["current_room_id"], Loader.current_room.id)
			Loader.Save.save_file()
			
			Samus.change_state("facefront")
			Samus.paused = true
			
			var sprite: AnimatedSprite = Samus.Animator.current[false].sprites[Samus.facing]
			var offset = $Position2D.global_position.x - sprite.global_position.x
			$Tween.interpolate_property(Samus, "global_position:x", Samus.global_position.x, Samus.global_position.x + offset, 0.25, Tween.TRANS_SINE, Tween.EASE_OUT)
			$Tween.start()
			yield($Tween, "tween_completed")
			
			var ghost: = sprite.duplicate()
			$Effect/Ghost.add_child(ghost)
			ghost.global_position = sprite.global_position
			$AnimationPlayer.play("save")
			yield($AnimationPlayer, "animation_finished")
			
			ghost.queue_free()
			Samus.paused = false
			saved = true
	else:
		emit_signal("hide_save_prompt")
		if not Samus.paused and $AnimatedSprite.animation == "down" and Samus in $SaveArea.get_overlapping_bodies():
			if Samus.Physics.vel.x == 0 and Samus.is_on_floor() and Samus.current_state.id in ["neutral", "crouch"]:
				save_prompt = $ButtonPopup.trigger("ui_accept", "Save progress", 0.25, [self, "hide_save_prompt"])

