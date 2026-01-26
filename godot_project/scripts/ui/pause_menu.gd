extends CanvasLayer
class_name PauseMenu
## PauseMenu - قائمة الإيقاف المؤقت

@onready var stats_panel = $Panel/VBox/StatsPanel
@onready var hp_label = $Panel/VBox/StatsPanel/Stats/HP
@onready var dmg_label = $Panel/VBox/StatsPanel/Stats/DMG
@onready var def_label = $Panel/VBox/StatsPanel/Stats/DEF
@onready var luck_label = $Panel/VBox/StatsPanel/Stats/LUCK
@onready var crit_label = $Panel/VBox/StatsPanel/Stats/CRIT
@onready var speed_label = $Panel/VBox/StatsPanel/Stats/SPD
@onready var gold_label = $Panel/VBox/StatsPanel/Stats/GOLD
@onready var kills_label = $Panel/VBox/StatsPanel/Stats/KILLS

@onready var music_slider = $Panel/VBox/Controls/MusicSlider
@onready var sfx_slider = $Panel/VBox/Controls/SFXSlider
@onready var resume_btn = $Panel/VBox/Buttons/ResumeBtn
@onready var quit_btn = $Panel/VBox/Buttons/QuitBtn

var player = null

func _ready() -> void:
	visible = false
	_apply_ui_theme()
	_setup_signals()
	_load_settings()

func _apply_ui_theme() -> void:
	# Helper to create StyleBoxTexture
	var create_style = func(path: String, margin: int) -> StyleBoxTexture:
		if not FileAccess.file_exists(path): return null
		var texture = load(path)
		if not texture: return null
		var style = StyleBoxTexture.new()
		style.texture = texture
		style.texture_margin_left = margin
		style.texture_margin_right = margin
		style.texture_margin_top = margin
		style.texture_margin_bottom = margin
		return style

	# Panel Background (Wood Table)
	var panel_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Wood Table/WoodTable.png", 32)
	if panel_style and has_node("Panel"):
		$Panel.add_theme_stylebox_override("panel", panel_style)
		$Panel.add_theme_constant_override("margin_left", 20)
		$Panel.add_theme_constant_override("margin_right", 20)
		$Panel.add_theme_constant_override("margin_top", 20)
		$Panel.add_theme_constant_override("margin_bottom", 20)

	# Stats Panel (Paper)
	var paper_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Papers/RegularPaper.png", 20)
	if paper_style and stats_panel:
		stats_panel.add_theme_stylebox_override("panel", paper_style)

	# Buttons
	var btn_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Regular.png", 10)
	var btn_pressed = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Pressed.png", 10)
	
	for btn in [resume_btn, quit_btn]:
		if btn and btn_style:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			if btn_pressed:
				btn.add_theme_stylebox_override("pressed", btn_pressed)
			else:
				btn.add_theme_stylebox_override("pressed", btn_style)


func _setup_signals() -> void:
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)

func _load_settings() -> void:
	if music_slider:
		music_slider.value = GameManager.music_volume * 100
	if sfx_slider:
		sfx_slider.value = GameManager.sfx_volume * 100

func set_player(p) -> void:
	player = p

func _update_stats() -> void:
	if not player:
		return
	
	if hp_label:
		hp_label.text = "%d/%d" % [player.current_hp, player.max_hp]
	if dmg_label:
		dmg_label.text = "%.0f%%" % (player.damage_mult * 100)
	if def_label:
		def_label.text = "%.0f%%" % (player.armor * 100)
	if luck_label:
		luck_label.text = "%.1f" % player.luck
	if crit_label:
		crit_label.text = "%.0f%%" % (player.crit_chance * 100)
	if speed_label:
		speed_label.text = "%.0f%%" % ((player.base_speed / 200.0) * 100)
	if gold_label:
		gold_label.text = str(GameManager.gold)
	if kills_label:
		kills_label.text = str(GameManager.kills)

func _on_game_paused() -> void:
	_update_stats()
	visible = true

func _on_game_resumed() -> void:
	visible = false

func _on_resume_pressed() -> void:
	GameManager.resume_game()

func _on_quit_pressed() -> void:
	GameManager.return_to_menu()

func _on_music_changed(value: float) -> void:
	GameManager.music_volume = value / 100.0
	AudioManager.set_music_volume(GameManager.music_volume)
	GameManager.save_settings()

func _on_sfx_changed(value: float) -> void:
	GameManager.sfx_volume = value / 100.0
	AudioManager.set_sfx_volume(GameManager.sfx_volume)
	GameManager.save_settings()
