extends WeaponBase
class_name WeaponProjectile
## WeaponProjectile - سلاح يطلق قذائف (النيزك، المقمع، إلخ)

@export var projectile_speed: float = 400.0
@export var projectile_count: int = 1

var projectile_scene: PackedScene

const PROJECTILES_PER_LEVEL: Array = [1, 1, 2, 2, 3, 3, 4, 4, 5, 6]

func _ready() -> void:
	super._ready()
	# TODO: تحميل مشهد القذيفة
	# projectile_scene = preload("res://scenes/projectile.tscn")

func _perform_attack() -> void:
	var target = get_closest_enemy()
	if not target:
		return
	
	var count = PROJECTILES_PER_LEVEL[min(level - 1, PROJECTILES_PER_LEVEL.size() - 1)]
	
	for i in count:
		_spawn_projectile(target, i, count)
	
	_start_cooldown()

func _spawn_projectile(target: Enemy, index: int, total: int) -> void:
	# حساب اتجاه القذيفة
	var direction = (target.global_position - player.global_position).normalized()
	
	# إضافة انتشار للقذائف المتعددة
	if total > 1:
		var spread_angle = deg_to_rad(15)  # 15 درجة انتشار
		var offset = (index - (total - 1) / 2.0) * spread_angle
		direction = direction.rotated(offset)
	
	# إنشاء القذيفة
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = player.global_position
		proj.initialize(direction, current_damage * player.get_damage(), projectile_speed, current_range)
		get_tree().current_scene.add_child(proj)
	else:
		# قذيفة مؤقتة بدون مشهد
		_create_temp_projectile(direction, target)

func _create_temp_projectile(_direction: Vector2, target: Enemy) -> void:
	# قذيفة مبسطة - ضرر مباشر مع تأخير
	var tween = create_tween()
	var travel_time = player.global_position.distance_to(target.global_position) / projectile_speed
	tween.tween_interval(travel_time)
	tween.tween_callback(func(): 
		if is_instance_valid(target) and not target.is_dead:
			deal_damage(target)
	)

func upgrade() -> void:
	super.upgrade()
	projectile_count = PROJECTILES_PER_LEVEL[min(level - 1, PROJECTILES_PER_LEVEL.size() - 1)]
