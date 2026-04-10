extends Node
## 游戏主控制器
## 管理游戏状态机: EXPLORE → COUNTDOWN → DEFEND → PHASE_END
## 协调所有子系统 (fog, wave, music, shelter)

enum GameState {
	EXPLORE,    # 探索模式, 迷雾揭示, 资源收集
	COUNTDOWN,  # 进入庇护所后倒计时, 等待尸潮
	DEFEND,     # 防守模式, 射击僵尸
	PHASE_END,  # 章节结束, 显示过渡信息
}

signal state_changed(from: GameState, to: GameState)

@export var countdown_duration: float = 10.0  # 秒
@export var total_waves: int = 3

var current_state: GameState = GameState.EXPLORE
var wave_manager: Node
var music_manager: Node
var fog_system: Node
var shelter: Node
var player: Node

var countdown_timer: float = 0.0
var current_wave: int = 0

func _ready() -> void:
	# 子系统通过场景树获取 (在 main.tscn 中已挂载)
	wave_manager = get_node_or_null("WaveManager")
	music_manager = get_node_or_null("MusicManager")
	fog_system = get_node_or_null("FogSystem")
	shelter = get_node_or_null("Shelter")
	player = get_node_or_null("Player")

	state_changed.connect(_on_state_changed)

func _process(delta: float) -> void:
	match current_state:
		GameState.COUNTDOWN:
			countdown_timer -= delta
			if countdown_timer <= 0.0:
				_start_defend()
		GameState.DEFEND:
			_check_wave_complete()

## ─── 状态转换 ───────────────────────────────────────────────────────────────

func transition_to(new_state: GameState) -> void:
	if new_state == current_state:
		return
	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)
	_on_enter_state(new_state)

func _on_state_changed(from: GameState, to: GameState) -> void:
	# 状态转换时可以触发音乐切换等副作用
	pass

func _on_enter_state(state: GameState) -> void:
	match state:
		GameState.EXPLORE:
			_enter_explore()
		GameState.COUNTDOWN:
			_enter_countdown()
		GameState.DEFEND:
			# _start_defend() 单独调用, 不从这里进入
			pass
		GameState.PHASE_END:
			_enter_phase_end()

func _enter_explore() -> void:
	# 恢复探索: 音乐切到 ambient, 迷雾系统激活
	if music_manager:
		music_manager.crossfade_to("explore")
	if player:
		player.set_shooting_enabled(false)

func _enter_countdown() -> void:
	countdown_timer = countdown_duration
	if music_manager:
		music_manager.crossfade_to("countdown")
	if player:
		player.set_shooting_enabled(false)

func _start_defend() -> void:
	current_wave = 1
	transition_to(GameState.DEFEND)
	if music_manager:
		music_manager.crossfade_to("defend")
	if wave_manager:
		wave_manager.start_wave(current_wave)
	if player:
		player.set_shooting_enabled(true)

func _enter_phase_end() -> void:
	# 显示章节过渡 UI, 打印完成信息
	print("=== CHAPTER COMPLETE: Edge City ===")
	print("Transitioning to: Bridge / Tunnel")
	# TODO: 显示过渡场景或打印到屏幕

func _check_wave_complete() -> void:
	if wave_manager and wave_manager.is_wave_cleared():
		current_wave += 1
		if current_wave > total_waves:
			transition_to(GameState.PHASE_END)
		else:
			# 下一波
			wave_manager.start_wave(current_wave)

## ─── 庇护所触发 ─────────────────────────────────────────────────────────────

func on_shelter_entered(shelter_node: Node) -> void:
	if current_state != GameState.EXPLORE:
		return
	shelter = shelter_node
	transition_to(GameState.COUNTDOWN)

## ─── 玩家死亡 ───────────────────────────────────────────────────────────────

func on_player_died() -> void:
	# 验证阶段: 无限复活, 在庇护所入口重生
	if player and shelter:
		player.respawn_at(shelter.get_respawn_position())
