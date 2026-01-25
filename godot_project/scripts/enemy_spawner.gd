extends Node2D
class_name EnemySpawner
## EnemySpawner - نظام توليد الأعداء

signal enemy_died(enemy: Enemy, position: Vector2)

@export var base_spawn_rate: float = 1.5  # عدد الأعداء في الثانية
@export var spawn_distance_min: float = 400.0
@export var spawn_distance_max: float = 600.0
@export var max_enemies: int = 100

var player: Player = null
var spawn_timer: float = 0.0
var enemy_scene: PackedScene

# أنواع الأعداء المتاحة حسب الوقت
var enemy_types_by_time: Array = [
	{"time": 0, "types": ["flyingEye", "goblin"]},
	{"time": 30, "types": ["flyingEye", "goblin", "mushroom"]},
	{"time": 60, "types": ["goblin", "mushroom", "skeleton"]},
	{"time": 120, "types": ["mushroom", "skeleton"]}
]

func _ready() -> void:
	# TODO: تحميل مشهد العدو
	# enemy_scene = preload("res://scenes/enemy.tscn")
	pass

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	if not player:
		return
	
	spawn_timer += delta
	
	var spawn_rate = _get_current_spawn_rate()
	var spawn_interval = 1.0 / spawn_rate
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_try_spawn_enemy()

func _get_current_spawn_rate() -> float:
	var rate = base_spawn_rate
	
	# زيادة المعدل مع الوقت
	var minutes = GameManager.game_time / 60.0
	rate += minutes * 0.5
	
	# تطبيق تأثير اللعنة
	# TODO: الحصول على قيمة اللعنة من اللاعب
	
	return rate

func _try_spawn_enemy() -> void:
	# فحص الحد الأقصى
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	if current_enemies >= max_enemies:
		return
	
	# توليد موقع عشوائي حول اللاعب
	var spawn_pos = _get_random_spawn_position()
	
	# اختيار نوع العدو
	var enemy_type = _get_random_enemy_type()
	
	# إنشاء العدو
	_spawn_enemy(enemy_type, spawn_pos)

func _get_random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	
	var spawn_pos = player.global_position + offset
	
	# التأكد من البقاء داخل حدود العالم
	var half_world = GameData.WORLD_SIZE / 2.0
	spawn_pos.x = clamp(spawn_pos.x, -half_world, half_world)
	spawn_pos.y = clamp(spawn_pos.y, -half_world, half_world)
	
	return spawn_pos

func _get_random_enemy_type() -> String:
	var available_types: Array = []
	var current_time = GameManager.game_time
	
	# الحصول على الأنواع المتاحة بناءً على الوقت
	for tier in enemy_types_by_time:
		if current_time >= tier.time:
			available_types = tier.types
	
	if available_types.is_empty():
		available_types = ["goblin"]
	
	return available_types[randi() % available_types.size()]

func _spawn_enemy(enemy_type: String, pos: Vector2) -> void:
	var enemy: Enemy
	
	if enemy_scene:
		enemy = enemy_scene.instantiate()
	else:
		# إنشاء عدو بدون مشهد (للاختبار)
		enemy = Enemy.new()
		
		# إضافة المكونات الأساسية
		var sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		enemy.add_child(sprite)
		
		var hitbox = Area2D.new()
		hitbox.name = "Hitbox"
		var collision = CollisionShape2D.new()
		collision.shape = CircleShape2D.new()
		collision.shape.radius = 20
		hitbox.add_child(collision)
		enemy.add_child(hitbox)
		
		var attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		attack_timer.one_shot = true
		enemy.add_child(attack_timer)
	
	enemy.initialize(enemy_type, pos, player)
	enemy.add_to_group("enemies")
	enemy.died.connect(_on_enemy_died)
	
	get_tree().current_scene.add_child(enemy)

func _on_enemy_died(enemy: Enemy, pos: Vector2) -> void:
	emit_signal("enemy_died", enemy, pos)
