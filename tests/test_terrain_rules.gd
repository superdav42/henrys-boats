extends SceneTree

const MapDataResource = preload("res://scripts/map_data.gd")
const MapBoardResource = preload("res://scripts/map_board.gd")
const GameStateResource = preload("res://scripts/game_state.gd")
const TeamDataResource = preload("res://scripts/team_data.gd")

var failures := 0

func _initialize() -> void:
	_test_terrain_rules()
	_test_movement_costs()
	_test_submarine_combat()
	_test_board_presentation()
	call_deferred("_finish")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_terrain_rules() -> void:
	var map = MapDataResource.new(10, 10, 260)
	map.set_terrain(Vector2i(1, 0), "Shore")
	map.set_terrain(Vector2i(2, 0), "Land")
	map.set_terrain(Vector2i(3, 0), "Mountain")
	map.set_terrain(Vector2i(4, 0), "Snow Mountain")
	map.set_terrain(Vector2i(5, 0), "River")
	_expect(map.movement_cost("Destroyer", false, Vector2i(1, 0)) == 2, "Shore must cost boats two movement points.")
	_expect(map.movement_cost("Destroyer", false, Vector2i(2, 0)) < 0, "Boats must not enter land.")
	_expect(map.movement_cost("Destroyer", false, Vector2i(3, 0)) < 0, "Boats must not enter mountains.")
	_expect(map.movement_cost("Jet", true, Vector2i(3, 0)) == 2, "Aircraft mountain cost must be two.")
	_expect(map.movement_cost("Jet", true, Vector2i(4, 0)) == 3, "Aircraft snow-mountain cost must be three.")
	_expect(not map.can_unit_occupy("Destroyer", false, Vector2i(5, 0)), "Destroyers must not stop on rivers.")
	_expect(map.can_unit_occupy("Patrol", false, Vector2i(5, 0)), "PT boats must be able to stop on rivers.")

func _test_movement_costs() -> void:
	var state = GameStateResource.new()
	state.map_data = MapDataResource.new(10, 10, 260)
	state.map_data.set_terrain(Vector2i(1, 0), "Shore")
	state.map_data.set_terrain(Vector2i(2, 0), "Land")
	state.teams = [TeamDataResource.new(0, "Blue", Color.BLUE, "human", 260), TeamDataResource.new(1, "Red", Color.RED, "cpu", 260)]
	state.add_unit("Destroyer", 0, Vector2i(0, 0), 4)
	var stats := {"Destroyer": {"move": 2, "air": false}}
	_expect(state.execute_command({"type": "move", "team_id": 0, "unit_id": 1, "cell": Vector2i(1, 0)}, stats).get("ok", false), "A destroyer with move two must enter adjacent shore.")
	state.reset_actions(0)
	_expect(not state.execute_command({"type": "move", "team_id": 0, "unit_id": 1, "cell": Vector2i(2, 0)}, stats).get("ok", false), "A destroyer must not enter land.")

func _test_submarine_combat() -> void:
	var state = GameStateResource.new()
	var destroyer := {"target": "any", "air": false, "detector": true}
	var patrol := {"target": "any", "air": false}
	var submarine := {"target": "any", "air": false, "submarine": true}
	_expect(state._can_attack(destroyer, submarine), "Destroyers must be able to attack submarines.")
	_expect(not state._can_attack(patrol, submarine), "Non-destroyers must not damage submarines.")
	_expect(state._can_attack(submarine, patrol), "Submarines must be able to attack surface units.")

func _test_board_presentation() -> void:
	var draft = MapDataResource.new(10, 10, 260)
	var draft_copy = draft.copy()
	_expect(draft_copy != null, "Incomplete editor drafts must remain copyable before ports are placed.")
	var board = MapBoardResource.new()
	board.set_editor_map(MapDataResource.new(100, 100, 260))
	var map_rect := Rect2(board.pan, Vector2(100, 100) * board.BASE_CELL_SIZE * board.zoom_level)
	_expect(board.view_rect.encloses(map_rect), "The full 100x100 map must fit inside the board view.")
	var editor = load("res://scenes/map_editor.tscn").instantiate()
	_expect(editor.get_node("BackgroundLayer").layer < 0, "The editor background must render on a canvas layer below the map.")
	editor.free()
	board.free()

func _finish() -> void:
	quit(1 if failures > 0 else 0)
