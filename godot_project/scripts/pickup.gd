extends Area2D
class_name Pickup
## Pickup - الأشياء القابلة للجمع

@export var value: int = 1
@export var pickup_type: String = "xp"  # xp, gold, item

var is_collected: bool = false
var magnet_speed: float = 0.0
var target: Node2D = null

func _ready() -> void:
	# الحصول على النوع من الميتا إذا موجود
	if has_meta("type"):
		pickup_type = get_meta("type")

func _process(delta: float) -> void:
	# حركة المغناطيس نحو اللاعب
	if target and magnet_speed > 0:
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta
		magnet_speed += 500 * delta  # تسارع

func collect(player: Player) -> void:
	if is_collected:
		return
	
	is_collected = true
	
	match pickup_type:
		"xp":
			player.add_xp(value)
		"gold":
			player.add_gold(value)
		"item":
			_collect_item(player)
	
	# تأثير الجمع
	_play_collect_effect()
	queue_free()

func _collect_item(_player) -> void:
	# TODO: معالجة جمع الأيتم
	# عرض نافذة الأيتم
	pass

func _play_collect_effect() -> void:
	# TODO: تأثير بصري وصوتي
	pass

func start_magnet(player: Node2D) -> void:
	target = player
	magnet_speed = 100.0

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collect(body)
