extends SamusState

var Animator: Node2D
var Physics: Node
var Weapons: Node2D
var animations: Dictionary
var physics_data: Dictionary

const damage_type: int = Enums.DamageType.BEAM
var damage_values: Dictionary = Data.data["damage_values"]["samus"]["weapons"]["airspark"]
var damage_amount: float = damage_values["damage"]

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2
var time_remaining: float
var sprite
var trailEmitter: SpriteTrailEmitter
var animation: String

var additional_midair_airsparks: Dictionary

var hud_meter: Node2D

# Called during Samus's readying period
func _init(_Samus: Node2D, _id: String).(_Samus, _id):
	trailEmitter = Animator.SpriteContainer
	additional_midair_airsparks = Samus.get_mini_upgrade("additional_midair_airsparks", 0)
	Physics.connect("landed", self, "samus_landed")
	animations = Animator.load_from_json("shinespark")
	hud_meter = Samus.Animator.get_node("AirsparkMeter")
	
	# TODO | Apply upgrades
	hud_meter.total_segments = physics_data["base_total_energy_segments"]
	hud_meter.full_segments = hud_meter.total_segments
	
	can_fire_chargebeam = false

# Called when Samus's state is changed to this one
func init_state(data: Dictionary, _previous_state_id: String):
	
	direction = Shortcut.get_pad_vector("pressed")
	if direction == Vector2.ZERO:
		direction = Vector2(0, -1)
	
	animation = "horiz" if direction.x != 0 else "vert"
	velocity = direction.normalized() * physics_data["speed"]
	Physics.apply_gravity = false
	Physics.vel = direction.normalized() * physics_data["speed"]
	time_remaining = physics_data["duration"]
	trailEmitter.current_profile = "airspark"
	
	if direction.x != 0:
		Samus.facing = Enums.dir.LEFT if direction.x == -1 else Enums.dir.RIGHT
	
	Samus.set_hurtbox_damage(id, damage_type, damage_amount)

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	if sprite != null:
		sprite.flip_v = false
		sprite = null
	trailEmitter.current_profile = null
	Physics.apply_gravity = true
	Samus.aiming = Samus.aim.NONE
	.change_state(new_state_key, data)
	
	Samus.set_hurtbox_damage(id, damage_type, null)

# Called every frame while this state is active
func process(delta: float):
	time_remaining -= delta
	
	if time_remaining <= 0.0 or not Input.is_action_pressed("airspark"):
		change_state("jump", {"options": ["fall"]})
		return
	
	Physics.vel = velocity
	Physics.disable_floor_snap = true
	if animation != "" and not Animator.transitioning():
		animations[animation].play()
		animation = ""
		
		sprite = Animator.current[false].sprites[Samus.facing]
		if direction.x == 0:
			sprite.playing = physics_data["vert_spin_sprite"]
			if direction.y == 1:
				sprite.flip_v = true

func physics_process(_delta: float):
	pass

func samus_landed():
	while Samus.is_on_floor() and hud_meter.full_segments < hud_meter.total_segments:
		yield(hud_meter.set_full_segments(hud_meter.full_segments + 1, true), "completed")
#		yield(Global.wait(0.5), "completed")

func can_airspark() -> bool:
	if not Samus.is_upgrade_active(Enums.Upgrade.AIRSPARK) or hud_meter.full_segments <= 0:
		return false
	elif Samus.current_state.id in ["run", "crouch", "neutral"]:
		if not physics_data["can_airspark_while_grounded"]:
			return false
		if Samus.current_state.id != "neutral":
			return not Input.is_action_pressed("pad_down")
	hud_meter.set_full_segments(hud_meter.full_segments - 1, true)
	return true
