extends WeaponBase
class_name WeaponChain
## WeaponChain - سلاح يقفز بين الأعداء (العقل)

@export var chain_count: int = 2
@export var chain_range: float = 150.0
@export var damage_decay: float = 0.2  # -20% ضرر لكل قفزة

const CHAINS_PER_LEVEL: Array = [2, 2, 3, 3, 4, 4, 5, 5, 6, 8]

func _ready() -> void:
	super._ready()

func _perform_attack() -> void:
	var target = get_closest_enemy()
	if not target:
		return
	
	var chains = CHAINS_PER_LEVEL[min(level - 1, CHAINS_PER_LEVEL.size() - 1)]
	_chain_attack(target, chains, 1.0, [])
	
	_start_cooldown()

func _chain_attack(current_target: Enemy, remaining_chains: int, damage_mult: float, hit_enemies: Array) -> void:
	if not is_instance_valid(current_target) or current_target.is_dead:
		return
	
	# إضافة للقائمة المضروبة
	hit_enemies.append(current_target)
	
	# إلحاق الضرر
	var dmg = current_damage * damage_mult * player.get_damage()
	current_target.take_damage(dmg, player)
	
	# تأثير بصري
	_spawn_chain_effect(current_target.global_position)
	
	# البحث عن الهدف التالي
	if remaining_chains > 0:
		var next_target = _find_next_target(current_target, hit_enemies)
		if next_target:
			# تأخير قصير قبل القفزة التالية
			await get_tree().create_timer(0.1).timeout
			_chain_attack(next_target, remaining_chains - 1, damage_mult * (1.0 - damage_decay), hit_enemies)

func _find_next_target(from_enemy: Enemy, exclude: Array) -> Enemy:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Enemy = null
	var closest_dist: float = chain_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue
		if enemy in exclude:
			continue
		
		var dist = from_enemy.global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest

func _spawn_chain_effect(pos: Vector2) -> void:
	# تأثير بصري للقفزة
	var effect = AnimatedSprite2D.new()
	effect.global_position = pos
	effect.scale = Vector2(1.5, 1.5)
	
	var texture = load("res://assets/weapons/New Weapons/brain/effect.png")
	if texture:
		var frames = SpriteFrames.new()
		frames.add_animation("hit")
		frames.set_animation_loop("hit", false)
		frames.set_animation_speed("hit", 15.0)
		
		var frame_width = 64
		var frame_count = texture.get_width() / frame_width
		for i in range(frame_count):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, texture.get_height())
			frames.add_frame("hit", atlas)
		
		effect.sprite_frames = frames
		effect.play("hit")
		effect.animation_finished.connect(func(): effect.queue_free())
	
	get_tree().current_scene.add_child(effect)

func upgrade() -> void:
	super.upgrade()
	chain_count = CHAINS_PER_LEVEL[min(level - 1, CHAINS_PER_LEVEL.size() - 1)]
