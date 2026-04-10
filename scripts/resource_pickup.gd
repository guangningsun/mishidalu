extends Area2D
## 资源道具
## 可见资源: 自动拾取
## 隐形资源: 按 E 发现后拾取

signal collected(type: String, amount: int)

@export var resource_type: String = "ammo"     # ammo, health, special
@export var amount: int = 10
@export var is_hidden: bool = false             # 隐形资源?

var _discovered: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hint_particles: CPUParticles2D = $HintParticles  # 隐形提示

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# 初始状态
	if is_hidden:
		sprite.modulate.a = 0.0  # 完全透明
		if hint_particles:
			hint_particles.emitting = true
	else:
		# 可见资源: 显示
		sprite.modulate.a = 1.0
		if hint_particles:
			hint_particles.emitting = false

	# 添加到 interactable 组 (供 player 检测)
	add_to_group("interactable")

## ─── 互动 (E 键) ────────────────────────────────────────────────────────────

func interact(player: Node) -> void:
	if is_hidden and not _discovered:
		_discover()
		return
	if is_hidden and _discovered:
		_collect(player)

func _discover() -> void:
	_discovered = true
	# 渐显
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	if hint_particles:
		tween.tween_property(hint_particles, "emitting", false, 0.0)
	print("HIDDEN RESOURCE DISCOVERED: %s @ %s" % [resource_type, global_position])

## ─── 拾取 ───────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	# 可见资源: 玩家碰到自动拾取
	if not is_hidden and body is CharacterBody2D:
		_collect(body)

func _collect(player: Node) -> void:
	collected.emit(resource_type, amount)
	if player.has_method("collect_resource"):
		player.collect_resource(resource_type, amount)

	# 拾取动画后删除
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)

## ─── 提示文本 ───────────────────────────────────────────────────────────────

func get_interact_prompt() -> String:
	if is_hidden and not _discovered:
		return "探索 (E)"
	return "拾取 (自动)"
