extends Node2D

const GRID_COLUMNS := 8
const GRID_ROWS := 8
const CELL_SIZE := 78
const GRID_ORIGIN := Vector2(48, 220)
const PLAYER := 0
const ENEMY := 1
const PLAYER_PORT := Vector2i(0, GRID_ROWS - 1)
const ENEMY_PORT := Vector2i(GRID_COLUMNS - 1, 0)

const TERRAIN := {
	Vector2i(2, 2): "Mountain",
	Vector2i(5, 1): "Mountain",
	Vector2i(1, 4): "Mountain",
	Vector2i(4, 5): "Mountain",
	Vector2i(3, 3): "Reef",
	Vector2i(5, 4): "Reef",
	Vector2i(2, 6): "Reef",
}

const UNIT_STATS := {
	"Patrol": {"cost": 100, "hp": 3, "move": 3, "range": 1, "damage": 1, "short": "PT", "air": false, "target": "any"},
	"Destroyer": {"cost": 180, "hp": 4, "move": 2, "range": 2, "damage": 2, "short": "DD", "air": false, "target": "any"},
	"Aircraft Carrier": {"cost": 300, "hp": 6, "move": 1, "range": 2, "damage": 1, "short": "AC", "air": false, "target": "any"},
	"Anti-Air Boat": {"cost": 220, "hp": 4, "move": 2, "range": 3, "damage": 4, "short": "AAB", "air": false, "target": "air"},
	"Jet": {"cost": 120, "hp": 2, "move": 4, "range": 2, "damage": 2, "short": "JET", "air": true, "target": "any"},
	"Fighter": {"cost": 150, "hp": 3, "move": 5, "range": 2, "damage": 3, "short": "FIG", "air": true, "target": "air"},
	"Bomber": {"cost": 180, "hp": 2, "move": 4, "range": 2, "damage": 4, "short": "BMB", "air": true, "target": "surface"},
}

var money := 260
var kills := 0
var turn := 1
var selected_unit_id := -1
var next_unit_id := 1
var units: Array[Dictionary] = []
var game_over := false

@onready var board_layer: Node2D = $BoardLayer
@onready var unit_layer: Node2D = $UnitLayer
@onready var hud: CanvasLayer = $Hud
@onready var status_label: Label = $Hud/StatusLabel
@onready var help_label: Label = $Hud/HelpLabel
@onready var end_turn_button: Button = $Hud/EndTurnButton
@onready var patrol_button: Button = $Hud/BuildPanel/PatrolButton
@onready var destroyer_button: Button = $Hud/BuildPanel/DestroyerButton
@onready var carrier_button: Button = $Hud/BuildPanel/CarrierButton
@onready var anti_air_button: Button = $Hud/BuildPanel/AntiAirButton
@onready var jet_button: Button = $Hud/AirPanel/JetButton
@onready var fighter_button: Button = $Hud/AirPanel/FighterButton
@onready var bomber_button: Button = $Hud/AirPanel/BomberButton

func _ready() -> void:
	_draw_board()
	_seed_units()
	_connect_buttons()
	_redraw_units()
	_update_hud("Capture the enemy port or destroy every enemy unit to win.")

func _connect_buttons() -> void:
	end_turn_button.pressed.connect(_end_player_turn)
	patrol_button.pressed.connect(_build_boat.bind("Patrol"))
	destroyer_button.pressed.connect(_build_boat.bind("Destroyer"))
	carrier_button.pressed.connect(_build_boat.bind("Aircraft Carrier"))
	anti_air_button.pressed.connect(_build_boat.bind("Anti-Air Boat"))
	jet_button.pressed.connect(_build_air_from_selected_ac.bind("Jet"))
	fighter_button.pressed.connect(_build_air_from_selected_ac.bind("Fighter"))
	bomber_button.pressed.connect(_build_air_from_selected_ac.bind("Bomber"))

