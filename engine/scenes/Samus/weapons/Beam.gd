extends SamusWeapon

var current_types: Array = []
var current_sound_key: String

onready var sprite: AnimatedSprite = ProjectileNode.get_node("Sprite")
onready var sprite_chargebeam: AnimatedSprite = ProjectileNode.get_node("SpriteChargebeam")

onready var sounds: Dictionary = Audio.get_players_from_dir("/samus/weapons/beam/", Audio.TYPE.SAMUS)

func _ready():
	Loader.loaded_save.connect("value_set", self, "save_value_set")
	set_types()

const sound_letter_order = ["C", "S", "w", "I", "P"]
func set_types():
	var types = []
	for type in Enums.UpgradeTypes["beam"]:
		if type != Enums.Upgrade.POWERBEAM and Samus.is_upgrade_active(type):
			types.append(type)
	types.sort()
	current_types = types
	
	var animation = ""
	if len(current_types) == 0:
		animation = "b"
	else:
		for type in current_types:
			animation += Enums.Upgrade.keys()[type][0].to_lower()
	
	sprite.play(animation)
	sprite_chargebeam.play(animation)
	set_collision()
	
	ProjectileNode.get_node("IceParticles").emitting = Enums.Upgrade.ICEBEAM in current_types
	ProjectileNode.get_node("Trail").texture = sprite_chargebeam.frames.get_frame(animation, 0)
	
	# Apply damage_amount and cooldown modifiers for each current type
	damage_amount = damage_values["damage"]
	cooldown = damage_values["cooldown"]
	for type in current_types:
		var data: Dictionary = damage_values["upgrades"][Enums.Upgrade.keys()[type]]
		damage_amount *= data["damage_multiplier"]
		cooldown *= data["cooldown_multiplier"]
	
	# Set fire sound key
	var current_sound_letters: Array = []
	for type in current_types:
		current_sound_letters.append(Enums.Upgrade.keys()[type][0].to_upper())
	
	current_sound_key = ""
	for type in sound_letter_order:
		if type in current_sound_letters:
			current_sound_key += type

func set_collision():
	var texture = sprite.frames.get_frame(sprite.animation, 0)
	ProjectileNode.get_node("CollisionShape2D").shape.extents = texture.get_size()/2
	ProjectileNode.get_node("CollisionShape2D").position = sprite.position
	
	ProjectileNode.get_node("CollisionArea/CollisionShape2D").shape.extents = texture.get_size()
	ProjectileNode.get_node("CollisionArea/CollisionShape2D").position = sprite.position
	

func save_value_set(keys: Array, _value):
	if len(keys) != 4 or keys[0] != "samus" or keys[1] != "upgrades" or not keys[2] is int:
		return
	set_types()

func get_base_type(chargebeam: bool) -> int:
	var ret: int
	for type in [Enums.Upgrade.ICEBEAM, Enums.Upgrade.PLASMABEAM, Enums.Upgrade.WAVEBEAM]:
		if type in current_types:
			ret = type
			break
	if not ret:
		if chargebeam and Samus.is_upgrade_active(Enums.Upgrade.CHARGEBEAM):
			ret = Enums.Upgrade.CHARGEBEAM
		else:
			ret = Enums.Upgrade.POWERBEAM
	return ret

