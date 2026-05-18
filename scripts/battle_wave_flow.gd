extends RefCounted

const RUN_STATE = preload("res://scripts/run_state.gd")
const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")

var owner: Control


func setup(target_owner: Control) -> void:
	owner = target_owner


func start_wave(index: int) -> void:
	owner.wave_index = index
	owner.wave_queue.clear()
	var wave_data: Dictionary = owner.wave_defs[index]
	var rows: Array = wave_data.get("rows", [])
	for row_entries in rows:
		owner.wave_queue.append(row_entries.duplicate(true))

	if index == owner.wave_defs.size() - 1:
		owner.wave_turn_limit = -1
		owner.wave_turns_remaining = -1
	else:
		owner.wave_turn_limit = int(wave_data.get("turn_limit", 1))
		owner.wave_turns_remaining = owner.wave_turn_limit

	if index == 0 and not owner.wave_queue.is_empty():
		var opening_row: Array = owner.wave_queue.pop_front()
		owner._spawn_wave_row(opening_row, owner.FIRST_BATTLE_ROW)

	fill_preview_tiles()


func build_wave_defs_from_current_deck() -> void:
	owner.wave_defs.clear()
	if RUN_STATE.get_current_stage_encounter_type() == "boss":
		_build_boss_wave_def()
		return
	if RUN_STATE.get_current_stage_encounter_type() == "elite":
		_build_elite_wave_def()
		return
	var enemy_deck: Array[String] = RUN_STATE.get_enemy_deck()
	if enemy_deck.is_empty():
		enemy_deck = ["basic"]

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var stage_index: int = max(RUN_STATE.current_stage_index, 1)
	var wave_budgets: Array = _get_stage_wave_budgets(stage_index, enemy_deck)
	var row_cap: int = _get_stage_row_cap(stage_index)

	for wave_budget_variant in wave_budgets:
		var enemies_remaining: int = int(wave_budget_variant)
		var rows: Array = []
		while enemies_remaining > 0:
			var row_enemy_count: int = min(roll_wave_row_size(rng, row_cap), enemies_remaining)
			var row_entries: Array = []
			var row_budget_remaining: int = enemies_remaining
			for _entry_index in range(row_enemy_count):
				var enemy_type: String = _pick_enemy_for_budget(enemy_deck, row_budget_remaining, rng)
				var lane_index: int = rng.randi_range(0, owner.LANE_COUNT - 1)
				var enemy_def: Dictionary = ENEMY_CATALOG.get_enemy(enemy_type)
				row_entries.append({
					"lane": lane_index,
					"type": enemy_type,
				})
				row_budget_remaining -= int(enemy_def.get("danger_score", 1))
				enemies_remaining -= int(enemy_def.get("danger_score", 1))
				if enemies_remaining <= 0:
					break
			if row_entries.is_empty():
				break
			rows.append(row_entries)

		var turn_limit: int = int(ceil(float(int(wave_budget_variant)) + float(rows.size())))
		owner.wave_defs.append({
			"rows": rows,
			"turn_limit": turn_limit,
			"average_score": int(wave_budget_variant),
		})


