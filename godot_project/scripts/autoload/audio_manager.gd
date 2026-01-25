extends Node
## AudioManager - يدير الصوت والموسيقى

var bgm_player: AudioStreamPlayer
var boss_bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

const MAX_SFX_PLAYERS = 8

func _ready() -> void:
	# إنشاء مشغلات الصوت
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	boss_bgm_player = AudioStreamPlayer.new()
	boss_bgm_player.bus = "Music"
	add_child(boss_bgm_player)
	
	# إنشاء مشغلات المؤثرات الصوتية
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_bgm(stream: AudioStream, loop: bool = true) -> void:
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func play_boss_bgm(stream: AudioStream) -> void:
	# Fade out normal BGM
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40, 1.0)
	tween.tween_callback(bgm_player.stop)
	
	# Start boss BGM
	boss_bgm_player.stream = stream
	boss_bgm_player.volume_db = -40
	boss_bgm_player.play()
	
	var boss_tween = create_tween()
	boss_tween.tween_property(boss_bgm_player, "volume_db", 0, 1.0)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	# Find available SFX player
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return
	
	# If all players busy, use first one
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = volume_db
	sfx_players[0].play()

func set_music_volume(volume: float) -> void:
	var db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_sfx_volume(volume: float) -> void:
	var db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
