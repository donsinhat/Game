extends CanvasLayer
class_name PauseMenu
## PauseMenu - قائمة الإيقاف المؤقت مع الخريطة المصغرة

# المراجع
@onready var panel: PanelContainer = $Panel
@onready var stats_container: VBoxContainer = $Panel/VBox/StatsPanel/Stats
@onready var resume_btn: Button = $Panel/VBox/Buttons/ResumeBtn
@onready var quit_btn: Button = $Panel/VBox/Buttons/QuitBtn
@onready var music_slider: HSlider = $Panel/VBox/Controls/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/Controls/SFXSlider

# الـ Minimap
var minimap_container: PanelContainer
var minimap_canvas: Control
var minimap_size: Vector2 = Vector2(200, 200)

var player: Player = null

func _ready() -> void:
	visible = false
	_setup_buttons()
	_setup_minimap()
	_connect_signals()

func _setup_buttons() -> void:
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _setup_minimap() -> void:
	# إنشاء حاوية الخريطة المصغرة
	minimap_container = PanelContainer.new()
	minimap_container.custom_minimum_size = minimap_size
	minimap_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# إنشاء العنوان
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	minimap_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "🗺️ الخريطة"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# إنشاء كانفس الخريطة
	minimap_canvas = Control.new()
	minimap_canvas.custom_minimum_size = Vector2(180, 150)
	minimap_canvas.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_child(minimap_canvas)
	
	# إضافة الأسطورة
	var legend = HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(legend)
	
	_add_legend_item(legend, "🔵", "أنت")
	_add_legend_item(legend, "🟣", "آيتم")
	_add_legend_item(legend, "📦", "صندوق")
	
	# إضافة الخريطة للقائمة
	if panel and panel.has_node("VBox"):
		var main_vbox = panel.get_node("VBox")
		# إضافة الخريطة بعد العنوان
		main_vbox.add_child(minimap_container)
		main_vbox.move_child(minimap_container, 1)

func _add_legend_item(container: HBoxContainer, icon: String, text: String) -> void:
	var item = Label.new()
	item.text = icon + " " + text
	item.add_theme_font_size_override("font_size", 10)
	container.add_child(item)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	container.add_child(spacer)

func _connect_signals() -> void:
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)

func set_player(p: Player) -> void:
	player = p

func _on_game_paused() -> void:
	visible = true
	_update_stats()
	_update_minimap()

func _on_game_resumed() -> void:
	visible = false

func _update_stats() -> void:
	if not player or not stats_container:
		return
	
	# تحديث الإحصائيات
	var hp_label = stats_container.get_node_or_null("HP")
	if hp_label:
		hp_label.text = "❤️ %d/%d" % [player.current_hp, player.max_hp]
	
	var dmg_label = stats_container.get_node_or_null("DMG")
	if dmg_label:
		dmg_label.text = "⚔️ %.0f%%" % (player.damage_mult * 100)
	
	var def_label = stats_container.get_node_or_null("DEF")
	if def_label:
		def_label.text = "🛡️ %.0f%%" % (player.armor * 100)
	
	var luck_label = stats_container.get_node_or_null("LUCK")
	if luck_label:
		luck_label.text = "🍀 %.1f" % player.luck
	
	var crit_label = stats_container.get_node_or_null("CRIT")
	if crit_label:
		crit_label.text = "💥 %.0f%%" % (player.crit_chance * 100)
	
	var spd_label = stats_container.get_node_or_null("SPD")
	if spd_label:
		spd_label.text = "👟 %.0f%%" % ((player.base_speed / 200.0) * 100)
	
	var gold_label = stats_container.get_node_or_null("GOLD")
	if gold_label:
		gold_label.text = "💰 %d" % GameManager.gold
	
	var kills_label = stats_container.get_node_or_null("KILLS")
	if kills_label:
		kills_label.text = "💀 %d" % GameManager.kills

func _update_minimap() -> void:
	if not minimap_canvas or not player:
		return
	
	# حذف العناصر القديمة
	for child in minimap_canvas.get_children():
		child.queue_free()
	
	# حساب نسبة التحويل من العالم للخريطة
	var world_size = GameData.WORLD_SIZE
	var map_scale = minimap_canvas.size / world_size
	var center_offset = minimap_canvas.size / 2
	
	# رسم اللاعب (في المنتصف دائماً)
	var player_dot = Label.new()
	player_dot.text = "🔵"
	player_dot.position = _world_to_minimap(player.global_position, map_scale, center_offset, player.global_position)
	player_dot.position -= Vector2(8, 8)  # تعديل للمركز
	minimap_canvas.add_child(player_dot)
	
	# رسم الآيتمات
	var pickups = get_tree().get_nodes_in_group("pickup")
	for pickup in pickups:
		if not is_instance_valid(pickup):
			continue
		
		var pickup_type = pickup.get_meta("type", "item")
		var dot = Label.new()
		
		match pickup_type:
			"item":
				dot.text = "🟣"
			"chest":
				dot.text = "📦"
			_:
				continue  # تخطي XP والذهب
		
		dot.position = _world_to_minimap(pickup.global_position, map_scale, center_offset, player.global_position)
		dot.position -= Vector2(6, 6)
		dot.add_theme_font_size_override("font_size", 10)
		minimap_canvas.add_child(dot)
	
	# رسم الصناديق
	var chests = get_tree().get_nodes_in_group("chest")
	for chest in chests:
		if not is_instance_valid(chest):
			continue
		
		var dot = Label.new()
		dot.text = "📦"
		dot.position = _world_to_minimap(chest.global_position, map_scale, center_offset, player.global_position)
		dot.position -= Vector2(8, 8)
		minimap_canvas.add_child(dot)

func _world_to_minimap(world_pos: Vector2, scale: Vector2, offset: Vector2, player_pos: Vector2) -> Vector2:
	# تحويل من إحداثيات العالم لإحداثيات الخريطة المصغرة
	# نجعل اللاعب في المنتصف
	var relative_pos = world_pos - player_pos
	var minimap_pos = (relative_pos * scale) + offset
	
	# حدود الخريطة
	minimap_pos.x = clamp(minimap_pos.x, 0, minimap_canvas.size.x)
	minimap_pos.y = clamp(minimap_pos.y, 0, minimap_canvas.size.y)
	
	return minimap_pos

func _on_resume_pressed() -> void:
	GameManager.resume_game()

func _on_quit_pressed() -> void:
	GameManager.resume_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
