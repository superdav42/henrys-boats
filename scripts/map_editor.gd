class_name MapEditor
extends Node2D

const MapDataResource = preload("res://scripts/map_data.gd")
const SaveStoreResource = preload("res://scripts/save_store.gd")

signal cancelled
signal map_selected(map_data)

@onready var board = $MapBoard
@onready var status_label: Label = $EditorHud/StatusLabel
@onready var terrain_select: OptionButton = $EditorHud/Controls/TerrainSelect
@onready var tool_select: OptionButton = $EditorHud/Controls/ToolSelect
@onready var team_select: SpinBox = $EditorHud/Controls/TeamSelect
@onready var unit_select: OptionButton = $EditorHud/Controls/UnitSelect
@onready var money_input: SpinBox = $EditorHud/Controls/MoneyInput
@onready var size_select: OptionButton = $EditorHud/Controls/SizeSelect
@onready var map_name: LineEdit = $EditorHud/MapName
@onready var replace_check: CheckBox = $EditorHud/ReplaceCheck
@onready var saved_maps: OptionButton = $EditorHud/SavedMaps
@onready var delete_check: CheckBox = $EditorHud/DeleteCheck
@onready var json_text: TextEdit = $EditorHud/JsonText

var working_map

func _ready() -> void:
	for terrain_type in MapDataResource.TERRAIN_TYPES:
		terrain_select.add_item(terrain_type)
	for tool in ["Terrain", "Port", "Starting unit", "Erase"]:
		tool_select.add_item(tool)
	for unit_type in MapDataResource.UNIT_TYPES:
		unit_select.add_item(unit_type)
	for size in MapDataResource.MAP_SIZES:
		size_select.add_item("%d × %d" % [size, size], size)
	team_select.min_value = 0
	team_select.max_value = 7
	money_input.min_value = 0
	money_input.max_value = 100000
	board.cell_pressed.connect(_on_cell_pressed)
	set_map(MapDataResource.default_map())

func set_map(map_data) -> void:
	working_map = map_data.copy()
	money_input.value = working_map.starting_money
	for index in size_select.item_count:
		if size_select.get_item_id(index) == working_map.width:
			size_select.select(index)
			break
	board.set_editor_map(working_map)
	_refresh_saved_maps()
	_update_status()

func _on_cell_pressed(cell: Vector2i) -> void:
	var tool := tool_select.get_item_text(tool_select.selected)
	var changed := false
	if tool == "Terrain":
		working_map.set_terrain(cell, terrain_select.get_item_text(terrain_select.selected))
		changed = true
	elif tool == "Port":
		changed = working_map.place_port(int(team_select.value), cell)
	elif tool == "Starting unit":
		changed = working_map.place_starting_unit(unit_select.get_item_text(unit_select.selected), int(team_select.value), cell)
	else:
		changed = working_map.remove_starting_unit_at(cell) or working_map.remove_port_at(cell)
	if changed:
		board.set_editor_map(working_map)
	_update_status("Map changed." if changed else "That placement is not allowed.")

func _on_money_changed(value: float) -> void:
	working_map.starting_money = int(value)
	_update_status()

func _on_size_selected(index: int) -> void:
	var size := size_select.get_item_id(index)
	if size == working_map.width and size == working_map.height:
		return
	set_map(MapDataResource.new(size, size, int(money_input.value)))
	_update_status("Size changed; the previous unsaved layout was discarded.")

func _on_save_pressed() -> void:
	if not working_map.is_valid():
		_update_status("Cannot save: %s" % "; ".join(working_map.validation_errors()))
		return
	var result: Error = SaveStoreResource.save_map(map_name.text, working_map, replace_check.button_pressed)
	if result == OK:
		_refresh_saved_maps()
		_update_status("Saved %s." % map_name.text.strip_edges())
	elif result == ERR_ALREADY_EXISTS:
		_update_status("That name exists. Tick Replace to overwrite it.")
	else:
		_update_status("Map could not be saved (error %d)." % result)

func _on_load_pressed() -> void:
	if saved_maps.selected < 0:
		_update_status("Choose a saved map first.")
		return
	var result: Dictionary = SaveStoreResource.load_map_result(saved_maps.get_item_text(saved_maps.selected))
	if result["map"] == null:
		_update_status(result["error"])
		return
	map_name.text = saved_maps.get_item_text(saved_maps.selected)
	set_map(result["map"])
	_update_status("Loaded a copy. Save to make changes permanent.")

func _on_delete_pressed() -> void:
	if saved_maps.selected < 0 or not delete_check.button_pressed:
		_update_status("Choose a map and tick Confirm delete.")
		return
	var result: Error = SaveStoreResource.delete_map(saved_maps.get_item_text(saved_maps.selected), true)
	delete_check.button_pressed = false
	_refresh_saved_maps()
	_update_status("Map deleted." if result == OK else "Map could not be deleted (error %d)." % result)

func _on_export_pressed() -> void:
	json_text.text = JSON.stringify(working_map.to_dictionary(), "\t")
	_update_status("JSON is ready to copy or download with the browser's text controls.")

func _on_import_pressed() -> void:
	var parsed = JSON.parse_string(json_text.text)
	var imported = MapDataResource.from_dictionary(parsed)
	if imported == null:
		_update_status("Import rejected: the JSON is malformed, invalid, or uses an unsupported version.")
		return
	set_map(imported)
	_update_status("Imported into the working copy. Save when ready.")

func _on_use_pressed() -> void:
	if not working_map.is_valid():
		_update_status("Cannot use map: %s" % "; ".join(working_map.validation_errors()))
		return
	map_selected.emit(working_map.copy())

func _on_cancel_pressed() -> void:
	cancelled.emit()

func _refresh_saved_maps() -> void:
	saved_maps.clear()
	for saved_name in SaveStoreResource.list_maps():
		saved_maps.add_item(saved_name)

func _update_status(prefix: String = "") -> void:
	var errors: PackedStringArray = working_map.validation_errors()
	var validity := "Ready to save or use." if errors.is_empty() else "%d validation issue(s): %s" % [errors.size(), "; ".join(errors)]
	status_label.text = ("%s %s" % [prefix, validity]).strip_edges()
