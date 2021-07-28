extends SamusState

var Animator: Node
var Physics: Node
var animations = {}

var idle_timer: Timer = Global.get_timer([self, "play_idle_animation", []])
var idle_animations: Array
const idle_animation_interval = [5, 10] 

var from_powergrip = false

# Called during Samus's readying period
func _init(_Samus: KinematicBody2D, _id: String).(_Samus, _id):
	idle_animations = Animator.load_from_json(id, "neutral_idle").values()

# Called every frame while this state is active
func process(_delta: float):
	
	# DEBUG
	if Input.is_action_just_pressed("[DEBUG] trigger_idle_animation"):
		idle_timer.stop()
		play_idle_animation()
	
	var original_facing = Samus.facing
	var play_transition = false
	var reset_idle_timer = false
	
	if Settings.get("controls/aiming_style") == 0:
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
		reset_idle_timer = Input.is_action_pressed("arm_weapon")
	
	if Input.is_action_just_pressed("fire_weapon"):
		Samus.Weapons.fire()
		reset_idle_timer = true
		Samus.aim_none_timer.start()
	
	if Input.is_action_just_pressed("pause") and Samus.PauseMenu.mode == Samus.PauseMenu.MODES.CLOSED:
		reset_idle_timer = true
		Samus.PauseMenu.pause()
	elif Input.is_action_just_pressed("morph_shortcut") and Samus.is_upgrade_active(Enums.Upgrade.MORPHBALL):
		change_state("morphball", {"options": ["animate"]})
		return
	elif Input.is_action_just_pressed("airspark") and Samus.states["airspark"].can_airspark():
		change_state("airspark")
		return
	elif Input.is_action_just_pressed("jump"):
		if Physics.vel.x != 0 or Input.is_action_pressed("pad_left") or Input.is_action_pressed("pad_right"):
			change_state("jump", {"options": ["jump", "spin"]})
		else:
			if Samus.shinespark_charged:
				change_state("shinespark", {"ballspark": false})
				return
			else:
				change_state("jump", {"options": ["jump"]})
		return
	elif not Samus.is_on_floor() and not from_powergrip:
		change_state("jump", {"options": ["fall"]})
		return
#		Animator.Player.play("neutral_open_map_left")
	elif from_powergrip and Samus.is_on_floor():
		from_powergrip = false
	elif Samus.Weapons.cycle_visor():
		change_state("visor")
		return
	
	var shortcut_facing = Shortcut.get_facing()
	if shortcut_facing != null and shortcut_facing != Samus.facing:
		Samus.facing = shortcut_facing
		play_transition = true
		reset_idle_timer = true
	
	var shortcut_aiming = Shortcut.get_aiming(Samus)
	if shortcut_aiming != null and shortcut_aiming != Samus.aiming:
		if shortcut_aiming == Samus.aim.FLOOR:
			shortcut_aiming = Samus.aim.DOWN
		Samus.aiming = shortcut_aiming
		reset_idle_timer = true
	
	if not Animator.transitioning():
		
		if Input.is_action_pressed("pad_left"):
			Samus.facing = Enums.dir.LEFT
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
				reset_idle_timer = true
			elif not Samus.is_on_wall() and Physics.can_walk(-1):
				change_state("run", {"boost": false})
				return
		elif Input.is_action_pressed("pad_right"):
			Samus.facing = Enums.dir.RIGHT
			if original_facing == Enums.dir.LEFT:
				play_transition = true
				reset_idle_timer = true
			elif not Samus.is_on_wall() and Physics.can_walk(1):
				change_state("run", {"boost": false})
				return
	
	if Input.is_action_pressed("aim_weapon"):
		
		if Samus.aiming == Samus.aim.FRONT or Samus.aiming == Samus.aim.NONE:
			Samus.aiming = Samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			Samus.aiming = Samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			if Samus.aiming == Samus.aim.DOWN:
				change_state("crouch")
				return
			Samus.aiming = Samus.aim.DOWN
		
		reset_idle_timer = true
	elif Input.is_action_pressed("pad_up") and Samus.time_since_last_state("crouch", 0.085):
		Samus.aiming = Samus.aim.SKY
		reset_idle_timer = true
		
	elif Input.is_action_just_pressed("pad_down"):
		change_state("crouch")
		return
	elif shortcut_aiming == null:
		if Samus.aim_none_timer.time_left == 0:
			Samus.aiming = Samus.aim.NONE
		else:
			Samus.aiming = Samus.aim.FRONT
	
	var animation: String
	
#	if play_transition and Samus.states["run"].run_transition != null:
#		Samus.aiming = Samus.states["run"].run_transition
#		Samus.states["run"].run_transition = null
	
	match Samus.aiming:
		Samus.aim.SKY: animation = "aim_sky"
		Samus.aim.UP: animation = "aim_up"
		Samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	if play_transition:
		Samus.states["run"].animations["turn_" + animation].play()
		Samus.states["run"].animations["turn_legs"].play()
	elif ((not Animator.current[false] in idle_animations) or reset_idle_timer) and not Animator.transitioning(false, true):
		animations[animation].play(true)
	
	if reset_idle_timer:
		idle_timer.start()
	
# Called when Samus's state changes to this one
func init_state(data: Dictionary, _previous_state_id: String):
	idle_timer.start(Global.rng.randi_range(idle_animation_interval[0], idle_animation_interval[1]))
	from_powergrip = "from_powergrip" in data and data["from_powergrip"]

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	idle_timer.stop()
	.change_state(new_state_key, data)

# Called by the idle timer, plays a random idle animation
func play_idle_animation():
	
	if not Samus.paused:
		# Play a random idle animation and wait for it to finish
		var anim = Global.random_array_item(idle_animations)
		yield(anim.play(), "completed")
		animations["aim_front"].play()
	
	if Samus.current_state == self:
		# Restart the timer with a random time
		idle_timer.start(Global.rng.randi_range(4, 10))

func physics_process(delta: float):
	Physics.move_x(0, Physics.data["run"]["deceleration"]*delta)
