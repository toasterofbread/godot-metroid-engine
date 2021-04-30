extends Node

var samus: Node2D
var animator: Node
var physics: Node
var idle_timer: Timer

const id = "neutral"

var idle_animations: Array
const idle_animation_interval = [5, 10] 

var animations = {}

# Called during Samus's readying period
func _init(_samus: Node2D):
	self.samus = _samus
	self.animator = samus.animator
	self.physics = samus.physics
	idle_timer = Global.start_timer("idle_animation", -1, {}, [self, "play_idle_animation"])

	animations = {
		"aim_down": animator.Animation.new(animator,"aim_down", self.id),
		"aim_front": animator.Animation.new(animator,"aim_front", self.id),
		"aim_sky": animator.Animation.new(animator,"aim_sky", self.id),
		"aim_up": animator.Animation.new(animator,"aim_up", self.id),
		"legs_start": animator.Animation.new(animator,"legs_start", "jump", {"transition": true, "overlay": true, "position": Vector2(4, 4)})
	}
		
	idle_animations = [animator.Animation.new(animator,"idle_0", self.id), animator.Animation.new(animator,"idle_1", self.id)]


# Called when Samus's state is changed to this one
func init(_data: Dictionary):
	idle_timer.start(samus.rng.randi_range(idle_animation_interval[0], idle_animation_interval[1]))
	return self

# Called every frame while this state is active
func process(_delta):
	
	# DEBUG
	if Input.is_action_just_pressed("[DEBUG] trigger_idle_animation"):
		idle_timer.stop()
		play_idle_animation("")
	
	var original_facing = samus.facing
	var play_transition = false
	var reset_idle_timer = false
	
	if Global.config["zm_controls"]:
		animator.set_armed(Input.is_action_pressed("arm_weapon"))
		reset_idle_timer = Input.is_action_pressed("arm_weapon")
	
	if not animator.transitioning():
		if Input.is_action_just_pressed("morph_shortcut"):
			change_state("morphball", {"transition": true})
			return
		elif Input.is_action_just_pressed("jump"):
			if physics.vel.x == 0:
				animations["legs_start"].play()
				change_state("jump", {"jump": true})
			else:
				change_state("spin")
			return
		elif Input.is_action_just_pressed("fire_weapon"):
			samus.weapons.fire()
			reset_idle_timer = true
	
		if Input.is_action_pressed("pad_left"):
			samus.facing = Global.dir.LEFT
			if original_facing == Global.dir.RIGHT:
				play_transition = true
				reset_idle_timer = true
			else:
				change_state("run")
				return
		elif Input.is_action_pressed("pad_right"):
			samus.facing = Global.dir.RIGHT
			if original_facing == Global.dir.LEFT:
				play_transition = true
				reset_idle_timer = true
			else:
				change_state("run")
				return
	
	if Input.is_action_pressed("aim_weapon"):
		
		if samus.aiming == samus.aim.FRONT:
			samus.aiming = samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			if samus.aiming == samus.aim.DOWN and not animator.transitioning():
				change_state("crouch")
				return
			samus.aiming = samus.aim.DOWN
		
		reset_idle_timer = true
	elif Input.is_action_pressed("pad_up") and samus.time_since_last_state("crouch", 0.085):
		samus.aiming = samus.aim.SKY
		reset_idle_timer = true
	elif Input.is_action_just_pressed("pad_down"):
		change_state("crouch")
		return
	else:
		samus.aiming = samus.aim.FRONT
	
	var animation: String
	var aiming = samus.aiming
	
	if play_transition and "run_transition" in Global.timers:
		aiming = Global.timers["run_transition"][1]["aiming"]
		Global.clear_timer("run_transition")
	
	match aiming:
		samus.aim.SKY: animation = "aim_sky"
		samus.aim.UP: animation = "aim_up"
		samus.aim.DOWN: animation = "aim_down"
		_: animation = "aim_front"
	
	if play_transition:
		samus.states["run"].animations["turn_" + animation].play()
	elif ((not animator.current[false] in idle_animations) or reset_idle_timer) and not animator.transitioning(false, true):
		animations[animation].play(true)
	
	if reset_idle_timer:
		idle_timer.start()
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	samus.change_state(new_state_key, data)
	idle_timer.stop()

# Called by the idle timer, plays a random idle animation
func play_idle_animation(_timer_id):
	
	# Play a random idle animation and wait for it to finish
	var anim = Global.random_array_item(samus.rng, idle_animations)
	anim.play()
	yield(anim, "finished")
	
	if samus.current_state == self:
		# Restart the timer with a random time
		idle_timer.start(samus.rng.randi_range(4, 10))
#		animator.play("aim_front", {})

func physics_process(_delta: float):
	physics.decelerate_x(samus.states["run"].run_deceleration)
