extends Node
## GameManager - يدير حالة اللعبة والتحولات بين المشاهد

signal game_started
signal game_paused
signal game_resumed
signal game_over(victory: bool)
signal level_up(new_level: int)
signal boss_spawned()

# ==================== حالة اللعبة ====================
enum GameState { MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER }

var current_state: GameState = GameState.MENU
var selected_character: String = "abuSulaiman"
var selected_city: String = "badaya"
var is_endless_mode: bool = false

# ==================== إحصائيات الجلسة ====================
var game_time: float = 0.0
var kills: int = 0
var gold: int = 0
var player_level: int = 1
var high_score: int = 0

# ==================== إعدادات ====================
var music_volume: float = 0.5
var sfx_volume: float = 0.7

func _ready() -> void:
	_load_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _load_settings() -> void:
	if FileAccess.file_exists("user://settings.save"):
		var file = FileAccess.open("user://settings.save", FileAccess.READ)
		var data = file.get_var()
		if data:
			music_volume = data.get("music_volume", 0.5)
			sfx_volume = data.get("sfx_volume", 0.7)
			high_score = data.get("high_score", 0)
		file.close()

func save_settings() -> void:
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	file.store_var({
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"high_score": high_score
	})
	file.close()

# ==================== إدارة اللعبة ====================

func start_game(character: String, city: String, endless: bool = false) -> void:
	selected_character = character
	selected_city = city
	is_endless_mode = endless
	
	# إعادة تعيين الإحصائيات
	game_time = 0.0
	kills = 0
	gold = 0
	player_level = 1
	
	current_state = GameState.PLAYING
	get_tree().paused = false
	emit_signal("game_started")
	
	# تغيير المشهد للعبة
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		emit_signal("game_paused")

func resume_game() -> void:
	if current_state == GameState.PAUSED or current_state == GameState.LEVEL_UP:
		current_state = GameState.PLAYING
		get_tree().paused = false
		emit_signal("game_resumed")

func trigger_level_up() -> void:
	current_state = GameState.LEVEL_UP
	get_tree().paused = true
	player_level += 1
	emit_signal("level_up", player_level)

func end_game(victory: bool) -> void:
	current_state = GameState.GAME_OVER
	get_tree().paused = true
	
	# تحديث أعلى نتيجة
	if kills > high_score:
		high_score = kills
		save_settings()
	
	emit_signal("game_over", victory)

func return_to_menu() -> void:
	current_state = GameState.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ==================== إحصائيات ====================

func add_kill() -> void:
	kills += 1

func add_gold(amount: int) -> void:
	gold += amount

func get_formatted_time() -> String:
	var total_seconds: int = int(game_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func get_scaling_multiplier() -> float:
	# زيادة 30% كل دقيقة
	var minutes = game_time / 60.0
	return 1.0 + (minutes * GameData.SCALING_PER_MIN)

func should_spawn_boss() -> bool:
	return not is_endless_mode and game_time >= GameData.BOSS_TIME
