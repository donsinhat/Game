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
	_load_characters()
	_setup_signals()
	_update_character_display()
	_update_high_score()
	_setup_cities()

func _load_characters() -> void:
	character_list = GameData.get_character_list()
	if character_list.is_empty():
		character_list = ["abuSulaiman", "jayzen", "noura", "bedouin", "hawshabi", "layla"]

func _setup_signals() -> void:
	if prev_btn:
		prev_btn.pressed.connect(_on_prev_pressed)
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if leaderboard_btn:
		leaderboard_btn.pressed.connect(_on_leaderboard_pressed)

func _setup_cities() -> void:
	# إنشاء بطاقات المدن
	var cities = [
		{"id": "badaya", "name": "البدائع", "icon": "🏜️", "desc": "صحراء ونخيل", "locked": false},
		{"id": "endless", "name": "لا نهاية", "icon": "♾️", "desc": "بدون بوس", "locked": false},
		{"id": "baghdad", "name": "بغداد", "icon": "🏛️", "desc": "مدينة حضارية", "locked": true}
	]
	
	for city in cities:
		var card = _create_city_card(city)
		if city_container:
			city_container.add_child(card)

func _create_city_card(city: Dictionary) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(100, 80)
	card.text = "%s\n%s\n%s" % [city.icon, city.name, city.desc]
	
	if city.locked:
		card.disabled = true
		card.modulate = Color(0.5, 0.5, 0.5)
	else:
		card.pressed.connect(func(): _select_city(city.id))
	
	return card

func _select_city(city_id: String) -> void:
	selected_city = city_id
	is_endless = (city_id == "endless")
	
	# تحديث المظهر
	for i in city_container.get_child_count():
		var card = city_container.get_child(i)
		if card is Button:
			# تمييز المدينة المختارة
			pass

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
	
	# تحديث الإحصائيات
	if char_stats:
		_update_stats_display(char_data)

func _update_stats_display(char_data: Dictionary) -> void:
	# مسح الإحصائيات القديمة
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
	# TODO: فتح شاشة قائمة الأبطال
	pass
