extends Area2D
class_name Projectile
## Projectile - قذيفة السلاح

@onready var sprite: AnimatedSprite2D = $Sprite

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 10.0
var max_range: float = 500.0
var traveled: float = 0.0
var weapon_type: String = "rock"

# مسارات sprites القذائف
const PROJECTILE_SPRITES = {
	"rock": "res://assets/weapons/New Weapons/brain/effect.png",
	"mgma": "res://assets/weapons/New Weapons/Mgma/effect.png",
	"meteor": "res://assets/weapons/New Weapons/meteor/effect.png",
	"onion": "res://assets/weapons/New Weapons/Onion/projectile on the way.png",
	"brain": "res://assets/weapons/New Weapons/brain/effect.png",
	"shuriken": "res://assets/weapons/New Weapons/Shuriken/Shuriken animation.png"
}

const PROJECTILE_FRAME_DATA = {
	"rock": {"width": 64, "height": 64, "fps": 8},
	"mgma": {"width": 64, "height": 64, "fps": 10},
	"meteor": {"width": 64, "height": 64, "fps": 8},
	"onion": {"width": 64, "height": 64, "fps": 8},
	"brain": {"width": 64, "height": 64, "fps": 8},
	"shuriken": {"width": 64, "height": 64, "fps": 12}
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_setup_sprite()

func _setup_sprite() -> void:
	if not sprite:
		return
	
	var sprite_path = PROJECTILE_SPRITES.get(weapon_type, PROJECTILE_SPRITES["rock"])
	var frame_data = PROJECTILE_FRAME_DATA.get(weapon_type, PROJECTILE_FRAME_DATA["rock"])
	var texture = load(sprite_path)
	
	if not texture:
		return
	
	var frames = SpriteFrames.new()
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", frame_data.fps)
	
	var frame_count = texture.get_width() / frame_data.width
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_data.width, 0, frame_data.width, frame_data.height)
		frames.add_frame("fly", atlas)
	
	sprite.sprite_frames = frames
	sprite.play("fly")
	
	# توجيه القذيفة حسب اتجاه الحركة
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var move_dist = speed * delta
	position += direction * move_dist
	traveled += move_dist
	
	if traveled >= max_range:
		queue_free()

func initialize(dir: Vector2, dmg: float, spd: float, rng: float, type: String = "rock") -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd
	max_range = rng
	weapon_type = type

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy and not body.is_dead:
		var knockback = direction * 80
		body.take_damage(damage, null, knockback)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is Enemy and not parent.is_dead:
		var knockback = direction * 80
		parent.take_damage(damage, null, knockback)
		queue_free()
