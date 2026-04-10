extends Node
## A* 寻路系统
## 为僵尸提供绕过障碍物的路径追踪
## 使用 Godot 4.x NavigationServer2D (内置, 无需额外资源)

@export var map_tilemap: TileMapLayer  # 障碍物瓦片层

var _nav_region: NavigationRegion2D

func _ready() -> void:
	add_to_group("navigation")  # 供 zombie 查找
	_nav_region = $NavigationRegion2D
	if not _nav_region:
		push_error("Navigation: NavigationRegion2D node not found! Add one to the scene.")
		return

## ─── 路径查询 ─────────────────────────────────────────────────────────────

func get_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	# Godot 4.x 稳定 API: 通过 NavigationRegion2D 获取 map RID
	var nav_map: RID = _nav_region.get_world_2d().get_navigation_map()
	return NavigationServer2D.map_get_path(nav_map, from, to, false)

## ─── 导航网格更新 ────────────────────────────────────────────────────────

func _on_tilemap_changed() -> void:
	# TileMap 障碍物更新时调用, 重新构建导航网格
	if _nav_region:
		_nav_region.bake_navigation_mesh()
