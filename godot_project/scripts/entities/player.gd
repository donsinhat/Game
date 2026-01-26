extends CharacterBody2D
class_name Player
## Player - الشخصية الرئيسية

signal health_changed(current: int, maximum: int)
signal xp_changed(current: int, required: int)
signal gold_changed(amount: int)
signal died

# ==================== الإحصائيات ====================
@export var character_id: String = "abuSulaiman"

var max_hp: int = 100
var current_hp: int = 100
var base_speed: float = 200.0
var damage_mult: float = 1.0
var attack_speed_mult: float = 1.0
var armor: float = 0.0
var crit_chance: float = 0.0
var luck: float = 1.0
var gold_mult: float = 1.0
var xp_mult: float = 1.0
var pickup_range: float = 50.0
var regen: float = 0.0
var damage_reduce: float = 0.0
var dodge_chance: float = 0.0

# الحالة
var current_xp: int = 0
var xp_to_level: int = 10
var level: int = 1
var is_dead: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false

# التأثيرات المؤقتة
var temp_effects: Array = []
var shield_amount: float = 0.0
var has_revive: bool = false

# ==================== المراجع ====================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var pickup_area: Area2D = $PickupArea
@onready var weapon_container: Node2D = $WeaponContainer
@onready var hurt_timer: Timer = $HurtTimer
@onready var regen_timer: Timer = $RegenTimer

# للتحكم باللمس
var touch_input: Vector2 = Vector2.ZERO
var joystick_active: bool = false

func _ready() -> void:
	_load_character_stats()
	_setup_signals()
	current_hp = max_hp
	emit_signal("health_changed", current_hp, max_hp)

func _load_character_stats() -> void:
	var char_data = GameData.get_character(character_id)
	if char_data.is_empty():
		return
	
	var stats = char_data.get("stats", {})
	max_hp = int(stats.get("hp", 100))
	base_speed = stats.get("speed", 200)
	crit_chance = stats.get("crit", 0)
	luck = stats.get("luck", 1)
	gold_mult = stats.get("gold", 1)
	damage_reduce = stats.get("dmgReduce", 0)
	xp_mult = stats.get("xpMult", 1)
	dodge_chance = stats.get("dodge", 0)
	
	if stats.has("pickup"):
		pickup_range *= stats.get("pickup")
	if stats.has("cooldown"):
		attack_speed_mult = 1.0 / stats.get("cooldown")
	if stats.has("range"):
		# سيتم تطبيقها على الأسلحة
		pass
	if stats.has("atkSpd"):
		attack_speed_mult *= stats.get("atkSpd")
	if stats.has("dmgMult"):
		damage_mult *= stats.get("dmgMult")
	if stats.has("poison"):
		# سيتم التعامل معها في نظام الأسلحة
		pass

func _setup_signals() -> void:
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	if pickup_area:
		pickup_area.area_entered.connect(_on_pickup_area_entered)
	if regen_timer:
		regen_timer.timeout.connect(_on_regen_tick)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# الحصول على اتجاه الحركة
	var input_dir = _get_input_direction()
	
	# تحديث الاتجاه
	if input_dir != Vector2.ZERO:
		facing_direction = input_dir.normalized()
		is_moving = true
	else:
		is_moving = false
	
	# حساب السرعة
	var speed = base_speed * _get_speed_multiplier()
	velocity = input_dir.normalized() * speed
	
	# الحركة
	move_and_slide()
	
	# تحديث الرسوم المتحركة
	_update_animation()
	
	# تحديث التأثيرات المؤقتة
	_update_temp_effects(delta)
	
	# حدود العالم
	_clamp_to_world()

func _get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	
	# التحكم بلوحة المفاتيح
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	
	# التحكم باللمس (الجويستيك الافتراضي)
	if joystick_active:
		direction = touch_input
	
	return direction

func _get_speed_multiplier() -> float:
	var mult = 1.0
	for effect in temp_effects:
		if effect.type == "speed":
			mult *= (1.0 + effect.value)
	return mult

func _update_animation() -> void:
	if not sprite:
		return
	
	if is_moving:
		sprite.play("walk")
		sprite.flip_h = facing_direction.x < 0
	else:
		sprite.play("idle")

func _update_temp_effects(delta: float) -> void:
	var to_remove = []
	for i in range(temp_effects.size()):
		temp_effects[i].duration -= delta
		if temp_effects[i].duration <= 0:
			to_remove.append(i)
	
	# إزالة التأثيرات المنتهية (من الآخر للأول)
	for i in range(to_remove.size() - 1, -1, -1):
		temp_effects.remove_at(to_remove[i])

func _clamp_to_world() -> void:
	var half_size = GameData.WORLD_SIZE / 2.0
	position.x = clamp(position.x, -half_size, half_size)
	position.y = clamp(position.y, -half_size, half_size)

# ==================== التعرض للضرر ====================

