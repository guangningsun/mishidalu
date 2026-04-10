extends Node2D
## 迷雾探索系统
## 基于 TileMap 的可见性遮罩
## 相机揭示玩家周围的瓦片, 已揭示的瓦片永久可见

## 瓦片状态
const TILE_HIDDEN: int = 0
const TILE_REVEALED: int = 1

@export var reveal_radius: int = 4       # 瓦片半径
@export var tile_size: Vector2i = Vector2i(16, 16)

var _fog_tilemap: TileMapLayer
var _player: Node
var _revealed_tiles: Dictionary = {}    # {Vector2i: TILE_REVEALED}

func _ready() -> void:
	_fog_tilemap = $FogTilemap
	_player = get_node_or_null("../Player")

	if not _fog_tilemap:
		push_error("FogOfWar: FogTilemap node not found!")
		return

	# 初始化所有瓦片为隐藏
	_initialize_fog()

	# 每帧更新
	set_process(true)

func _process(_delta: float) -> void:
	if _player:
		_reveal_around_player()

func _initialize_fog() -> void:
	# 获取 FogTilemap 的区域, 全部设为隐藏
	# 实际地图大小需要根据关卡设计确定
	# 这里假设 50x30 的地图
	for x in range(50):
		for y in range(30):
			var coords := Vector2i(x, y)
			_fog_tilemap.set_cell(coords, 0, Vector2i(0, 0))  # 假设 tile 0 是迷雾

func _reveal_around_player() -> void:
	if not _player:
		return

	var player_tile: Vector2i = _fog_tilemap.local_to_map(_player.global_position)
	var player_cell := _world_to_fog_cell(player_tile)

	for dx in range(-reveal_radius, reveal_radius + 1):
		for dy in range(-reveal_radius, reveal_radius + 1):
			var dist := Vector2i(dx, dy).length()
			if dist > reveal_radius:
				continue
			var coords := player_cell + Vector2i(dx, dy)
			_reveal_tile(coords)

## ─── 公开方法 ───────────────────────────────────────────────────────────────

func _world_to_fog_cell(world_tile: Vector2i) -> Vector2i:
	# world_tile 是游戏地图的 TileMap 瓦片坐标
	# fog_cell 是迷雾系统的瓦片坐标
	# 如果两个系统共用同一个 tilemap, 直接返回 world_tile
	return world_tile

func _reveal_tile(coords: Vector2i) -> void:
	if not _revealed_tiles.has(coords):
		_revealed_tiles[coords] = TILE_REVEALED
		_fog_tilemap.set_cell(coords, -1)  # -1 表示清除 (揭示)
		# 实际项目中可能需要切换到"已揭示"的瓦片而非清除
		# _fog_tilemap.set_cell(coords, 0, Vector2i(1, 0))  # tile 1 = 已揭示

func is_tile_revealed(coords: Vector2i) -> bool:
	return _revealed_tiles.has(coords)