func _draw_board() -> void:
	for y in range(GRID_ROWS):
		for x in range(GRID_COLUMNS):
			var cell := Button.new()
			cell.name = "Cell_%d_%d" % [x, y]
			cell.position = _grid_to_world(Vector2i(x, y))
			cell.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
			var grid_position := Vector2i(x, y)
			var terrain := _terrain_at(grid_position)
			cell.text = _terrain_label(terrain)
			cell.tooltip_text = _terrain_tooltip(terrain, grid_position)
			cell.add_theme_stylebox_override("normal", _tile_style(terrain))
			cell.pressed.connect(_on_cell_pressed.bind(Vector2i(x, y)))
			board_layer.add_child(cell)

	_add_port_marker(PLAYER_PORT, "PORT", Color(0.14, 0.48, 0.24))
	_add_port_marker(ENEMY_PORT, "ENEMY\nPORT", Color(0.45, 0.16, 0.16))

func _add_port_marker(grid_position: Vector2i, text: String, color: Color) -> void:
	var marker := Label.new()
	marker.position = _grid_to_world(grid_position) + Vector2(5, 7)
	marker.size = Vector2(CELL_SIZE - 10, CELL_SIZE - 10)
	marker.text = text
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_theme_color_override("font_color", color)
	marker.add_theme_font_size_override("font_size", 18)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_layer.add_child(marker)

func _seed_units() -> void:
	_add_unit("Patrol", PLAYER, PLAYER_PORT)
	_add_unit("Destroyer", PLAYER, Vector2i(1, 7))
	_add_unit("Patrol", ENEMY, ENEMY_PORT)
	_add_unit("Destroyer", ENEMY, Vector2i(6, 0))
	_add_unit("Aircraft Carrier", ENEMY, Vector2i(7, 1))
	_add_unit("Fighter", ENEMY, Vector2i(5, 0))

func _add_unit(kind: String, side: int, grid_position: Vector2i) -> void:
	var stats: Dictionary = UNIT_STATS[kind]
	units.append({
		"id": next_unit_id,
		"kind": kind,
		"side": side,
		"grid": grid_position,
		"hp": stats["hp"],
		"moved": false,
		"attacked": false,
	})
	next_unit_id += 1

func _redraw_units() -> void:
	for child in unit_layer.get_children():
		child.queue_free()

	for unit in units:
		var button := Button.new()
		button.name = "Unit_%d" % unit["id"]
		button.position = _grid_to_world(unit["grid"]) + Vector2(8, 8)
		button.size = Vector2(CELL_SIZE - 16, CELL_SIZE - 16)
		button.text = _unit_label(unit)
		button.add_theme_font_size_override("font_size", 16)
		button.modulate = _unit_color(unit)
		button.pressed.connect(_on_unit_pressed.bind(unit["id"]))
		unit_layer.add_child(button)

func _unit_label(unit: Dictionary) -> String:
	var stats: Dictionary = UNIT_STATS[unit["kind"]]
	var prefix: String = stats["short"]
	if unit["id"] == selected_unit_id:
		prefix = ">" + prefix
	return "%s\nHP %d" % [prefix, unit["hp"]]

func _unit_color(unit: Dictionary) -> Color:
	if unit["side"] == PLAYER:
		if unit["id"] == selected_unit_id:
			return Color(0.65, 1.0, 0.82)
		return Color(0.28, 0.75, 1.0)
	return Color(1.0, 0.42, 0.35)