func _build_elite_wave_def() -> void:
	var enemy_deck: Array[String] = RUN_STATE.get_enemy_deck()
	if enemy_deck.is_empty():
		enemy_deck = ["basic"]

	var elite_id: String = RUN_STATE.get_current_stage_elite_id()
	if elite_id.is_empty():
		for enemy_id in ENEMY_CATALOG.all_enemy_ids():
			var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
			if String(enemy.get("rank", "")) == "elite":
				elite_id = enemy_id
				break
	if elite_id.is_empty():
		elite_id = "commander_elite"

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rows: Array = []
	var enemy_budget := 12

	var first_row: Array = [{
		"lane": 1,
		"type": elite_id,
	}]
	var first_row_enemy_count: int = 2 if rng.randf() < 0.7 else 3
	var first_row_lanes: Array[int] = [0, 1, 2]
	for lane_index in range(first_row_lanes.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, lane_index)
		var temp: int = first_row_lanes[lane_index]
		first_row_lanes[lane_index] = first_row_lanes[swap_index]
		first_row_lanes[swap_index] = temp
	for side_index in range(first_row_enemy_count):
		if enemy_budget <= 0:
			break
		var enemy_type: String = _pick_enemy_for_budget(enemy_deck, enemy_budget, rng)
		var enemy_def: Dictionary = ENEMY_CATALOG.get_enemy(enemy_type)
		first_row.append({
			"lane": first_row_lanes[side_index],
			"type": enemy_type,
		})
		enemy_budget -= int(enemy_def.get("danger_score", 1))
	rows.append(first_row)

	while enemy_budget > 0:
		var row_enemy_count: int = min(roll_wave_row_size(rng, 3), 3)
		var lane_pool: Array[int] = [0, 1, 2]
		for lane_index in range(lane_pool.size() - 1, 0, -1):
			var swap_index := rng.randi_range(0, lane_index)
			var temp: int = lane_pool[lane_index]
			lane_pool[lane_index] = lane_pool[swap_index]
			lane_pool[swap_index] = temp
		var row_entries: Array = []
		for entry_index in range(min(row_enemy_count, lane_pool.size())):
			var enemy_type: String = _pick_enemy_for_budget(enemy_deck, enemy_budget, rng)
			var enemy_def: Dictionary = ENEMY_CATALOG.get_enemy(enemy_type)
			row_entries.append({
				"lane": lane_pool[entry_index],
				"type": enemy_type,
			})
			enemy_budget -= int(enemy_def.get("danger_score", 1))
			if enemy_budget <= 0:
				break
		if row_entries.is_empty():
			break
		rows.append(row_entries)

	owner.wave_defs.append({
		"rows": rows,
		"turn_limit": 20,
		"average_score": 12,
		"is_elite_wave": true,
	})


func _build_boss_wave_def() -> void:
	var boss_id: String = RUN_STATE.get_current_stage_elite_id()
	if boss_id.is_empty():
		boss_id = "act1_boss"
	owner.wave_defs.append({
		"rows": [[{
			"lane": 1,
			"type": boss_id,
		}]],
		"turn_limit": -1,
		"average_score": 0,
		"is_boss_wave": true,
	})


func roll_wave_row_size(rng: RandomNumberGenerator, row_cap: int) -> int:
	var roll: float = rng.randf()
	if roll < 0.35:
		return 1
	if roll < 0.85:
		return min(2, row_cap)
	return min(3, row_cap)


func _get_stage_wave_budgets(stage_index: int, enemy_deck: Array[String]) -> Array:
	var base_budgets: Array[int] = []
	match min(stage_index, 9):
		1:
			base_budgets = [9]
		2:
			base_budgets = [12, 14]
		3:
			base_budgets = [12, 16, 16]
		4:
			base_budgets = [14, 16, 18]
		5:
			base_budgets = [16, 18, 18]
		6:
			base_budgets = [16, 18, 22]
		7:
			base_budgets = [18, 20, 22]
		8:
			base_budgets = [18, 22, 24]
		_:
			base_budgets = [20, 22, 24]

	var adjusted_budgets: Array = []
	for value in base_budgets:
		adjusted_budgets.append(value)

	var deck_pressure_bonus: int = _get_wave_pressure_bonus(enemy_deck)
	if deck_pressure_bonus <= 0 or adjusted_budgets.is_empty():
		return adjusted_budgets

	var weights: Array[int] = []
	match adjusted_budgets.size():
		1:
			weights = [1]
		2:
			weights = [1, 2]
		_:
			weights = [1, 2, 3]

	var weight_sum: int = 0
	for weight in weights:
		weight_sum += weight

	var allocated_bonus := 0
	for index in range(adjusted_budgets.size()):
		var bonus_share: int = int(floor(float(deck_pressure_bonus * weights[index]) / float(weight_sum)))
		adjusted_budgets[index] = int(adjusted_budgets[index]) + bonus_share
		allocated_bonus += bonus_share

	var spill_index: int = adjusted_budgets.size() - 1
	while allocated_bonus < deck_pressure_bonus and spill_index >= 0:
		adjusted_budgets[spill_index] = int(adjusted_budgets[spill_index]) + 1
		allocated_bonus += 1
		spill_index -= 1
		if spill_index < 0:
			spill_index = adjusted_budgets.size() - 1

	return adjusted_budgets


