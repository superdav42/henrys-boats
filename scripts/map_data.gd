class_name MapData
extends RefCounted

const VERSION := 1
const MIN_SIZE := 10
const MAX_SIZE := 100
const MAP_SIZES := [10, 15, 20, 25, 30, 40, 50, 75, 100]
const TERRAIN_TYPES := ["Water", "Shore", "Land", "Mountain", "Snow Mountain", "Reef", "River"]
const UNIT_TYPES := ["Patrol", "Destroyer", "Submarine", "Aircraft Carrier", "Anti-Air Boat", "Jet", "Fighter", "Bomber"]
const AIR_UNIT_TYPES := ["Jet", "Fighter", "Bomber"]
const INVALID_CELL := Vector2i(-1, -1)

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
	for cell in [Vector2i(2, 2), Vector2i(5, 1), Vector2i(1, 4)]:
		map.set_terrain(cell, "Mountain")
	map.set_terrain(Vector2i(5, 2), "Snow Mountain")
	for cell in [Vector2i(3, 3), Vector2i(5, 4), Vector2i(2, 6)]:
		map.set_terrain(cell, "Reef")
	for cell in [Vector2i(4, 1), Vector2i(6, 2)]:
		map.set_terrain(cell, "Shore")
	for cell in [Vector2i(4, 2), Vector2i(6, 3)]:
		map.set_terrain(cell, "Land")
	for cell in [Vector2i(4, 3), Vector2i(6, 4)]:
		map.set_terrain(cell, "River")
	map.ports.append({"team_id": 0, "cell": Vector2i(0, 9)})
	map.ports.append({"team_id": 1, "cell": Vector2i(9, 0)})
	for unit in [{"kind": "Patrol", "team_id": 0, "cell": Vector2i(0, 9)}, {"kind": "Destroyer", "team_id": 0, "cell": Vector2i(1, 9)}, {"kind": "Patrol", "team_id": 1, "cell": Vector2i(9, 0)}, {"kind": "Destroyer", "team_id": 1, "cell": Vector2i(8, 0)}, {"kind": "Aircraft Carrier", "team_id": 1, "cell": Vector2i(9, 1)}, {"kind": "Fighter", "team_id": 1, "cell": Vector2i(7, 0)}]:
		map.starting_units.append(unit)
	return map

static func from_dictionary(data: Variant):
	if not data is Dictionary:
		return null
	var version_value: Variant = data.get("version", VERSION)
	var version: Variant = _integer(version_value)
	if version == null or version != VERSION:
		return null
	var map_width: Variant = _integer(data.get("width"))
	var map_height: Variant = _integer(data.get("height"))
	var money: Variant = _integer(data.get("starting_money", 260))
	if map_width == null or map_height == null or money == null or money < 0:
		return null
	if not map_width in MAP_SIZES or not map_height in MAP_SIZES:
		return null
	var source_terrain: Variant = data.get("terrain")
	if not source_terrain is Array or source_terrain.size() != map_width * map_height:
		return null
	var map = load("res://scripts/map_data.gd").new(map_width, map_height, money)
	for index in source_terrain.size():
		if not source_terrain[index] is String or not source_terrain[index] in TERRAIN_TYPES:
			return null
		map.terrain[index] = source_terrain[index]
	var decoded_ports: Variant = _decode_entries(data.get("ports", []), map, false)
	var decoded_units: Variant = _decode_entries(data.get("starting_units", []), map, true)
	if decoded_ports == null or decoded_units == null:
		return null
	map.ports = decoded_ports
	map.starting_units = decoded_units
	return map if map.is_valid() else null

static func _decode_entries(entries: Variant, map, requires_kind: bool) -> Variant:
	if not entries is Array:
		return null
	var decoded: Array[Dictionary] = []
	for entry in entries:
		if not entry is Dictionary:
			return null
		var team_id: Variant = _integer(entry.get("team_id"))
		var cell: Vector2i = _cell_from_variant(entry.get("cell"))
		if team_id == null or team_id < 0 or team_id > 7 or cell == INVALID_CELL or not map.is_inside(cell):
			return null
		var clean := {"team_id": team_id, "cell": cell}
		if requires_kind:
			var kind: Variant = entry.get("kind")
			if not kind is String or not kind in UNIT_TYPES:
				return null
			clean["kind"] = kind
		decoded.append(clean)
	return decoded

static func _integer(value: Variant) -> Variant:
	if not value is int and not value is float:
		return null
	if float(value) != floor(float(value)):
		return null
	return int(value)

static func _cell_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if not value is Dictionary:
		return INVALID_CELL
	var x: Variant = _integer(value.get("x"))
	var y: Variant = _integer(value.get("y"))
	return Vector2i(x, y) if x != null and y != null else INVALID_CELL

