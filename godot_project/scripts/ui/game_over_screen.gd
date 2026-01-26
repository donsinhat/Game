extends CanvasLayer
class_name GameOverScreen
## GameOverScreen - شاشة نهاية اللعبة

@onready var title = $Panel/VBox/Title
@onready var stats_container = $Panel/VBox/Stats
@onready var name_input = $Panel/VBox/NameInput
@onready var submit_btn = $Panel/VBox/SubmitBtn
@onready var restart_btn = $Panel/VBox/RestartBtn

var was_victory: bool = false

func _ready() -> void:
	visible = false
	_apply_ui_theme()
	GameManager.game_over.connect(_on_game_over)
	
	if submit_btn:
		submit_btn.pressed.connect(_on_submit_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

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

	# Buttons
	var btn_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Regular.png", 10)
	var btn_pressed = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Pressed.png", 10)
	
	for btn in [submit_btn, restart_btn]:
		if btn and btn_style:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			if btn_pressed:
				btn.add_theme_stylebox_override("pressed", btn_pressed)
			else:
				btn.add_theme_stylebox_override("pressed", btn_style)

func _on_game_over(victory: bool) -> void:
	was_victory = victory
	_update_display()
	visible = true

func _update_display() -> void:
	if title:
		if was_victory:
			title.text = "🎉 النصر! 🎉"
			title.add_theme_color_override("font_color", Color.GOLD)
		else:
			title.text = "💀 انتهت اللعبة 💀"
			title.add_theme_color_override("font_color", Color.RED)
	
	_show_stats()
	
	if name_input:
		name_input.visible = GameManager.kills >= 10
	if submit_btn:
		submit_btn.visible = GameManager.kills >= 10

func _show_stats() -> void:
	if not stats_container:
		return
	
	for child in stats_container.get_children():
		child.queue_free()
	
	var stats = [
		["⏱️ الوقت", GameManager.get_formatted_time()],
		["💀 القتلى", str(GameManager.kills)],
		["📊 المستوى", str(GameManager.player_level)],
		["💰 الذهب", str(GameManager.gold)]
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = stat[0]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)
		
		var value = Label.new()
		value.text = stat[1]
		value.add_theme_color_override("font_color", Color.GOLD)
		hbox.add_child(value)
		
		stats_container.add_child(hbox)

func _on_submit_pressed() -> void:
	var player_name = name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "مجهول"
	
	_save_local_score(player_name)
	
	submit_btn.disabled = true
	submit_btn.text = "✅ تم التسجيل"

func _save_local_score(player_name: String) -> void:
	var scores = []
	
	if FileAccess.file_exists("user://scores.save"):
		var save_file = FileAccess.open("user://scores.save", FileAccess.READ)
		scores = save_file.get_var()
		save_file.close()
	
	scores.append({
		"name": player_name,
		"kills": GameManager.kills,
		"time": GameManager.game_time,
		"level": GameManager.player_level,
		"date": Time.get_datetime_string_from_system()
	})
	
	scores.sort_custom(func(a, b): return a.kills > b.kills)
	
	if scores.size() > 10:
		scores.resize(10)
	
	var save_file = FileAccess.open("user://scores.save", FileAccess.WRITE)
	save_file.store_var(scores)
	save_file.close()

func _on_restart_pressed() -> void:
	visible = false
	GameManager.start_game(
		GameManager.selected_character,
		GameManager.selected_city,
		GameManager.is_endless_mode
	)
