extends CanvasLayer
class_name LevelUpModal
## LevelUpModal - نافذة اختيار الترقية

signal upgrade_selected(type: String, id: String)

@onready var title = $Panel/VBox/Title
@onready var options_container = $Panel/VBox/Options

var current_options: Array = []

func _ready() -> void:
	visible = false
	_apply_ui_theme()
	GameManager.level_up.connect(_on_level_up)

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

	# Panel Background (Ribbon or Banner)
	var panel_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Banners/Banner.png", 32)
	if panel_style and has_node("Panel"):
		$Panel.add_theme_stylebox_override("panel", panel_style)
		# Add padding
		$Panel.add_theme_constant_override("margin_left", 30)
		$Panel.add_theme_constant_override("margin_right", 30)
		$Panel.add_theme_constant_override("margin_top", 25)
		$Panel.add_theme_constant_override("margin_bottom", 25)

func _create_option_card(option: Dictionary) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(120, 180)
	
	# Theme the card button
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
	
	var card_style = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Regular.png", 10)
	var card_pressed = create_style.call("res://assets/ui/UI Elements/UI Elements/Buttons/BigBlueButton_Pressed.png", 10)
	
	if card_style:
		card.add_theme_stylebox_override("normal", card_style)
		card.add_theme_stylebox_override("hover", card_style)
		if card_pressed:
			card.add_theme_stylebox_override("pressed", card_pressed)
		else:
			card.add_theme_stylebox_override("pressed", card_style)

	
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
