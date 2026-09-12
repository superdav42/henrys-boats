class_name SaveStore
extends RefCounted

const MapDataResource = preload("res://scripts/map_data.gd")
const PROFILE_PATH := "user://profile.json"
const MAP_DIRECTORY := "user://maps"

static func load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {"version": 1, "upgrades": []}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {"version": 1, "upgrades": []}

static func save_profile(profile: Dictionary) -> Error:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(profile))
	return OK

static func list_maps() -> PackedStringArray:
	var maps := PackedStringArray()
	if not DirAccess.dir_exists_absolute(MAP_DIRECTORY):
		return maps
	var directory := DirAccess.open(MAP_DIRECTORY)
	if directory == null:
		return maps
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			maps.append(file_name.trim_suffix(".json"))
		file_name = directory.get_next()
	directory.list_dir_end()
	maps.sort()
	return maps

static func load_map(map_name: String):
	var result := load_map_result(map_name)
	return result.get("map")

static func load_map_result(map_name: String) -> Dictionary:
	var path := _map_path(map_name)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"map": null, "error": "The selected map does not exist."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"map": null, "error": "The selected map could not be opened."}
	var parsed = JSON.parse_string(file.get_as_text())
	var map = MapDataResource.from_dictionary(parsed)
	return {"map": map, "error": "The map JSON is invalid or incompatible." if map == null else ""}

static func save_map(map_name: String, map_data, replace: bool = false) -> Error:
	if map_data == null or not map_data.is_valid():
		return ERR_INVALID_DATA
	var path := _map_path(map_name)
	if path.is_empty():
		return ERR_INVALID_PARAMETER
	if FileAccess.file_exists(path) and not replace:
		return ERR_ALREADY_EXISTS
	DirAccess.make_dir_recursive_absolute(MAP_DIRECTORY)
	var temporary_path := "%s.tmp" % path
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(map_data.to_dictionary(), "\t"))
	file.flush()
	file = null
	return DirAccess.rename_absolute(temporary_path, path)

static func delete_map(map_name: String, confirmed: bool) -> Error:
	if not confirmed:
		return ERR_UNAUTHORIZED
	var path := _map_path(map_name)
	if path.is_empty() or not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(path)

static func _map_path(map_name: String) -> String:
	var safe_name := map_name.strip_edges().validate_filename()
	if safe_name.is_empty() or safe_name != map_name.strip_edges():
		return ""
	return "%s/%s.json" % [MAP_DIRECTORY, safe_name]
