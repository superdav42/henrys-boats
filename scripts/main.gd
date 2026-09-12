extends Node2D

const GameStateResource = preload("res://scripts/game_state.gd")
const TeamDataResource = preload("res://scripts/team_data.gd")
const MapEditorScene = preload("res://scenes/map_editor.tscn")
const SetupMenuScene = preload("res://scenes/setup_menu.tscn")
const UpgradeScreenScene = preload("res://scenes/upgrade_screen.tscn")
const TurnManagerResource = preload("res://scripts/turn_manager.gd")
const CpuControllerResource = preload("res://scripts/cpu_controller.gd")
const SaveStoreResource = preload("res://scripts/save_store.gd")
const UpgradeCatalogResource = preload("res://scripts/upgrade_catalog.gd")

const UNIT_STATS := {
	"Patrol": {"cost": 100, "hp": 3, "move": 3, "range": 1, "damage": 1, "short": "PT", "air": false, "target": "any"},
	"Destroyer": {"cost": 180, "hp": 4, "move": 2, "range": 2, "damage": 2, "short": "DD", "air": false, "target": "any"},
	"Aircraft Carrier": {"cost": 300, "hp": 6, "move": 1, "range": 2, "damage": 1, "short": "AC", "air": false, "target": "any"},
	"Anti-Air Boat": {"cost": 220, "hp": 4, "move": 2, "range": 3, "damage": 4, "short": "AAB", "air": false, "target": "air"},
	"Jet": {"cost": 120, "hp": 2, "move": 4, "range": 2, "damage": 2, "short": "JET", "air": true, "target": "any"},
	"Fighter": {"cost": 150, "hp": 3, "move": 5, "range": 2, "damage": 3, "short": "FIG", "air": true, "target": "air"},
	"Bomber": {"cost": 180, "hp": 2, "move": 4, "range": 2, "damage": 4, "short": "BMB", "air": true, "target": "surface"},
}

var state = GameStateResource.new()
var selected_unit_id := -1
var kills := 0
var turn := 1
var game_over := false
var map_editor
var setup_menu
var upgrade_screen
var turn_manager
var unit_stats: Dictionary = UNIT_STATS.duplicate(true)

@onready var board = $MapBoard
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
@onready var map_editor_button: Button = $Hud/MapEditorButton
@onready var turn_overlay: Control = $TurnOverlay
@onready var turn_overlay_label: Label = $TurnOverlay/Message
@onready var home = $Home
@onready var inspector = $InspectorPanel

func _ready() -> void:
	board.cell_pressed.connect(_on_cell_pressed)
	board.unit_pressed.connect(_on_unit_pressed)
	_connect_buttons()
	turn_manager = TurnManagerResource.new()
	_show_home()

func _connect_buttons() -> void:
	end_turn_button.pressed.connect(_end_player_turn)
	patrol_button.pressed.connect(_build_boat.bind("Patrol"))
	destroyer_button.pressed.connect(_build_boat.bind("Destroyer"))
	carrier_button.pressed.connect(_build_boat.bind("Aircraft Carrier"))
	anti_air_button.pressed.connect(_build_boat.bind("Anti-Air Boat"))
	jet_button.pressed.connect(_build_air_from_selected_ac.bind("Jet"))
	fighter_button.pressed.connect(_build_air_from_selected_ac.bind("Fighter"))
	bomber_button.pressed.connect(_build_air_from_selected_ac.bind("Bomber"))
	map_editor_button.pressed.connect(_open_map_editor)
	$Home/PlayButton.pressed.connect(_open_setup)
	$Home/UpgradesButton.pressed.connect(_open_upgrades)
	$Home/MapEditorButton.pressed.connect(_open_map_editor)

func _show_home() -> void:
	home.visible = true
	$Hud.visible = false
	board.visible = false
	turn_overlay.visible = false
	inspector.clear()

func _open_setup() -> void:
	if setup_menu != null:
		return
	setup_menu = SetupMenuScene.instantiate()
	add_child(setup_menu)
	setup_menu.cancelled.connect(_close_setup)
	setup_menu.match_configured.connect(_start_configured_match)
	setup_menu.map_editor_requested.connect(_open_map_editor_from_setup)
	home.visible = false

func _close_setup() -> void:
	if setup_menu != null:
		setup_menu.queue_free()
		setup_menu = null
	_show_home()

