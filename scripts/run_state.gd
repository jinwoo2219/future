extends RefCounted
class_name RunState

const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")
const TOTEM_CATALOG = preload("res://scripts/totem_catalog.gd")
const MAX_SKILLS := 6
const MAX_ENEMY_DECK := 5
const STAGES_PER_ACT := 7
const ELITE_STAGE_CHANCE := 0.15
const GUARANTEED_ELITE_STAGE_INDEX := 5
const TOTEMS_ENABLED := false
const ACTION_BOSS_RELIC_IDS := [
	"tight_pack",
	"short_draft",
	"discipline",
	"lone_hunt",
	"war_drums",
]

static var current_enemy_deck: Array[String] = []
static var current_stage_index: int = 1
static var current_stage_label: String = "1-1"
static var current_stage_options: Array[String] = ["enemy:basic"]
static var current_stage_encounter_type: String = "normal"
static var current_stage_elite_id: String = ""
static var current_stage_totem_id: String = ""
static var current_owned_skill_ids: Array[String] = []
static var current_equipped_skill_ids: Array[String] = []
static var current_slot_module_ids: Array[String] = []
static var current_life: int = 10
static var current_max_life: int = 10
static var current_relic_ids: Array[String] = []
static var current_card_use_count: int = 0
static var current_boss_revive_used := false
static var current_card_rarity_chances := {
	"common": 80,
	"rare": 16,
	"epic": 4,
	"elite": 0,
}
static var current_route_history: Array[Dictionary] = []


static func reset_run() -> void:
	ENEMY_CATALOG.reload()
	current_enemy_deck.clear()
	current_stage_index = 1
	current_stage_label = _build_stage_label(current_stage_index)
	current_stage_options = ["enemy:basic"]
	current_stage_encounter_type = "normal"
	current_stage_elite_id = ""
	current_stage_totem_id = ""
	current_owned_skill_ids = ["bullet", "bomb", "push"]
	current_equipped_skill_ids = ["bullet", "bomb", "push"]
	current_slot_module_ids = _build_empty_slot_modules()
	current_life = 10
	current_max_life = 10
	current_relic_ids.clear()
	current_card_use_count = 0
	current_boss_revive_used = false
	current_card_rarity_chances = {
		"common": 80,
		"rare": 16,
		"epic": 4,
		"elite": 0,
	}
	current_route_history.clear()


static func add_enemy_to_deck(enemy_id: String) -> void:
	if current_enemy_deck.size() >= MAX_ENEMY_DECK:
		return
	current_enemy_deck.append(enemy_id)


static func set_enemy_deck(enemy_ids: Array[String]) -> void:
	current_enemy_deck = enemy_ids.duplicate()


static func get_enemy_deck() -> Array[String]:
	return current_enemy_deck.duplicate()


static func get_enemy_deck_limit() -> int:
	return MAX_ENEMY_DECK


static func is_enemy_deck_full() -> bool:
	return current_enemy_deck.size() >= MAX_ENEMY_DECK


static func replace_enemy_in_deck(removed_enemy_id: String, added_enemy_id: String) -> void:
	if removed_enemy_id == added_enemy_id:
		return
	var deck_index := current_enemy_deck.find(removed_enemy_id)
	if deck_index == -1:
		return
	current_enemy_deck[deck_index] = added_enemy_id


static func get_enemy_counts() -> Dictionary:
	var counts := {}
	for enemy_id in current_enemy_deck:
		counts[enemy_id] = int(counts.get(enemy_id, 0)) + 1
	return counts


static func get_stage_options() -> Array[String]:
	return current_stage_options.duplicate()


static func get_current_stage_encounter_type() -> String:
	return current_stage_encounter_type


static func get_current_stage_elite_id() -> String:
	return current_stage_elite_id


static func set_current_stage_encounter(encounter_type: String, elite_id: String = "") -> void:
	current_stage_encounter_type = encounter_type
	current_stage_elite_id = elite_id


static func get_current_stage_totem_id() -> String:
	return current_stage_totem_id


static func set_current_stage_totem_id(totem_id: String) -> void:
	if not TOTEMS_ENABLED:
		current_stage_totem_id = ""
		return
	current_stage_totem_id = totem_id


static func get_equipped_skill_ids() -> Array[String]:
	return current_equipped_skill_ids.duplicate()


