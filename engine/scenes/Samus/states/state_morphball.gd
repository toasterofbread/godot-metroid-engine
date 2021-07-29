extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var physics_data: Dictionary

var CeilingRaycast: RayCast2D
var particles: Particles2D

const bounce_fall_time: float = 0.5 # The morphball will bounce if it lands after falling for this many seconds
const bounce_fall_amount: float = 200.0 # The amount to bounce in the above case

# PHYSICS
var springball_speed: float
var springball_acceleration: float
var springball_time: float
var springball_current_time: float

var sounds = {
	"morph": Audio.get_player("/samus/morphball/sndMorph", Audio.TYPE.SAMUS),
	"unmorph": Audio.get_player("/samus/morphball/sndUnMorph", Audio.TYPE.SAMUS),
	"bounce": Audio.get_player("/samus/morphball/sndBallBounce", Audio.TYPE.SAMUS),
}

# Called during Samus's readying period
func _init(_Samus: Node2D, _id: String).(_Samus, _id):
	CeilingRaycast = Animator.raycasts.get_node("morphball/Ceiling")
	particles = Samus.get_node("Particles/morphball")
	particles.emitting = false
	
	Loader.loaded_save.connect("value_set", self, "save_value_set")
	set_jump_values()

# Called when Samus's state is changed to this one
func init_state(data: Dictionary, _previous_state_id: String):
	var options = data["options"]
	if "animate" in options:
		animations["morph"].play()
		sounds["morph"].play()
	
	if "jump_current_time" in data:
		springball_current_time = data["jump_current_time"]
	
	Samus.aiming = Samus.aim.NONE
	CeilingRaycast.enabled = true

# Called every frame while this state is active
func process(_delta: float):
	
	var original_facing = Samus.facing

	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))

	if Input.is_action_just_pressed("fire_weapon"):
		Samus.Weapons.fire()
	
	if Samus.is_upgrade_active(Enums.Upgrade.SPIDERBALL):
		if (Settings.get("controls/spiderball_style") == 0 and Input.is_action_pressed("spiderball")) or (Settings.get("controls/spiderball_style") == 1 and Input.is_action_just_pressed("spiderball")):
			change_state("spiderball")
			return
	
	if Samus.shinespark_charged and Input.is_action_just_pressed("jump") and not Animator.transitioning(false, true):
		if not Input.is_action_pressed("pad_left") and not Input.is_action_pressed("pad_right"):
			change_state("shinespark", {"ballspark": true})
	
	if (Input.is_action_just_pressed("morph_shortcut") or Input.is_action_just_pressed("pad_up")) and not Animator.transitioning():
		if not CeilingRaycast.is_colliding():
			animations["unmorph"].play()
			if Samus.is_on_floor():
				change_state("crouch")
			else:
				change_state("jump", {"options": []})
			return
	elif Input.is_action_just_pressed("airspark") and Samus.states["airspark"].can_airspark():
		animations["unmorph"].play()
		change_state("airspark")
		return

	if Input.is_action_pressed("pad_left"):
		Samus.facing = Enums.dir.LEFT
		if original_facing == Enums.dir.RIGHT:
			animations["turn"].play()
			
	elif Input.is_action_pressed("pad_right"):
		Samus.facing = Enums.dir.RIGHT
		if original_facing == Enums.dir.LEFT:
			animations["turn"].play()

	if not Animator.transitioning(false, true):
		
		var anim_speed: float
		if Settings.get("visuals/morphball_always_spin"):
			anim_speed = 1.0
		else:
			anim_speed = 0.0 if (abs(Physics.vel.x) < 1 or Samus.is_on_wall()) and "roll" in Animator.current[false].id else 1
			var target_physics_speed: float = physics_data["ground_speed"] if Samus.is_on_floor() else physics_data["air_speed"]
			anim_speed *= (abs(Physics.vel.x)/target_physics_speed)
		
		animations["roll"].play(true, anim_speed)

#		if (abs(Physics.vel.x) < 1 or Samus.is_on_wall()) and "roll" in Animator.current[false].id:
#			Animator.pause()
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.boosting = false
	CeilingRaycast.enabled = false
	particles.emitting = false
	
	if new_state_key != "spiderball":
		sounds["unmorph"].play()
		Animator.resume()
	
	.change_state(new_state_key, data)

func bounce(amount: float):
	if Samus.current_fluid == Fluid.TYPES.NONE:
		Physics.move_y(-amount)
	else:
		Physics.move_y(-amount*0.5)
#	Physics.disable_floor_snap = true
#	Physics.vel.y = -amount

func physics_process(delta: float, spiderball: bool = false):
	
	if spiderball:
		Samus.fall_time = 0.0
	elif Samus.is_on_floor() and Samus.fall_time > bounce_fall_time:
		bounce(bounce_fall_amount)
		sounds["bounce"].play()
	
	# Vertical
	if Samus.is_upgrade_active(Enums.Upgrade.SPRINGBALL):
		if not spiderball and Input.is_action_just_pressed("jump") and Samus.is_on_floor():
			springball_current_time = springball_time
			Physics.move_y(-springball_speed, springball_acceleration*delta)
#			Physics.vel.y = move_toward(Physics.vel.y, -springball_speed, springball_acceleration*delta)
			Physics.disable_floor_snap = true
		elif not Samus.is_on_floor() and springball_current_time != 0 and Input.is_action_pressed("jump"):
#			Physics.vel.y = move_toward(Physics.vel.y, -springball_speed, springball_acceleration*delta)
			Physics.move_y(-springball_speed, springball_acceleration*delta)
			Physics.disable_floor_snap = true
			springball_current_time -= delta
			if springball_current_time <= 0:
				springball_current_time = 0
		else:
			springball_current_time = 0
	
	# Horizontal
	var pad_x = Shortcut.get_pad_vector("pressed").x
	if not Samus.is_on_floor():
		Physics.move_x(physics_data["air_speed"]*pad_x, (physics_data["air_acceleration"] if pad_x != 0 else physics_data["air_deceleration"])*delta)
	else:
		Physics.move_x(physics_data["ground_speed"]*pad_x, (physics_data["ground_acceleration"] if pad_x != 0 else physics_data["ground_deceleration"])*delta)
	
	CeilingRaycast.global_position.x = Animator.current[false].sprites[Samus.facing].global_position.x
	particles.emitting = Physics.vel != Vector2.ZERO
	particles.global_position = Animator.current[false].sprites[Samus.facing].global_position

func set_jump_values():
	if Samus.is_upgrade_active(Enums.Upgrade.HIGHJUMP):
		springball_speed = physics_data["springball_speed_high"]
		springball_acceleration = physics_data["springball_acceleration_high"]
		springball_time = physics_data["springball_time_high"]
	else:
		springball_speed = physics_data["springball_speed"]
		springball_acceleration = physics_data["springball_acceleration"]
		springball_time = physics_data["springball_time"]

func save_value_set(path: Array, _value):
	if len(path) != 4 or path[0] != "samus" or path[1] != "upgrades" or path[2] != Enums.Upgrade.HIGHJUMP:
		return
	set_jump_values()
	
