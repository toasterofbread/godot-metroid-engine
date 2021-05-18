extends Node2D
class_name Door

export(String, FILE) var target_room_path: String
export var id: String
export var target_id: String
enum DOOR_COLOURS {blue, red, green, yellow}
export(DOOR_COLOURS) var _colour: int = DOOR_COLOURS.blue
export(int, 3) var frame_colour: int = 0

var target_room_scene: PackedScene
var opened: bool = false
var locked: bool = false

onready var target_spawn_position: Position2D = $TargetSpawnPosition
var destructive_damage_types: Array = Enums.DamageType.values()

var sounds = {
	"open": Sound.new("res://audio/objects/door/sndDoorOpen.wav"),
	"close": Sound.new("res://audio/objects/door/sndDoorClose.wav"),
	"lock": Sound.new("res://audio/objects/door/sndDoorLock.wav"),
	"unlock": Sound.new("res://audio/objects/door/sndDoorUnlock.wav")
}

# Called when the node enters the scene tree for the first time.
func _ready():
	target_room_scene = load(target_room_path)
	
	match _colour:
		DOOR_COLOURS.blue: destructive_damage_types = [Enums.DamageType.BEAM, Enums.DamageType.BOMB, Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE, Enums.DamageType.POWERBOMB]
		DOOR_COLOURS.red: destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
		DOOR_COLOURS.green: destructive_damage_types = [Enums.DamageType.SUPERMISSILE]
		DOOR_COLOURS.yellow: destructive_damage_types = [Enums.DamageType.POWERBOMB]
		

func damage(damage_type: int, _damage_amount: int):
	if locked:
		return
	
	if damage_type in destructive_damage_types:
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
	$CollisionShape2D.disabled = false
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
