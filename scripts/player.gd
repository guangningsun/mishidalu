extends CharacterBody2D
## 玩家角色
## WASD 移动, 鼠标瞄准, 左键射击, E 键互动

signal died
signal resource_collected(type: String, amount: int)

@export var move_speed: float = 150.0
@export var max_hp: int = 100
@export var shoot_cooldown: float = 0.3       # 秒
@export var interact_range: float = 48.0     # 像素

var hp: int = max_hp
var shoot_timer: float = 0.0
var is_shooting_enabled: bool = false
var can_take_damage: bool = true
var damage_cooldown: float = 0.5             # 接触伤害冷却

var _last_interact_target: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_origin: Marker2D = $ShootOrigin
@onready var interaction_prompt: Label = $InteractionPrompt

func _ready() -> void:
	# interaction_prompt 初始隐藏
	if interaction_prompt:
		interaction_prompt.visible = false

func _physics_process(delta: float) -> void:
	# 移动
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	move_and_collide(input_dir * move_speed * delta)

	# 射击冷却
	if shoot_timer > 0:
		shoot_timer -= delta

	# 互动提示
	_update_interaction_prompt()

	# 射击 (在 DEFEND 模式下)
	if is_shooting_enabled and Input.is_action_pressed("shoot") and shoot_timer <= 0:
		_shoot()

func _update_interaction_prompt() -> void:
	# 检测范围内可互动对象
	var nearest: Node = _get_nearest_interactable()
	if nearest and interaction_prompt:
		interaction_prompt.visible = true
		interaction_prompt.text = "Press E: " + nearest.interact_prompt
		_last_interact_target = nearest
	elif interaction_prompt:
		interaction_prompt.visible = false
		_last_interact_target = null

func _get_nearest_interactable() -> Node:
	# 从场景中获取所有带 interactable 组的节点
	var interactables := get_tree().get_nodes_in_group("interactable")
	var nearest: Node = null
	var min_dist := interact_range

	for node in interactables:
		var dist := global_position.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = node
	return nearest

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_do_interact()

func _do_interact() -> void:
	if _last_interact_target and _last_interact_target.has_method("interact"):
		_last_interact_target.interact(self)

## ─── 射击 ───────────────────────────────────────────────────────────────────

func _shoot() -> void:
	# 获取鼠标方向
	var mouse_pos := get_global_mouse_position()
	var dir := (mouse_pos - global_position).normalized()

	# TODO: 生成子弹场景
	# var bullet := bullet_scene.instantiate()
	# bullet.position = shoot_origin.global_position
	# bullet.direction = dir
	# get_parent().add_child(bullet)

	shoot_timer = shoot_cooldown

	# 简单射击特效: 向鼠标方向"戳"一下
	# 后续替换为实际子弹
	print("SHOOT: dir=%s pos=%s" % [dir, shoot_origin.global_position])

## ─── 伤害 ───────────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if not can_take_damage:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
		died.emit()
		_on_death()

func _on_death() -> void:
	can_take_damage = false
	print("PLAYER DIED: respawning...")
	# 延迟后复活 (实际重生逻辑在 main.gd 的 on_player_died)
	await get_tree().create_timer(1.0).timeout
	can_take_damage = true

func respawn_at(position: Vector2) -> void:
	global_position = position
	hp = max_hp
	can_take_damage = true
	print("PLAYER RESPAWNED at ", position)

## ─── 公开方法 ───────────────────────────────────────────────────────────────

func set_shooting_enabled(enabled: bool) -> void:
	is_shooting_enabled = enabled

func collect_resource(type: String, amount: int) -> void:
	resource_collected.emit(type, amount)
	print("COLLECTED: %s x%d" % [type, amount])
