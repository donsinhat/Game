extends WeaponBase
class_name WeaponOrbit
## WeaponOrbit - سلاح يدور حول اللاعب (العقال)

@export var orbit_count: int = 1  # عدد العناصر الدوارة
@export var orbit_speed: float = 3.0  # سرعة الدوران

var current_angle: float = 0.0
var orbit_sprites: Array[Sprite2D] = []
var hit_enemies: Dictionary = {}  # لتتبع الأعداء الذين تم ضربهم

# تأثير الترقية
const ORBITS_PER_LEVEL: Array = [1, 1, 2, 2, 3, 3, 4, 4, 5, 6]

func _ready() -> void:
	super._ready()
	_update_orbit_count()

func _update_orbit_count() -> void:
	var new_count = ORBITS_PER_LEVEL[min(level - 1, ORBITS_PER_LEVEL.size() - 1)]
	
	# إزالة السبرايتات القديمة
	for sprite in orbit_sprites:
		sprite.queue_free()
	orbit_sprites.clear()
	
	# تحميل تكستشر السلاح
	var texture = load("res://assets/weapons/New Weapons/agal/effect.png")
	
	# إنشاء السبرايتات الجديدة
	orbit_count = new_count
	for i in orbit_count:
		var sprite = AnimatedSprite2D.new()
		
		if texture:
			# إنشاء SpriteFrames من sprite sheet
			var frames = SpriteFrames.new()
			frames.add_animation("spin")
			frames.set_animation_loop("spin", true)
			frames.set_animation_speed("spin", 8.0)
			
			# تقسيم sprite sheet إلى إطارات (64x64 لكل إطار)
			var frame_count = texture.get_width() / 64
			for f in range(frame_count):
				var atlas = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(f * 64, 0, 64, 64)
				frames.add_frame("spin", atlas)
			
			sprite.sprite_frames = frames
			sprite.play("spin")
		else:
			# fallback
			sprite.modulate = Color.GOLD
		
		sprite.scale = Vector2(1.5, 1.5)
		add_child(sprite)
		orbit_sprites.append(sprite)

func _physics_process(delta: float) -> void:
	if not player or player.is_dead:
		return
	
	# تحديث زاوية الدوران
	current_angle += orbit_speed * delta
	
	# تحديث مواقع السبرايتات
	var angle_step = TAU / orbit_count
	for i in orbit_count:
		if i < orbit_sprites.size():
			var angle = current_angle + (i * angle_step)
			var offset = Vector2(cos(angle), sin(angle)) * current_range
			orbit_sprites[i].position = offset
	
	# فحص الاصطدام
	_check_collision()
	
	# إعادة تعيين قائمة الأعداء المضروبين
	_reset_hit_list(delta)

func _check_collision() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for sprite in orbit_sprites:
		var orbit_pos = global_position + sprite.position
		
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.is_dead:
				continue
			
			# فحص إذا تم ضرب هذا العدو مؤخراً
			var enemy_id = enemy.get_instance_id()
			if hit_enemies.has(enemy_id):
				continue
			
			var dist = orbit_pos.distance_to(enemy.global_position)
			if dist < 30:  # نصف قطر الاصطدام
				deal_damage(enemy)
				hit_enemies[enemy_id] = current_cooldown

func _reset_hit_list(delta: float) -> void:
	var to_remove = []
	for enemy_id in hit_enemies.keys():
		hit_enemies[enemy_id] -= delta
		if hit_enemies[enemy_id] <= 0:
			to_remove.append(enemy_id)
	
	for id in to_remove:
		hit_enemies.erase(id)

func _perform_attack() -> void:
	# السلاح الدوار لا يحتاج لتنفيذ هجوم منفصل
	pass

func upgrade() -> void:
	super.upgrade()
	_update_orbit_count()
