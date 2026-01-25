extends Node2D
class_name WeaponBase
## WeaponBase - الصنف الأساسي لجميع الأسلحة

signal attack_performed

@export var weapon_id: String = ""
@export var level: int = 1

# الإحصائيات الأساسية
var base_damage: float = 5.0
var base_cooldown: float = 1.0
var base_range: float = 100.0
var weapon_type: String = ""
var weapon_name: String = ""
var icon: String = ""

# الإحصائيات الحالية (بعد الترقيات)
var current_damage: float = 5.0
var current_cooldown: float = 1.0
var current_range: float = 100.0

# المراجع
var player: Player = null
var cooldown_timer: float = 0.0
var can_attack: bool = true

# للترقيات
const DAMAGE_PER_LEVEL: float = 0.15  # +15% ضرر لكل مستوى
const COOLDOWN_PER_LEVEL: float = 0.05  # -5% كولداون لكل مستوى
const RANGE_PER_LEVEL: float = 0.08  # +8% مدى لكل مستوى

func _ready() -> void:
	_load_weapon_data()
	_calculate_stats()

func _load_weapon_data() -> void:
	var data = GameData.get_weapon(weapon_id)
	if data.is_empty():
		return
	
	base_damage = data.get("dmg", 5)
	base_cooldown = data.get("cd", 1.0)
	base_range = data.get("range", 100)
	weapon_type = data.get("type", "")
	weapon_name = data.get("name", "")
	icon = data.get("icon", "")

func _calculate_stats() -> void:
	# حساب الإحصائيات بناءً على المستوى
	var level_mult = level - 1
	
	current_damage = base_damage * (1.0 + DAMAGE_PER_LEVEL * level_mult)
	current_cooldown = base_cooldown * (1.0 - COOLDOWN_PER_LEVEL * level_mult)
	current_range = base_range * (1.0 + RANGE_PER_LEVEL * level_mult)
	
	# تطبيق مضاعفات اللاعب
	if player:
		current_damage *= player.damage_mult
		current_cooldown /= player.attack_speed_mult

func _process(delta: float) -> void:
	if not can_attack:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_attack = true

func _physics_process(_delta: float) -> void:
	if can_attack and player and not player.is_dead:
		_perform_attack()

func _perform_attack() -> void:
	# يتم تجاوزها في الأصناف الفرعية
	pass

func _start_cooldown() -> void:
	can_attack = false
	cooldown_timer = current_cooldown
	emit_signal("attack_performed")

func upgrade() -> void:
	level += 1
	_calculate_stats()

func initialize(p: Player, id: String, lvl: int = 1) -> void:
	player = p
	weapon_id = id
	level = lvl
	_load_weapon_data()
	_calculate_stats()

func get_enemies_in_range() -> Array:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var in_range = []
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist <= current_range:
				in_range.append(enemy)
	
	return in_range

func get_closest_enemy() -> Enemy:
	var enemies = get_enemies_in_range()
	if enemies.is_empty():
		return null
	
	var closest: Enemy = null
	var closest_dist: float = INF
	
	for enemy in enemies:
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest

func get_random_enemy() -> Enemy:
	var enemies = get_enemies_in_range()
	if enemies.is_empty():
		return null
	
	return enemies[randi() % enemies.size()]

func deal_damage(enemy: Enemy, multiplier: float = 1.0) -> void:
	if enemy and not enemy.is_dead:
		var dmg = current_damage * multiplier * player.get_damage()
		var knockback = (enemy.global_position - player.global_position).normalized() * 50
		enemy.take_damage(dmg, player, knockback)