func _open_upgrades() -> void:
	if upgrade_screen != null:
		return
	upgrade_screen = UpgradeScreenScene.instantiate()
	add_child(upgrade_screen)
	upgrade_screen.cancelled.connect(_close_upgrades)
	home.visible = false

func _close_upgrades() -> void:
	if upgrade_screen != null:
		upgrade_screen.queue_free()
		upgrade_screen = null
	_show_home()

func _open_map_editor_from_setup() -> void:
	_close_setup()
	_open_map_editor()

func _open_map_editor() -> void:
	if map_editor != null or (board.visible and _player_input_locked()):
		return
	map_editor = MapEditorScene.instantiate()
	add_child(map_editor)
	map_editor.cancelled.connect(_close_map_editor)
	map_editor.map_selected.connect(_start_custom_match)
	$Hud.visible = false
	home.visible = false

func _close_map_editor() -> void:
	if map_editor == null:
		return
	map_editor.queue_free()
	map_editor = null
	_show_home()

func _start_custom_match(map_data) -> void:
	if map_data == null:
		return
	var controllers: Array[String] = []
	for team_id in map_data.ports.size():
		controllers.append("human" if team_id == 0 else "cpu")
	_start_configured_match({"map": map_data, "controllers": controllers})

func _start_configured_match(configuration: Dictionary) -> void:
	var map_data = configuration.get("map")
	var controllers: Variant = configuration.get("controllers", [])
	if map_data == null or not map_data.is_valid() or not controllers is Array or controllers.size() != map_data.ports.size() or controllers.size() < 2 or controllers.size() > 8:
		return
	var profile := SaveStoreResource.load_profile()
	unit_stats = _unit_stats_for_profile(profile)
	var effects := UpgradeCatalogResource.effects(profile)
	state = GameStateResource.new()
	state.map_data = map_data
	state.teams = TeamDataResource.create_teams(map_data.ports.size(), map_data.starting_money + effects["starting_money_bonus"])
	for team_id in state.teams.size():
		state.teams[team_id].controller_type = controllers[team_id]
	for unit in map_data.starting_units:
		var stats: Dictionary = unit_stats[unit["kind"]]
		state.add_unit(unit["kind"], unit["team_id"], unit["cell"], stats["hp"])
	selected_unit_id = -1
	kills = 0
	turn = 1
	game_over = false
	inspector.clear()
	turn_manager.begin_match(state)
	if map_editor != null:
		map_editor.queue_free()
		map_editor = null
	if setup_menu != null:
		setup_menu.queue_free()
		setup_menu = null
	home.visible = false
	board.visible = true
	$Hud.visible = true
	_redraw_board()
	_update_hud("Match started. Prepare to hand off the device.")
	_begin_current_turn()

func _unit_stats_for_profile(profile: Dictionary) -> Dictionary:
	var adjusted: Dictionary = UNIT_STATS.duplicate(true)
	var effects := UpgradeCatalogResource.effects(profile)
	for kind in adjusted:
		if adjusted[kind]["air"]:
			adjusted[kind]["move"] += effects["air_move_bonus"]
		else:
			adjusted[kind]["hp"] += effects["water_hp_bonus"]
	return adjusted

func _redraw_board() -> void:
	board.set_match(state.map_data, state.units, selected_unit_id, state.current_team().id, unit_stats)

func _on_cell_pressed(cell: Vector2i) -> void:
	if _player_input_locked() or not state.map_data.is_inside(cell):
		return
	_show_cell_inspector(cell)
	if selected_unit_id == -1:
		_update_hud("Select one of your boats first.")
		return
	var selected: Dictionary = state.unit_by_id(selected_unit_id)
	if selected.is_empty():
		selected_unit_id = -1
		return
	if selected["team_id"] != state.current_team().id:
		return
	if state.unit_id_at(cell) != -1:
		_update_hud("That space is occupied. Tap an enemy unit to attack it.")
		return
	_execute_human_command({"type": "move", "team_id": state.current_team().id, "unit_id": selected_unit_id, "cell": cell})

func _on_unit_pressed(unit_id: int) -> void:
	if _player_input_locked():
		return
	var unit: Dictionary = state.unit_by_id(unit_id)
	if unit.is_empty():
		return
	if unit["team_id"] == state.current_team().id:
		selected_unit_id = unit_id
		_update_hud("Selected %s. Move, attack, or build from the port/AC." % unit["kind"])
		_redraw_board()
		_show_unit_inspector(unit)
		return
	_show_unit_inspector(unit)
	if selected_unit_id == -1:
		_update_hud("Select one of your units before attacking.")
		return
	_attack(selected_unit_id, unit_id)

