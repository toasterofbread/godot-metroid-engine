extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node

const id = "neutral"
var animations = {}
var animations_json_path: String

var idle_timer: Timer = Global.timer([self, "play_idle_animation", []])
var idle_animations: Array
const idle_animation_interval = [5, 10] 


# Called during Samus's readying period
func _init(_samus: KinematicBody2D):
	self.Samus = _samus
	self.Animator = Samus.Animator
	self.Physics = Samus.Physics
	
	self.animations = Animator.load_from_json(self.id)
	self.idle_animations = Animator.load_from_json(self.id, "neutral_idle").values()

# Called every frame while this state is active
func process(_delta):
	
	# DEBUG
	if Input.is_action_just_pressed("[DEBUG] trigger_idle_animation"):
		idle_timer.stop()
		play_idle_animation()
	
	var original_facing = Samus.facing
	var play_transition = false
	var reset_idle_timer = false
	var fire_weapon = false
	
	if Settings.get("controls/zm_style_aiming"):
		Animator.set_armed(Input.is_action_pressed("arm_weapon"))
		reset_idle_timer = Input.is_action_pressed("arm_weapon")
	
	if Input.is_action_just_pressed("morph_shortcut"):
		change_state("morphball", {"options": ["animate"]})
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
	elif not Samus.is_on_floor():
		change_state("jump", {"options": ["fall"]})
		return
	elif Input.is_action_just_pressed("fire_weapon"):
		fire_weapon = true
		reset_idle_timer = true
		Samus.aim_none_timer.start()
		
	if not Animator.transitioning():
	
		if Input.is_action_pressed("pad_left"):
			Samus.facing = Enums.dir.LEFT
			if original_facing == Enums.dir.RIGHT:
				play_transition = true
				reset_idle_timer = true
			elif not Samus.is_on_wall():
				change_state("run", {"boost": false})
				return
		elif Input.is_action_pressed("pad_right"):
			Samus.facing = Enums.dir.RIGHT
			if original_facing == Enums.dir.LEFT:
				play_transition = true
				reset_idle_timer = true
			elif not Samus.is_on_wall():
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
	else:
		if Samus.aim_none_timer.time_left == 0:
			Samus.aiming = Samus.aim.NONE
		else:
			Samus.aiming = Samus.aim.FRONT
	
	var animation: String
	
	if play_transition and "run_transition" in Global.timers:
		Samus.aiming = Global.timers["run_transition"][1]["aiming"]
		Global.clear_timer("run_transition")
	
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
	
	if fire_weapon:
		Samus.Weapons.fire()
	
# Called when Samus's state changes to this one
func init_state(_data: Dictionary):
	idle_timer.start(Samus.rng.randi_range(idle_animation_interval[0], idle_animation_interval[1]))
	return self

# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.change_state(new_state_key, data)
	idle_timer.stop()

# Called by the idle timer, plays a random idle animation
func play_idle_animation():

	# Play a random idle animation and wait for it to finish
	var anim = Global.random_array_item(Samus.rng, idle_animations)
	anim.play()
	yield(anim, "finished")
	
	if Samus.current_state == self:
		# Restart the timer with a random time
		idle_timer.start(Samus.rng.randi_range(4, 10))
#		Animator.play("aim_front", {})

func physics_process(_delta: float):
	Physics.decelerate_x(Samus.states["run"].run_deceleration)
