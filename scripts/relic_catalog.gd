extends RefCounted
class_name RelicCatalog

const RELIC_DATA_DIR := "res://data/relics"

static var _relic_cache: Dictionary = {}
static var _relic_order: Array[String] = []
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_relic_cache.clear()
	_relic_order.clear()
	_ensure_loaded()


static func all_relic_ids() -> Array[String]:
	_ensure_loaded()
	return _relic_order.duplicate()


static func get_relic(relic_id: String) -> Dictionary:
	_ensure_loaded()
	if _relic_cache.has(relic_id):
		return _relic_cache[relic_id].duplicate(true)
	if not _relic_order.is_empty():
		return _relic_cache[_relic_order[0]].duplicate(true)
	return {}


static func get_relic_ids_by_source(source: String) -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for relic_id in _relic_order:
		var relic: Dictionary = _relic_cache[relic_id]
		if String(relic.get("source", "normal")) == source:
			ids.append(relic_id)
	return ids


static func get_relic_ids_by_boss_group(group_name: String) -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for relic_id in _relic_order:
		var relic: Dictionary = _relic_cache[relic_id]
		if String(relic.get("source", "normal")) != "boss":
			continue
		if String(relic.get("boss_group", "")) != group_name:
			continue
		ids.append(relic_id)
	return ids


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_relic_cache.clear()
	_relic_order.clear()

	var dir := DirAccess.open(RELIC_DATA_DIR)
	if dir == null:
		_loaded = true
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	var file_names: Array[String] = []
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	file_names.sort()
	for tres_name in file_names:
		var resource_path := "%s/%s" % [RELIC_DATA_DIR, tres_name]
		var relic_resource: Resource = load(resource_path)
		if relic_resource == null:
			continue
		var relic_id := String(relic_resource.id)
		if relic_id.is_empty():
			continue
		var relic_data := {
			"id": relic_id,
			"name": String(relic_resource.name),
			"source": String(relic_resource.source),
			"boss_group": String(relic_resource.boss_group),
			"description": String(relic_resource.description),
		}
		_relic_cache[relic_id] = relic_data
		_relic_order.append(relic_id)

	_loaded = true
