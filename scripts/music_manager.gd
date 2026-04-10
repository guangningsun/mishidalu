extends Node
## 动态音乐切换
## Phase/Defend 状态, 2 秒交叉淡入淡出
## 热插拔接口: 后续替换音乐文件不影响代码

@export var crossfade_duration: float = 2.0  # 秒

var _current_track: String = ""
var _target_track: String = ""
var _tween: Tween
var _music_players: Array[AudioStreamPlayer] = []

# 音乐路径映射 (后续替换为实际文件)
var _track_paths: Dictionary = {
	"explore": "",    # "res://resources/audio/explore.ogg"
	"countdown": "",  # "res://resources/audio/countdown.ogg"
	"defend": "",     # "res://resources/audio/defend.ogg"
}

func _ready() -> void:
	# 创建两个 AudioStreamPlayer (A/B 交叉淡入淡出)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_music_players.append(player)

func crossfade_to(track_name: String) -> void:
	if track_name == _current_track:
		return
	_target_track = track_name

	var path: String = _track_paths.get(track_name, "")
	if path.is_empty():
		print("MusicManager: no path for track '%s'" % track_name)
		return

	# 加载新音乐
	var stream: AudioStream = load(path)
	if not stream:
		print("MusicManager: failed to load '%s'" % path)
		return

	# A/B 交叉淡入淡出
	_crossfade(stream)

func _crossfade(new_stream: AudioStream) -> void:
	# 停止已有 tween
	if _tween and _tween.is_valid():
		_tween.kill()

	var player_cur := _music_players[0]
	var player_next := _music_players[1]

	# 当前播放器的目标: 淡出到 0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(player_cur, "volume_db", -80.0, crossfade_duration)
	_tween.chain().tween_callback(player_cur.stop)

	# 下一播放器: 设置新音乐, 从 0 淡入
	player_next.stream = new_stream
	player_next.volume_db = -80.0
	player_next.play()
	_tween.tween_property(player_next, "volume_db", 0.0, crossfade_duration)

	# 交换
	_music_players[0] = player_next
	_music_players[1] = player_cur

	_current_track = _target_track
	print("MusicManager: crossfade to '%s'" % _current_track)

## ─── 热插拔 ─────────────────────────────────────────────────────────────────

func set_track_path(track_name: String, path: String) -> void:
	_track_paths[track_name] = path

## ─── 状态查询 ───────────────────────────────────────────────────────────────

func get_current_track() -> String:
	return _current_track