func _attack(attacker_id: int, defender_id: int) -> void:
	_execute_human_command({"type": "attack", "team_id": state.current_team().id, "unit_id": attacker_id, "target_id": defender_id})

func _build_boat(kind: String) -> void:
	if _player_input_locked():
		return
	_execute_human_command({"type": "build", "team_id": state.current_team().id, "kind": kind})

func _build_air_from_selected_ac(kind: String) -> void:
	if _player_input_locked():
		return
	_execute_human_command({"type": "launch", "team_id": state.current_team().id, "unit_id": selected_unit_id, "kind": kind})

func _end_player_turn() -> void:
	if _player_input_locked():
		return
	_advance_turn()

func _execute_human_command(command: Dictionary) -> void:
	var result := state.execute_command(command, unit_stats)
	_apply_command_result(result)

func _apply_command_result(result: Dictionary) -> bool:
	if not result.get("ok", false):
		_update_hud(result.get("message", "That action is not legal."))
		return false
	if result.get("destroyed", false):
		kills += 1
	if result.has("winner"):
		_finish_game(int(result["winner"]), result["message"])
		return true
	_update_hud(result["message"])
	_redraw_board()
	_show_selected_inspector()
	return true

func _begin_current_turn() -> void:
	if game_over:
		return
	selected_unit_id = -1
	inspector.clear()
	turn_manager.lock_input()
	_refresh_controls()
	_redraw_board()
	var team = turn_manager.current_team()
	if team.is_cpu():
		turn_overlay.visible = false
		_update_hud("%s is planning a move. Player controls are locked." % team.name)
		_run_cpu_turn()
		return
	turn_overlay_label.text = "Pass the device to\n%s" % team.name
	turn_overlay_label.modulate = team.color
	turn_overlay.visible = true
	_update_hud("Prepare the hand-off to %s." % team.name)
	await get_tree().create_timer(5.0).timeout
	if game_over or not is_instance_valid(self):
		return
	turn_overlay.visible = false
	turn_manager.unlock_human_input()
	_refresh_controls()
	_update_hud("Turn %d. %s is ready." % [turn, team.name])

func _run_cpu_turn() -> void:
	while not game_over:
		var command := CpuControllerResource.next_command(state, unit_stats)
		if command.is_empty():
			break
		selected_unit_id = int(command.get("unit_id", -1))
		_redraw_board()
		_update_hud("%s is choosing an action." % state.current_team().name)
		await get_tree().create_timer(0.35).timeout
		if game_over:
			return
		var result := state.execute_command(command, unit_stats)
		if not _apply_command_result(result):
			break
		if game_over:
			return
		await get_tree().create_timer(1.5).timeout
	selected_unit_id = -1
	inspector.clear()
	_advance_turn()

func _advance_turn() -> void:
	if game_over:
		return
	turn += 1
	turn_manager.advance_turn()
	_begin_current_turn()

func _player_input_locked() -> bool:
	return game_over or turn_manager == null or turn_manager.input_locked or state.current_team().is_cpu()

func _refresh_controls() -> void:
	var locked := _player_input_locked()
	for button in [end_turn_button, patrol_button, destroyer_button, carrier_button, anti_air_button, jet_button, fighter_button, bomber_button, map_editor_button]:
		button.disabled = locked

func _first_open_neighbor(cell: Vector2i, stats: Dictionary) -> Vector2i:
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate: Vector2i = cell + direction
		if state.map_data.is_inside(candidate) and state.unit_id_at(candidate) == -1 and _can_occupy_terrain(stats, candidate):
			return candidate
	return Vector2i(-1, -1)

func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _can_occupy_terrain(stats: Dictionary, cell: Vector2i) -> bool:
	return state.map_data.terrain_at(cell) != "Mountain" or stats["air"]

func _can_attack(attacker: Dictionary, defender: Dictionary) -> bool:
	return attacker["target"] == "any" or (attacker["target"] == "air" and defender["air"]) or (attacker["target"] == "surface" and not defender["air"])

