class_name MapBoard
extends Node2D

signal cell_pressed(cell: Vector2i)
signal unit_pressed(unit_id: int)

const BASE_CELL_SIZE := 64.0
const MIN_ZOOM := 0.05
const MAX_ZOOM := 2.0
@export var view_rect := Rect2(24, 270, 672, 520)
var map_data
var units: Array[Dictionary] = []
var selected_unit_id := -1
var active_team_id := 0
var unit_stats: Dictionary = {}
var move_overlay: Array[Vector2i] = []
var attack_overlay: Array[Vector2i] = []
var editor_mode := false
var zoom_level := 1.0
var pan := Vector2(48, 220)
var dragging := false
var drag_origin := Vector2.ZERO
var water_phase := 0.0

func set_match(new_map, new_units: Array[Dictionary], selected_id: int, team_id: int, stats: Dictionary) -> void:
	var should_fit: bool = map_data != new_map
	map_data = new_map
	units = new_units
	selected_unit_id = selected_id
	active_team_id = team_id
	unit_stats = stats
	editor_mode = false
	if should_fit:
		_fit_map_to_view()
	_rebuild_overlays()
	queue_redraw()

func set_editor_map(new_map) -> void:
	var should_fit: bool = map_data != new_map
	map_data = new_map
	units = new_map.starting_units
	selected_unit_id = -1
	active_team_id = 0
	unit_stats = {}
	editor_mode = true
	if should_fit:
		_fit_map_to_view()
	move_overlay.clear()
	attack_overlay.clear()
	queue_redraw()

func _fit_map_to_view() -> void:
	if map_data == null or map_data.width <= 0 or map_data.height <= 0:
		return
	var padding := 8.0
	var available := view_rect.size - Vector2.ONE * padding * 2.0
	var map_size := Vector2(map_data.width, map_data.height) * BASE_CELL_SIZE
	zoom_level = clampf(minf(available.x / map_size.x, available.y / map_size.y), MIN_ZOOM, MAX_ZOOM)
	var fitted_size := map_size * zoom_level
	pan = view_rect.position + (view_rect.size - fitted_size) * 0.5

func _process(delta: float) -> void:
	if visible and map_data != null:
		water_phase = fmod(water_phase + delta, 6.0)
		queue_redraw()

func _draw() -> void:
	if map_data == null: return
	var board_rect := Rect2(pan, Vector2(map_data.width, map_data.height) * BASE_CELL_SIZE * zoom_level)
	draw_rect(board_rect.grow(8.0 * zoom_level), Color("071827", 0.82))
	for y in map_data.height:
		for x in map_data.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(pan + Vector2(cell) * BASE_CELL_SIZE * zoom_level, Vector2.ONE * BASE_CELL_SIZE * zoom_level)
			_draw_terrain(rect, map_data.terrain_at(cell), cell)
			draw_rect(rect, Color(0.72, 0.9, 0.98, 0.48), false, maxf(1.0, zoom_level))
			if cell in move_overlay:
				_draw_overlay_marker(rect, Color(0.2, 0.85, 0.55, 0.72), "M")
			if cell in attack_overlay:
				_draw_overlay_marker(rect, Color(1.0, 0.45, 0.35, 0.78), "A")
	for port in map_data.ports:
		var rect := _cell_rect(port["cell"])
		_draw_port_marker(rect, _team_color(port["team_id"]))
	for unit in units:
		var cell: Vector2i = unit.get("cell", unit.get("grid", Vector2i(-1, -1)))
		if not map_data.is_inside(cell) or not _unit_is_visible(unit):
			continue
		_draw_unit(_cell_rect(cell), unit)
	draw_rect(board_rect, Color("b9edff"), false, maxf(3.0, 3.0 * zoom_level))

