extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var sounds: Dictionary
var physics_data: Dictionary

const damage_type: int = Enums.DamageType.SPEEDBOOSTER
var damage_values: Dictionary = Data.data["damage_values"]["samus"]["weapons"]["speedbooster"]
var damage_amount: float = damage_values["damage"]
var maintain_shinespark_when_airsparking: Dictionary

var ShinesparkUseWindow: Timer = Global.get_timer([self, "discharge_shinespark", []])
var shinespark_hold_time: float = 3.0

var ShinesparkStoreWindow: Timer = Global.get_timer()
var shinespark_store_window: float = 0.2
var SpeedboostAnimationPlayer: AnimationPlayer

# Well this is nostalgic (18 jul)
#var SpeedboosterRaycasts: Array
#var SpeedboosterArea: Area2D

var direction: Vector2
var velocity: Vector2
var moving: bool = false
var ballspark: bool = false
var sprite

# Called during Samus's readying period
func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	SpeedboostAnimationPlayer = Animator.get_node("SpeedboostAnimationPlayer")
	maintain_shinespark_when_airsparking = Samus.get_mini_upgrade("maintain_shinespark_when_airsparking", 0)

# Called when Samus's state is changed to this one
func init_state(data: Dictionary, previous_state_id: String):
	
	Physics.apply_gravity = false
	Physics.vel = Vector2.ZERO
	direction = InputManager.get_pad_vector("pressed")
	
	discharge_shinespark()
	Physics.disable_floor_snap = true
	Samus.boosting = true
	
	var from_airspark: bool = "from_airspark" in data and data["from_airspark"]
	if not from_airspark:
		if Samus.is_on_floor():
			Physics.vel.y = -50
	
	ballspark = data["ballspark"]
	if not ballspark:
		yield(animations["start"].play(), "completed")
		Physics.vel.y = 0
	else:
		yield(Global.wait(0.05), "completed")
		Physics.vel.y = 0
		yield(Global.wait(0.15), "completed")
	
	var pad_vector: Vector2 = InputManager.get_pad_vector("pressed")
	if pad_vector != Vector2.ZERO:
		direction = pad_vector
	elif direction == Vector2.ZERO:
		direction = Vector2(0, -1)
	velocity = direction.normalized() * physics_data["speed"]
	Physics.vel = velocity
	
	if direction.x != 0:
		Samus.facing = Enums.dir.LEFT if direction.x == -1 else Enums.dir.RIGHT
	if not ballspark:
		animations["horiz" if direction.x != 0 else "vert"].play()
		if direction == Vector2(0, 1):
			sprite = Animator.current[false].sprites[Samus.facing]
			sprite.flip_v = true
	else:
		animations["roll"].play()
	
	var boost_animation: String
	if direction.x == 0:
		boost_animation = "boost_fx_vert_" + ("up" if direction.y == -1 else "down")
	elif direction.y == 0:
		boost_animation = "boost_fx_horiz"
	else:
		boost_animation = "boost_fx_horiz_" + ("up" if direction.y == -1 else "down")
	animations[("ball_" if ballspark else "") + boost_animation].play()
	
	if previous_state_id != id:
		sounds["sndSJLoop"].play()
	moving = true

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	
	if sprite != null:
		sprite.flip_v = false
	moving = false
	Physics.apply_gravity = true
	
	if new_state_key != id:
		sounds["sndSJLoop"].stop()
	.change_state(new_state_key, data)
	
# Called every frame while this state is active
func process(_delta: float):
	
	if not moving:
		Physics.vel.x = 0
		return
	
	Physics.vel = velocity
	if Physics.on_slope and direction.x != 0:
		moving = false
		Physics.apply_gravity = true
		Animator.resume()
		if ballspark:
			ballspark = false
			change_state("morphball", {"options": ["animate"]})
		else:
			change_state("run", {"boost": true})
		return
	elif Input.is_action_just_pressed("airspark") and Samus.states["airspark"].can_airspark():
		if maintain_shinespark_when_airsparking["created"] > 0:
			if physics_data["airspark_into_shinespark"]:
				change_state(id, {"from_airspark": true, "ballspark": ballspark})
				return
			else:
				charge_shinespark()
		change_state("airspark")
		return
	
	var stop_shinespark = false
	if direction.y == 0:
		stop_shinespark = Samus.is_on_wall()
	elif direction.x == 0:
		stop_shinespark = Samus.is_on_ceiling() if direction.y == -1 else Samus.is_on_floor()
	else:
		if direction.y == -1:
			stop_shinespark = Samus.is_on_ceiling() or Samus.is_on_wall()
		else:
			stop_shinespark = Samus.is_on_floor() or Samus.is_on_wall()
	
	if stop_shinespark:
		
		Physics.vel = Vector2.ZERO
		Samus.boosting = false
		moving = false
		Animator.current[true].sprites[Samus.facing].visible = false
		sounds["sndSJLoop"].stop()
		
		Loader.current_room.earthquake(Samus.global_position, damage_values["earthquake_strength"], damage_values["earthquake_duration"])
		
		Animator.pause()
		yield(Global.wait(0.5), "completed")
		Animator.resume()
		
		if not ballspark:
			if sprite != null:
				sprite.flip_v = false
			if direction != Vector2(0, 1):
				animations["end"].play()
			change_state("jump", {"options": []})
		else:
			change_state("morphball", {"options": []})

var previous_boosting: = false
var previous_shinespark_charged: = false
func process_speedboooster(_delta: float):
	
	if Samus.boosting:
		if Samus.current_state.id == "run":
			ShinesparkStoreWindow.start(shinespark_store_window)
	
	if Samus.boosting == previous_boosting and Samus.shinespark_charged == previous_shinespark_charged:
		return
	previous_boosting = Samus.boosting
	previous_shinespark_charged = Samus.shinespark_charged
	
	Animator.SpriteContainer.current_profile = "speedboost" if Samus.boosting else null
	
	if Samus.boosting or Samus.shinespark_charged:
		SpeedboostAnimationPlayer.play("speedboost")
	elif SpeedboostAnimationPlayer.current_animation == "speedboost":
		SpeedboostAnimationPlayer.play("reset")

func charge_shinespark():
	ShinesparkUseWindow.start(shinespark_hold_time)
	Samus.shinespark_charged = true
	
func discharge_shinespark():
	ShinesparkUseWindow.stop()
	Samus.shinespark_charged = false
