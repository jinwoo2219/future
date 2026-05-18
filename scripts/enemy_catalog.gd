extends RefCounted
class_name EnemyCatalog

const ENEMY_DATA_DIR := "res://data/enemies"

static var _enemy_cache: Dictionary = {}
static var _enemy_order: Array[String] = []
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_enemy_cache.clear()
	_enemy_order.clear()
	_ensure_loaded()


static func all_enemy_ids() -> Array[String]:
	_ensure_loaded()
	return _enemy_order.duplicate()


static func get_enemy(enemy_id: String) -> Dictionary:
	_ensure_loaded()
	if _enemy_cache.has(enemy_id):
		return _enemy_cache[enemy_id].duplicate(true)
	if not _enemy_order.is_empty():
		return _enemy_cache[_enemy_order[0]].duplicate(true)
	return {}


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_enemy_cache.clear()
	_enemy_order.clear()

	var dir := DirAccess.open(ENEMY_DATA_DIR)
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
		var resource_path := "%s/%s" % [ENEMY_DATA_DIR, tres_name]
		var enemy_resource: Resource = load(resource_path)
		if enemy_resource == null:
			continue

		var enemy_id := String(enemy_resource.id)
		if enemy_id.is_empty():
			continue

		var enemy_data := {
			"id": enemy_id,
			"name": String(enemy_resource.name),
			"short": _resolve_short_label(enemy_resource),
			"hp": int(enemy_resource.hp),
			"attack": int(enemy_resource.attack),
			"danger_score": int(enemy_resource.danger_score),
			"speed": _resolve_speed(enemy_resource),
			"rank": String(enemy_resource.rank),
			"category": String(enemy_resource.category),
			"move_pattern_id": String(enemy_resource.move_pattern_id),
			"color": _resolve_color(enemy_resource),
			"icon": enemy_resource.icon,
			"traits": enemy_resource.traits.duplicate(),
			"keywords": enemy_resource.keywords,
			"description": String(enemy_resource.description),
			"special": _resolve_special(enemy_resource),
		}

		_enemy_cache[enemy_id] = enemy_data
		_enemy_order.append(enemy_id)

	_loaded = true


static func _resolve_short_label(enemy_resource: Resource) -> String:
	var initial := String(enemy_resource.initial)
	if not initial.is_empty():
		return initial
	var enemy_name := String(enemy_resource.name)
	if enemy_name.is_empty():
		return "?"
	return enemy_name.left(1).to_upper()


static func _resolve_speed(enemy_resource: Resource) -> int:
	var move_pattern_id := String(enemy_resource.move_pattern_id)
	match move_pattern_id:
		"straight_2":
			return 2
		"hold_then_move":
			return 1
		"dash_countdown":
			return 0
		_:
			return 1


static func _resolve_color(enemy_resource: Resource) -> Color:
	var color_id := String(enemy_resource.color)
	match color_id:
		"red":
			return Color(0.78, 0.24, 0.24, 1.0)
		"yellow":
			return Color(0.96, 0.62, 0.24, 1.0)
		"blue":
			return Color(0.56, 0.72, 0.82, 1.0)
		"green":
			return Color(0.43, 0.76, 0.48, 1.0)
		"dark_green":
			return Color(0.18, 0.42, 0.22, 1.0)
		"light_gray":
			return Color(0.88, 0.9, 0.92, 1.0)
		"dark_pink":
			return Color(0.58, 0.22, 0.38, 1.0)
		"gold":
			return Color(0.86, 0.68, 0.18, 1.0)
		"brown":
			return Color(0.48, 0.31, 0.18, 1.0)
		"sage_gray":
			return Color(0.56, 0.66, 0.6, 1.0)
		"indigo":
			return Color(0.24, 0.28, 0.52, 1.0)
		"steel":
			return Color(0.56, 0.6, 0.68, 1.0)
		_:
			return Color(0.62, 0.66, 0.74, 1.0)


static func _resolve_special(enemy_resource: Resource) -> String:
	if enemy_resource.traits.has(&"stealth_cycle"):
		return "Alternates stealth. Hidden enemies cannot be targeted."
	if enemy_resource.traits.has(&"self_regen_5"):
		return "Recovers 5 HP each turn."
	if enemy_resource.traits.has(&"shield_regen"):
		return "Regains a shield and moves toward the most crowded tile."
	if enemy_resource.traits.has(&"attach_support"):
		return "Attaches to an ally in the same tile and boosts its attack and speed."
	if enemy_resource.traits.has(&"advance_others_on_death"):
		return "On death, all other enemies advance 1."
	var move_pattern_id := String(enemy_resource.move_pattern_id)
	match move_pattern_id:
		"king_kong_launch":
			return "Moves every 2 turns and throws a minion 2 rows ahead."
		"dash_countdown":
			return "Reaches the core in 3 turns."
		"straight_2":
			return "2 tiles per turn."
		"hold_then_move":
			return "Slow advance pattern."
		"archer_fire_line":
			return "Stops at row 4 and shoots the core."
		"side_shift":
			return "Can shift lanes."
		"static_support":
			return "Does not advance normally."
		_:
			return "No special ability."