func _on_cell_pressed(grid_position: Vector2i) -> void:
	if game_over:
		return
	if selected_unit_id == -1:
		_update_hud("Select one of your boats first.")
		return

	var selected := _get_unit(selected_unit_id)
	if selected.is_empty():
		selected_unit_id = -1
		return

	if selected["side"] != PLAYER:
		return
	if _unit_at(grid_position) != -1:
		_update_hud("That space is occupied. Tap an enemy unit to attack it.")
		return
	if selected["moved"]:
		_update_hud("That unit already moved this turn.")
		return

	var stats: Dictionary = UNIT_STATS[selected["kind"]]
	if not _can_occupy_terrain(stats, grid_position):
		_update_hud("Only air units can land on mountain terrain.")
		return
	var distance := _grid_distance(selected["grid"], grid_position)
	if distance > stats["move"]:
		_update_hud("Too far. %s can move %d spaces." % [selected["kind"], stats["move"]])
		return

	_set_unit_grid(selected_unit_id, grid_position)
	_set_unit_flag(selected_unit_id, "moved", true)
	if grid_position == ENEMY_PORT:
		_finish_game(PLAYER, "Your fleet captured the enemy port!")
		return
	_update_hud("Moved %s. You can still attack if an enemy is in range." % selected["kind"])
	_redraw_units()

func _on_unit_pressed(unit_id: int) -> void:
	if game_over:
		return
	var unit := _get_unit(unit_id)
	if unit.is_empty():
		return

	if unit["side"] == PLAYER:
		selected_unit_id = unit_id
		_update_hud("Selected %s. Move, attack, or build from the port/AC." % unit["kind"])
		_redraw_units()
		return

	if selected_unit_id == -1:
		_update_hud("Select one of your units before attacking.")
		return
	_attack(selected_unit_id, unit_id)

func _attack(attacker_id: int, defender_id: int) -> void:
	var attacker := _get_unit(attacker_id)
	var defender := _get_unit(defender_id)
	if attacker.is_empty() or defender.is_empty():
		return
	if attacker["attacked"]:
		_update_hud("That unit already attacked this turn.")
		return

	var stats: Dictionary = UNIT_STATS[attacker["kind"]]
	var defender_stats: Dictionary = UNIT_STATS[defender["kind"]]
	if not _can_attack(stats, defender_stats):
		_update_hud("%s cannot attack %s." % [attacker["kind"], defender["kind"]])
		return
	var distance := _grid_distance(attacker["grid"], defender["grid"])
	if distance > stats["range"]:
		_update_hud("Enemy is out of range for %s." % attacker["kind"])
		return

	_set_unit_flag(attacker_id, "attacked", true)
	var damage := _damage_unit(defender_id, stats["damage"])
	var remaining := _get_unit(defender_id)
	if remaining.is_empty():
		kills += 1
		money += 50
		if _count_units(ENEMY) == 0:
			_finish_game(PLAYER, "All enemy units were destroyed!")
			return
		_update_hud("Enemy destroyed! +$50 bounty. End turn or keep commanding.")
	else:
		_update_hud("Hit %s for %d damage." % [defender["kind"], damage])
	_redraw_units()

func _build_boat(kind: String) -> void:
	if game_over:
		return
	var port := PLAYER_PORT
	if _unit_at(port) != -1:
		_update_hud("Your port corner is blocked. Move the boat away to build.")
		return
	var stats: Dictionary = UNIT_STATS[kind]
	if money < stats["cost"]:
		_update_hud("Not enough money for %s. Need $%d." % [kind, stats["cost"]])
		return
	money -= stats["cost"]
	_add_unit(kind, PLAYER, port)
	_update_hud("Built %s at your corner port." % kind)
	_redraw_units()

func _build_air_from_selected_ac(kind: String) -> void:
	if game_over:
		return
	var carrier := _get_unit(selected_unit_id)
	if carrier.is_empty() or carrier["side"] != PLAYER or carrier["kind"] != "Aircraft Carrier":
		_update_hud("Select your Aircraft Carrier (AC) to make air units.")
		return
	var stats: Dictionary = UNIT_STATS[kind]
	if money < stats["cost"]:
		_update_hud("Not enough money for a %s. Need $%d." % [kind, stats["cost"]])
		return
	var spawn := _first_open_neighbor(carrier["grid"], stats)
	if spawn == Vector2i(-1, -1):
		_update_hud("No open launch space beside the AC for a %s." % kind)
		return
	money -= stats["cost"]
	_add_unit(kind, PLAYER, spawn)
	_update_hud("AC launched a %s air unit." % kind)
	_redraw_units()

