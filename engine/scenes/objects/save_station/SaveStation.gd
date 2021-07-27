extends StaticBody2D

signal hide_save_prompt
var save_prompt = null

export var id: int = 0

onready var Samus: KinematicBody2D = Loader.Samus
#var exit_timestamp = null

var saved = false

func _ready():
	Enums.add_node_to_group(self, Enums.Groups.SAVESTATION)

func _on_TriggerArea_body_entered_safe(body):
	if body != Loader.Samus or ($AnimatedSprite.animation == "down"):
		return
#	exit_timestamp = null
	$AnimatedSprite.play("down")

func _on_TriggerArea_body_exited_safe(body):
	if body != Loader.Samus or $AnimatedSprite.animation == "up":
		return
	
#	var time = Global.time()
#	exit_timestamp = time
#	yield(Global.wait(0.02), "completed")
#	if exit_timestamp == time:
	$AnimatedSprite.play("up")
#	exit_timestamp = null
	if save_prompt != null:
		save_prompt = null
		emit_signal("hide_save_prompt")

func _process(_delta: float):
	
	if saved:
		return
	
	if save_prompt != null and is_instance_valid(save_prompt):
		if save_prompt.just_pressed():
			save_prompt = null
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
			
			Notification.types["text"].instance().init(tr("savestation_notification_savecomplete"), Notification.lengths["short"])
		elif not Samus.current_state.id in ["neutral", "crouch", "run"]:
			emit_signal("hide_save_prompt")
			save_prompt = null
	else:
		emit_signal("hide_save_prompt")
		if not Samus.paused and $AnimatedSprite.animation == "down" and Samus in $TriggerArea.get_overlapping_bodies():
			if Samus.Physics.vel.x == 0 and Samus.is_on_floor() and Samus.current_state.id in ["neutral", "crouch"]:
				save_prompt = Notification.types["buttonprompt"].instance().init(tr("savestation_notification_saveprompt"), Notification.moving_interaction_button, [self, "hide_save_prompt"])

func spawn_samus():
	Samus.visible = false
	Samus.change_state("facefront", {}, true)
	Samus.paused = true
	
	var sprite: AnimatedSprite = Samus.Animator.current[false].sprites[Samus.facing]
	var offset = $Position2D.global_position.x - sprite.global_position.x
	Samus.global_position.x += offset
	yield(Global.wait(0.2), "completed")
	
	var SpriteContainer: Node2D = Samus.Animator.SpriteContainer
	SpriteContainer.material.set("shader_param/dissolve_enabled", true)
	SpriteContainer.material.set("shader_param/dissolve_progress", 1.0)
	Samus.visible = true
	$Tween.interpolate_property(SpriteContainer.material, "shader_param/dissolve_progress", 1.0, 0.0, 2.0)
	$Tween.start()
	yield($Tween, "tween_completed")
	
	SpriteContainer.material.set("shader_param/dissolve_enabled", false)
#	yield(Global.wait(0.2, true), "completed")
	Samus.paused = false
