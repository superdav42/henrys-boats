class_name GameState
extends RefCounted

const MapDataResource = preload("res://scripts/map_data.gd")
const TeamDataResource = preload("res://scripts/team_data.gd")

var map_data
var teams: Array = []
var units: Array[Dictionary] = []
var current_team_index := 0
var next_unit_id := 1

func initialize_default() -> void:
	map_data = MapDataResource.new(10, 10, 260)
	for cell in [Vector2i(2, 2), Vector2i(5, 1), Vector2i(1, 4)]: map_data.set_terrain(cell, "Mountain")
	for cell in [Vector2i(3, 3), Vector2i(5, 4), Vector2i(2, 6)]: map_data.set_terrain(cell, "Reef")
	map_data.ports.append({"team_id": 0, "cell": Vector2i(0, 9)})
	map_data.ports.append({"team_id": 1, "cell": Vector2i(9, 0)})
	for unit in [{"kind": "Patrol", "team_id": 0, "cell": Vector2i(0, 9), "hp": 3}, {"kind": "Destroyer", "team_id": 0, "cell": Vector2i(1, 9), "hp": 4}, {"kind": "Patrol", "team_id": 1, "cell": Vector2i(9, 0), "hp": 3}, {"kind": "Destroyer", "team_id": 1, "cell": Vector2i(8, 0), "hp": 4}, {"kind": "Aircraft Carrier", "team_id": 1, "cell": Vector2i(9, 1), "hp": 6}, {"kind": "Fighter", "team_id": 1, "cell": Vector2i(7, 0), "hp": 3}]:
		map_data.starting_units.append(unit)
	for team_id in range(2):
		teams.append(TeamDataResource.new(team_id, "Team %d" % (team_id + 1), TeamDataResource.TEAM_COLORS[team_id], "human" if team_id == 0 else "cpu", map_data.starting_money))
	for unit in map_data.starting_units:
		add_unit(unit["kind"], unit["team_id"], unit["cell"], unit["hp"])

func current_team():
	return teams[current_team_index]

func advance_turn() -> void:
	current_team_index = (current_team_index + 1) % teams.size()

func team_by_id(team_id: int):
	for team in teams:
		if team.id == team_id: return team
	return teams[0]

func add_unit(kind: String, team_id: int, cell: Vector2i, hp: int) -> void:
	units.append({"id": next_unit_id, "kind": kind, "team_id": team_id, "grid": cell, "hp": hp, "moved": false, "attacked": false})
	next_unit_id += 1

func unit_by_id(unit_id: int) -> Dictionary:
	for unit in units:
		if unit["id"] == unit_id: return unit
	return {}

func unit_id_at(cell: Vector2i) -> int:
	for unit in units:
		if unit["grid"] == cell: return unit["id"]
	return -1

func set_unit_grid(unit_id: int, cell: Vector2i) -> void:
	for unit in units:
		if unit["id"] == unit_id: unit["grid"] = cell; return

func set_unit_flag(unit_id: int, flag: String, value: bool) -> void:
	for unit in units:
		if unit["id"] == unit_id: unit[flag] = value; return

func damage_unit(unit_id: int, damage: int, defense: int) -> int:
	for index in units.size():
		if units[index]["id"] == unit_id:
			var result := maxi(0, damage - defense)
			units[index]["hp"] -= result
			if units[index]["hp"] <= 0: units.remove_at(index)
			return result
	return 0

func count_units_for_team(team_id: int) -> int:
	var count := 0
	for unit in units:
		if unit["team_id"] == team_id: count += 1
	return count

func reset_actions(team_id: int) -> void:
	for unit in units:
		if unit["team_id"] == team_id: unit["moved"] = false; unit["attacked"] = false

func port_for_team(team_id: int) -> Vector2i:
	for port in map_data.ports:
		if port.get("team_id", -1) == team_id: return port["cell"]
	return Vector2i(-1, -1)

func is_enemy_port(cell: Vector2i, team_id: int) -> bool:
	for port in map_data.ports:
		if port["cell"] == cell and port.get("team_id", team_id) != team_id: return true
	return false
