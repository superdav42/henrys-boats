class_name CpuController
extends RefCounted

static func next_command(state, unit_stats: Dictionary) -> Dictionary:
	var team = state.current_team()
	var port: Vector2i = state.port_for_team(team.id)
	if port != Vector2i(-1, -1) and state.unit_id_at(port) == -1 and team.money >= unit_stats["Patrol"]["cost"]:
		return {"type": "build", "team_id": team.id, "kind": "Patrol"}
	for unit in state.units:
		if unit["team_id"] != team.id or unit["attacked"]:
			continue
		var target_id := _nearest_attackable_target(unit, state, unit_stats)
		if target_id != -1:
			return {"type": "attack", "team_id": team.id, "unit_id": unit["id"], "target_id": target_id}
	for unit in state.units:
		if unit["team_id"] != team.id or unit["moved"]:
			continue
		var destination := _legal_step_towards_target(unit, state, unit_stats)
		if destination != Vector2i(-1, -1):
			return {"type": "move", "team_id": team.id, "unit_id": unit["id"], "cell": destination}
	return {}

static func _nearest_attackable_target(unit: Dictionary, state, unit_stats: Dictionary) -> int:
	var stats: Dictionary = unit_stats[unit["kind"]]
	var closest_id := -1
	var closest_distance := 9999
	for candidate in state.units:
		if candidate["team_id"] == unit["team_id"]:
			continue
		var target_stats: Dictionary = unit_stats[candidate["kind"]]
		var distance := _distance(unit["grid"], candidate["grid"])
		if _can_attack(stats, target_stats) and distance <= stats["range"] and distance < closest_distance:
			closest_id = candidate["id"]
			closest_distance = distance
	return closest_id

static func _legal_step_towards_target(unit: Dictionary, state, unit_stats: Dictionary) -> Vector2i:
	var target := _nearest_enemy_or_port(unit, state)
	if target == Vector2i(-1, -1):
		return Vector2i(-1, -1)
	var stats: Dictionary = unit_stats[unit["kind"]]
	var best := Vector2i(-1, -1)
	var best_distance := _distance(unit["grid"], target)
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate: Vector2i = unit["grid"] + direction
		if not state.map_data.is_inside(candidate) or state.unit_id_at(candidate) != -1 or state.map_data.terrain_at(candidate) == "Mountain" and not stats["air"]:
			continue
		var distance := _distance(candidate, target)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best

static func _nearest_enemy_or_port(unit: Dictionary, state) -> Vector2i:
	var target := Vector2i(-1, -1)
	var closest_distance := 9999
	for candidate in state.units:
		if candidate["team_id"] == unit["team_id"]:
			continue
		var distance := _distance(unit["grid"], candidate["grid"])
		if distance < closest_distance:
			target = candidate["grid"]
			closest_distance = distance
	for port in state.map_data.ports:
		if port.get("team_id", unit["team_id"]) == unit["team_id"]:
			continue
		var distance := _distance(unit["grid"], port["cell"])
		if distance < closest_distance:
			target = port["cell"]
			closest_distance = distance
	return target

static func _can_attack(attacker: Dictionary, defender: Dictionary) -> bool:
	return attacker["target"] == "any" or (attacker["target"] == "air" and defender["air"]) or (attacker["target"] == "surface" and not defender["air"])

static func _distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
