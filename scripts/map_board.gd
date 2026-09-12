class_name MapBoard
extends Node2D

signal cell_pressed(cell: Vector2i)
signal unit_pressed(unit_id: int)

const BASE_CELL_SIZE := 64.0
const MIN_ZOOM := 0.25
const MAX_ZOOM := 2.0
var map_data
var units: Array[Dictionary] = []
var selected_unit_id := -1
var active_team_id := 0
var unit_stats: Dictionary = {}
var editor_mode := false
var zoom_level := 1.0
var pan := Vector2(48, 220)
var dragging := false
var drag_origin := Vector2.ZERO

func set_match(new_map, new_units: Array[Dictionary], selected_id: int, team_id: int, stats: Dictionary) -> void:
	map_data = new_map
	units = new_units
	selected_unit_id = selected_id
	active_team_id = team_id
	unit_stats = stats
	editor_mode = false
	queue_redraw()

func set_editor_map(new_map) -> void:
	map_data = new_map
	units = new_map.starting_units
	selected_unit_id = -1
	active_team_id = 0
	unit_stats = {}
	editor_mode = true
	queue_redraw()

func _draw() -> void:
	if map_data == null: return
	for y in map_data.height:
		for x in map_data.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(pan + Vector2(cell) * BASE_CELL_SIZE * zoom_level, Vector2.ONE * BASE_CELL_SIZE * zoom_level)
			draw_rect(rect, _terrain_color(map_data.terrain_at(cell)))
			draw_rect(rect, Color(0.62, 0.82, 0.94), false, maxf(1.0, zoom_level))
	for port in map_data.ports:
		var rect := _cell_rect(port["cell"])
		draw_circle(rect.get_center(), 10.0 * zoom_level, _team_color(port["team_id"]))
	for unit in units:
		var cell: Vector2i = unit.get("cell", unit.get("grid", Vector2i(-1, -1)))
		if not map_data.is_inside(cell):
			continue
		var rect := _cell_rect(cell).grow(-8.0 * zoom_level)
		var color := _team_color(unit["team_id"])
		draw_rect(rect, color)
		if not editor_mode and unit["id"] == selected_unit_id: draw_rect(rect.grow(3.0), Color.WHITE, false, 3.0)
		var label: String = unit_stats.get(unit["kind"], {}).get("short", unit["kind"].left(2).to_upper())
		var hp: Variant = unit.get("hp", 0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(4, 20) * zoom_level, "%s" % label if editor_mode else "%s %d" % [label, hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 14.0 * zoom_level, Color(0.03, 0.08, 0.12))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: _set_zoom(zoom_level * 1.15, event.position); return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _set_zoom(zoom_level / 1.15, event.position); return
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if event.pressed: drag_origin = event.position
			elif event.position.distance_to(drag_origin) < 3.0: _select_at(event.position)
	elif event is InputEventMouseMotion and dragging:
		pan += event.relative
		queue_redraw()

func _set_zoom(value: float, focus: Vector2) -> void:
	var old_zoom := zoom_level
	zoom_level = clampf(value, MIN_ZOOM, MAX_ZOOM)
	pan = focus - (focus - pan) * (zoom_level / old_zoom)
	queue_redraw()

func _select_at(point: Vector2) -> void:
	if map_data == null: return
	var cell := world_to_grid(point)
	if not map_data.is_inside(cell): return
	for unit in units:
		var unit_cell: Vector2i = unit.get("cell", unit.get("grid", Vector2i(-1, -1)))
		if unit_cell == cell:
			if not editor_mode:
				unit_pressed.emit(unit["id"])
				return
	cell_pressed.emit(cell)

func world_to_grid(point: Vector2) -> Vector2i:
	return Vector2i(floori((point.x - pan.x) / (BASE_CELL_SIZE * zoom_level)), floori((point.y - pan.y) / (BASE_CELL_SIZE * zoom_level)))

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(pan + Vector2(cell) * BASE_CELL_SIZE * zoom_level, Vector2.ONE * BASE_CELL_SIZE * zoom_level)

func _terrain_color(terrain: String) -> Color:
	if terrain == "Mountain": return Color(0.36, 0.31, 0.22)
	if terrain == "Reef": return Color(0.13, 0.44, 0.43)
	return Color(0.08, 0.25, 0.44)

func _team_color(team_id: int) -> Color:
	var colors := [Color(0.28, 0.75, 1.0), Color(1.0, 0.42, 0.35), Color(0.35, 0.9, 0.45), Color(1.0, 0.8, 0.25), Color(0.78, 0.42, 1.0), Color(1.0, 0.55, 0.2), Color(0.3, 0.9, 0.85), Color(0.95, 0.4, 0.65)]
	return colors[clampi(team_id, 0, colors.size() - 1)]
