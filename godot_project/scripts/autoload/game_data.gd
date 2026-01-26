extends Node
## GameData - يحمل بيانات اللعبة من JSON ويوفرها للأنظمة الأخرى

# ==================== الثوابت ====================
const WORLD_SIZE: int = 4000
const TILE_SIZE: int = 32
const MAX_WEAPONS: int = 4
const MAX_BOOKS: int = 4
const MAX_UPGRADE_LEVEL: int = 10
const BOSS_TIME: int = 600  # 10 دقائق

# إحصائيات الأعداء الأساسية
const ENEMY_BASE_HP: int = 22
const ENEMY_BASE_ATK: int = 10
const ENEMY_BASE_SPEED: int = 65
const SCALING_PER_MIN: float = 0.30

# ==================== البيانات ====================
var characters: Dictionary = {}
var weapons: Dictionary = {}
var books: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var boss: Dictionary = {}

# ==================== الندرة ====================
var RARITY: Dictionary = {
	"COMMON": {"name": "شائع", "color": Color("#9d9d9d"), "bonus": 1, "weight": 50},
	"UNCOMMON": {"name": "غير شائع", "color": Color("#1eff00"), "bonus": 2, "weight": 25},
	"RARE": {"name": "نادر", "color": Color("#0070dd"), "bonus": 3, "weight": 13},
	"EPIC": {"name": "ملحمي", "color": Color("#a335ee"), "bonus": 4, "weight": 7},
	"LEGENDARY": {"name": "أسطوري", "color": Color("#ff8000"), "bonus": 5, "weight": 5}
}

func _ready() -> void:
	_load_game_data()

