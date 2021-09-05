extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var sounds: Dictionary

var tween: Tween = Global.get_tween(true)

func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	for sound in sounds:
		sounds[sound].set_ignore_paused(true)

# Called when Samus' state is changed to this one
func init_state(data: Dictionary, _previous_state_id: String):
	Samus.paused = true
	Physics.apply_velocity = false
	var material: ShaderMaterial = Animator.get_node("Sprites").material
	material.set("shader_param/whitening_value", 0)
	
	animations["suit"].play(false, 1.0, true)
	
	var camera: ControlledCamera2D = Samus.camera
	camera.set_limits(null)
	tween.interpolate_property(camera, "global_position", camera.get_center(), Samus.global_position, 0.5, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	
	tween.interpolate_property(Loader.current_room, "modulate:a", Loader.current_room.modulate.a, 0, 0.2)
	
#	var colour_value = 0
	Samus.camera.dim_colour = Color.black
	Samus.camera.set_dim_layer(-1)
	tween.interpolate_property(Samus.camera, "dim_colour:a", 0, 1, 0.2)
#	tween.interpolate_property(Animator.get_node("DimLayer/ColorRect"), "color", Color(colour_value, colour_value, colour_value, 0), Color(colour_value, colour_value, colour_value, 1), 0.2)
	tween.interpolate_property(Samus.HUD.Modulate, "color:a", Samus.HUD.Modulate.color.a, 0, 0.2)
	
	tween.start()
	yield(tween, "tween_all_completed")
	Samus.get_tree().paused = true
	
	var death_sound: AudioPlayer = sounds["death_full" if Samus.real else "death"]
	death_sound.play()
	if not Samus.real:
		yield(death_sound, "finished")
		yield(Global.wait(0.5, true), "completed")
	else:
		yield(Global.wait(1.3, true), "completed")
	
	if Samus.real:
		animations["samus"].play(false, 1.0, true)
		var sprite: AnimatedSprite = Animator.current[false].sprites[Samus.facing]
		sprite.playing = false
		yield(Global.wait(0.2, true), "completed")
		sprite.playing = true
		yield(sprite, "animation_finished")
		tween.interpolate_property(Samus, "modulate:a", Samus.modulate.a, 0, 1.0)
		tween.start()
		yield(tween, "tween_completed")
	else:
		material.set("shader_param/whitening_enabled", true)
		tween.interpolate_property(material, "shader_param/whitening_value", 0, 1, 1.0)
		tween.start()
		yield(tween, "tween_completed")
		
		material.set("shader_param/dissolve_enabled", true)
		tween.interpolate_property(material, "shader_param/dissolve_progress", 0, 1, 2.0)
		tween.start()
		yield(tween, "tween_completed")
	
	yield(Global.wait(0.5, true), "completed")
	Samus.HUD.display_death_screen(Samus.real)

func paused_physics_process(delta: float):
	Physics.vel = lerp(Physics.vel, Vector2.ZERO, delta)
