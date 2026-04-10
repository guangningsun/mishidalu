extends Area2D
## 庇护所
## 玩家进入触发尸潮倒计时, 防守时锁定

signal player_entered(shelter: Node)
signal defense_started

@export var is_shelter_active: bool = true  # 是否可进入

var _defense_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var door_block: Sprite2D = $DoorBlock   # 防守时显示阻挡

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	door_block.visible = false  # 初始不显示

func _on_area_entered(area: Area2D) -> void:
	if not is_shelter_active:
		return
	if area.get_parent() has "Player":
		_enter_shelter(area.get_parent())

func _enter_shelter(player_node: Node) -> void:
	if _defense_active:
		return  # 已在防守中

	_defense_active = true
	door_block.visible = true  # 显示门锁

	# 通知 main.gd
	player_entered.emit(self)

	# 触发 main.gd 进入 COUNTDOWN → DEFEND 流程
	var main_node := get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("on_shelter_entered"):
		main_node.on_shelter_entered(self)

	print("SHELTER ENTERED: defense incoming")

func start_defense() -> void:
	_defense_active = true
	door_block.visible = true
	defense_started.emit()

func end_defense() -> void:
	_defense_active = false
	door_block.visible = false

## ─── 公开方法 ───────────────────────────────────────────────────────────────

func get_respawn_position() -> Vector2:
	# 复活点: 庇护所入口
	return global_position + Vector2(0, 32)  # 略微偏移到门外

func is_defense_active() -> bool:
	return _defense_active
