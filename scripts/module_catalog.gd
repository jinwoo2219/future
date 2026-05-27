extends RefCounted
class_name ModuleCatalog

const MODULE_DATA_DIR := "res://data/modules"

static var _module_cache: Dictionary = {}
static var _module_order: Array[String] = []
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_module_cache.clear()
	_module_order.clear()
	_ensure_loaded()


static func all_module_ids() -> Array[String]:
	_ensure_loaded()
	return _module_order.duplicate()


static func get_module(module_id: String) -> Dictionary:
	_ensure_loaded()
	if module_id.is_empty():
		return {}
	if _module_cache.has(module_id):
		return _module_cache[module_id].duplicate(true)
	return {}


static func get_module_ids_by_rarity(rarity: String) -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for module_id in _module_order:
		var module_data: Dictionary = _module_cache[module_id]
		if String(module_data.get("rarity", "")) == rarity:
			ids.append(module_id)
	return ids


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_module_cache.clear()
	_module_order.clear()

	var dir := DirAccess.open(MODULE_DATA_DIR)
	if dir == null:
		_loaded = true
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var file_names: Array[String] = []
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	file_names.sort()
	for tres_name in file_names:
		var resource_path := "%s/%s" % [MODULE_DATA_DIR, tres_name]
		var module_resource: Resource = load(resource_path)
		if module_resource == null:
			continue

		var module_id := String(module_resource.id)
		if module_id.is_empty():
			continue

		var module_data := {
			"id": module_id,
			"name": String(module_resource.name),
			"rarity": String(module_resource.rarity),
			"effect_key": String(module_resource.effect_key),
			"values": module_resource.values.duplicate(true),
			"description": String(module_resource.description),
			"detail_description": String(module_resource.detail_description),
		}

		_module_cache[module_id] = module_data
		_module_order.append(module_id)

	_loaded = true
