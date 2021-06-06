extends AnimatedSprite

func _ready():
	material.set_shader_param("nb_frames",Vector2(1, 1))

func _process(delta):
	material.set_shader_param("frame_coords", Vector2(0, 0))
	material.set_shader_param("velocity", Loader.Samus.Physics.vel)
