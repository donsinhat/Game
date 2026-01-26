extends Node
## GameManager - إدارة حالة اللعبة

signal game_paused
signal game_resumed
signal level_up_triggered
signal game_over

# حالة اللعبة
var is_paused: bool = false
var is_game_over: bool = false
var elapsed_time: float = 0.0
var kills: int = 0
var gold: int = 0

# الشخصية المختارة
var selected_character: String = "abuSulaiman"

# معدل ظهور الأعداء (للـ curse)
var enemy_spawn_multiplier: float = 1.0

# مرجع اللاعب
var player: Player = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not is_paused and not is_game_over:
		elapsed_time += delta

# ==================== التحكم باللعبة ====================

func start_game(character_id: String) -> void:
	selected_character = character_id
	is_paused = false
	is_game_over = false
	elapsed_time = 0.0
	kills = 0
	gold = 0
	enemy_spawn_multiplier = 1.0

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	emit_signal("game_paused")

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	emit_signal("game_resumed")

func end_game() -> void:
	is_game_over = true
	emit_signal("game_over")

# ==================== الإحصائيات ====================

func add_kill() -> void:
	kills += 1

func add_gold(amount: int) -> void:
	gold += amount

func get_scaling_multiplier() -> float:
	# تصعيد الأعداء مع الوقت
	var minutes = elapsed_time / 60.0
	return 1.0 + (minutes * 0.1)  # +10% كل دقيقة

func get_formatted_time() -> String:
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	return "%02d:%02d" % [minutes, seconds]

# ==================== Level Up ====================

func trigger_level_up() -> void:
	pause_game()
	emit_signal("level_up_triggered")

# ==================== المعدات ====================

func give_random_equipment() -> void:
	# TODO: إعطاء سلاح أو كتاب عشوائي
	pass

func increase_enemy_spawn_rate(amount: float) -> void:
	enemy_spawn_multiplier += amount