func _end_player_turn() -> void:
	if game_over:
		return
	selected_unit_id = -1
	_run_enemy_turn()
	if game_over:
		return
	turn += 1
	var income := 60 + _count_units(PLAYER) * 15 + kills * 10
	money += income
	_reset_player_actions()
	_update_hud("Turn %d. Income +$%d from fleet size and kills." % [turn, income])
	_redraw_units()

func _run_enemy_turn() -> void:
	var enemy_ids: Array[int] = []
	for unit in units:
		if unit["side"] == ENEMY:
			enemy_ids.append(unit["id"])

	for enemy_id in enemy_ids:
		var enemy := _get_unit(enemy_id)
		if enemy.is_empty():
			continue
		var stats: Dictionary = UNIT_STATS[enemy["kind"]]
		var target_id := _nearest_valid_target(enemy)
		if target_id != -1 and _grid_distance(enemy["grid"], _get_unit(target_id)["grid"]) <= stats["range"]:
			_damage_unit(target_id, stats["damage"])
			if _count_units(PLAYER) == 0:
				_finish_game(ENEMY, "All of your units were destroyed!")
				return
		else:
			var destination := PLAYER_PORT
			if target_id != -1:
				destination = _get_unit(target_id)["grid"]
			_enemy_step_toward(enemy_id, destination)
			if _get_unit(enemy_id)["grid"] == PLAYER_PORT:
				_finish_game(ENEMY, "The enemy captured your port!")
				return

func _enemy_step_toward(enemy_id: int, target_grid: Vector2i) -> void:
	var enemy := _get_unit(enemy_id)
	if enemy.is_empty():
		return
	var best: Vector2i = enemy["grid"]
	var best_distance := _grid_distance(best, target_grid)
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for direction in directions:
		var candidate: Vector2i = enemy["grid"] + direction
		if not _is_inside_grid(candidate) or _unit_at(candidate) != -1 or not _can_occupy_terrain(UNIT_STATS[enemy["kind"]], candidate):
			continue
		var candidate_distance := _grid_distance(candidate, target_grid)
		if candidate_distance < best_distance:
			best = candidate
			best_distance = candidate_distance
	_set_unit_grid(enemy_id, best)

func _nearest_valid_target(attacker: Dictionary) -> int:
	var best_id := -1
	var best_distance := 999
	var attacker_stats: Dictionary = UNIT_STATS[attacker["kind"]]
	for unit in units:
		if unit["side"] == attacker["side"] or not _can_attack(attacker_stats, UNIT_STATS[unit["kind"]]):
			continue
		var distance := _grid_distance(attacker["grid"], unit["grid"])
		if distance < best_distance:
			best_distance = distance
			best_id = unit["id"]
	return best_id

func _reset_player_actions() -> void:
	for unit in units:
		if unit["side"] == PLAYER:
			unit["moved"] = false
			unit["attacked"] = false

func _damage_unit(unit_id: int, damage: int) -> int:
	for index in range(units.size()):
		if units[index]["id"] == unit_id:
			var defense := _defense_for(units[index])
			var effective_damage: int = maxi(0, damage - defense)
			units[index]["hp"] -= effective_damage
			if units[index]["hp"] <= 0:
				units.remove_at(index)
			return effective_damage
	return 0

func _set_unit_grid(unit_id: int, grid_position: Vector2i) -> void:
	for unit in units:
		if unit["id"] == unit_id:
			unit["grid"] = grid_position
			return

func _set_unit_flag(unit_id: int, flag: String, value: bool) -> void:
	for unit in units:
		if unit["id"] == unit_id:
			unit[flag] = value
			return

func _get_unit(unit_id: int) -> Dictionary:
	for unit in units:
		if unit["id"] == unit_id:
			return unit
	return {}

