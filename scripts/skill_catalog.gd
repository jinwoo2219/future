extends RefCounted
class_name SkillCatalog

const SKILL_DATA_DIR := "res://data/skills"

static var _skill_cache: Dictionary = {}
static var _skill_order: Array[String] = []
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_skill_cache.clear()
	_skill_order.clear()
	_ensure_loaded()


static func all_skill_ids() -> Array[String]:
	_ensure_loaded()
	return _skill_order.duplicate()


static func get_skill(skill_id: String) -> Dictionary:
	_ensure_loaded()
	if _skill_cache.has(skill_id):
		return _skill_cache[skill_id].duplicate(true)
	if not _skill_order.is_empty():
		return _skill_cache[_skill_order[0]].duplicate(true)
	return {}


static func get_skill_ids_by_rarity(rarity: String) -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for skill_id in _skill_order:
		var skill: Dictionary = _skill_cache[skill_id]
		if String(skill.get("rarity", "")) == rarity:
			ids.append(skill_id)
	return ids


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_skill_cache.clear()
	_skill_order.clear()

	var dir := DirAccess.open(SKILL_DATA_DIR)
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
		var resource_path := "%s/%s" % [SKILL_DATA_DIR, tres_name]
		var skill_resource: Resource = load(resource_path)
		if skill_resource == null:
			continue

		var skill_id := String(skill_resource.id)
		if skill_id.is_empty():
			continue

		var skill_data := {
			"id": skill_id,
			"name": String(skill_resource.name),
			"rarity": String(skill_resource.rarity),
			"category": String(skill_resource.category),
			"targeting_type": String(skill_resource.targeting_type),
			"effect_key": String(skill_resource.effect_key),
			"cooldown": int(skill_resource.cooldown),
			"consumes_action": bool(skill_resource.consumes_action),
			"action_cost": int(skill_resource.action_cost),
			"values": skill_resource.values.duplicate(true),
			"keywords": skill_resource.keywords,
			"description": String(skill_resource.description),
			"detail_description": String(skill_resource.detail_description),
		}

		_skill_cache[skill_id] = skill_data
		_skill_order.append(skill_id)

	_loaded = true
