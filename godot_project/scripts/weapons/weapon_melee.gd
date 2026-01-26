extends WeaponBase
class_name WeaponMelee
## WeaponMelee - سلاح قريب المدى (السيف)

@export var arc_angle: float = 90.0  # زاوية القوس بالدرجات

@onready var visual: Sprite2D = $Visual
@onready var attack_area: Area2D = $AttackArea

var swing_direction: float = 1.0  # 1 أو -1 لتبديل اتجاه الضربة

func _ready() -> void:
	super._ready()

func _perform_attack() -> void:
	if not player:
		return
	
	# تحديد اتجاه الضربة بناءً على اتجاه اللاعب
	var facing = player.facing_direction
	var arc_center = facing.angle()
	var arc_half = deg_to_rad(arc_angle / 2.0)
	
	# الحصول على الأعداء في النطاق
	var enemies = get_enemies_in_range()
	
	for enemy in enemies:
		# فحص إذا كان العدو داخل قوس الضربة
		var to_enemy = (enemy.global_position - player.global_position).normalized()
		var angle_to_enemy = to_enemy.angle()
		var angle_diff = abs(angle_difference(arc_center, angle_to_enemy))
		
		if angle_diff <= arc_half:
			deal_damage(enemy)
	
	# تأثير بصري
	_play_swing_effect(arc_center)
	
	# تبديل اتجاه الضربة التالية
	swing_direction *= -1
	
	_start_cooldown()

func _play_swing_effect(angle: float) -> void:
	if visual:
		visual.visible = true
		visual.rotation = angle
		
		var tween = create_tween()
		tween.tween_property(visual, "rotation", angle + (swing_direction * deg_to_rad(arc_angle)), 0.15)
		tween.tween_callback(func(): visual.visible = false)

func upgrade() -> void:
	super.upgrade()
	# زيادة زاوية القوس مع المستوى
	arc_angle = 90.0 + (level * 5)
