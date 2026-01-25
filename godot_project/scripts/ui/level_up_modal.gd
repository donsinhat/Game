extends CanvasLayer
class_name LevelUpModal
## LevelUpModal - نافذة اختيار الترقية

signal upgrade_selected(type: String, id: String)

@onready var title: Label = $Panel/VBox/Title
@onready var options_container: HBoxContainer = $Panel/VBox/Options

var current_options: Array = []

func _ready() -> void:
	visible = false
	GameManager.level_up.connect(_on_level_up)

func _on_level_up(_new_level: int) -> void:
	_generate_options()
	visible = true

func _generate_options() -> void:
	# مسح الخيارات القديمة
	for child in options_container.get_children():
		child.queue_free()
	
	current_options.clear()
	
	# توليد 3-4 خيارات عشوائية
	var num_options = 3
	var available_weapons = GameData.get_weapon_list()
	var available_books = GameData.get_book_list()
	
	for i in num_options:
		var option = _get_random_option(available_weapons, available_books)
		if option:
			current_options.append(option)
			var card = _create_option_card(option)
			options_container.add_child(card)

func _get_random_option(weapons: Array, books: Array) -> Dictionary:
	# 50% سلاح، 50% كتاب
	var is_weapon = randf() < 0.5
	
	if is_weapon and not weapons.is_empty():
		var weapon_id = weapons[randi() % weapons.size()]
		var weapon_data = GameData.get_weapon(weapon_id)
		var rarity = GameData.get_random_rarity()
		return {
			"type": "weapon",
			"id": weapon_id,
			"name": weapon_data.get("name", ""),
			"desc": weapon_data.get("desc", ""),
			"icon": weapon_data.get("icon", ""),
			"rarity": rarity
		}
	elif not books.is_empty():
		var book_id = books[randi() % books.size()]
		var book_data = GameData.get_book(book_id)
		var rarity = GameData.get_random_rarity()
		return {
			"type": "book",
			"id": book_id,
			"name": book_data.get("name", ""),
			"desc": book_data.get("desc", ""),
			"icon": book_data.get("icon", ""),
			"rarity": rarity
		}
	
	return {}

func _create_option_card(option: Dictionary) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(120, 180)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# الأيقونة
	var icon = Label.new()
	icon.text = option.get("icon", "?")
	icon.add_theme_font_size_override("font_size", 32)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)
	
	# الاسم
	var name_label = Label.new()
	name_label.text = option.get("name", "")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# النوع
	var type_label = Label.new()
	type_label.text = "سلاح" if option.type == "weapon" else "كتاب"
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color.GRAY)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)
	
	# الندرة
	var rarity = option.get("rarity", {})
	var rarity_label = Label.new()
	rarity_label.text = rarity.get("name", "شائع")
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", rarity.get("color", Color.GRAY))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)
	
	# الوصف
	var desc_label = Label.new()
	desc_label.text = option.get("desc", "")
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)
	
	card.add_child(vbox)
	card.pressed.connect(func(): _select_option(option))
	
	return card

func _select_option(option: Dictionary) -> void:
	emit_signal("upgrade_selected", option.type, option.id)
	visible = false
	GameManager.resume_game()
