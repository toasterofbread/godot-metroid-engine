tool
extends StaticBody2D
#class_name Door

export var target_room_id: String
export var target_door_id: String
enum DOOR_COLOURS {blue, red, green, yellow}
export(DOOR_COLOURS) var colour: int = DOOR_COLOURS.blue setget set_colour
export var visual: bool = true setget set_visual

var locked: bool = false setget set_locked
var open: bool = false setget set_open

var sounds = {
	"open": Sound.new("res://audio/objects/door/sndDoorOpen.wav", Sound.TYPE.FX),
	"close": Sound.new("res://audio/objects/door/sndDoorClose.wav", Sound.TYPE.FX),
	"lock": Sound.new("res://audio/objects/door/sndDoorLock.wav", Sound.TYPE.FX),
	"unlock": Sound.new("res://audio/objects/door/sndDoorUnlock.wav", Sound.TYPE.FX)
}

const colour_damage_types = {
	DOOR_COLOURS.blue: [Enums.DamageType.BEAM, Enums.DamageType.BOMB, Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE, Enums.DamageType.POWERBOMB],
	DOOR_COLOURS.red: [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE],
	DOOR_COLOURS.green: [Enums.DamageType.SUPERMISSILE],
	DOOR_COLOURS.yellow: [Enums.DamageType.POWERBOMB],
}
onready var destructive_damage_types = colour_damage_types[colour]

onready var coverSprite: AnimatedSprite = $Cover/Sprite
onready var coverCollider: CollisionPolygon2D = $Cover/CollisionPolygon2D
const cover_animation_frames: int = 4

func set_visual(value: bool):
	visual = value
func set_colour(value: int):
	colour = value

func set_open(value: bool, animate: bool = true):
	if open == value:
		return
	open = value
	
	var animation: String = DOOR_COLOURS.keys()[colour] + ("_open" if open else "_close")
	coverSprite.play(animation)
	
	if open:
		coverCollider.disabled = true
	
	if animate:
		sounds["open" if open else "close"].play()
		yield(coverSprite, "animation_finished")
		if not open and coverSprite.animation == animation and not coverSprite.playing:
			coverSprite.visible = false
	else:
		coverSprite.frame = cover_animation_frames - 1
	
	if not open:
		coverCollider.disabled = false

func set_locked(value: bool, animate: bool = true):
	if locked == value:
		return
	locked = value
	
	if animate:
		sounds["lock" if locked else "unlock"].play()

func _on_Cover_damage(type: int, amount: int, _impact_position):
	if locked:
		return
	if type in destructive_damage_types and amount > 0:
		set_open(true)

func _on_TransitionTriggerArea_body_entered(body):
	if body.name != "Samus":
		return
	Loader.door_transition(self)
