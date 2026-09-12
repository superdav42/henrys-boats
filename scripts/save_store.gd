class_name SaveStore
extends RefCounted

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

static func save_map(map_name: String, map_data: MapData) -> Error:
	DirAccess.make_dir_recursive_absolute(MAP_DIRECTORY)
	var safe_name := map_name.validate_filename()
	if safe_name.is_empty():
		return ERR_INVALID_PARAMETER
	var file := FileAccess.open("%s/%s.json" % [MAP_DIRECTORY, safe_name], FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(map_data.to_dictionary()))
	return OK
