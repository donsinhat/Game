extends CanvasLayer
class_name GameOverScreen
## GameOverScreen - شاشة نهاية اللعبة

@onready var title = $Panel/VBox/Title
@onready var stats_container = $Panel/VBox/Stats
@onready var name_input = $Panel/VBox/NameInput
@antml:parameter name="new_string">@onready var submit_btn = $Panel/VBox/SubmitBtn
@onready var restart_btn = $Panel/VBox/RestartBtn

var was_victory: bool = false

func _ready() -> void:
	visible = false
	GameManager.game_over.connect(_on_game_over)
	
	if submit_btn:
		submit_btn.pressed.connect(_on_submit_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

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
	
	# عرض الإحصائيات
	_show_stats()
	
	# إظهار حقل الاسم إذا كانت النتيجة جيدة
	if name_input:
		name_input.visible = GameManager.kills >= 10
	if submit_btn:
		submit_btn.visible = GameManager.kills >= 10

func _show_stats() -> void:
	if not stats_container:
		return
	
	# مسح الإحصائيات القديمة
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
	
	# TODO: إرسال النتيجة للخادم
	_save_local_score(player_name)
	
	submit_btn.disabled = true
	submit_btn.text = "✅ تم التسجيل"

func _save_local_score(player_name: String) -> void:
	# حفظ النتيجة محلياً
	var scores = []
	
	if FileAccess.file_exists("user://scores.save"):
		var file = FileAccess.open("user://scores.save", FileAccess.READ)
		scores = file.get_var()
		file.close()
	
	scores.append({
		"name": player_name,
		"kills": GameManager.kills,
		"time": GameManager.game_time,
		"level": GameManager.player_level,
		"date": Time.get_datetime_string_from_system()
	})
	
	# ترتيب حسب القتلى
	scores.sort_custom(func(a, b): return a.kills > b.kills)
	
	# الاحتفاظ بأفضل 10 نتائج
	if scores.size() > 10:
		scores.resize(10)
	
	var file = FileAccess.open("user://scores.save", FileAccess.WRITE)
	file.store_var(scores)
	file.close()

func _on_restart_pressed() -> void:
	visible = false
	GameManager.start_game(
		GameManager.selected_character,
		GameManager.selected_city,
		GameManager.is_endless_mode
	)