func _defense_for(unit: Dictionary) -> int:
	var stats: Dictionary = unit_stats[unit["kind"]]
	var terrain: String = state.map_data.terrain_at(unit["grid"])
	return 2 if stats["air"] and terrain == "Mountain" else (1 if not stats["air"] and terrain == "Reef" else 0)

func _finish_game(winner: int, message: String) -> void:
	game_over = true
	selected_unit_id = -1
	inspector.clear()
	turn_manager.lock_input()
	turn_overlay.visible = false
	_refresh_controls()
	_update_hud("%s %s" % [state.team_by_id(winner).name + " wins!", message])
	_redraw_board()

func _update_hud(message: String) -> void:
	var team: Variant = state.current_team()
	status_label.text = "Turn %d  %s  Money $%d  Fleet %d  Kills %d" % [turn, team.name, team.money, state.count_units_for_team(team.id), kills]
	help_label.text = message
	var selected: Dictionary = state.unit_by_id(selected_unit_id)
	var disable_air: bool = selected.is_empty() or selected["kind"] != "Aircraft Carrier" or selected["team_id"] != team.id or _player_input_locked()
	jet_button.disabled = disable_air
	fighter_button.disabled = disable_air
	bomber_button.disabled = disable_air

func _show_selected_inspector() -> void:
	var selected: Dictionary = state.unit_by_id(selected_unit_id)
	if selected.is_empty():
		inspector.clear()
		return
	_show_unit_inspector(selected)

func _show_cell_inspector(cell: Vector2i) -> void:
	var terrain: String = state.map_data.terrain_at(cell)
	var details := PackedStringArray(["Terrain: %s" % _terrain_description(terrain), "Terrain defence: %s" % _terrain_defense_description(terrain)])
	var selected: Dictionary = state.unit_by_id(selected_unit_id)
	if selected.is_empty():
		details.append("No unit selected. Tap a friendly silhouette to reveal legal move and attack cells.")
	else:
		details.append("Selected %s: %d legal moves • %d legal attacks." % [selected["kind"], board.move_overlay.size(), board.attack_overlay.size()])
	inspector.show_snapshot({"title": "%s at %d, %d" % [terrain, cell.x + 1, cell.y + 1], "context": "Tile inspection • Read-only", "details": details})

func _show_unit_inspector(unit: Dictionary) -> void:
	var stats: Dictionary = unit_stats.get(unit.get("kind", ""), {})
	if stats.is_empty():
		inspector.clear()
		return
	var cell: Vector2i = unit.get("grid", Vector2i(-1, -1))
	var terrain: String = state.map_data.terrain_at(cell)
	var team = state.team_by_id(int(unit.get("team_id", 0)))
	var target_label := "any unit" if stats.get("target", "any") == "any" else ("air units only" if stats.get("target") == "air" else "surface units only")
	var unit_type := "Air unit" if stats.get("air", false) else "Surface unit"
	var legal_actions := "Legal actions: inspect this unit; select a friendly unit to reveal its overlays."
	if unit.get("id", -1) == selected_unit_id and unit.get("team_id", -1) == state.current_team().id:
		legal_actions = "Legal now: %d move cells • %d attack targets." % [board.move_overlay.size(), board.attack_overlay.size()]
	var details := PackedStringArray([
		"Team: %s  •  Unit type: %s  •  HP: %d" % [team.name, unit_type, int(unit.get("hp", 0))],
		"Move %d  •  Range %d  •  Attack %d" % [int(stats.get("move", 0)), int(stats.get("range", 0)), int(stats.get("damage", 0))],
		"Targets: %s  •  Active defence: %d (%s)" % [target_label, _defense_for(unit), terrain],
		legal_actions,
	])
	inspector.show_snapshot({"title": "%s at %d, %d" % [unit.get("kind", "Unit"), cell.x + 1, cell.y + 1], "context": "%s • %s terrain • Read-only" % [unit_type, terrain], "details": details})

func _terrain_description(terrain: String) -> String:
	match terrain:
		"Shore": return "sandy coastal shallows"
		"Land": return "green land"
		"Mountain": return "mountain terrain"
		"Reef": return "shallow coral reef"
		"River": return "river channel"
		_: return "open water"

func _terrain_defense_description(terrain: String) -> String:
	if terrain == "Reef": return "Reef gives surface units +1 defence."
	if terrain == "Mountain": return "Mountain gives air units +2 defence."
	return "%s gives no terrain defence." % terrain
