extends Node
## GameData - بيانات اللعبة المحملة من JSON

# الثوابت
const WORLD_SIZE: float = 3000.0
const ENEMY_BASE_HP: float = 22.0
const ENEMY_BASE_ATK: float = 10.0
const ENEMY_BASE_SPEED: float = 65.0

# البيانات المحملة
var data: Dictionary = {}

func _ready() -> void:
	_load_game_data()

func _load_game_data() -> void:
	var file = FileAccess.open("res://game_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			data = json.data
		file.close()
	else:
		# محاولة تحميل من مسار بديل
		file = FileAccess.open("user://game_data.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			if error == OK:
				data = json.data
			file.close()

# ==================== الشخصيات ====================

func get_character(id: String) -> Dictionary:
	if data.has("CHARACTERS") and data["CHARACTERS"].has(id):
		return data["CHARACTERS"][id]
	return {}

func get_character_list() -> Array:
	if data.has("CHARACTERS"):
		return data["CHARACTERS"].keys()
	return []

# ==================== الأعداء ====================

func get_enemy(id: String) -> Dictionary:
	if data.has("ENEMIES") and data["ENEMIES"].has(id):
		var enemy = data["ENEMIES"][id].duplicate()
		# تحويل الأسماء للاختصارات المستخدمة في الكود
		enemy["hpM"] = enemy.get("hpMultiplier", 1.0)
		enemy["atkM"] = enemy.get("atkMultiplier", 1.0)
		enemy["spdM"] = enemy.get("speedMultiplier", 1.0)
		enemy["ranged"] = enemy.get("specialAbility") == "ranged"
		return enemy
	return {}

func get_available_enemies(elapsed_seconds: float) -> Array:
	var available = []
	if data.has("ENEMIES"):
		for enemy_id in data["ENEMIES"]:
			var enemy = data["ENEMIES"][enemy_id]
			if enemy.get("appearsAfterSeconds", 0) <= elapsed_seconds:
				available.append(enemy_id)
	return available

# ==================== الأسلحة ====================

func get_weapon(id: String) -> Dictionary:
	if data.has("WEAPONS") and data["WEAPONS"].has(id):
		return data["WEAPONS"][id]
	return {}

func get_weapon_list() -> Array:
	if data.has("WEAPONS"):
		return data["WEAPONS"].keys()
	return []

# ==================== الكتب ====================

func get_book(id: String) -> Dictionary:
	if data.has("BOOKS") and data["BOOKS"].has(id):
		return data["BOOKS"][id]
	return {}

func get_book_list() -> Array:
	if data.has("BOOKS"):
		return data["BOOKS"].keys()
	return []

# ==================== الآيتمات ====================

func get_item(rarity: String, id: String) -> Dictionary:
	if data.has("ITEMS") and data["ITEMS"].has(rarity):
		if data["ITEMS"][rarity].has(id):
			return data["ITEMS"][rarity][id]
	return {}

func get_random_item(rarity: String) -> Dictionary:
	if data.has("ITEMS") and data["ITEMS"].has(rarity):
		var items = data["ITEMS"][rarity]
		var keys = items.keys()
		if keys.size() > 0:
			var random_key = keys[randi() % keys.size()]
			return items[random_key]
	return {}

func get_random_rarity(luck: float = 1.0) -> String:
	var roll = randf() * 100.0 / luck
	
	if roll < 1:  # 1%
		return "LEGENDARY"
	elif roll < 10:  # 9%
		return "RARE"
	else:  # 90%
		return "COMMON"

# ==================== البوس ====================

func get_boss() -> Dictionary:
	if data.has("BOSS"):
		return data["BOSS"]
	return {}

# ==================== الألوان ====================

func get_rarity_color(rarity: String) -> Color:
	if data.has("RARITY_COLORS") and data["RARITY_COLORS"].has(rarity):
		return Color(data["RARITY_COLORS"][rarity])
	return Color.WHITE
