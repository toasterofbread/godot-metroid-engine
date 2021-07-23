#extends Node2D
#class_name Door
#
#export var target_room_id: String
#export var target_door_id: String
#enum DOOR_COLOURS {blue, red, green, yellow}
#export(DOOR_COLOURS) var _colour: int = DOOR_COLOURS.blue
#export var no_visual: bool = false
#
#var target_room_scene: PackedScene
#var opened: bool = false
#var locked: bool = false
#
#onready var target_spawn_position: Position2D = $TargetSpawnPosition
#var destructive_damage_types: Array = Enums.DamageType.values()
#
#var sounds = {
#	"open": Sound.new("res://audio/objects/door/sndDoorOpen.wav", Sound.TYPE.FX),
#	"close": Sound.new("res://audio/objects/door/sndDoorClose.wav", Sound.TYPE.FX),
#	"lock": Sound.new("res://audio/objects/door/sndDoorLock.wav", Sound.TYPE.FX),
#	"unlock": Sound.new("res://audio/objects/door/sndDoorUnlock.wav", Sound.TYPE.FX)
#}
#
#func set_no_visual(value: bool):
#	opened = true
#	$CollisionPolygon2D.disabled = value
#	$FullDoorArea/CollisionShape2D.disabled = value
#	$Sprite.visible = !value
#	$Frame.visible = !value
#
## Called when the node enters the scene tree for the first time.
#func _ready():
#	set_no_visual(no_visual)
#
#	z_index = Enums.Layers.DOOR
#	z_as_relative = false
#
#	target_room_scene = Loader.rooms[target_room_id]
#
#	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_close")
#	$Sprite.frame = 3
#
#	match _colour:
#		DOOR_COLOURS.blue: destructive_damage_types = [Enums.DamageType.BEAM, Enums.DamageType.BOMB, Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE, Enums.DamageType.POWERBOMB]
#		DOOR_COLOURS.red: destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
#		DOOR_COLOURS.green: destructive_damage_types = [Enums.DamageType.SUPERMISSILE]
#		DOOR_COLOURS.yellow: destructive_damage_types = [Enums.DamageType.POWERBOMB]
#
#func open(skip_animation: bool = false):
#	opened = true
#	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_open")
#	$CollisionPolygon2D.set_deferred("disabled", true)
#
#	if not skip_animation:
#		sounds["open"].play()
#		yield($Sprite, "animation_finished")
#
#	$Sprite.visible = false
#
#func close(skip_animation: bool = false):
#	sounds["close"].play()
#	opened = false
#	$Sprite.visible = true
#	$CollisionPolygon2D.set_deferred("disabled", false)
#	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_close")
#
#	if not skip_animation:
#		yield($Sprite, "animation_finished")
#
#func lock():
#	sounds["lock"].play()
#	locked = true
#
#func unlock():
#	sounds["unlock"].play()
#	locked = false
#
#func _on_TransitionTriggerArea_body_entered(body):
#	if body.name != "Samus" or not opened or locked:
#		return
#	Loader.transition(self)
#
#func fade_out(duration: float):
#	$Tween.interpolate_property(self, "modulate:a", 1, 0, duration)
#	$Tween.start()
#	yield($Tween, "tween_completed")
#
#func fade_in(duration: float):
#	$Tween.interpolate_property(self, "modulate:a", 0, 1, duration)
#	$Tween.start()
#	yield($Tween, "tween_completed")
#
#func room_entered():
#	locked = false
#	while true:
#		var body = yield($FullDoorArea, "body_exited")
#		if body == Loader.Samus:
#			close()
#			break

tool
extends StaticBody2D
class_name Door

export var target_room_id: String
export var target_door_id: String
enum DOOR_COLOURS {blue, red, green, yellow}
export(DOOR_COLOURS) var colour: int = DOOR_COLOURS.blue setget set_colour
export var cameraChunk: NodePath
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

onready var target_room_scene: PackedScene = Loader.rooms[target_room_id]
onready var targetSpawnPosition: Position2D = $TargetSpawnPosition

func set_visual(value: bool):
	visual = value
func set_colour(value: int):
	colour = value

func _ready():
	set_open(open, false)

func set_open(value: bool, animate: bool = true):
#	if open == value:
#		return
	open = value
	
	var animation: String = DOOR_COLOURS.keys()[colour] + ("_open" if open else "_close")
	coverSprite.play(animation)
	
	if open:
		coverCollider.disabled = true
	coverSprite.visible = true
	
	if animate:
		sounds["open" if open else "close"].play()
		yield(coverSprite, "animation_finished")
		if not open and coverSprite.animation == animation and not coverSprite.playing:
			coverSprite.visible = false
	else:
		coverSprite.frame = cover_animation_frames - 1
	
	if not open:
		coverCollider.disabled = false
	else:
		coverSprite.visible = false

func set_locked(value: bool, animate: bool = true):
	if locked == value:
		return
	locked = value
	
	if animate:
		sounds["lock" if locked else "unlock"].play()

func _on_Cover_damage(type: int, amount: int, _impact_position):
	if locked or open:
		return
	if type in destructive_damage_types and amount > 0:
		set_open(true)

func _on_TransitionTriggerArea_body_entered(body):
	if body.name != "Samus":
		return
	Loader.door_transition(self)

func door_entered():
	locked = false
	while true:
		var body = yield($FullDoorArea, "body_exited")
		if body == Loader.Samus:
			set_open(false)
			break
