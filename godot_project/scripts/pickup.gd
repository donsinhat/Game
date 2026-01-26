extends Area2D
class_name Pickup
## Pickup - الآيتم الملتقط (XP, Gold, Items, Chests)

var value: int = 1
var is_collected: bool = false

# للحركة نحو اللاعب
var move_to_player: bool = false
var target_player: Player = null
var move_speed: float = 500.0

func _ready() -> void:
	# إضافة collision للـ pickup area
	collision_layer = 4  # pickup layer
	collision_mask = 0

func _physics_process(delta: float) -> void:
	if move_to_player and target_player and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta
		
		# إذا وصلنا للاعب
		if global_position.distance_to(target_player.global_position) < 20:
			_apply_effect(target_player)
			queue_free()

## يجمع الآيتم
func collect(player: Player) -> void:
	if is_collected:
		return
	
	is_collected = true
	
	var pickup_type = get_meta("type", "xp")
	
	# الآيتمات تتحرك نحو اللاعب أولاً
	if pickup_type in ["xp", "gold"]:
		# XP والذهب يطبقون مباشرة
		_apply_effect(player)
		_play_collect_effect()
		queue_free()
	else:
		# الآيتمات والصناديق تتحرك ثم تطبق
		move_to_player = true
		target_player = player
		_play_collect_effect()

## يطبق تأثير الآيتم
func _apply_effect(player: Player) -> void:
	var pickup_type = get_meta("type", "xp")
	
	match pickup_type:
		"xp":
			player.add_xp(value)
		"gold":
			player.add_gold(value)
		"item":
			_apply_item_effect(player)
		"chest":
			_open_chest(player)

## يطبق تأثير الآيتم حسب نوعه
func _apply_item_effect(player: Player) -> void:
	var rarity = get_meta("rarity", "COMMON")
	var item_data = GameData.get_random_item(rarity)
	
	if item_data.is_empty():
		return
	
	var effect = item_data.get("effect", "")
	var val = item_data.get("val", 0)
	var dur = item_data.get("dur", 0)
	
	match effect:
		"heal":
			player.heal(int(val))
		"fullHeal":
			player.full_heal(int(val))
		"tempSpeed":
			player.add_temp_effect("speed", val, dur)
		"tempDmg":
			player.add_temp_effect("damage", val, dur)
		"tempAtkSpd":
			player.add_temp_effect("atkSpd", val, dur)
		"shield":
			player.add_shield(val)
		"slow":
			_slow_all_enemies(val, dur)
		"revive":
			player.set_revive(true)
		"permGold":
			player.gold_mult += val
		"randomEquip":
			GameManager.give_random_equipment()
		"gold":
			player.add_gold(int(val))
		"moreEnemies":
			GameManager.increase_enemy_spawn_rate(val)
	
	# عرض اسم الآيتم
	_show_item_name(item_data.get("name", ""), item_data.get("icon", ""))

## يفتح الصندوق ويعطي مكافآت
func _open_chest(player: Player) -> void:
	# الصندوق يعطي عدة مكافآت
	var rewards_count = randi_range(2, 4)
	
	for i in range(rewards_count):
		var rarity = GameData.get_random_rarity(player.luck)
		var item_data = GameData.get_random_item(rarity)
		
		if not item_data.is_empty():
			var effect = item_data.get("effect", "")
			var val = item_data.get("val", 0)
			
			match effect:
				"heal":
					player.heal(int(val))
				"gold":
					player.add_gold(int(val))
				_:
					# باقي التأثيرات
					pass
	
	# ذهب إضافي من الصندوق
	player.add_gold(randi_range(10, 50))
	
	_show_item_name("صندوق كنز!", "📦")

## يبطئ كل الأعداء
func _slow_all_enemies(amount: float, duration: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(1.0 - amount, duration)

## يعرض اسم الآيتم
func _show_item_name(item_name: String, icon: String) -> void:
	# TODO: إظهار نص الآيتم فوق اللاعب
	print("[Pickup] %s %s" % [icon, item_name])

## تأثير الجمع
func _play_collect_effect() -> void:
	# تأثير بسيط - تكبير ثم اختفاء
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
