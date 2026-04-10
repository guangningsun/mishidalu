extends Node2D
## 迷雾探索系统
## 基于 TileMap 的可见性遮罩
## 相机揭示玩家周围的瓦片, 已揭示的瓦片永久可见

## 瓦片状态
const TILE_HIDDEN: int = 0
const TILE_REVEALED: int = 1

@export var reveal_radius: int = 4       # 瓦片半径

var _fog_tilemap: TileMapLayer
var _player: Node
var _revealed_tiles: Dictionary = {}    # {Vector2i: TILE_REVEALED}

func _ready() -> void:
	_fog_tilemap = $FogTilemap
	_player = get_node_or_null("../Player")

	if not _fog_tilemap:
		push_error("FogOfWar: FogTilemap node not found!")
		return

	# 动态获取地图范围，不硬编码
	_initialize_fog()

	# 每帧更新
	set_process(true)

func _initialize_fog() -> void:
	# 从 TileMap 动态获取实际使用的区域
	var used_cells := _fog_tilemap.get_used_cells()
	if used_cells.size() == 0:
		push_warning("FogOfWar: FogTilemap has no tiles. Set up your map tiles first.")
		return

	# 计算 bounding box
	var min_x := 0
	var min_y := 0
	var max_x := 0
	var max_y := 0
	for cell in used_cells:
		if cell.x < min_x:
			min_x = cell.x
		if cell.x > max_x:
			max_x = cell.x
		if cell.y < min_y:
			min_y = cell.y
		if cell.y > max_y:
			max_y = cell.y

	# 初始化所有瓦片为隐藏 (tile source -1 = 清除)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var coords := Vector2i(x, y)
			_fog_tilemap.set_cell(coords, 0, Vector2i(0, 0))  # tile 0 = 迷雾

func _process(_delta: float) -> void:
	if _player:
		_reveal_around_player()

func _reveal_around_player() -> void:
	if not _player:
		return

	var player_tile: Vector2i = _fog_tilemap.local_to_map(_player.global_position)

	for dx in range(-reveal_radius, reveal_radius + 1):
		for dy in range(-reveal_radius, reveal_radius + 1):
			var dist := Vector2i(dx, dy).length()
			if dist > reveal_radius:
				continue
			var coords := player_tile + Vector2i(dx, dy)
			_reveal_tile(coords)

## ─── 公开方法 ───────────────────────────────────────────────────────────────

func _reveal_tile(coords: Vector2i) -> void:
	if not _revealed_tiles.has(coords):
		_revealed_tiles[coords] = TILE_REVEALED
		_fog_tilemap.set_cell(coords, -1)  # -1 清除 = 揭示

func is_tile_revealed(coords: Vector2i) -> bool:
	return _revealed_tiles.has(coords)
