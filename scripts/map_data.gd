class_name MapData
extends RefCounted

const MIN_SIZE := 10
const MAX_SIZE := 100
const MAP_SIZES := [10, 15, 20, 25, 30, 40, 50, 75, 100]
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

static func default_map():
	var map = load("res://scripts/map_data.gd").new(10, 10, 260)
	for cell in [Vector2i(2, 2), Vector2i(5, 1), Vector2i(1, 4)]: map.set_terrain(cell, "Mountain")
	for cell in [Vector2i(3, 3), Vector2i(5, 4), Vector2i(2, 6)]: map.set_terrain(cell, "Reef")
	map.ports.append({"team_id": 0, "cell": Vector2i(0, 9)})
	map.ports.append({"team_id": 1, "cell": Vector2i(9, 0)})
	for unit in [{"kind": "Patrol", "team_id": 0, "cell": Vector2i(0, 9)}, {"kind": "Destroyer", "team_id": 0, "cell": Vector2i(1, 9)}, {"kind": "Patrol", "team_id": 1, "cell": Vector2i(9, 0)}, {"kind": "Destroyer", "team_id": 1, "cell": Vector2i(8, 0)}, {"kind": "Aircraft Carrier", "team_id": 1, "cell": Vector2i(9, 1)}, {"kind": "Fighter", "team_id": 1, "cell": Vector2i(7, 0)}]:
		map.starting_units.append(unit)
	return map

static func from_dictionary(data: Dictionary):
	if not data.has("width") or not data.has("height"):
		return default_map()
	var map = load("res://scripts/map_data.gd").new(int(data["width"]), int(data["height"]), int(data.get("starting_money", 260)))
	var source_terrain = data.get("terrain", [])
	if source_terrain is Array and source_terrain.size() == map.width * map.height:
		for index in source_terrain.size():
			if source_terrain[index] in TERRAIN_TYPES: map.terrain[index] = source_terrain[index]
	for entry in _valid_entries(data.get("ports", []), map): map.ports.append(entry)
	for entry in _valid_entries(data.get("starting_units", []), map): map.starting_units.append(entry)
	return map if map.ports.size() >= 2 else default_map()

static func _valid_entries(entries: Variant, map) -> Array[Dictionary]:
	var valid: Array[Dictionary] = []
	if not entries is Array: return valid
	for entry in entries:
		if entry is Dictionary and entry.get("cell") is Vector2i and map.is_inside(entry["cell"]): valid.append(entry)
	return valid

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func terrain_at(cell: Vector2i) -> String:
	return terrain[cell.y * width + cell.x] if is_inside(cell) else "Water"

func set_terrain(cell: Vector2i, terrain_type: String) -> void:
	if is_inside(cell) and terrain_type in TERRAIN_TYPES: terrain[cell.y * width + cell.x] = terrain_type

func to_dictionary() -> Dictionary:
	return {"version": 1, "width": width, "height": height, "starting_money": starting_money, "terrain": terrain, "ports": ports, "starting_units": starting_units}
