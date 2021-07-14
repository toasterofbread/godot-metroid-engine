extends Node

var Samus: KinematicBody2D
var Animator: Node
var Physics: Node
const id = "hurt"
var animations: Dictionary
var physics_data: Dictionary

var InvincibilityTimer: ExTimer

func _init(_samus: Node2D):
	Samus = _samus
	Animator = Samus.Animator
	Physics = Samus.Physics
	animations = Animator.load_from_json(self.id)
	physics_data = Physics.data[id]
	
	yield(Samus, "ready")
	InvincibilityTimer = Samus.InvincibilityTimer

# Called every frame while this state is active
func process(_delta: float):
	pass

# Called when Samus' state is changed to this one
func init_state(data: Dictionary):
	yield(animations["knockback"].play(), "completed")
	if Samus.is_on_floor():
		change_state("neutral")
	else:
		change_state("jump", {"options": []})

# Changes Samus' state to the passed state script
func change_state(new_state_key: String, data: Dictionary = {}):
	Samus.change_state(new_state_key, data)

func physics_process(_delta: float):
	pass
