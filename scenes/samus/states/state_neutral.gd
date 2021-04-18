extends Node

var samus: Node2D
var animator: Node
var idle_timer: Timer

const id = "neutral"

const idle_animations = ["idle_0"]
const idle_animation_interval = [5, 10] 

# Called during Samus's readying period
func _init(samus: Node2D):
	self.samus = samus
	self.animator = samus.animator
	idle_timer = Global.start_timer("idle_animation", -1, {}, [self, "play_idle_animation"])

# Called when Samus's state is changed to this one
func init(previous_state: Node2D):
	idle_timer.start(samus.rng.randi_range(idle_animation_interval[0], idle_animation_interval[1]))
	return self

# Called every frame while this state is active
func process(delta):
	
	var original_facing = samus.facing
	
	var play_transition = false
	var reset_idle_timer = false
	if Input.is_action_pressed("pad_left"):
		samus.facing = samus.face.LEFT
		if original_facing == samus.face.RIGHT:
			play_transition = true
			reset_idle_timer = true
		elif not animator.playing_transition and not "transition_cooldown" in Global.timers:
			change_state("run", delta)
			return
	elif Input.is_action_pressed("pad_right"):
		samus.facing = samus.face.RIGHT
		if original_facing == samus.face.LEFT:
			play_transition = true
			reset_idle_timer = true
		elif not animator.playing_transition and not "transition_cooldown" in Global.timers:
			change_state("run", delta)
			return
	
	if Input.is_action_pressed("aim_weapon"):
		
		if samus.aiming == samus.aim.FRONT:
			samus.aiming = samus.aim.UP
		
		if Input.is_action_just_pressed("pad_up"):
			samus.aiming = samus.aim.UP
		elif Input.is_action_just_pressed("pad_down"):
			samus.aiming = samus.aim.DOWN
		
		reset_idle_timer = true
	elif Input.is_action_pressed("pad_up"):
		samus.aiming = samus.aim.SKY
		reset_idle_timer = true
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
		animator.play("turn_" + animation, {"transition": true, "state_id": "run"})
	elif ((not animator.animation_id in idle_animations) or reset_idle_timer):
		animator.play(animation, {"retain_frame": true})
	
	if reset_idle_timer:
		idle_timer.start()
	
# Changes Samus's state to the passed state script
func change_state(new_state_key: String, process_delta = null):
	samus.change_state(new_state_key, process_delta)
	idle_timer.stop()

# Called by the idle timer, plays a random idle animation
func play_idle_animation(_timer_id: String):
	
	# Play a random idle animation and wait for it to finish
	animator.play(Global.random_array_item(samus.rng, idle_animations), {"yield": true})
	yield(animator, "animation_finished")
	
	if samus.current_state == self:
		# Restart the timer with a random time
		idle_timer.start(samus.rng.randi_range(4, 10))
		animator.play("aim_front", {})

