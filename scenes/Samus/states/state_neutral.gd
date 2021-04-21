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
# warning-ignore:shadowed_variable
func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	self.physics = samus.physics
	idle_timer = Global.start_timer("idle_animation", -1, {}, [self, "play_idle_animation"])

	for anim in ["aim_down", "aim_front", "aim_sky", "aim_up"]:
		animations[anim] = animator.Animation.new(anim, self.id)
		
	idle_animations = [animator.Animation.new("idle_0", self.id), animator.Animation.new("idle_1", self.id)]


# Called when Samus's state is changed to this one
# warning-ignore:unused_argument
func init(data: Dictionary):
	idle_timer.start(samus.rng.randi_range(idle_animation_interval[0], idle_animation_interval[1]))
	return self

# Called every frame while this state is active
func process(delta):
	
	# DEBUG
	if Input.is_action_just_pressed("[DEBUG] trigger_idle_animation"):
		idle_timer.stop()
		play_idle_animation("")
	
	var original_facing = samus.facing
	var play_transition = false
	var reset_idle_timer = false
	
	if not animator.transitioning():
		if Input.is_action_just_pressed("morph_shortcut"):
			animations["crouch"].play(animator, true)
			change_state("morphball")
			return
		elif Input.is_action_just_released("jump"):
			if physics.vel.x == 0:
				change_state("jump", {"jump": true})
			else:
				change_state("spin")
			return
	
	if Input.is_action_pressed("pad_left"):
		samus.facing = Global.dir.LEFT
		if original_facing == Global.dir.RIGHT:
			play_transition = true
			reset_idle_timer = true
		elif not animator.transitioning():
			change_state("run")
			return
	elif Input.is_action_pressed("pad_right"):
		samus.facing = Global.dir.RIGHT
		if original_facing == Global.dir.LEFT:
			play_transition = true
			reset_idle_timer = true
		elif not animator.transitioning():
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
		samus.states["run"].animations["turn_" + animation].play(animator, true)
	elif ((not animator.current_animation[Global.dir.NONE] in idle_animations) or reset_idle_timer):
		animations[animation].play(animator, false, true)
	
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
	anim.play(animator)
	yield(anim, "finished")
	
	if samus.current_state == self:
		# Restart the timer with a random time
		idle_timer.start(samus.rng.randi_range(4, 10))
#		animator.play("aim_front", {})

func physics_process(delta: float):
	physics.decelerate_x(samus.states["run"].run_deceleration)
