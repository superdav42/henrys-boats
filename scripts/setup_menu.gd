class_name SetupMenu
extends Control

const MapDataResource = preload("res://scripts/map_data.gd")
const SaveStoreResource = preload("res://scripts/save_store.gd")

signal cancelled
signal match_configured(configuration: Dictionary)
signal map_editor_requested

@onready var map_select: OptionButton = $Panel/Content/MapSelect
@onready var team_count: SpinBox = $Panel/Content/TeamCount
@onready var controllers: OptionButton = $Panel/Content/Controllers
@onready var status_label: Label = $Panel/Content/StatusLabel

func _ready() -> void:
	for size in MapDataResource.MAP_SIZES:
		map_select.add_item("Standard %d × %d" % [size, size])
		map_select.set_item_metadata(map_select.item_count - 1, size)
	for map_name in SaveStoreResource.list_maps():
		map_select.add_item("Saved: %s" % map_name)
		map_select.set_item_metadata(map_select.item_count - 1, map_name)
	team_count.min_value = 2
	team_count.max_value = 8
	team_count.value = 2
	controllers.add_item("Team 1 Human; remaining CPU")
	controllers.add_item("All Human (hot-seat)")
	controllers.add_item("Team 1 Human; alternating CPU")

func _on_start_pressed() -> void:
	var count := int(team_count.value)
	var map_data = _selected_map(count)
	if map_data == null:
		return
	if count < 2 or count > 8 or map_data.ports.size() != count:
		status_label.text = "This map has %d ports. Choose exactly %d teams." % [map_data.ports.size(), map_data.ports.size()]
		return
	var controller_types: Array[String] = []
	for team_id in range(count):
		controller_types.append(_controller_for(team_id))
	if not "human" in controller_types:
		status_label.text = "At least one team must be human-controlled."
		return
	match_configured.emit({"map": map_data, "controllers": controller_types})

func _selected_map(team_total: int):
	if map_select.selected < MapDataResource.MAP_SIZES.size():
		var size: int = int(map_select.get_item_metadata(map_select.selected))
		if size == 10 and team_total == 2:
			return MapDataResource.default_map()
		var map = MapDataResource.new(size, size, 260)
		var port_cells := [Vector2i(0, size - 1), Vector2i(size - 1, 0), Vector2i(0, 0), Vector2i(size - 1, size - 1), Vector2i(size / 2, 0), Vector2i(size / 2, size - 1), Vector2i(0, size / 2), Vector2i(size - 1, size / 2)]
		for team_id in range(team_total):
			map.ports.append({"team_id": team_id, "cell": port_cells[team_id]})
			map.starting_units.append({"kind": "Patrol", "team_id": team_id, "cell": port_cells[team_id]})
		return map
	var result: Dictionary = SaveStoreResource.load_map_result(str(map_select.get_item_metadata(map_select.selected)))
	if result["map"] == null:
		status_label.text = result["error"]
		return null
	return result["map"]

func _controller_for(team_id: int) -> String:
	if controllers.selected == 1:
		return "human"
	if controllers.selected == 2:
		return "human" if team_id % 2 == 0 else "cpu"
	return "human" if team_id == 0 else "cpu"
