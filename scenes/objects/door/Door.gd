extends Node2D
class_name Door

export var target_room_id: String
export var target_door_id: String
enum DOOR_COLOURS {blue, red, green, yellow}
export(DOOR_COLOURS) var _colour: int = DOOR_COLOURS.blue
export var no_visual: bool = false

var target_room_scene: PackedScene
var opened: bool = false
var locked: bool = false

onready var target_spawn_position: Position2D = $TargetSpawnPosition
var destructive_damage_types: Array = Enums.DamageType.values()

var sounds = {
	"open": Sound.new("res://audio/objects/door/sndDoorOpen.wav", Sound.TYPE.FX),
	"close": Sound.new("res://audio/objects/door/sndDoorClose.wav", Sound.TYPE.FX),
	"lock": Sound.new("res://audio/objects/door/sndDoorLock.wav", Sound.TYPE.FX),
	"unlock": Sound.new("res://audio/objects/door/sndDoorUnlock.wav", Sound.TYPE.FX)
}

func set_no_visual(value: bool):
	opened = true
	$CollisionShape2D.disabled = value
	$FullDoorArea/CollisionShape2D.disabled = value
	$Sprite.visible = !value
	$Frame.visible = !value

# Called when the node enters the scene tree for the first time.
func _ready():
	set_no_visual(no_visual)
	
	z_index = Enums.Layers.DOOR
	z_as_relative = false
	
	target_room_scene = Loader.rooms[target_room_id]
	
	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_close")
	$Sprite.frame = 3
	
	match _colour:
		DOOR_COLOURS.blue: destructive_damage_types = [Enums.DamageType.BEAM, Enums.DamageType.BOMB, Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE, Enums.DamageType.POWERBOMB]
		DOOR_COLOURS.red: destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
		DOOR_COLOURS.green: destructive_damage_types = [Enums.DamageType.SUPERMISSILE]
		DOOR_COLOURS.yellow: destructive_damage_types = [Enums.DamageType.POWERBOMB]
		

func damage(type: int, _amount: float, _impact_position):
	if locked:
		return
	
	if type in destructive_damage_types:
		open()

func open(skip_animation: bool = false):
	opened = true
	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_open")
	$CollisionShape2D.set_deferred("disabled", true)
	
	if not skip_animation:
		sounds["open"].play()
		yield($Sprite, "animation_finished")
	
	$Sprite.visible = false

func close(skip_animation: bool = false):
	sounds["close"].play()
	opened = false
	$Sprite.visible = true
	$CollisionShape2D.set_deferred("disabled", false)
	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_close")
	
	if not skip_animation:
		yield($Sprite, "animation_finished")

func lock():
	sounds["lock"].play()
	locked = true

func unlock():
	sounds["unlock"].play()
	locked = false

func _on_TransitionTriggerArea_body_entered(body):
	if body.name != "Samus" or not opened or locked:
		return
	
	Loader.transition(self)

func fade_out(duration: float):
	$Tween.interpolate_property(self, "modulate:a", 1, 0, duration)
	$Tween.start()
	yield($Tween, "tween_completed")

func fade_in(duration: float):
	$Tween.interpolate_property(self, "modulate:a", 0, 1, duration)
	$Tween.start()
	yield($Tween, "tween_completed")

func room_entered():
	locked = false
	while true:
		var body = yield($FullDoorArea, "body_exited")
		if body == Loader.Samus:
			close()
			break