func _unit_at(grid_position: Vector2i) -> int:
	for unit in units:
		if unit["grid"] == grid_position:
			return unit["id"]
	return -1

func _count_units(side: int) -> int:
	var count := 0
	for unit in units:
		if unit["side"] == side:
			count += 1
	return count

func _first_open_neighbor(grid_position: Vector2i, stats: Dictionary) -> Vector2i:
	var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for direction in directions:
		var candidate: Vector2i = grid_position + direction
		if _is_inside_grid(candidate) and _unit_at(candidate) == -1 and _can_occupy_terrain(stats, candidate):
			return candidate
	return Vector2i(-1, -1)

func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _is_inside_grid(grid_position: Vector2i) -> bool:
	return grid_position.x >= 0 and grid_position.x < GRID_COLUMNS and grid_position.y >= 0 and grid_position.y < GRID_ROWS

func _grid_to_world(grid_position: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(grid_position.x * CELL_SIZE, grid_position.y * CELL_SIZE)

func _terrain_at(grid_position: Vector2i) -> String:
	return TERRAIN.get(grid_position, "Water")

func _terrain_label(terrain: String) -> String:
	match terrain:
		"Mountain":
			return "MTN\nAIR +2"
		"Reef":
			return "REEF\nDEF 1"
	return ""

func _terrain_tooltip(terrain: String, grid_position: Vector2i) -> String:
	match terrain:
		"Mountain":
			return "Mountain %d,%d: only air units can land here; air units gain 2 defense." % [grid_position.x, grid_position.y]
		"Reef":
			return "Coral reef %d,%d: water units gain 1 defense." % [grid_position.x, grid_position.y]
	return "Water %d,%d" % [grid_position.x, grid_position.y]

func _tile_style(terrain: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match terrain:
		"Mountain":
			style.bg_color = Color(0.36, 0.31, 0.22)
		"Reef":
			style.bg_color = Color(0.13, 0.44, 0.43)
		_:
			style.bg_color = Color(0.08, 0.25, 0.44)
	style.border_color = Color(0.62, 0.82, 0.94)
	style.set_border_width_all(1)
	return style

func _can_occupy_terrain(stats: Dictionary, grid_position: Vector2i) -> bool:
	return _terrain_at(grid_position) != "Mountain" or stats["air"]

func _can_attack(attacker_stats: Dictionary, defender_stats: Dictionary) -> bool:
	match attacker_stats["target"]:
		"air":
			return defender_stats["air"]
		"surface":
			return not defender_stats["air"]
	return true

func _defense_for(unit: Dictionary) -> int:
	var stats: Dictionary = UNIT_STATS[unit["kind"]]
	var terrain := _terrain_at(unit["grid"])
	if stats["air"]:
		return 2 if terrain == "Mountain" else 0
	return 1 if terrain == "Reef" else 0

func _finish_game(winner: int, message: String) -> void:
	game_over = true
	selected_unit_id = -1
	end_turn_button.disabled = true
	patrol_button.disabled = true
	destroyer_button.disabled = true
	carrier_button.disabled = true
	anti_air_button.disabled = true
	jet_button.disabled = true
	fighter_button.disabled = true
	bomber_button.disabled = true
	var winner_name := "You win!" if winner == PLAYER else "Enemy wins!"
	_update_hud("%s %s" % [winner_name, message])
	_redraw_units()

func _update_hud(message: String) -> void:
	status_label.text = "Turn %d  Money $%d  Fleet %d  Kills %d" % [turn, money, _count_units(PLAYER), kills]
	help_label.text = message
	if game_over:
		return
	var selected := _get_unit(selected_unit_id)
	var air_buttons_disabled: bool = selected.is_empty() or selected["kind"] != "Aircraft Carrier" or selected["side"] != PLAYER
	jet_button.disabled = air_buttons_disabled
	fighter_button.disabled = air_buttons_disabled
	bomber_button.disabled = air_buttons_disabled