func _load_game_data() -> void:
	# تحميل بيانات اللعبة من JSON
	var file = FileAccess.open("res://data/game_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			if data.has("CHARACTERS"):
				characters = data["CHARACTERS"]
			if data.has("WEAPONS"):
				weapons = data["WEAPONS"]
			if data.has("BOOKS"):
				books = data["BOOKS"]
			if data.has("ITEMS"):
				items = data["ITEMS"]
			if data.has("ENEMIES"):
				enemies = data["ENEMIES"]
			if data.has("BOSS"):
				boss = data["BOSS"]
		file.close()
	
	# إذا فشل تحميل JSON، استخدم البيانات المدمجة
	if characters.is_empty():
		_load_embedded_data()

func _load_embedded_data() -> void:
	# الشخصيات
	characters = {
		"abuSulaiman": {
			"name": "أبو سليمان",
			"title": "التاجر الثري",
			"desc": "تاجر ثري يحب الذهب أكثر من أي شيء",
			"weapon": "agal",
			"stats": {
				"gold": 1.5, "luck": 1.2, "hp": 110, "speed": 200,
				"crit": 0, "enemyBuff": 0, "chestDiscount": 0.3
			},
			"passiveText": ["+50% ذهب", "+20% حظ", "-30% سعر الصناديق"]
		},
		"jayzen": {
			"name": "جيزن",
			"title": "المقاتل الشرس",
			"desc": "مقاتل عنيد لا يخاف الموت",
			"weapon": "vape",
			"stats": {
				"gold": 1, "luck": 1, "hp": 115, "speed": 200,
				"dmgReduce": 0.2, "crit": 0, "enemyBuff": 0
			},
			"passiveText": ["-20% ضرر مستلم", "+15% صحة"]
		},
		"noura": {
			"name": "نورة",
			"title": "المرأة القوية",
			"desc": "امرأة قوية تجمع كل شيء حولها",
			"weapon": "aura",
			"stats": {
				"gold": 1, "luck": 1, "hp": 100, "speed": 200,
				"pickup": 2.5, "xpMult": 1.2, "crit": 0, "enemyBuff": 0
			},
			"passiveText": ["+150% مغناطيس", "+20% خبرة"]
		},
		"bedouin": {
			"name": "الاعرابي",
			"title": "بدوي غدار",
			"desc": "بدوي وغدار، سريع وقوي",
			"weapon": "sword",
			"stats": {
				"gold": 1, "luck": 1, "hp": 90, "speed": 220,
				"crit": 0.20, "enemyBuff": 0
			},
			"passiveText": ["+20% ضربة حرجة", "+10% سرعة"]
		},
		"hawshabi": {
			"name": "الحوشبي",
			"title": "صعوبة متقدمة",
			"desc": "للاعبين المتمرسين فقط",
			"weapon": "mgma",
			"stats": {
				"gold": 1.5, "luck": 1.2, "hp": 80, "speed": 180,
				"crit": 0, "enemyBuff": 0.20
			},
			"passiveText": ["+20% قوة الأعداء", "+50% ذهب", "+20% حظ"]
		},
		"layla": {
			"name": "ليلى",
			"title": "الساحرة",
			"desc": "ساحرة غامضة تتحكم بالنار الزرقاء",
			"weapon": "meteor",
			"stats": {
				"gold": 1, "luck": 1, "hp": 85, "speed": 210,
				"cooldown": 0.8, "range": 1.3, "crit": 0, "enemyBuff": 0
			},
			"passiveText": ["-20% كولداون", "+30% مدى"]
		}
	}
	
	# الأسلحة
	weapons = {
		"agal": {
			"name": "العقال",
			"desc": "حبل يدور حولك ويضرب الأعداء",
			"type": "orbit",
			"dmg": 5, "cd": 0.1, "range": 65, "icon": "⭕"
		},
		"vape": {
			"name": "الفيب",
			"desc": "دخان سام يسبب ضرر مستمر",
			"type": "cone_aoe",
			"dmg": 10, "cd": 0.1, "range": 70, "icon": "💨"
		},
		"aura": {
			"name": "الهيبة",
			"desc": "هالة ضرر حولك",
			"type": "aura",
			"dmg": 4, "cd": 0.5, "range": 60, "icon": "💫"
		},
		"sword": {
			"name": "السيف",
			"desc": "ضربة قوسية أمامك",
			"type": "melee",
			"dmg": 6, "cd": 0.65, "range": 75, "icon": "⚔️"
		},
		"mgma": {
			"name": "المقمع",
			"desc": "طلقة شوتجن",
			"type": "projectile",
			"dmg": 5, "cd": 1.0, "range": 200, "icon": "🔫"
		},
		"meteor": {
			"name": "النيزك",
			"desc": "قذيفة لعدو عشوائي",
			"type": "lightning",
			"dmg": 6, "cd": 1.4, "range": 400, "icon": "☄️"
		},
		"brain": {
			"name": "العقل",
			"desc": "قذيفة تقفز بين الأعداء",
			"type": "chain",
			"dmg": 4, "cd": 1.2, "range": 300, "icon": "🧠"
		},
		"onion": {
			"name": "البصل",
			"desc": "قذيفة طويلة المدى",
			"type": "dot",
			"dmg": 3, "cd": 1.5, "range": 450, "icon": "🧅"
		},
		"shuriken": {
			"name": "الشوريكن",
			"desc": "نجمة نينجا ترتد بين الأعداء",
			"type": "bounce",
			"dmg": 5, "cd": 0.8, "range": 350, "icon": "✴️"
		}
	}
	
	# الكتب
	books = {
		"power": {"name": "كتاب القوة", "desc": "+15% قوة الهجوم", "stat": "damage", "val": 0.15, "icon": "📕"},
		"speed": {"name": "كتاب السرعة", "desc": "+12% سرعة الهجوم", "stat": "atkSpd", "val": 0.12, "icon": "📗"},
		"wind": {"name": "كتاب الريح", "desc": "+10% سرعة الحركة", "stat": "moveSpd", "val": 0.10, "icon": "📘"},
		"wisdom": {"name": "كتاب الحكمة", "desc": "+15% الخبرة", "stat": "xp", "val": 0.15, "icon": "📙"},
		"life": {"name": "كتاب الحياة", "desc": "+15% الصحة القصوى", "stat": "maxHp", "val": 0.15, "icon": "📓"},
		"armor": {"name": "كتاب الدرع", "desc": "+8% تقليل الضرر", "stat": "armor", "val": 0.08, "icon": "📔"},
		"magnet": {"name": "كتاب المغناطيس", "desc": "+20% مدى الجمع", "stat": "pickup", "val": 0.20, "icon": "📒"},
		"luck": {"name": "كتاب الحظ", "desc": "+12% حظ", "stat": "luck", "val": 0.12, "icon": "📚"},
		"curse": {"name": "كتاب اللعنة", "desc": "+20% أعداء وخبرة", "stat": "curse", "val": 0.20, "icon": "📖"},
		"regen": {"name": "كتاب التجديد", "desc": "+1.5 شفاء/ثانية", "stat": "regen", "val": 1.5, "icon": "📜"},
		"critical": {"name": "كتاب الضربة الحرجة", "desc": "+6% كريت", "stat": "crit", "val": 0.06, "icon": "💥"}
	}
	
	# الأعداء
	enemies = {
		"flyingEye": {"name": "العين الطائرة", "hpM": 0.7, "atkM": 0.7, "spdM": 1.1, "xp": 3, "time": 0, "ranged": true},
		"goblin": {"name": "الغوبلين", "hpM": 1.0, "atkM": 1.0, "spdM": 1.0, "xp": 4, "time": 0},
		"mushroom": {"name": "الفطر", "hpM": 1.4, "atkM": 1.2, "spdM": 0.8, "xp": 6, "time": 30, "ranged": true},
		"skeleton": {"name": "الهيكل العظمي", "hpM": 2.0, "atkM": 1.5, "spdM": 0.85, "xp": 8, "time": 60}
	}
	
	# البوس
	boss = {
		"name": "ابو حلزه",
		"hp": 12000,
		"atk": 40,
		"spd": 60
	}

# ==================== دوال مساعدة ====================

func get_random_rarity(luck: float = 1.0) -> Dictionary:
	var luck_power = pow(luck, 2)
	var weights = {
		"COMMON": RARITY["COMMON"]["weight"] / luck_power,
		"UNCOMMON": RARITY["UNCOMMON"]["weight"] * luck,
		"RARE": RARITY["RARE"]["weight"] * luck_power,
		"EPIC": RARITY["EPIC"]["weight"] * luck_power * 1.5,
		"LEGENDARY": RARITY["LEGENDARY"]["weight"] * luck_power * 2
	}
	
	var total = 0.0
	for w in weights.values():
		total += w
	
	var roll = randf() * total
	for key in weights.keys():
		roll -= weights[key]
		if roll <= 0:
			return RARITY[key]
	
	return RARITY["COMMON"]

func get_character(id: String) -> Dictionary:
	if characters.has(id):
		return characters[id]
	return {}

func get_weapon(id: String) -> Dictionary:
	if weapons.has(id):
		return weapons[id]
	return {}

func get_book(id: String) -> Dictionary:
	if books.has(id):
		return books[id]
	return {}

func get_enemy(id: String) -> Dictionary:
	if enemies.has(id):
		return enemies[id]
	return {}

func get_character_list() -> Array:
	return characters.keys()

func get_weapon_list() -> Array:
	return weapons.keys()

func get_book_list() -> Array:
	return books.keys()