func _draw_terrain(rect: Rect2, terrain: String, cell: Vector2i) -> void:
	match terrain:
		"Shore":
			_draw_shore(rect, cell)
		"Land":
			draw_rect(rect, Color("4b8a4b"))
			for dot in [Vector2(0.22, 0.3), Vector2(0.68, 0.22), Vector2(0.45, 0.7), Vector2(0.82, 0.78)]:
				draw_circle(rect.position + rect.size * dot, 2.0 * zoom_level, Color("78b85c"))
		"Mountain":
			draw_rect(rect, Color("5f8050"))
			_draw_mountain(rect, 0.16, 0.9, 0.5, 0.16, 0.84, 0.9, Color("756653"))
			_draw_mountain(rect, 0.38, 0.9, 0.69, 0.32, 0.96, 0.9, Color("554b45"))
		"Snow Mountain":
			draw_rect(rect, Color("58734b"))
			_draw_mountain(rect, 0.1, 0.92, 0.48, 0.08, 0.86, 0.92, Color("59616b"))
			var snow := PackedVector2Array([rect.position + rect.size * Vector2(0.31, 0.45), rect.position + rect.size * Vector2(0.48, 0.08), rect.position + rect.size * Vector2(0.65, 0.45), rect.position + rect.size * Vector2(0.55, 0.38), rect.position + rect.size * Vector2(0.48, 0.48), rect.position + rect.size * Vector2(0.4, 0.37)])
			draw_colored_polygon(snow, Color("f2f7fb"))
		"Reef":
			_draw_water(rect)
			for reef in [Vector2(0.28, 0.35), Vector2(0.64, 0.56), Vector2(0.46, 0.75)]:
				draw_circle(rect.position + rect.size * reef, 7.0 * zoom_level, Color("38a897"))
				draw_circle(rect.position + rect.size * reef + Vector2(1.0, -1.0) * zoom_level, 3.5 * zoom_level, Color("8ed9b1"))
		"River":
			draw_rect(rect, Color("4d8b50"))
			var river := PackedVector2Array([rect.position + rect.size * Vector2(0.2, 0.0), rect.position + rect.size * Vector2(0.66, 0.35), rect.position + rect.size * Vector2(0.35, 0.65), rect.position + rect.size * Vector2(0.78, 1.0)])
			draw_polyline(river, Color("1978ae"), 16.0 * zoom_level, true)
			draw_polyline(river, Color("68c9e8"), 5.0 * zoom_level, true)
		_:
			_draw_water(rect)

func _draw_shore(rect: Rect2, cell: Vector2i) -> void:
	_draw_water(rect)
	var sand := Color("dcbf77")
	var foam := Color("f5e4ad")
	var center := Rect2(rect.position + rect.size * 0.28, rect.size * 0.44)
	draw_rect(center, sand)
	var land_neighbors := {
		Vector2i.UP: Rect2(rect.position + Vector2(rect.size.x * 0.28, 0), Vector2(rect.size.x * 0.44, rect.size.y * 0.5)),
		Vector2i.DOWN: Rect2(rect.position + Vector2(rect.size.x * 0.28, rect.size.y * 0.5), Vector2(rect.size.x * 0.44, rect.size.y * 0.5)),
		Vector2i.LEFT: Rect2(rect.position + Vector2(0, rect.size.y * 0.28), Vector2(rect.size.x * 0.5, rect.size.y * 0.44)),
		Vector2i.RIGHT: Rect2(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.28), Vector2(rect.size.x * 0.5, rect.size.y * 0.44)),
	}
	for direction in land_neighbors:
		var neighbor: Vector2i = cell + Vector2i(direction)
		if map_data.is_inside(neighbor) and map_data.terrain_at(neighbor) in ["Land", "Mountain", "Snow Mountain"]:
			draw_rect(land_neighbors[direction], sand)
	draw_rect(center, foam, false, maxf(1.0, zoom_level))

func _draw_water(rect: Rect2) -> void:
	draw_rect(rect, Color("176a9f"))
	for row in range(1, 5):
		var y := rect.position.y + rect.size.y * row / 5.0
		var offset := fposmod(water_phase * 14.0 + rect.position.x * 0.12 + row * 11.0, 22.0) - 22.0
		for column in range(3):
			var start_x := rect.position.x + offset + column * 28.0 * zoom_level
			draw_line(Vector2(start_x, y), Vector2(start_x + 13.0 * zoom_level, y), Color("75c9e6", 0.7), maxf(1.0, zoom_level))

func _draw_mountain(rect: Rect2, left_x: float, base_y: float, peak_x: float, peak_y: float, right_x: float, right_y: float, color: Color) -> void:
	var points := PackedVector2Array([rect.position + rect.size * Vector2(left_x, base_y), rect.position + rect.size * Vector2(peak_x, peak_y), rect.position + rect.size * Vector2(right_x, right_y)])
	draw_colored_polygon(points, color)

func _draw_overlay_marker(rect: Rect2, color: Color, marker: String) -> void:
	var inset := 4.0 * zoom_level
	var inner := rect.grow(-inset)
	draw_rect(inner, Color(color, 0.2))
	draw_rect(inner, color, false, maxf(1.5, zoom_level))
	draw_string(ThemeDB.fallback_font, inner.get_center() + Vector2(-4.0, 5.0) * zoom_level, marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 13.0 * zoom_level, Color.WHITE)