func _get_wave_pressure_bonus(enemy_deck: Array[String]) -> int:
	if enemy_deck.is_empty():
		return 0
	var total_score := 0
	for enemy_id in enemy_deck:
		var def: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
		total_score += int(def.get("danger_score", 1))
	var baseline_score: int = enemy_deck.size() * 3
	var excess_score: int = max(total_score - baseline_score, 0)
	return int(ceil(float(excess_score) / 2.0))


func _get_stage_row_cap(stage_index: int) -> int:
	return 2 if stage_index <= 4 else 3


func _pick_enemy_for_budget(enemy_deck: Array[String], remaining_budget: int, rng: RandomNumberGenerator) -> String:
	var valid: Array[String] = []
	var cheapest_id: String = enemy_deck[0]
	var cheapest_score: int = 99999
	for enemy_id in enemy_deck:
		var def: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
		var score: int = int(def.get("danger_score", 1))
		if score <= remaining_budget:
			valid.append(enemy_id)
		if score < cheapest_score:
			cheapest_score = score
			cheapest_id = enemy_id
	if valid.is_empty():
		return cheapest_id
	return valid[rng.randi_range(0, valid.size() - 1)]


func fill_preview_tiles() -> void:
	if owner.wave_queue.is_empty():
		return
	if preview_row_has_enemies():
		return

	var next_row_entries: Array = owner.wave_queue.pop_front()
	if battlefield_has_enemies():
		owner._spawn_wave_row(next_row_entries, owner.PREVIEW_ROW)
	else:
		owner._spawn_wave_row(next_row_entries, owner.FIRST_BATTLE_ROW)


func preview_row_has_enemies() -> bool:
	for lane_index in range(owner.LANE_COUNT):
		if not owner.board_state[lane_index][owner.PREVIEW_ROW].is_empty():
			return true
	return false


func battlefield_has_enemies() -> bool:
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			if not owner.board_state[lane_index][row_index].is_empty():
				return true
	return false


func check_wave_clear() -> void:
	if owner.battle_finished:
		return
	if not owner.wave_queue.is_empty():
		return
	if RUN_STATE.get_current_stage_encounter_type() == "boss" and not _is_boss_alive_on_field():
		owner._handle_battle_result("Stage Clear")
		return

	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			if not owner.board_state[lane_index][row_index].is_empty():
				return

	if owner.wave_index + 1 < owner.wave_defs.size():
		owner.pending_skill_id = ""
		owner.pending_push_target_id = -1
		owner.pending_push_destinations.clear()
		owner.pending_retreat_target_id = -1
		owner.pending_retreat_destinations.clear()
		owner.selected_skill_id = ""
		owner._clear_lane_selection()
		owner.combat_resolver.reduce_cooldowns()
		owner.aoe_range_bonus_this_turn = 0
		owner.turret_damage_multiplier_this_turn = 1
		owner.turn_manager.begin_next_turn()
		owner._reset_discipline_lock()
		if owner.pending_bonus_actions_next_turn > 0:
			owner.turn_manager.add_actions(owner.pending_bonus_actions_next_turn)
			owner.pending_bonus_actions_next_turn = 0
		start_wave(owner.wave_index + 1)
		owner._refresh_ui()
	else:
		owner._handle_battle_result("Stage Clear")


func advance_wave_on_timeout() -> bool:
	if owner.battle_finished:
		return false
	if owner.wave_turns_remaining != 0:
		return false
	if owner.wave_index + 1 >= owner.wave_defs.size():
		return false

	owner.pending_skill_id = ""
	owner.pending_push_target_id = -1
	owner.pending_push_destinations.clear()
	owner.pending_retreat_target_id = -1
	owner.pending_retreat_destinations.clear()
	owner.selected_skill_id = ""
	owner._clear_lane_selection()
	start_wave(owner.wave_index + 1)
	owner._refresh_ui()
	return true


func _is_boss_alive_on_field() -> bool:
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index]:
				if String(enemy.get("rank", "")) == "boss":
					return true
	return false