func is_valid() -> bool:
	return validation_errors().is_empty()

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not width in MAP_SIZES or not height in MAP_SIZES:
		errors.append("Map size must use an approved width and height.")
	if starting_money < 0:
		errors.append("Starting money cannot be negative.")
	if terrain.size() != width * height:
		errors.append("Terrain data does not match the map size.")
	for terrain_type in terrain:
		if not terrain_type in TERRAIN_TYPES:
			errors.append("Map terrain contains an unknown value.")
			break
	if ports.size() < 2 or ports.size() > 8:
		errors.append("A map needs ports for two to eight teams.")
	var port_cells := {}
	var teams := {}
	for port in ports:
		var cell: Variant = port.get("cell")
		var team_id: Variant = port.get("team_id")
		if not cell is Vector2i or not is_inside(cell) or not team_id is int or team_id < 0 or team_id > 7:
			errors.append("Every port needs a valid team and cell.")
			continue
		var key := "%d,%d" % [cell.x, cell.y]
		if port_cells.has(key) or teams.has(team_id):
			errors.append("Ports must use unique cells and teams.")
		port_cells[key] = true
		teams[team_id] = true
	if teams.size() >= 2:
		for team_id in teams.size():
			if not teams.has(team_id):
				errors.append("Team IDs must be consecutive from 0.")
				break
	var unit_cells := {}
	for unit in starting_units:
		var cell: Variant = unit.get("cell")
		var team_id: Variant = unit.get("team_id")
		var kind: Variant = unit.get("kind")
		if not cell is Vector2i or not is_inside(cell) or not team_id is int or not teams.has(team_id) or not kind is String or not kind in UNIT_TYPES:
			errors.append("Every starting unit needs a known type, participating team, and valid cell.")
			continue
		var key := "%d,%d" % [cell.x, cell.y]
		if unit_cells.has(key):
			errors.append("Starting units must use unique cells.")
		unit_cells[key] = true
		if not can_unit_occupy(kind, kind in AIR_UNIT_TYPES, cell):
			errors.append("That starting unit cannot occupy its terrain.")
	return errors

func copy():
	return from_dictionary(to_dictionary())

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func terrain_at(cell: Vector2i) -> String:
	return terrain[cell.y * width + cell.x] if is_inside(cell) else "Water"

func set_terrain(cell: Vector2i, terrain_type: String) -> void:
	if is_inside(cell) and terrain_type in TERRAIN_TYPES:
		terrain[cell.y * width + cell.x] = terrain_type

func movement_cost(kind: String, is_air: bool, cell: Vector2i) -> int:
	var terrain_type := terrain_at(cell)
	if is_air:
		if terrain_type == "Snow Mountain":
			return 3
		if terrain_type == "Mountain":
			return 2
		return 1
	if terrain_type in ["Land", "Mountain", "Snow Mountain"]:
		return -1
	if terrain_type == "Shore":
		return 2
	return 1

func can_unit_occupy(kind: String, is_air: bool, cell: Vector2i) -> bool:
	if movement_cost(kind, is_air, cell) < 0:
		return false
	return terrain_at(cell) != "River" or is_air or kind == "Patrol"

func place_port(team_id: int, cell: Vector2i) -> bool:
	if team_id < 0 or team_id > 7 or not is_inside(cell):
		return false
	for index in ports.size():
		if ports[index]["team_id"] == team_id:
			ports[index]["cell"] = cell
			return true
	for port in ports:
		if port["cell"] == cell:
			return false
	ports.append({"team_id": team_id, "cell": cell})
	return true

func remove_port_at(cell: Vector2i) -> bool:
	for index in ports.size():
		if ports[index]["cell"] == cell:
			ports.remove_at(index)
			return true
	return false

func place_starting_unit(kind: String, team_id: int, cell: Vector2i) -> bool:
	if not kind in UNIT_TYPES or not is_inside(cell) or not can_unit_occupy(kind, kind in AIR_UNIT_TYPES, cell):
		return false
	for index in starting_units.size():
		if starting_units[index]["cell"] == cell:
			starting_units[index] = {"kind": kind, "team_id": team_id, "cell": cell}
			return true
	starting_units.append({"kind": kind, "team_id": team_id, "cell": cell})
	return true

func remove_starting_unit_at(cell: Vector2i) -> bool:
	for index in starting_units.size():
		if starting_units[index]["cell"] == cell:
			starting_units.remove_at(index)
			return true
	return false

func to_dictionary() -> Dictionary:
	var serialized_ports: Array[Dictionary] = []
	for port in ports:
		serialized_ports.append({"team_id": port["team_id"], "cell": _serialize_cell(port["cell"])})
	var serialized_units: Array[Dictionary] = []
	for unit in starting_units:
		serialized_units.append({"kind": unit["kind"], "team_id": unit["team_id"], "cell": _serialize_cell(unit["cell"])})
	return {"version": VERSION, "width": width, "height": height, "starting_money": starting_money, "terrain": terrain.duplicate(), "ports": serialized_ports, "starting_units": serialized_units}

static func _serialize_cell(cell: Vector2i) -> Dictionary:
	return {"x": cell.x, "y": cell.y}