func _draw_port_marker(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	draw_circle(center, 11.0 * zoom_level, Color("10263a"))
	draw_circle(center, 8.0 * zoom_level, color)
	draw_line(center + Vector2(0, -7.0) * zoom_level, center + Vector2(0, 7.0) * zoom_level, Color.WHITE, maxf(1.0, zoom_level))
	draw_line(center + Vector2(-5.0, 0) * zoom_level, center + Vector2(5.0, 0) * zoom_level, Color.WHITE, maxf(1.0, zoom_level))

func _draw_unit(cell_rect: Rect2, unit: Dictionary) -> void:
	var rect := cell_rect.grow(-7.0 * zoom_level)
	var stats: Dictionary = unit_stats.get(unit.get("kind", ""), {})
	var color := _team_color(int(unit.get("team_id", 0)))
	draw_circle(rect.get_center(), rect.size.x * 0.43, Color("f4fbff", 0.22))
	var is_air: bool = bool(stats.get("air", unit.get("kind", "") in ["Jet", "Fighter", "Bomber"]))
	if is_air:
		_draw_aircraft(rect, color)
	else:
		_draw_ship(rect, color, unit.get("kind", ""))
	_draw_hit_points(rect, int(unit.get("hp", 0)), int(stats.get("hp", unit.get("hp", 0))))
	if not editor_mode and unit.get("id", -1) == selected_unit_id:
		_draw_selection_outline(rect)
	if zoom_level >= 0.55:
		var label: String = stats.get("short", unit.get("kind", "Unit").left(2).to_upper())
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(2.0, rect.size.y - 2.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11.0 * zoom_level, Color.WHITE)

func _draw_ship(rect: Rect2, color: Color, kind: String) -> void:
	if kind == "Submarine":
		var center := rect.get_center()
		_draw_oval(center, Vector2(rect.size.x * 0.4, rect.size.y * 0.2), color)
		draw_rect(Rect2(center + Vector2(-rect.size.x * 0.08, -rect.size.y * 0.3), rect.size * Vector2(0.16, 0.22)), color)
		draw_line(center + Vector2(0, -rect.size.y * 0.3), center + Vector2(rect.size.x * 0.15, -rect.size.y * 0.42), Color("d9eff5"), maxf(1.5, zoom_level))
		return
	var hull := PackedVector2Array([rect.position + rect.size * Vector2(0.12, 0.62), rect.position + rect.size * Vector2(0.76, 0.62), rect.position + rect.size * Vector2(0.95, 0.48), rect.position + rect.size * Vector2(0.76, 0.8), rect.position + rect.size * Vector2(0.2, 0.8)])
	draw_colored_polygon(hull, color)
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[0]]), Color("10263a"), maxf(1.5, zoom_level), true)
	if kind == "Aircraft Carrier":
		draw_rect(Rect2(rect.position + rect.size * Vector2(0.2, 0.38), rect.size * Vector2(0.58, 0.2)), Color("e4edf1"))
		draw_line(rect.position + rect.size * Vector2(0.28, 0.48), rect.position + rect.size * Vector2(0.7, 0.48), Color("344454"), maxf(1.0, zoom_level))
	else:
		draw_rect(Rect2(rect.position + rect.size * Vector2(0.38, 0.35), rect.size * Vector2(0.24, 0.28)), Color("d9eff5"))
		draw_line(rect.position + rect.size * Vector2(0.5, 0.35), rect.position + rect.size * Vector2(0.66, 0.2), Color("d9eff5"), maxf(2.0, zoom_level))

func _draw_aircraft(rect: Rect2, color: Color) -> void:
	var plane := PackedVector2Array([rect.position + rect.size * Vector2(0.5, 0.08), rect.position + rect.size * Vector2(0.62, 0.4), rect.position + rect.size * Vector2(0.94, 0.56), rect.position + rect.size * Vector2(0.61, 0.6), rect.position + rect.size * Vector2(0.54, 0.9), rect.position + rect.size * Vector2(0.45, 0.9), rect.position + rect.size * Vector2(0.39, 0.6), rect.position + rect.size * Vector2(0.06, 0.56), rect.position + rect.size * Vector2(0.38, 0.4)])
	draw_colored_polygon(plane, color)
	draw_polyline(PackedVector2Array([plane[0], plane[1], plane[2], plane[3], plane[4], plane[5], plane[6], plane[7], plane[8], plane[0]]), Color("10263a"), maxf(1.5, zoom_level), true)

