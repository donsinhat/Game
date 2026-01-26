extends Control
class_name MainMenu
## MainMenu - القائمة الرئيسية

@onready var title = $VBox/Title
@onready var subtitle = $VBox/Subtitle
@onready var char_preview = $VBox/CharacterSelect/CharInfo/CharPreview
@onready var char_name = $VBox/CharacterSelect/CharInfo/CharName
@onready var char_title = $VBox/CharacterSelect/CharInfo/CharTitle
@onready var char_desc = $VBox/CharacterSelect/CharInfo/CharDesc
@onready var char_stats = $VBox/CharacterSelect/CharInfo/CharStats
@onready var prev_btn = $VBox/CharacterSelect/PrevBtn
@onready var next_btn = $VBox/CharacterSelect/NextBtn
@onready var city_container = $VBox/CitySelect
@onready var start_btn = $VBox/Buttons/StartBtn
@onready var leaderboard_btn = $VBox/Buttons/LeaderboardBtn
@onready var high_score_label = $VBox/Buttons/HighScore

var character_list: Array = []
var current_char_index: int = 0
var selected_city: String = "badaya"
var is_endless: bool = false

func _ready() -> void:
	_apply_ui_theme()
	_load_characters()
	_setup_signals()
	_update_character_display()
	_update_high_score()
	_setup_cities()

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

	# Buttons
	var btn_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Regular.png", 10)
	var btn_pressed = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Pressed.png", 10)
	
	for btn in [start_btn, leaderboard_btn]:
		if btn and btn_style:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			if btn_pressed:
				btn.add_theme_stylebox_override("pressed", btn_pressed)
			else:
				btn.add_theme_stylebox_override("pressed", btn_style)

	# Arrow Buttons
	var arrow_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/SmallBlueSquareButton_Regular.png", 6)
	var arrow_pressed = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/SmallBlueSquareButton_Pressed.png", 6)
	
	for btn in [prev_btn, next_btn]:
		if btn and arrow_style:
			btn.add_theme_stylebox_override("normal", arrow_style)
			btn.add_theme_stylebox_override("hover", arrow_style)
			if arrow_pressed:
				btn.add_theme_stylebox_override("pressed", arrow_pressed)
			else:
				btn.add_theme_stylebox_override("pressed", arrow_style)

func _create_city_card(city: Dictionary) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(100, 80)
	card.text = "%s\n%s\n%s" % [city.icon, city.name, city.desc]
	
	# Theme City Card
	var create_style = func(path, margin):
		var texture = load(path)
		if not texture: return null
		var style = StyleBoxTexture.new()
		style.texture = texture
		style.texture_margin_left = margin
		style.texture_margin_right = margin
		style.texture_margin_top = margin
		style.texture_margin_bottom = margin
		return style
	
	var card_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigRedButton_Regular.png", 10)
	var card_pressed = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigRedButton_Pressed.png", 10)
	
	if card_style:
		card.add_theme_stylebox_override("normal", card_style)
		card.add_theme_stylebox_override("hover", card_style)
		if card_pressed:
			card.add_theme_stylebox_override("pressed", card_pressed)
		else:
			card.add_theme_stylebox_override("pressed", card_style)

	if city.locked:
		card.disabled = true
		card.modulate = Color(0.5, 0.5, 0.5)
	else:
		card.pressed.connect(func(): _select_city(city.id))
	
	return card

func _select_city(city_id: String) -> void:
	selected_city = city_id
	is_endless = (city_id == "endless")

func _update_character_display() -> void:
	if character_list.is_empty():
		return
	
	var char_id = character_list[current_char_index]
	var char_data = GameData.get_character(char_id)
	
	if char_data.is_empty():
		return
	
	if char_name:
		char_name.text = char_data.get("name", "")
	if char_title:
		char_title.text = char_data.get("title", "")
	if char_desc:
		char_desc.text = char_data.get("desc", "")
	
	if char_stats:
		_update_stats_display(char_data)

func _update_stats_display(char_data: Dictionary) -> void:
	for child in char_stats.get_children():
		child.queue_free()
	
	var passive_text = char_data.get("passiveText", [])
	for text in passive_text:
		var label = Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.GREEN)
		char_stats.add_child(label)

func _update_high_score() -> void:
	if high_score_label:
		high_score_label.text = "أعلى نتيجة: %d قتيل" % GameManager.high_score

func _on_prev_pressed() -> void:
	current_char_index -= 1
	if current_char_index < 0:
		current_char_index = character_list.size() - 1
	_update_character_display()

func _on_next_pressed() -> void:
	current_char_index += 1
	if current_char_index >= character_list.size():
		current_char_index = 0
	_update_character_display()

func _on_start_pressed() -> void:
	var char_id = character_list[current_char_index]
	GameManager.start_game(char_id, selected_city, is_endless)

func _on_leaderboard_pressed() -> void:
	pass
