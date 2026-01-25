extends CanvasLayer
class_name HUD
## HUD - واجهة المستخدم أثناء اللعب

# المراجع
@onready var health_bar: ProgressBar = $MainPanel/Bars/HealthBar
@onready var health_text: Label = $MainPanel/Bars/HealthBar/HealthText
@onready var xp_bar: ProgressBar = $MainPanel/Bars/XPBar
@onready var xp_text: Label = $MainPanel/Bars/XPBar/XPText
@onready var gold_text: Label = $GoldPanel/GoldText
@onready var level_text: Label = $StatsPanel/LevelText
@onready var kills_text: Label = $StatsPanel/KillsText
@onready var timer_text: Label = $StatsPanel/TimerText
@onready var weapon_slots: HBoxContainer = $WeaponSlots
@onready var book_slots: HBoxContainer = $BookSlots
@onready var pause_btn: Button = $PauseBtn

var player: Player = null

func _ready() -> void:
	_connect_signals()
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)

func _connect_signals() -> void:
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)

func _process(_delta: float) -> void:
	# تحديث المؤقت
	if timer_text:
		timer_text.text = GameManager.get_formatted_time()

func set_player(p: Player) -> void:
	player = p
	if player:
		player.health_changed.connect(_on_health_changed)
		player.xp_changed.connect(_on_xp_changed)
		player.gold_changed.connect(_on_gold_changed)
		
		# تحديث القيم الأولية
		_on_health_changed(player.current_hp, player.max_hp)
		_on_xp_changed(player.current_xp, player.xp_to_level)
		_on_gold_changed(GameManager.gold)

func _on_health_changed(current: int, maximum: int) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_text:
		health_text.text = "%d/%d" % [current, maximum]

func _on_xp_changed(current: int, required: int) -> void:
	if xp_bar:
		xp_bar.max_value = required
		xp_bar.value = current
	if xp_text:
		xp_text.text = "%d/%d" % [current, required]
	if level_text:
		level_text.text = "Lv.%d" % player.level

func _on_gold_changed(amount: int) -> void:
	if gold_text:
		gold_text.text = str(amount)

func update_kills(count: int) -> void:
	if kills_text:
		kills_text.text = str(count)

func add_weapon_slot(weapon_icon: String, level: int) -> void:
	# إضافة خانة سلاح جديدة
	var slot = _create_slot(weapon_icon, level)
	if weapon_slots:
		weapon_slots.add_child(slot)

func add_book_slot(book_icon: String, level: int) -> void:
	# إضافة خانة كتاب جديدة
	var slot = _create_slot(book_icon, level)
	if book_slots:
		book_slots.add_child(slot)

func _create_slot(icon: String, level: int) -> Control:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(40, 40)
	
	var label = Label.new()
	label.text = icon
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(label)
	
	if level > 1:
		var level_label = Label.new()
		level_label.text = str(level)
		level_label.add_theme_font_size_override("font_size", 10)
		level_label.position = Vector2(28, 28)
		slot.add_child(level_label)
	
	return slot

func update_weapon_level(index: int, level: int) -> void:
	if weapon_slots and index < weapon_slots.get_child_count():
		var slot = weapon_slots.get_child(index)
		# تحديث مستوى السلاح
		pass

func _on_pause_pressed() -> void:
	GameManager.pause_game()

func _on_game_paused() -> void:
	visible = false

func _on_game_resumed() -> void:
	visible = true
