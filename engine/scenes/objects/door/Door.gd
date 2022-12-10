tool
extends RoomPhysicsBody2D
class_name Door

signal target_room_loaded

export var target_room_id: String
export var target_door_id: String
enum DOOR_COLOURS {blue, red, green, yellow}
export(DOOR_COLOURS) var colour: int = DOOR_COLOURS.blue setget set_colour
export var cameraChunk: NodePath
export var visual: bool = true setget set_visual

var locked: bool = false setget set_locked
var open: bool = false setget set_open

onready var sounds = {
	"open": Audio.get_player("/objects/door/sndDoorOpen", Audio.TYPE.FX),
	"close": Audio.get_player("/objects/door/sndDoorClose", Audio.TYPE.FX),
	"lock": Audio.get_player("/objects/door/sndDoorLock", Audio.TYPE.FX),
	"unlock": Audio.get_player("/objects/door/sndDoorUnlock", Audio.TYPE.FX)
}

const colour_damage_types = {
	DOOR_COLOURS.blue: [Enums.DamageType.BEAM, Enums.DamageType.BOMB, Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE, Enums.DamageType.POWERBOMB],
	DOOR_COLOURS.red: [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE],
	DOOR_COLOURS.green: [Enums.DamageType.SUPERMISSILE],
	DOOR_COLOURS.yellow: [Enums.DamageType.POWERBOMB],
}
onready var destructive_damage_types = colour_damage_types[colour]

onready var coverSprite: AnimatedSprite = $Cover/Sprite
onready var coverCollider: CollisionShape2D = $Cover/CollisionShape2D
const cover_animation_frames: int = 4

var target_room_instance: GameRoom
onready var targetSpawnPosition: Position2D = $TargetSpawnPosition

func set_visual(value: bool):
	visual = value
	visible = visual
	if not visual:
		for node in [$Cover, $CollisionPolygon2D, $FullDoorArea]:
			node.queue_free()
func set_colour(value: int):
	colour = value

func _ready():
	Enums.add_node_to_group(self, Enums.Groups.DOOR)
	set_open(open, false)
	
	# DEBUG
	assert(target_room_id in Loader.rooms)
	
	# Load target room in background
	var loader = ResourceLoader.load_interactive(Loader.rooms[target_room_id])
	if loader == null: # Check for errors.
		push_error("Room could not be loaded: " + Loader.rooms[target_room_id])
		return
	
	while true:
		var err = loader.poll()
		
		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loader.get_resource()
			target_room_instance = resource.instance()
			emit_signal("target_room_loaded")
			break
#		elif err == OK:
#			var progress = float(loader.get_stage()) / loader.get_stage_count()
#			print("Loading room '" + target_room_id + "': " + str(progress*100) + "%")
		elif err != OK:
			push_error("Error occured while loading room '" + target_room_id + "': " + err)
			break
	loader = null

func set_open(value: bool, animate: bool = true):
	open = value
	
	if not visual:
		return
	
	var animation: String = DOOR_COLOURS.keys()[colour] + ("_open" if open else "_close")
	coverSprite.play(animation)
	
	if open:
		coverCollider.disabled = true
		$CollisionPolygon2D.disabled = true
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
		$CollisionPolygon2D.disabled = false
	else:
		coverSprite.visible = false

func set_locked(value: bool, animate: bool = true):
	if locked == value:
		return
	locked = value
	if not visual:
		return
	
	if animate:
		sounds["lock" if locked else "unlock"].play()

func _on_Cover_damage(type: int, amount: int, _impact_position: Vector2):
	if locked or open:
		return
	if type in destructive_damage_types and amount > 0:
		set_open(true)

func _on_TransitionTriggerArea_body_entered(body):
	if body == Loader.Samus:
		Loader.door_transition(self)

func door_entered():
	locked = false
	while true:
		var body = yield($FullDoorArea, "body_exited")
		if body == Loader.Samus:
			set_open(false)
			break
