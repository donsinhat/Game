extends WeaponBase
class_name WeaponAura
## WeaponAura - هالة ضرر حول اللاعب (الهيبة)

@onready var area: Area2D = $Area2D
@onready var visual: Sprite2D = $Visual

var pulse_timer: float = 0.0
var is_pulsing: bool = false

func _ready() -> void:
	super._ready()
	_update_area_size()

func _update_area_size() -> void:
	if area and area.has_node("CollisionShape2D"):
		var shape = area.get_node("CollisionShape2D").shape
		if shape is CircleShape2D:
			shape.radius = current_range
	
	if visual:
		var scale_factor = current_range / 60.0  # 60 هو الحجم الافتراضي
		visual.scale = Vector2(scale_factor, scale_factor)

func _perform_attack() -> void:
	if not player:
		return
	
	# الحصول على الأعداء في النطاق
	var enemies = get_enemies_in_range()
	
	for enemy in enemies:
		deal_damage(enemy)
	
	# تأثير بصري
	_play_pulse_effect()
	
	_start_cooldown()

func _play_pulse_effect() -> void:
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, "modulate:a", 0.8, 0.1)
		tween.tween_property(visual, "modulate:a", 0.3, 0.2)

func upgrade() -> void:
	super.upgrade()
	_update_area_size()
