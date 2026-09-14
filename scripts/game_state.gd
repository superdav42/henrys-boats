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

func execute_command(command: Dictionary, unit_stats: Dictionary) -> Dictionary:
	var team_id: int = int(command.get("team_id", -1))
	if team_id != current_team().id:
		return {"ok": false, "message": "That team is not active."}
	match command.get("type", ""):
		"build":
			return _execute_build(command, unit_stats)
		"launch":
			return _execute_launch(command, unit_stats)
		"move":
			return _execute_move(command, unit_stats)
		"attack":
			return _execute_attack(command, unit_stats)
	return {"ok": false, "message": "Unknown action command."}

func _execute_build(command: Dictionary, unit_stats: Dictionary) -> Dictionary:
	var kind: String = command.get("kind", "")
	if not unit_stats.has(kind):
		return {"ok": false, "message": "Unknown unit type."}
	var port := port_for_team(current_team().id)
	var stats: Dictionary = unit_stats[kind]
	if port == Vector2i(-1, -1) or unit_id_at(port) != -1 or current_team().money < stats["cost"]:
		return {"ok": false, "message": "Build requires an open port and enough money."}
	current_team().money -= stats["cost"]
	add_unit(kind, current_team().id, port, stats["hp"])
	return {"ok": true, "message": "%s built a %s." % [current_team().name, kind], "unit_id": next_unit_id - 1}

func _execute_launch(command: Dictionary, unit_stats: Dictionary) -> Dictionary:
	var unit_id: int = int(command.get("unit_id", -1))
	var kind: String = command.get("kind", "")
	var carrier := unit_by_id(unit_id)
	if carrier.is_empty() or carrier["team_id"] != current_team().id or carrier["kind"] != "Aircraft Carrier" or not unit_stats.has(kind):
		return {"ok": false, "message": "A selected Aircraft Carrier is required."}
	var stats: Dictionary = unit_stats[kind]
	var spawn := _first_open_neighbor(carrier["grid"], stats)
	if spawn == Vector2i(-1, -1) or current_team().money < stats["cost"]:
		return {"ok": false, "message": "Launch requires an open space and enough money."}
	current_team().money -= stats["cost"]
	add_unit(kind, current_team().id, spawn, stats["hp"])
	return {"ok": true, "message": "%s launched a %s." % [current_team().name, kind], "unit_id": next_unit_id - 1}

func _execute_move(command: Dictionary, unit_stats: Dictionary) -> Dictionary:
	var unit_id: int = int(command.get("unit_id", -1))
	var destination: Vector2i = command.get("cell", Vector2i(-1, -1))
	var unit := unit_by_id(unit_id)
	if unit.is_empty() or unit["team_id"] != current_team().id or unit["moved"]:
		return {"ok": false, "message": "Unit cannot move."}
	var stats: Dictionary = unit_stats[unit["kind"]]
	if not map_data.is_inside(destination) or unit_id_at(destination) != -1:
		return {"ok": false, "message": "Move is not legal."}
	if not map_data.can_unit_occupy(unit["kind"], stats["air"], destination):
		return {"ok": false, "message": "%s cannot stop on %s." % [unit["kind"], map_data.terrain_at(destination)]}
	if _shortest_movement_cost(unit, destination, stats) > int(stats["move"]):
		return {"ok": false, "message": "Move is not legal."}
	set_unit_grid(unit_id, destination)
	set_unit_flag(unit_id, "moved", true)
	if is_enemy_port(destination, current_team().id):
		return {"ok": true, "message": "%s captured an enemy port!" % current_team().name, "winner": current_team().id}
	return {"ok": true, "message": "%s moved %s." % [current_team().name, unit["kind"]], "unit_id": unit_id}

func _execute_attack(command: Dictionary, unit_stats: Dictionary) -> Dictionary:
	var attacker_id: int = int(command.get("unit_id", -1))
	var defender_id: int = int(command.get("target_id", -1))
	var attacker := unit_by_id(attacker_id)
	var defender := unit_by_id(defender_id)
	if attacker.is_empty() or defender.is_empty() or attacker["team_id"] != current_team().id or attacker["team_id"] == defender["team_id"] or attacker["attacked"]:
		return {"ok": false, "message": "Attack is not legal."}
	var attack_stats: Dictionary = unit_stats[attacker["kind"]]
	var defense_stats: Dictionary = unit_stats[defender["kind"]]
	if not _can_attack(attack_stats, defense_stats) or _grid_distance(attacker["grid"], defender["grid"]) > attack_stats["range"]:
		return {"ok": false, "message": "Target is out of range."}
	set_unit_flag(attacker_id, "attacked", true)
	var damage := damage_unit(defender_id, attack_stats["damage"], _defense_for(defender, defense_stats))
	if unit_by_id(defender_id).is_empty():
		current_team().money += 50
		if count_units_for_team(defender["team_id"]) == 0:
			return {"ok": true, "message": "%s destroyed the final enemy unit!" % current_team().name, "damage": damage, "destroyed": true, "winner": current_team().id}
		return {"ok": true, "message": "%s destroyed an enemy unit." % current_team().name, "damage": damage, "destroyed": true}
	return {"ok": true, "message": "%s hit %s for %d damage." % [current_team().name, defender["kind"], damage], "damage": damage}

func _shortest_movement_cost(unit: Dictionary, destination: Vector2i, stats: Dictionary) -> int:
	var origin: Vector2i = unit["grid"]
	var costs := {origin: 0}
	var frontier: Array[Vector2i] = [origin]
	while not frontier.is_empty():
		var best_index := 0
		for index in range(1, frontier.size()):
			if int(costs[frontier[index]]) < int(costs[frontier[best_index]]):
				best_index = index
		var current: Vector2i = frontier.pop_at(best_index)
		if current == destination:
			return int(costs[current])
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next: Vector2i = current + direction
			if not map_data.is_inside(next) or map_data.movement_cost(unit["kind"], stats["air"], next) < 0:
				continue
			if next != destination and unit_id_at(next) != -1:
				continue
			var next_cost: int = int(costs[current]) + map_data.movement_cost(unit["kind"], stats["air"], next)
			if next_cost > int(stats["move"]):
				continue
			if not costs.has(next) or next_cost < int(costs[next]):
				costs[next] = next_cost
				if next not in frontier:
					frontier.append(next)
	return 1000000

func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _first_open_neighbor(cell: Vector2i, stats: Dictionary) -> Vector2i:
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate: Vector2i = cell + direction
		if map_data.is_inside(candidate) and unit_id_at(candidate) == -1 and map_data.can_unit_occupy("Aircraft", stats["air"], candidate):
			return candidate
	return Vector2i(-1, -1)

func _can_attack(attacker: Dictionary, defender: Dictionary) -> bool:
	if defender.get("submarine", false):
		return attacker.get("detector", false)
	return attacker["target"] == "any" or (attacker["target"] == "air" and defender["air"]) or (attacker["target"] == "surface" and not defender["air"])

func _defense_for(unit: Dictionary, stats: Dictionary) -> int:
	var terrain: String = map_data.terrain_at(unit["grid"])
	if stats["air"] and terrain == "Snow Mountain":
		return 3
	if stats["air"] and terrain == "Mountain":
		return 2
	return 1 if not stats["air"] and terrain == "Reef" else 0
