extends Node2D
class_name PickupSpawner
## PickupSpawner - نظام توليد الملتقطات (XP, Gold, Items)

var player: Player = null

# مشاهد الملتقطات
var xp_scene: PackedScene
var gold_scene: PackedScene
var item_scene: PackedScene

# حد أقصى للآيتمات على الأرض (لمنع تعليق اللعبة)
const MAX_ITEMS_ON_GROUND: int = 10

func _ready() -> void:
	# TODO: تحميل المشاهد
	pass

## يحسب عدد الآيتمات (بدون XP والذهب) الموجودة حالياً
func get_item_count() -> int:
	var count = 0
	var pickups = get_tree().get_nodes_in_group("pickup")
	for pickup in pickups:
		if is_instance_valid(pickup):
			var pickup_type = pickup.get_meta("type", "")
			if pickup_type == "item" or pickup_type == "chest":
				count += 1
	return count

## يتحقق إذا ممكن نضيف آيتم جديد
func can_spawn_item() -> bool:
	return get_item_count() < MAX_ITEMS_ON_GROUND

func spawn_xp(pos: Vector2, value: int) -> void:
	var pickup = _create_pickup("xp", pos)
	if pickup:
		pickup.value = value
		pickup.set_meta("type", "xp")

func spawn_gold(pos: Vector2, value: int) -> void:
	var pickup = _create_pickup("gold", pos)
	if pickup:
		pickup.value = value
		pickup.set_meta("type", "gold")

func spawn_item(pos: Vector2) -> void:
	# تحقق من الحد الأقصى للآيتمات
	if not can_spawn_item():
		return
	
	var pickup = _create_pickup("item", pos)
	if pickup:
		# اختيار أيتم عشوائي
		var rarity = GameData.get_random_rarity(player.luck if player else 1.0)
		pickup.set_meta("type", "item")
		pickup.set_meta("rarity", rarity)

## ينشئ صندوق كنز
func spawn_chest(pos: Vector2) -> void:
	# تحقق من الحد الأقصى للآيتمات
	if not can_spawn_item():
		return
	
	var pickup = _create_pickup("chest", pos)
	if pickup:
		pickup.set_meta("type", "chest")

func _create_pickup(type: String, pos: Vector2) -> Area2D:
	var pickup = Area2D.new()
	pickup.global_position = pos
	pickup.add_to_group("pickup")
	
	# إضافة الشكل
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	pickup.add_child(collision)
	
	# إضافة السبرايت
	var sprite = Sprite2D.new()
	match type:
		"xp":
			sprite.modulate = Color.GREEN
		"gold":
			sprite.modulate = Color.GOLD
		"item":
			sprite.modulate = Color.PURPLE
		"chest":
			sprite.modulate = Color.ORANGE
			shape.radius = 25  # صندوق أكبر
	pickup.add_child(sprite)
	
	# إضافة السكربت
	pickup.set_script(preload("res://scripts/pickup.gd"))
	
	get_tree().current_scene.add_child(pickup)
	return pickup
