class_name MapData
extends RefCounted

const MIN_SIZE := 10
const MAX_SIZE := 100
const TERRAIN_TYPES := ["Water", "Reef", "Mountain"]

var width: int
var height: int
var starting_money: int
var terrain: Array[String] = []
var ports: Array[Dictionary] = []
var starting_units: Array[Dictionary] = []

func _init(map_width: int = 10, map_height: int = 10, money: int = 260) -> void:
	width = clampi(map_width, MIN_SIZE, MAX_SIZE)
	height = clampi(map_height, MIN_SIZE, MAX_SIZE)
	starting_money = maxi(0, money)
	terrain.resize(width * height)
	terrain.fill("Water")

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func terrain_at(cell: Vector2i) -> String:
	if not is_inside(cell):
		return "Water"
	return terrain[cell.y * width + cell.x]

func set_terrain(cell: Vector2i, terrain_type: String) -> void:
	if is_inside(cell) and terrain_type in TERRAIN_TYPES:
		terrain[cell.y * width + cell.x] = terrain_type

func to_dictionary() -> Dictionary:
	return {
		"version": 1,
		"width": width,
		"height": height,
		"starting_money": starting_money,
		"terrain": terrain,
		"ports": ports,
		"starting_units": starting_units,
	}
