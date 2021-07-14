extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node
const id = "death"
var animations: Dictionary
var sounds = {
	"death": Sound.new("res://audio/samus/death/death.ogg", Sound.TYPE.SAMUS, 20.0),
	"death_real": Sound.new("res://audio/samus/death/death_real.ogg", Sound.TYPE.SAMUS, 20.0),
}

var tween: Tween = Global.tween(true)

func _init(_samus: Node2D):
	Samus = _samus
	Animator = Samus.Animator
	Physics = Samus.Physics
	animations = Animator.load_from_json(self.id)
#	physics_data = Physics.data[id]

# Called every frame while this state is active
func process(_delta: float):
	pass

# Called when Samus' state is changed to this one
func init_state(data: Dictionary):
	Samus.paused = true
	
	var material: ShaderMaterial = Animator.get_node("Sprites").material
	material.set("shader_param/whitening_value", 0)
	
	animations["suit"].play(false, 1.0, true)
	
	var camera: ExCamera2D = Samus.camera
	camera.set_limits(null)
	tween.interpolate_property(camera, "global_position", camera.get_center(), Samus.global_position, 0.5, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	
	tween.interpolate_property(Loader.current_room, "modulate:a", Loader.current_room.modulate.a, 0, 0.2)
	
	var colour_value = 0
	tween.interpolate_property(Animator.get_node("DimLayer/ColorRect"), "color", Color(colour_value, colour_value, colour_value, 0), Color(colour_value, colour_value, colour_value, 1), 0.2)
	tween.interpolate_property(Samus.HUD.Modulate, "color:a", Samus.HUD.Modulate.color.a, 0, 0.2)
	
	tween.start()
	yield(tween, "tween_all_completed")
	Samus.get_tree().paused = true
	
	var death_sound: Sound = sounds["death_real" if Samus.real else "death"].play(false, true)
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

func set_room_modulation(value: float):
	pass

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.change_state(new_state_key, data)

func paused_physics_process(delta: float):
	Physics.vel = lerp(Physics.vel, Vector2.ZERO, delta)
