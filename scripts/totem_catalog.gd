extends RefCounted
class_name TotemCatalog

const TOTEM_DATA_DIR := "res://data/totems"

static var _totem_cache: Dictionary = {}
static var _totem_order: Array[String] = []
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_totem_cache.clear()
	_totem_order.clear()
	_ensure_loaded()


static func all_totem_ids() -> Array[String]:
	_ensure_loaded()
	return _totem_order.duplicate()


static func get_totem(totem_id: String) -> Dictionary:
	_ensure_loaded()
	if _totem_cache.has(totem_id):
		return _totem_cache[totem_id].duplicate(true)
	if not _totem_order.is_empty():
		return _totem_cache[_totem_order[0]].duplicate(true)
	return {}


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_totem_cache.clear()
	_totem_order.clear()

	var dir := DirAccess.open(TOTEM_DATA_DIR)
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
		var resource_path := "%s/%s" % [TOTEM_DATA_DIR, tres_name]
		var totem_resource: Resource = load(resource_path)
		if totem_resource == null:
			continue

		var totem_id := String(totem_resource.id)
		if totem_id.is_empty():
			continue

		var totem_data := {
			"id": totem_id,
			"name": String(totem_resource.name),
			"short": String(totem_resource.short if not String(totem_resource.short).is_empty() else String(totem_resource.name).left(2).to_upper()),
			"range_type": String(totem_resource.range_type),
			"effect_key": String(totem_resource.effect_key),
			"values": totem_resource.values.duplicate(true),
			"keywords": PackedStringArray(totem_resource.keywords),
			"description": String(totem_resource.description),
			"detail_description": String(totem_resource.detail_description),
			"color": Color(totem_resource.color),
		}

		_totem_cache[totem_id] = totem_data
		_totem_order.append(totem_id)

	_loaded = true