func get_fire_object(pos: SamusCannonPosition, chargebeam_damage_multiplier):
	if Cooldown.time_left > 0:
		return null
	
	play_fire_sound(chargebeam_damage_multiplier != null)
	sprite.visible = chargebeam_damage_multiplier == null
	sprite_chargebeam.visible = chargebeam_damage_multiplier != null
	
	var projectile_data = {"types": current_types.duplicate(), "rotation": pos.rotation, "base_type": get_base_type(chargebeam_damage_multiplier!=null)}
	
	var projectiles = []
	if Enums.Upgrade.SPAZERBEAM in current_types:
		for i in range(3):
			var projectile: SamusKinematicProjectile = ProjectileNode.duplicate()
			projectile_data["position"] = i
			projectile.init(self, pos, chargebeam_damage_multiplier, projectile_data.duplicate())
			projectile.affected_by_world = not Enums.Upgrade.WAVEBEAM in current_types
			projectiles.append(projectile)
			if i != 1:
				projectile.get_node("IceParticles").emitting = false
		
		if not Enums.Upgrade.WAVEBEAM in current_types:
			projectiles[0].position += 10*Vector2.LEFT.rotated(pos.rotation)
			projectiles[2].position += 10*Vector2.RIGHT.rotated(pos.rotation)
			
			var sprite_path = "SpriteChargebeam" if chargebeam_damage_multiplier != null else "Sprite"
			
			$Tween.interpolate_property(projectiles[0].get_node(sprite_path), "offset:y", 10, 0, 0.1)
			$Tween.interpolate_property(projectiles[2].get_node(sprite_path), "offset:y", -10, 0, 0.1)
			$Tween.start()
	else:
		var projectile: SamusKinematicProjectile = ProjectileNode.duplicate()
		projectile.init(self, pos, chargebeam_damage_multiplier, projectile_data)
		projectile.affected_by_world = not Enums.Upgrade.WAVEBEAM in current_types
		projectiles = [projectile]
	
	for projectile in projectiles:
		projectile.get_node("IceParticles").preprocess = randf()*2
		if Enums.Upgrade.PLASMABEAM in current_types:
			projectile.apply_damage = false
			projectile.data["damaged_bodies"] = []
		
	projectiles[0].burst_start(true, Enums.Upgrade.keys()[projectile_data["base_type"]] + " start")
	return projectiles

func play_fire_sound(is_chargebeam: bool):
	sounds[("sndFireBeamC" if is_chargebeam else "sndFireBeam") + current_sound_key].play()

func offset(object, offset: Vector2):
	object.position += offset

func projectile_physics_process(projectile: SamusKinematicProjectile, colliders: Array, delta: float):
	var types = projectile.data["types"]
	
	if Enums.Upgrade.WAVEBEAM in types:
		# Apply wavebeam visual effect
		if Enums.Upgrade.SPAZERBEAM in types:
			if projectile.data["position"] != 1:
				var y = -6*sin(0.075*projectile.travel_distance)*(projectile.data["position"]-1)
				projectile.position += Vector2(y, 0).rotated(projectile.data["rotation"])*delta*60
				projectile.rotation = Vector2(10, y).rotated(projectile.data["rotation"]).angle()
		else:
			var y = -4.5*cos(0.1*projectile.travel_distance)
			projectile.position += Vector2(y, 0).rotated(projectile.data["rotation"])*delta*60
			projectile.rotation = Vector2(10, y).rotated(projectile.data["rotation"]).angle()
	else:
		# Projeciles should collide with world if not wavebeam
		for collider in colliders:
			if collider.get_collision_layer_bit(19):
				projectile_collided(projectile)
	
	if Enums.Upgrade.PLASMABEAM in types:
		for collider in colliders:
			# Special damage case for plasmabeam to ensure enemies are only
			# damaged once per projectile
			if collider.has_method("damage") and not collider in projectile.data["damaged_bodies"]:
				collider.damage(
					damage_type, 
					damage_amount*(projectile.chargebeam_damage_multiplier if projectile.chargebeam_damage_multiplier != null else 1.0) * Loader.loaded_save.difficulty_data["outgoing_damage_multiplier"],
					projectile.get_node("ImpactPosition").global_position
					)
				projectile.data["damaged_bodies"].append(collider)
	else:
		# Projectiles should collide with world if not plasmabeam
		for collider in colliders:
			if collider.get_collision_layer_bit(2):
				projectile_collided(projectile)

func projectile_collided(projectile: SamusKinematicProjectile):
	if not projectile.visible:
		return
	projectile.visible = false
	projectile.moving = false
	yield(projectile.burst_end(true, Enums.Upgrade.keys()[projectile.data["base_type"]] + " end"), "completed")
	projectile.queue_free()

func fluid_splash(_projectile: SamusKinematicProjectile, _type: int):
	return "large"# if abs(projectile.velocity.y) > 5 else "small"
