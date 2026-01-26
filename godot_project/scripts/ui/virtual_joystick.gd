extends Control
class_name VirtualJoystick
## VirtualJoystick - جويستيك افتراضي للتحكم باللمس

signal joystick_input(direction: Vector2)

@export var max_distance: float = 64.0
@export var dead_zone: float = 0.2

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var is_pressed: bool = false
var touch_index: int = -1
var center_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	center_position = base.size / 2

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _is_in_joystick_area(event.position):
			is_pressed = true
			touch_index = event.index
			_update_knob_position(event.position)
	else:
		if event.index == touch_index:
			_reset_joystick()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if is_pressed and event.index == touch_index:
		_update_knob_position(event.position)

func _is_in_joystick_area(pos: Vector2) -> bool:
	var local_pos = pos - global_position
	return local_pos.distance_to(center_position) <= max_distance * 2

func _update_knob_position(touch_pos: Vector2) -> void:
	var local_pos = touch_pos - global_position - base.position
	var direction = local_pos - center_position
	
	# تطبيق الحد الأقصى للمسافة
	if direction.length() > max_distance:
		direction = direction.normalized() * max_distance
	
	knob.position = center_position + direction - knob.size / 2
	
	# حساب الاتجاه المُطبَّع
	var normalized = direction / max_distance
	
	# تطبيق المنطقة الميتة
	if normalized.length() < dead_zone:
		normalized = Vector2.ZERO
	
	emit_signal("joystick_input", normalized)

func _reset_joystick() -> void:
	is_pressed = false
	touch_index = -1
	knob.position = center_position - knob.size / 2
	emit_signal("joystick_input", Vector2.ZERO)
