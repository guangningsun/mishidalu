extends CharacterBody2D
## 僵尸
## A* 路径追踪玩家, 接触造成伤害

signal died(zombie: Node)

@export var move_speed: float = 60.0
@export var damage: int = 10
@export var contact_damage_cooldown: float = 0.5  # 秒

var _damage_timer: float = 0.0
var _player: Node
var _navigation: Node
var _current_path: PackedVector2Array = []
var _path_index: int = 0
var _repath_timer: float = 0.0
var _repath_interval: float = 0.5  # 每 0.5 秒重新寻路

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_navigation = get_tree().get_first_node_in_group("navigation")
	add_to_group("zombies")

func _physics_process(delta: float) -> void:
	if _damage_timer > 0:
		_damage_timer -= delta

	if _player:
		_repath_timer -= delta
		if _repath_timer <= 0:
			_repath_timer = _repath_interval
			_refresh_path()

		_follow_path(delta)

	# 简单朝向
	if _player and global_position.x < _player.global_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

func _refresh_path() -> void:
	if not _player or not _navigation:
		return

	var from: Vector2 = global_position
	var to: Vector2 = _player.global_position
	_current_path = _navigation.get_path(from, to)
	_path_index = 0

func _follow_path(delta: float) -> void:
	if _current_path.size() == 0 or _path_index >= _current_path.size():
		return

	var target: Vector2 = _current_path[_path_index]
	var dir := (target - global_position).normalized()

	var collided := move_and_collide(dir * move_speed * delta)

	if collided:
		# 碰到障碍, 尝试跳到下一个路径点
		_path_index += 1
		return

	# 到达当前路径点, 移动到下一个
	if global_position.distance_to(target) < 8.0:
		_path_index += 1

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and _damage_timer <= 0:
		body.take_damage(damage)
		_damage_timer = contact_damage_cooldown
		print("ZOMBIE HIT PLAYER: %d dmg, %.1fs cooldown" % [damage, contact_damage_cooldown])

func die() -> void:
	died.emit(self)
	queue_free()
