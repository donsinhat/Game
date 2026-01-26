extends WeaponBase
class_name WeaponMelee
## WeaponMelee - سلاح قريب المدى (السيف)

@export var arc_angle: float = 90.0  # زاوية القوس بالدرجات

var visual: AnimatedSprite2D = null
var attack_area: Area2D = null

var swing_direction: float = 1.0  # 1 أو -1 لتبديل اتجاه الضربة

func _ready() -> void:
	super._ready()
	_setup_visual()

func _setup_visual() -> void:
	# إنشاء تأثير بصري للسيف
	visual = AnimatedSprite2D.new()
	visual.visible = false
	visual.scale = Vector2(2, 2)
	add_child(visual)
	
	var texture = load("res://assets/weapons/New Weapons/sword/effect.png")
	if texture:
		var frames = SpriteFrames.new()
		frames.add_animation("swing")
		frames.set_animation_loop("swing", false)
		frames.set_animation_speed("swing", 15.0)
		
		var frame_width = 64
		var frame_count = texture.get_width() / frame_width
		for i in range(frame_count):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, texture.get_height())
			frames.add_frame("swing", atlas)
		
		visual.sprite_frames = frames

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
		visual.rotation = angle + (swing_direction * PI / 4)
		visual.flip_h = swing_direction < 0
		
		# تشغيل الأنيميشن
		visual.play("swing")
		
		# إخفاء بعد انتهاء الأنيميشن
		await get_tree().create_timer(0.2).timeout
		visual.visible = false

func upgrade() -> void:
	super.upgrade()
	# زيادة زاوية القوس مع المستوى
	arc_angle = 90.0 + (level * 5)
