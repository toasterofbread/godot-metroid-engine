extends SamusState

var Animator: Node
var Physics: Node
var animations: Dictionary
var sounds: Dictionary
var physics_data: Dictionary

var InvincibilityTimer: ExTimer

func _init(_Samus: Node2D, _id).(_Samus, _id):
	yield(Samus, "ready")
	InvincibilityTimer = Samus.InvincibilityTimer

# Called when Samus' state is changed to this one
func init_state(data: Dictionary, _previous_state_id: String):
	Physics.apply_velocity = true
	Physics.apply_gravity = true
	Animator.SpriteContainer.current_profile = null
	sounds["sndHurt"].play()
	yield(animations["knockback"].play(), "completed")
	if Samus.is_on_floor():
		change_state("neutral")
	else:
		change_state("jump", {"options": []})