func take_damage(amount: float, _source: Node2D = null) -> void:
	if is_dead or hurt_timer.time_left > 0:
		return
	
	# فحص التفادي
	if randf() < dodge_chance:
		_show_dodge_text()
		return
	
	# تطبيق الدرع أولاً
	if shield_amount > 0:
		var absorbed = min(shield_amount, amount)
		shield_amount -= absorbed
		amount -= absorbed
	
	# تطبيق تقليل الضرر
	amount *= (1.0 - armor)
	amount *= (1.0 - damage_reduce)
	
	# الحد الأدنى للضرر
	amount = max(1, amount)
	
	current_hp -= int(amount)
	emit_signal("health_changed", current_hp, max_hp)
	
	# تأثير التعرض للضرر
	_play_hurt_effect()
	hurt_timer.start(0.5)  # فترة المناعة
	
	if current_hp <= 0:
		_handle_death()

func _handle_death() -> void:
	# فحص الإحياء
	if has_revive:
		has_revive = false
		current_hp = max_hp
		emit_signal("health_changed", current_hp, max_hp)
		_show_revive_effect()
		return
	
	is_dead = true
	emit_signal("died")

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("health_changed", current_hp, max_hp)
	_show_heal_effect()

func full_heal(bonus_hp: int = 0) -> void:
	max_hp += bonus_hp
	current_hp = max_hp
	emit_signal("health_changed", current_hp, max_hp)

func _play_hurt_effect() -> void:
	# تأثير وميض أحمر
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _show_dodge_text() -> void:
	# TODO: إظهار نص "تفادي!"
	pass

func _show_heal_effect() -> void:
	# TODO: تأثير الشفاء
	pass

func _show_revive_effect() -> void:
	# TODO: تأثير الإحياء
	pass

# ==================== الخبرة والمستوى ====================

func add_xp(amount: int) -> void:
	amount = int(amount * xp_mult)
	current_xp += amount
	
	while current_xp >= xp_to_level:
		current_xp -= xp_to_level
		_level_up()
	
	emit_signal("xp_changed", current_xp, xp_to_level)

func _level_up() -> void:
	level += 1
	xp_to_level = _calculate_xp_required(level)
	GameManager.trigger_level_up()

func _calculate_xp_required(lvl: int) -> int:
	# معادلة الخبرة المطلوبة
	return 10 + (lvl * 5)

# ==================== الذهب ====================

func add_gold(amount: int) -> void:
	amount = int(amount * gold_mult)
	GameManager.add_gold(amount)
	emit_signal("gold_changed", GameManager.gold)

# ==================== التأثيرات ====================

func add_temp_effect(type: String, value: float, duration: float) -> void:
	temp_effects.append({
		"type": type,
		"value": value,
		"duration": duration
	})

func add_shield(amount: float) -> void:
	shield_amount += amount

func set_revive(has_it: bool) -> void:
	has_revive = has_it

# ==================== الترقيات ====================

func apply_book_upgrade(stat: String, value: float) -> void:
	match stat:
		"damage":
			damage_mult += value
		"atkSpd":
			attack_speed_mult += value
		"moveSpd":
			base_speed *= (1.0 + value)
		"xp":
			xp_mult += value
		"maxHp":
			var bonus = int(max_hp * value)
			max_hp += bonus
			current_hp += bonus
			emit_signal("health_changed", current_hp, max_hp)
		"armor":
			armor = min(armor + value, 0.75)  # حد أقصى 75%
		"pickup":
			pickup_range *= (1.0 + value)
			_update_pickup_area()
		"luck":
			luck += value
		"curse":
			# يتم التعامل معها في GameManager
			pass
		"regen":
			regen += value
			if regen > 0 and regen_timer.is_stopped():
				regen_timer.start(1.0)
		"crit":
			crit_chance += value

func _update_pickup_area() -> void:
	if pickup_area and pickup_area.has_node("CollisionShape2D"):
		var shape = pickup_area.get_node("CollisionShape2D").shape
		if shape is CircleShape2D:
			shape.radius = pickup_range

func _on_regen_tick() -> void:
	if regen > 0 and current_hp < max_hp:
		heal(int(regen))

# ==================== الالتقاط ====================

func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickup"):
		area.collect(self)

func _on_hitbox_area_entered(_area: Area2D) -> void:
	# التعامل مع ضربات الأعداء يتم في Enemy
	pass

# ==================== التحكم باللمس ====================

func set_joystick_input(input: Vector2) -> void:
	touch_input = input
	joystick_active = input.length() > 0.1

# ==================== مساعد ====================

func get_damage() -> float:
	var dmg = damage_mult
	# فحص الضربة الحرجة
	if randf() < crit_chance:
		dmg *= 2.0
	return dmg

func get_attack_speed() -> float:
	var spd = attack_speed_mult
	for effect in temp_effects:
		if effect.type == "atkSpd":
			spd *= (1.0 + effect.value)
	return spd