func _draw_oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _draw_hit_points(rect: Rect2, current_hp: int, max_hp: int) -> void:
	var count := clampi(max_hp, 1, 6)
	for index in count:
		var color := Color("f2f7f8") if index < current_hp else Color("10263a", 0.75)
		draw_circle(rect.position + Vector2((7.0 + index * 7.0) * zoom_level, 7.0 * zoom_level), 2.2 * zoom_level, color)

func _draw_selection_outline(rect: Rect2) -> void:
	var points := [rect.get_center() + Vector2(0, -rect.size.y * 0.62), rect.get_center() + Vector2(rect.size.x * 0.62, 0), rect.get_center() + Vector2(0, rect.size.y * 0.62), rect.get_center() + Vector2(-rect.size.x * 0.62, 0)]
	for index in points.size():
		draw_line(points[index], points[(index + 1) % points.size()], Color.WHITE, maxf(2.0, zoom_level))

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
		if unit_cell == cell and _unit_is_visible(unit):
			if not editor_mode:
				unit_pressed.emit(unit["id"])
				return
	cell_pressed.emit(cell)

func _rebuild_overlays() -> void:
	move_overlay.clear()
	attack_overlay.clear()
	if map_data == null or editor_mode or selected_unit_id == -1:
		return
	var selected := _unit_by_id(selected_unit_id)
	if selected.is_empty() or selected.get("team_id", -1) != active_team_id:
		return
	var stats: Dictionary = unit_stats.get(selected.get("kind", ""), {})
	if stats.is_empty():
		return
	var origin: Vector2i = selected.get("grid", Vector2i(-1, -1))
	if not selected.get("moved", false):
		for y in map_data.height:
			for x in map_data.width:
				var cell := Vector2i(x, y)
				if cell != origin and _unit_id_at(cell) == -1 and map_data.can_unit_occupy(selected.get("kind", ""), stats.get("air", false), cell) and _shortest_movement_cost(selected, cell, stats) <= int(stats.get("move", 0)):
					move_overlay.append(cell)
	if not selected.get("attacked", false):
		for unit in units:
			var target_cell: Vector2i = unit.get("grid", Vector2i(-1, -1))
			if unit.get("team_id", active_team_id) != active_team_id and _can_attack(stats, unit_stats.get(unit.get("kind", ""), {})) and _grid_distance(origin, target_cell) <= int(stats.get("range", 0)):
				attack_overlay.append(target_cell)

func _unit_by_id(unit_id: int) -> Dictionary:
	for unit in units:
		if unit.get("id", -1) == unit_id:
			return unit
	return {}

func _unit_id_at(cell: Vector2i) -> int:
	for unit in units:
		if unit.get("grid", Vector2i(-1, -1)) == cell:
			return int(unit.get("id", -1))
	return -1

func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _shortest_movement_cost(unit: Dictionary, destination: Vector2i, stats: Dictionary) -> int:
	var origin: Vector2i = unit.get("grid", Vector2i(-1, -1))
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
			if not map_data.is_inside(next) or map_data.movement_cost(unit.get("kind", ""), stats.get("air", false), next) < 0:
				continue
			if next != destination and _unit_id_at(next) != -1:
				continue
			var next_cost: int = int(costs[current]) + map_data.movement_cost(unit.get("kind", ""), stats.get("air", false), next)
			if next_cost > int(stats.get("move", 0)):
				continue
			if not costs.has(next) or next_cost < int(costs[next]):
				costs[next] = next_cost
				if next not in frontier:
					frontier.append(next)
	return 1000000

func _can_attack(attacker: Dictionary, defender: Dictionary) -> bool:
	if defender.get("submarine", false):
		return attacker.get("detector", false)
	return attacker.get("target", "") == "any" or (attacker.get("target", "") == "air" and defender.get("air", false)) or (attacker.get("target", "") == "surface" and not defender.get("air", false))

func _unit_is_visible(unit: Dictionary) -> bool:
	if unit.get("kind", "") != "Submarine" or unit.get("team_id", -1) == active_team_id or editor_mode:
		return true
	var cell: Vector2i = unit.get("grid", unit.get("cell", Vector2i(-1, -1)))
	for detector in units:
		if detector.get("team_id", -1) != active_team_id or detector.get("kind", "") != "Destroyer":
			continue
		var detector_cell: Vector2i = detector.get("grid", detector.get("cell", Vector2i(-1, -1)))
		if _grid_distance(detector_cell, cell) <= int(unit_stats.get("Destroyer", {}).get("range", 2)):
			return true
	return false

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
