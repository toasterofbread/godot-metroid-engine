extends Node2D
class_name Door

export(String, FILE) var target_room_path: String
export var id: String
export var target_id: String
enum DOOR_COLOURS {blue, red, green, yellow}
export(DOOR_COLOURS) var _colour: int = DOOR_COLOURS.blue
export(int, 3) var frame_colour: int = 0

var target_room_scene: PackedScene
var destination_door: Door
var target_room_instance
var opened: bool = false
var locked: bool = false

onready var target_spawn_position: Position2D = $TargetSpawnPosition
var _destructive_damage_types: Array = Enums.DamageType.values()

# Called when the node enters the scene tree for the first time.
func _ready():
	target_room_scene = load(target_room_path)
	
	match _colour:
		DOOR_COLOURS.blue: _destructive_damage_types = [Enums.DamageType.BEAM, Enums.DamageType.BOMB, Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE, Enums.DamageType.GRAPPLE]
		DOOR_COLOURS.red: _destructive_damage_types = [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]
		DOOR_COLOURS.green: _destructive_damage_types = [Enums.DamageType.SUPERMISSILE]
		DOOR_COLOURS.yellow: _destructive_damage_types = [Enums.DamageType.POWERBOMB]
		

func damage(damage_type: int, _damage_amount: int):
	if locked:
		return
	
	if damage_type in _destructive_damage_types:
		open()

func open(skip_animation: bool = false):
	opened = true
	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_open")
	$CollisionShape2D.disabled = true
	$Frame/CollisionShape2D.disabled = true
	
	if not skip_animation:
		yield($Sprite, "animation_finished")
	
	$Sprite.visible = false

func close(skip_animation: bool = false):
	opened = false
	$Sprite.visible = true
	$CollisionShape2D.disabled = false
	$Frame/CollisionShape2D.disabled = false
	$Sprite.play(DOOR_COLOURS.keys()[_colour] + "_close")
	
	if not skip_animation:
		yield($Sprite, "animation_finished")

func lock():
	locked = true

func unlock():
	locked = false

func _on_TransitionTriggerArea_body_entered(body):
	if body.name != "Samus" or not opened or locked:
		return
	
	Loader.transition(self)

func load_target_room():
	target_room_instance = target_room_scene.instance()
	
	for door in target_room_instance.get_node("Doors").get_children():
		if door.id == target_id:
			destination_door = door
			break
	if not destination_door:
		assert(false, "No destination door found in room")
		return
	
	Loader.room_container.call_deferred("add_child", target_room_instance)
	yield(target_room_instance, "ready")
	
	destination_door.open(true)
	
	var spawn_point = target_spawn_position.global_position
	var offset = target_room_instance.global_position - destination_door.global_position
	target_room_instance.global_position = spawn_point + offset
	
	return destination_door
