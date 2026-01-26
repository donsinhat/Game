extends Node2D
class_name PickupSpawner
## PickupSpawner - نظام توليد الملتقطات (XP, Gold, Items)

var player: Player = null

# مشاهد الملتقطات
var xp_scene: PackedScene
var gold_scene: PackedScene
var item_scene: PackedScene

# تكستشرات الملتقطات
var xp_texture: Texture2D
var gold_texture: Texture2D

func _ready() -> void:
	# تحميل تكستشرات الملتقطات
	xp_texture = load("res://assets/pickups/xp_gem.png")
	gold_texture = load("res://assets/pickups/gold_coin.png")

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
	var pickup = _create_pickup("item", pos)
	if pickup:
		# اختيار أيتم عشوائي
		var rarity = GameData.get_random_rarity(player.luck if player else 1.0)
		pickup.set_meta("type", "item")
		pickup.set_meta("rarity", rarity)

func _create_pickup(type: String, pos: Vector2) -> Area2D:
	var pickup = Area2D.new()
	pickup.global_position = pos
	pickup.add_to_group("pickup")
	pickup.collision_layer = 4
	pickup.collision_mask = 1
	
	# إضافة الشكل
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	pickup.add_child(collision)
	
	# إضافة السبرايت
	var sprite = Sprite2D.new()
	sprite.scale = Vector2(1.5, 1.5)
	match type:
		"xp":
			if xp_texture:
				sprite.texture = xp_texture
			else:
				sprite.modulate = Color.GREEN
		"gold":
			if gold_texture:
				sprite.texture = gold_texture
			else:
				sprite.modulate = Color.GOLD
		"item":
			sprite.modulate = Color.PURPLE
			sprite.scale = Vector2(2, 2)
	pickup.add_child(sprite)
	
	# إضافة السكربت
	pickup.set_script(preload("res://scripts/pickup.gd"))
	
	get_tree().current_scene.add_child(pickup)
	return pickup