static func _build_empty_slot_modules() -> Array[String]:
	var module_ids: Array[String] = []
	for _index in range(MAX_SKILLS):
		module_ids.append("")
	return module_ids


static func _ensure_slot_module_size() -> void:
	while current_slot_module_ids.size() < MAX_SKILLS:
		current_slot_module_ids.append("")
	while current_slot_module_ids.size() > MAX_SKILLS:
		current_slot_module_ids.pop_back()


static func get_slot_module_ids() -> Array[String]:
	_ensure_slot_module_size()
	return current_slot_module_ids.duplicate()


static func get_slot_module_id(slot_index: int) -> String:
	_ensure_slot_module_size()
	if slot_index < 0 or slot_index >= current_slot_module_ids.size():
		return ""
	return String(current_slot_module_ids[slot_index])


static func set_slot_module_id(slot_index: int, module_id: String) -> void:
	_ensure_slot_module_size()
	if slot_index < 0 or slot_index >= current_slot_module_ids.size():
		return
	current_slot_module_ids[slot_index] = module_id


static func clear_slot_module_id(slot_index: int) -> void:
	set_slot_module_id(slot_index, "")


static func get_owned_skill_ids() -> Array[String]:
	return current_owned_skill_ids.duplicate()


static func get_skill_limit() -> int:
	var limit := MAX_SKILLS
	if has_relic("tight_pack"):
		limit -= 1
	return max(limit, 1)


static func is_skill_inventory_full() -> bool:
	return current_owned_skill_ids.size() >= get_skill_limit()


static func get_route_history() -> Array[Dictionary]:
	return current_route_history.duplicate(true)


static func commit_stage_choice(enemy_id: String) -> void:
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	current_route_history.append({
		"stage_index": current_stage_index,
		"stage_label": current_stage_label,
		"enemy_id": enemy_id,
		"enemy_name": String(enemy.get("name", enemy_id)),
		"enemy_short": String(enemy.get("short", "?")),
		"color": Color(enemy.get("color", Color(0.3, 0.3, 0.3, 1.0))),
	})


static func get_current_life() -> int:
	return current_life


static func set_current_life(value: int) -> void:
	current_life = clamp(value, 0, current_max_life)


static func get_current_max_life() -> int:
	return current_max_life


static func set_current_max_life(value: int) -> void:
	current_max_life = max(value, 1)
	current_life = clamp(current_life, 0, current_max_life)


static func get_relic_ids() -> Array[String]:
	return current_relic_ids.duplicate()


static func has_relic(relic_id: String) -> bool:
	return current_relic_ids.has(relic_id)


static func add_relic(relic_id: String) -> void:
	if relic_id.is_empty():
		return
	if current_relic_ids.has(relic_id):
		return
	current_relic_ids.append(relic_id)
	if relic_id == "life":
		current_max_life += 5
		current_life = min(current_life + 5, current_max_life)
	elif relic_id == "pain_engine":
		current_max_life = max(current_max_life - 3, 1)
		current_life = min(current_life, current_max_life)


static func increment_card_use_count() -> int:
	current_card_use_count += 1
	return current_card_use_count


static func get_card_use_count() -> int:
	return current_card_use_count


static func add_owned_skill(skill_id: String) -> void:
	if current_owned_skill_ids.has(skill_id):
		return
	if current_owned_skill_ids.size() >= get_skill_limit():
		return
	current_owned_skill_ids.append(skill_id)
	if not current_equipped_skill_ids.has(skill_id):
		current_equipped_skill_ids.append(skill_id)


static func replace_owned_skill(removed_skill_id: String, added_skill_id: String) -> void:
	if removed_skill_id == added_skill_id:
		return
	var owned_index := current_owned_skill_ids.find(removed_skill_id)
	if owned_index == -1:
		return
	current_owned_skill_ids[owned_index] = added_skill_id

	var equipped_index := current_equipped_skill_ids.find(removed_skill_id)
	if equipped_index != -1:
		current_equipped_skill_ids[equipped_index] = added_skill_id
	elif current_equipped_skill_ids.size() < get_skill_limit() and not current_equipped_skill_ids.has(added_skill_id):
		current_equipped_skill_ids.append(added_skill_id)


