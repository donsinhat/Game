extends Node2D
class_name Game
## Game - المشهد الرئيسي للعبة

# المراجع
@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var pickup_spawner: PickupSpawner = $PickupSpawner
@onready var hud: HUD = $UI/HUD
@onready var pause_menu: PauseMenu = $UI/PauseMenu
@onready var level_up_modal: LevelUpModal = $UI/LevelUpModal
@onready var game_over_screen: GameOverScreen = $UI/GameOverScreen
@onready var virtual_joystick: VirtualJoystick = $UI/VirtualJoystick
@onready var tilemap: TileMap = $TileMap

var boss_spawned: bool = false
var weapons: Array[WeaponBase] = []
var books: Dictionary = {}  # book_id -> level

func _ready() -> void:
	_setup_player()
	_setup_ui()
	_setup_spawners()
	_connect_signals()
	_setup_initial_weapon()

func _setup_player() -> void:
	if player:
		player.character_id = GameManager.selected_character
		player._load_character_stats()
		player.current_hp = player.max_hp

func _setup_ui() -> void:
	if hud:
		hud.set_player(player)
	if pause_menu:
		pause_menu.set_player(player)
	if virtual_joystick:
		virtual_joystick.joystick_input.connect(_on_joystick_input)
		# إخفاء الجويستيك على الكمبيوتر
		if not OS.has_feature("mobile"):
			virtual_joystick.visible = false

func _setup_spawners() -> void:
	if enemy_spawner:
		enemy_spawner.player = player
	if pickup_spawner:
		pickup_spawner.player = player

func _connect_signals() -> void:
	if player:
		player.died.connect(_on_player_died)
	
	if level_up_modal:
		level_up_modal.upgrade_selected.connect(_on_upgrade_selected)
	
	if enemy_spawner:
		enemy_spawner.enemy_died.connect(_on_enemy_died)

func _setup_initial_weapon() -> void:
	var char_data = GameData.get_character(GameManager.selected_character)
	if char_data.has("weapon"):
		add_weapon(char_data["weapon"])

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# تحديث وقت اللعبة
	GameManager.game_time += delta
	
	# فحص ظهور البوس
	if not boss_spawned and GameManager.should_spawn_boss():
		_spawn_boss()
	
	# تحديث عدد القتلى في HUD
	if hud:
		hud.update_kills(GameManager.kills)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			GameManager.resume_game()

func _on_joystick_input(direction: Vector2) -> void:
	if player:
		player.set_joystick_input(direction)

# ==================== الأسلحة ====================

func add_weapon(weapon_id: String) -> void:
	# فحص إذا كان السلاح موجود
	for weapon in weapons:
		if weapon.weapon_id == weapon_id:
			weapon.upgrade()
			_update_weapon_ui()
			return
	
	# فحص الحد الأقصى
	if weapons.size() >= GameData.MAX_WEAPONS:
		return
	
	# إنشاء سلاح جديد
	var weapon = _create_weapon(weapon_id)
	if weapon:
		weapons.append(weapon)
		player.weapon_container.add_child(weapon)
		weapon.initialize(player, weapon_id, 1)
		_update_weapon_ui()

func _create_weapon(weapon_id: String) -> WeaponBase:
	var weapon_data = GameData.get_weapon(weapon_id)
	if weapon_data.is_empty():
		return null
	
	var weapon_type = weapon_data.get("type", "projectile")
	var weapon: WeaponBase
	
	match weapon_type:
		"orbit":
			weapon = WeaponOrbit.new()
		"aura":
			weapon = WeaponAura.new()
		"melee":
			weapon = WeaponMelee.new()
		"chain", "bounce":
			weapon = WeaponChain.new()
		_:
			weapon = WeaponProjectile.new()
	
	return weapon

func _update_weapon_ui() -> void:
	# TODO: تحديث واجهة الأسلحة
	pass

# ==================== الكتب ====================

func add_book(book_id: String) -> void:
	if books.has(book_id):
		books[book_id] += 1
	else:
		if books.size() >= GameData.MAX_BOOKS:
			return
		books[book_id] = 1
	
	_apply_book_effect(book_id)
	_update_book_ui()

func _apply_book_effect(book_id: String) -> void:
	var book_data = GameData.get_book(book_id)
	if book_data.is_empty():
		return
	
	var stat = book_data.get("stat", "")
	var val = book_data.get("val", 0)
	
	player.apply_book_upgrade(stat, val)

func _update_book_ui() -> void:
	# TODO: تحديث واجهة الكتب
	pass

# ==================== الأحداث ====================

func _on_upgrade_selected(type: String, id: String) -> void:
	if type == "weapon":
		add_weapon(id)
	else:
		add_book(id)

func _on_enemy_died(enemy: Enemy, pos: Vector2) -> void:
	# إسقاط XP والذهب
	if pickup_spawner:
		pickup_spawner.spawn_xp(pos, enemy.xp_value)
		
		# فرصة إسقاط ذهب
		if randf() < 0.3:
			pickup_spawner.spawn_gold(pos, randi_range(1, 5))
		
		# فرصة إسقاط أيتم
		if randf() < 0.05 * player.luck:
			pickup_spawner.spawn_item(pos)

func _on_player_died() -> void:
	GameManager.end_game(false)

func _spawn_boss() -> void:
	boss_spawned = true
	GameManager.emit_signal("boss_spawned")
	
	# TODO: إنشاء البوس
	# عرض تحذير
	# تغيير الموسيقى

# ==================== Pickup Handling ====================

func _on_pickup_collected(pickup_type: String, value) -> void:
	match pickup_type:
		"xp":
			player.add_xp(value)
		"gold":
			player.add_gold(value)
		"item":
			# TODO: معالجة الأيتم
			pass
