class_name SaveStore
extends RefCounted

const MapDataResource = preload("res://scripts/map_data.gd")
const UpgradeCatalogResource = preload("res://scripts/upgrade_catalog.gd")
const PROFILE_PATH := "user://profile.json"
const MAP_DIRECTORY := "user://maps"

static func load_profile() -> Dictionary:
	var default_profile := default_profile()
	if not FileAccess.file_exists(PROFILE_PATH):
		return default_profile
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return default_profile
	var parsed = JSON.parse_string(file.get_as_text())
	var normalized := normalized_profile(parsed)
	return normalized if not normalized.is_empty() else default_profile

static func save_profile(profile: Dictionary) -> Error:
	var normalized := normalized_profile(profile)
	if normalized.is_empty():
		return ERR_INVALID_DATA
	var temporary_path := "%s.tmp" % PROFILE_PATH
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(normalized))
	file.flush()
	file = null
	return DirAccess.rename_absolute(temporary_path, PROFILE_PATH)

static func default_profile() -> Dictionary:
	return {"version": 1, "upgrades": [], "currency": 1500}

static func normalized_profile(profile: Variant) -> Dictionary:
	if not profile is Dictionary or int(profile.get("version", 1)) != 1:
		return {}
	var upgrades: Variant = profile.get("upgrades", [])
	if not upgrades is Array:
		return {}
	var known_upgrades: Array[String] = []
	for upgrade_id in upgrades:
		if not upgrade_id is String or not UpgradeCatalogResource.UPGRADES.has(upgrade_id):
			return {}
		if not upgrade_id in known_upgrades:
			known_upgrades.append(upgrade_id)
	var currency: Variant = profile.get("currency", default_profile()["currency"])
	if not currency is int or currency < 0:
		return {}
	return {"version": 1, "upgrades": known_upgrades, "currency": currency}

static func reset_profile(confirmed: bool) -> Error:
	if not confirmed:
		return ERR_UNAUTHORIZED
	if not FileAccess.file_exists(PROFILE_PATH):
		return OK
	return DirAccess.remove_absolute(PROFILE_PATH)

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
