extends WeaponBase
class_name WeaponAura
## WeaponAura - هالة ضرر حول اللاعب (الهيبة)

var area: Area2D = null
var visual: AnimatedSprite2D = null

var pulse_timer: float = 0.0
var is_pulsing: bool = false

func _ready() -> void:
	super._ready()
	_setup_visual()
	_setup_area()
	_update_area_size()

func _setup_visual() -> void:
	visual = AnimatedSprite2D.new()
	visual.modulate.a = 0.5
	add_child(visual)
	
	var texture = load("res://assets/weapons/New Weapons/aura/effect.png")
	if texture:
		var frames = SpriteFrames.new()
		frames.add_animation("pulse")
		frames.set_animation_loop("pulse", true)
		frames.set_animation_speed("pulse", 8.0)
		
		var frame_width = 64
		var frame_count = texture.get_width() / frame_width
		for i in range(frame_count):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, texture.get_height())
			frames.add_frame("pulse", atlas)
		
		visual.sprite_frames = frames
		visual.play("pulse")

func _setup_area() -> void:
	area = Area2D.new()
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = current_range
	area.add_child(collision)
	add_child(area)

func _update_area_size() -> void:
	if area and area.get_child_count() > 0:
		var shape_node = area.get_child(0)
		if shape_node is CollisionShape2D and shape_node.shape is CircleShape2D:
			shape_node.shape.radius = current_range
	
	if visual:
		var scale_factor = current_range / 32.0  # تعديل الحجم
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
