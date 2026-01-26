extends CharacterBody2D
class_name Enemy
## Enemy - العدو الأساسي

signal died(enemy: Enemy, position: Vector2)

# ==================== الإحصائيات ====================
@export var enemy_type: String = "goblin"

var max_hp: float = 22
var current_hp: float = 22
var attack_damage: float = 10
var move_speed: float = 65
var xp_value: int = 4
var is_ranged: bool = false

# الحالة
var is_dead: bool = false
var target: Node2D = null
var knockback_velocity: Vector2 = Vector2.ZERO
var slow_multiplier: float = 1.0
var is_poisoned: bool = false
var poison_damage: float = 0.0
var poison_timer: float = 0.0

# ==================== المراجع ====================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar

# للتأثيرات
var damage_numbers_scene: PackedScene

func _ready() -> void:
	_load_enemy_stats()
	_setup_signals()
	current_hp = max_hp
	_update_health_bar()
	
	# إخفاء شريط الصحة في البداية
	if health_bar:
		health_bar.visible = false

func _load_enemy_stats() -> void:
	var enemy_data = GameData.get_enemy(enemy_type)
	if enemy_data.is_empty():
		return
	
	var scaling = GameManager.get_scaling_multiplier()
	var enemy_buff = 1.0
	
	# الحصول على buff الأعداء من الشخصية المختارة
	var char_data = GameData.get_character(GameManager.selected_character)
	if char_data and char_data.has("stats"):
		enemy_buff += char_data["stats"].get("enemyBuff", 0)
	
	# تطبيق الإحصائيات
	max_hp = GameData.ENEMY_BASE_HP * enemy_data.get("hpM", 1.0) * scaling * enemy_buff
	attack_damage = GameData.ENEMY_BASE_ATK * enemy_data.get("atkM", 1.0) * scaling * enemy_buff
	move_speed = GameData.ENEMY_BASE_SPEED * enemy_data.get("spdM", 1.0)
	xp_value = enemy_data.get("xp", 4)
	is_ranged = enemy_data.get("ranged", false)

func _setup_signals() -> void:
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# تحديث السم
	if is_poisoned:
		_update_poison(delta)
	
	# الحركة نحو اللاعب
	if target and is_instance_valid(target):
		_move_towards_target(delta)
	
	# تطبيق الارتداد
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
	
	move_and_slide()
	
	# تحديث الرسوم
	_update_animation()

func _move_towards_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	var speed = move_speed * slow_multiplier
	
	# للأعداء البعيدين، حافظ على مسافة
	if is_ranged:
		var distance = global_position.distance_to(target.global_position)
		if distance < 150:
			direction = -direction  # ابتعد
		elif distance < 200:
			direction = Vector2.ZERO  # توقف
	
	velocity = direction * speed

func _update_animation() -> void:
	if not sprite:
		return
	
	if velocity.length() > 10:
		sprite.play("walk")
		sprite.flip_h = velocity.x < 0
	else:
		sprite.play("idle")

# ==================== التعرض للضرر ====================

func take_damage(amount: float, _source: Node2D = null, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	
	current_hp -= amount
	_update_health_bar()
	_play_hurt_effect()
	_spawn_damage_number(amount)
	
	# تطبيق الارتداد
	if knockback != Vector2.ZERO:
		knockback_velocity = knockback
	
	# إظهار شريط الصحة
	if health_bar:
		health_bar.visible = true
	
	if current_hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	emit_signal("died", self, global_position)
	GameManager.add_kill()
	
	# تأثير الموت
	_play_death_effect()
	
	# تأخير قبل الحذف
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func _play_hurt_effect() -> void:
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)

func _play_death_effect() -> void:
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)

func _spawn_damage_number(_amount: float) -> void:
	# TODO: إنشاء رقم الضرر العائم
	pass

# ==================== السم والإبطاء ====================

func apply_poison(damage: float, duration: float) -> void:
	is_poisoned = true
	poison_damage = damage
	poison_timer = duration
	
	# تلوين أخضر للسم
	if sprite:
		sprite.modulate = Color(0.5, 1.0, 0.5)

func _update_poison(delta: float) -> void:
	poison_timer -= delta
	if poison_timer <= 0:
		is_poisoned = false
		if sprite:
			sprite.modulate = Color.WHITE
		return
	
	# ضرر السم كل ثانية (يتم التحقق كل فريم)
	# poison_damage هو الضرر في الثانية
	take_damage(poison_damage * delta, null)

func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = multiplier
	
	# تلوين أزرق للإبطاء
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.0)
	
	await get_tree().create_timer(duration).timeout
	slow_multiplier = 1.0
	if sprite and not is_poisoned:
		sprite.modulate = Color.WHITE

# ==================== الهجوم ====================

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		_attack_player(body)

func _on_attack_timer_timeout() -> void:
	# يمكن الهجوم مرة أخرى
	pass

func _attack_player(player: Player) -> void:
	if attack_timer.time_left > 0:
		return
	
	player.take_damage(attack_damage, self)
	attack_timer.start(1.0)  # فترة انتظار بين الهجمات

# ==================== الإعداد ====================

func set_target(new_target: Node2D) -> void:
	target = new_target

func initialize(type: String, pos: Vector2, player: Node2D) -> void:
	enemy_type = type
	global_position = pos
	target = player
	_load_enemy_stats()
	current_hp = max_hp