static func remove_owned_skill(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	var owned_index := current_owned_skill_ids.find(skill_id)
	if owned_index != -1:
		current_owned_skill_ids.remove_at(owned_index)
	var equipped_index := current_equipped_skill_ids.find(skill_id)
	if equipped_index != -1:
		current_equipped_skill_ids.remove_at(equipped_index)


static func get_bonus_actions_per_turn() -> int:
	var bonus := 0
	for relic_id in ACTION_BOSS_RELIC_IDS:
		if has_relic(relic_id):
			bonus += 1
	return bonus


static func get_stage_option_count() -> int:
	return 1 if has_relic("lone_hunt") else 2


static func set_card_rarity_chances(chances: Dictionary) -> void:
	current_card_rarity_chances = chances.duplicate(true)


static func get_card_rarity_chances() -> Dictionary:
	return current_card_rarity_chances.duplicate(true)


static func get_act_index_for_stage(stage_index: int) -> int:
	return int(floor(float(max(stage_index - 1, 0)) / float(STAGES_PER_ACT))) + 1


static func get_stage_sub_index(stage_index: int) -> int:
	return (max(stage_index - 1, 0) % STAGES_PER_ACT) + 1


static func _build_stage_label(stage_index: int) -> String:
	return "%d-%d" % [get_act_index_for_stage(stage_index), get_stage_sub_index(stage_index)]


static func _attach_random_totems_to_stage_options() -> void:
	if not TOTEMS_ENABLED:
		return
	var totem_ids: Array[String] = TOTEM_CATALOG.all_totem_ids()
	if totem_ids.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in range(current_stage_options.size()):
		var option_token: String = String(current_stage_options[index])
		if option_token.begins_with("boss:") or option_token.contains("|totem:"):
			continue
		var totem_id: String = totem_ids[rng.randi_range(0, totem_ids.size() - 1)]
		current_stage_options[index] = "%s|totem:%s" % [option_token, totem_id]


static func advance_after_stage_clear() -> void:
	ENEMY_CATALOG.reload()
	current_stage_index += 1
	current_stage_label = _build_stage_label(current_stage_index)
	current_stage_totem_id = ""
	current_stage_encounter_type = "normal"
	current_stage_elite_id = ""

	if get_stage_sub_index(current_stage_index) == STAGES_PER_ACT:
		var act_index: int = get_act_index_for_stage(current_stage_index)
		current_stage_options = ["boss:act%d_boss" % act_index]
		return

	var remaining: Array[String] = []
	for enemy_id in ENEMY_CATALOG.all_enemy_ids():
		var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
		if String(enemy.get("rank", "normal")) != "normal":
			continue
		if not current_enemy_deck.has(enemy_id):
			remaining.append(enemy_id)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in range(remaining.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp: String = remaining[index]
		remaining[index] = remaining[swap_index]
		remaining[swap_index] = temp

	current_stage_options = []
	var option_count := get_stage_option_count()
	for enemy_id in remaining.slice(0, min(option_count, remaining.size())):
		current_stage_options.append("enemy:%s" % enemy_id)

	var elite_ids: Array[String] = []
	for enemy_id in ENEMY_CATALOG.all_enemy_ids():
		var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
		if String(enemy.get("rank", "normal")) == "elite":
			elite_ids.append(enemy_id)

	var current_sub_index: int = get_stage_sub_index(current_stage_index)
	if current_sub_index >= 2 and current_sub_index < STAGES_PER_ACT and not elite_ids.is_empty():
		var should_offer_elite: bool = current_sub_index == GUARANTEED_ELITE_STAGE_INDEX
		if not should_offer_elite:
			var elite_rng := RandomNumberGenerator.new()
			elite_rng.randomize()
			should_offer_elite = elite_rng.randf() < ELITE_STAGE_CHANCE
		if should_offer_elite and not current_stage_options.is_empty():
			var elite_rng := RandomNumberGenerator.new()
			elite_rng.randomize()
			var elite_id: String = elite_ids[elite_rng.randi_range(0, elite_ids.size() - 1)]
			var insert_index: int = min(1, current_stage_options.size() - 1)
			if current_stage_options.size() == 2:
				insert_index = elite_rng.randi_range(0, 1)
			current_stage_options[insert_index] = "elite:%s" % elite_id

	if get_act_index_for_stage(current_stage_index) >= 2:
		_attach_random_totems_to_stage_options()
