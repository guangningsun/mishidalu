extends Node
## 尸潮波次管理器
## 定时触发僵尸生成, 3 波递增, 追踪清波状态

signal wave_started(wave_num: int)
signal wave_cleared(wave_num: int)
signal all_waves_complete

@export var zombie_scene: PackedScene       # Zombie.tscn
@export var spawn_points: Array[Vector2]   # 尸潮生成点 (庇护所外)
@export var wave_durations: Array[float]   # 每波持续时间 [10.0, 15.0, 20.0]

var _current_wave: int = 0
var _active_zombies: Array[Node] = []
var _wave_timer: float = 0.0
var _is_wave_active: bool = false

var zombie_count_per_wave: Array[int] = [5, 8, 12]  # 默认

func _process(delta: float) -> void:
	if not _is_wave_active:
		return

	_wave_timer -= delta
	if _wave_timer <= 0:
		# 时间到但没清完: 波次失败, 重试
		print("WAVE %d TIMEOUT: retrying..." % _current_wave)
		_stop_wave()
		_start_wave(_current_wave)

	_check_zombies_alive()

## ─── 波次控制 ───────────────────────────────────────────────────────────────

func start_wave(wave_num: int) -> void:
	_current_wave = wave_num
	_start_wave(wave_num)

func _start_wave(wave_num: int) -> void:
	_is_wave_active = true
	_wave_timer = wave_durations[wave_num - 1] if wave_num <= wave_durations.size() else 15.0

	var count: int = zombie_count_per_wave[wave_num - 1] if wave_num <= zombie_count_per_wave.size() else 5
	_spawn_zombies(count)

	wave_started.emit(wave_num)
	print("WAVE %d STARTED: %d zombies, %.1fs" % [wave_num, count, _wave_timer])

func _stop_wave() -> void:
	_is_wave_active = false
	# 清理存活僵尸
	for z in _active_zombies:
		if is_instance_valid(z):
			z.queue_free()
	_active_zombies.clear()

func _spawn_zombies(count: int) -> void:
	for i in range(count):
		var spawn_pos: Vector2
		if spawn_points.size() > 0:
			spawn_pos = spawn_points[i % spawn_points.size()]
		else:
			# 默认: 庇护所外随机
			spawn_pos = Vector2(randf_range(200, 600), randf_range(100, 400))

		var zombie: Node = _create_zombie(spawn_pos)
		_active_zombies.append(zombie)

func _create_zombie(pos: Vector2) -> Node:
	# 实例化僵尸
	var zombie: Node
	if zombie_scene:
		zombie = zombie_scene.instantiate()
	else:
		# 验证阶段: 如果没有僵尸场景, 打印警告
		push_warning("WaveManager: zombie_scene not set, using placeholder")
		zombie = Node2D.new()
		zombie.name = "ZombiePlaceholder"
		zombie.position = pos

	zombie.died.connect(_on_zombie_died)
	get_parent().add_child(zombie)
	zombie.global_position = pos
	return zombie

func _on_zombie_died(zombie: Node) -> void:
	_active_zombies.erase(zombie)

## ─── 状态查询 ───────────────────────────────────────────────────────────────

func is_wave_cleared() -> bool:
	return _is_wave_active == false and _active_zombies.size() == 0

func _check_zombies_alive() -> void:
	# 清理已销毁的引用
	_active_zombies = _active_zombies.filter(func(z): return is_instance_valid(z))

	if _is_wave_active and _active_zombies.size() == 0:
		# 意外空场, 波次结束
		_is_wave_active = false
		wave_cleared.emit(_current_wave)
		print("WAVE %d CLEARED" % _current_wave)

## ─── 僵尸AI (内联) ──────────────────────────────────────────────────────────

## 注: 实际项目中僵尸 AI 在 zombie.gd
## 这里保留简单 chase 逻辑供参考:
##   func _chase_player(delta):
##       var dir := (player.global_position - global_position).normalized()
##       move_and_collide(dir * speed * delta)
