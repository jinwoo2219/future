extends RefCounted

const RUN_STATE = preload("res://scripts/run_state.gd")
const SLIME_SINGLE_ICON := preload("res://character/slime/single.png")

var owner: Control


func setup(target_owner: Control) -> void:
	owner = target_owner


func is_enemy_hidden(enemy: Dictionary) -> bool:
	return owner._is_enemy_hidden(enemy)


func is_enemy_targetable(enemy: Dictionary) -> bool:
	if enemy.is_empty():
		return false
	if int(enemy.get("attached_host_id", -1)) != -1:
		return false
	return not is_enemy_hidden(enemy)


func get_front_enemy_in_lane(lane_index: int) -> Dictionary:
	for row_index in range(owner.LAST_BATTLE_ROW, owner.FIRST_BATTLE_ROW - 1, -1):
		var occupants: Array = owner.board_state[lane_index][row_index]
		if occupants.is_empty():
			continue
		for occupant in occupants:
			if not is_enemy_targetable(occupant):
				continue
			return occupant
	var wide_boss: Dictionary = _get_wide_boss_covering_tile(lane_index, owner.FIRST_BATTLE_ROW)
	if not wide_boss.is_empty() and is_enemy_targetable(wide_boss):
		return wide_boss
	return {}


func get_back_enemy_in_lane(lane_index: int) -> Dictionary:
	for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
		var occupants: Array = owner.board_state[lane_index][row_index]
		if occupants.is_empty():
			continue
		for index in range(occupants.size() - 1, -1, -1):
			var occupant: Dictionary = occupants[index]
			if not is_enemy_targetable(occupant):
				continue
			return occupant
	var wide_boss: Dictionary = _get_wide_boss_covering_tile(lane_index, owner.FIRST_BATTLE_ROW)
	if not wide_boss.is_empty() and is_enemy_targetable(wide_boss):
		return wide_boss
	return {}


func get_front_enemy_in_tile(lane_index: int, row_index: int) -> Dictionary:
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return {}
	if row_index < owner.PREVIEW_ROW or row_index > owner.LAST_BATTLE_ROW:
		return {}
	var occupants: Array = owner.board_state[lane_index][row_index]
	if occupants.is_empty():
		var wide_boss: Dictionary = _get_wide_boss_covering_tile(lane_index, row_index)
		if not wide_boss.is_empty() and is_enemy_targetable(wide_boss):
			return wide_boss
		return {}
	for occupant in occupants:
		if not is_enemy_targetable(occupant):
			continue
		return occupant
	return {}


func get_enemy_stack_index(enemy: Dictionary) -> int:
	if enemy.is_empty():
		return 0
	var lane_index: int = int(enemy.get("lane", -1))
	var row_index: int = int(enemy.get("row", -1))
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return 0
	if row_index < owner.PREVIEW_ROW or row_index > owner.LAST_BATTLE_ROW:
		return 0
	var occupants: Array = owner.board_state[lane_index][row_index]
	for index in range(occupants.size()):
		if int(occupants[index].get("instance_id", -1)) == int(enemy.get("instance_id", -1)):
			return index
	return 0


func get_closest_enemy_behind(target: Dictionary) -> Dictionary:
	if target.is_empty():
		return {}

	var lane_index: int = int(target.get("lane", -1))
	var row_index: int = int(target.get("row", -1))
	var target_instance_id: int = int(target.get("instance_id", -1))
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return {}

	var same_tile_occupants: Array = owner.board_state[lane_index][row_index]
	for occupant in same_tile_occupants:
		if int(occupant.get("instance_id", -1)) == target_instance_id:
			continue
		if not is_enemy_targetable(occupant):
			continue
		return occupant

	for behind_row in range(row_index - 1, owner.FIRST_BATTLE_ROW - 1, -1):
		var occupants: Array = owner.board_state[lane_index][behind_row]
		if occupants.is_empty():
			continue
		for occupant in occupants:
			if not is_enemy_targetable(occupant):
				continue
			return occupant

	return {}


func get_next_combo_target(current_target: Dictionary, hit_ids: Dictionary) -> Dictionary:
	if current_target.is_empty():
		return {}

	var lane_index: int = int(current_target.get("lane", -1))
	var row_index: int = int(current_target.get("row", -1))
	var current_instance_id: int = int(current_target.get("instance_id", -1))
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return {}

	var same_tile_occupants: Array = owner.board_state[lane_index][row_index]
	for occupant in same_tile_occupants:
		var occupant_id: int = int(occupant.get("instance_id", -1))
		if occupant_id == current_instance_id:
			continue
		if hit_ids.has(occupant_id):
			continue
		if not is_enemy_targetable(occupant):
			continue
		return occupant

	for target_row in range(row_index - 1, row_index + 2):
		if target_row < owner.FIRST_BATTLE_ROW or target_row > owner.LAST_BATTLE_ROW:
			continue
		for target_lane in range(lane_index - 1, lane_index + 2):
			if target_lane < 0 or target_lane >= owner.LANE_COUNT:
				continue
			if target_lane == lane_index and target_row == row_index:
				continue
			var occupants: Array = owner.board_state[target_lane][target_row]
			for occupant in occupants:
				var occupant_id: int = int(occupant.get("instance_id", -1))
				if hit_ids.has(occupant_id):
					continue
				if not is_enemy_targetable(occupant):
					continue
				return occupant

	return {}


func get_rows_behind_target(target: Dictionary) -> Array:
	if target.is_empty():
		return []

	var lane_index: int = int(target.get("lane", -1))
	var row_index: int = int(target.get("row", -1))
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return []

	var destinations: Array = []
	for behind_row in range(row_index - 1, owner.FIRST_BATTLE_ROW - 1, -1):
		destinations.append({"lane": lane_index, "row": behind_row})
	return destinations


func get_rows_in_front_of_target(target: Dictionary) -> Array:
	if target.is_empty():
		return []

	var lane_index: int = int(target.get("lane", -1))
	var row_index: int = int(target.get("row", -1))
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return []

	var destinations: Array = []
	for front_row in range(row_index + 1, owner.LAST_BATTLE_ROW + 1):
		destinations.append({"lane": lane_index, "row": front_row})
	return destinations


func get_all_enemies_in_row(row_index: int) -> Array:
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return []

	var enemies: Array = []
	var seen_ids := {}
	for lane_index in range(owner.LANE_COUNT):
		for enemy in owner.board_state[lane_index][row_index]:
			var enemy_id: int = int(enemy.get("instance_id", -1))
			if seen_ids.has(enemy_id):
				continue
			seen_ids[enemy_id] = true
			enemies.append(enemy)
	var wide_boss: Dictionary = _get_wide_boss_covering_tile(0, row_index)
	if not wide_boss.is_empty():
		var wide_boss_id: int = int(wide_boss.get("instance_id", -1))
		if not seen_ids.has(wide_boss_id):
			enemies.append(wide_boss)
	return enemies


func is_row_fully_occupied(row_index: int) -> bool:
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return false
	if not _get_wide_boss_covering_tile(0, row_index).is_empty():
		return true

	for lane_index in range(owner.LANE_COUNT):
		if owner.board_state[lane_index][row_index].is_empty():
			return false
	return true


func _get_wide_boss_covering_tile(lane_index: int, row_index: int) -> Dictionary:
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return {}
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return {}
	for search_lane in range(owner.LANE_COUNT):
		for enemy in owner.board_state[search_lane][row_index]:
			if not enemy.get("traits", []).has("wide_top_3"):
				continue
			return enemy
	return {}


func get_bomb_preview_role(lane_index: int, row_index: int) -> int:
	if owner.selected_skill_id != "bomb":
		return 0
	if owner.selected_lane == -1:
		return 0
	var target: Dictionary = get_front_enemy_in_lane(owner.selected_lane)
	if target.is_empty():
		return 0
	var center_lane: int = int(target.get("lane", -1))
	var center_row: int = int(target.get("row", -1))
	if lane_index == center_lane and row_index == center_row:
		return 2
	var aoe_bonus: int = max(owner.aoe_range_bonus_this_turn, 0)
	var manhattan: int = abs(lane_index - center_lane) + abs(row_index - center_row)
	return 1 if manhattan <= aoe_bonus else 0


func get_sweep_preview_role(lane_index: int, row_index: int) -> int:
	if owner.selected_skill_id != "sweep":
		return 0
	if owner.selected_lane == -1:
		return 0
	var target: Dictionary = get_front_enemy_in_lane(owner.selected_lane)
	if target.is_empty():
		return 0
	var target_row: int = int(target.get("row", -1))
	var aoe_bonus: int = max(owner.aoe_range_bonus_this_turn, 0)
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return 0
	if row_index == target_row:
		return 2
	return 1 if row_index >= target_row - aoe_bonus and row_index <= target_row + aoe_bonus else 0


func get_cross_preview_role(lane_index: int, row_index: int) -> int:
	if owner.selected_skill_id != "cross":
		return 0
	if owner.selected_lane == -1:
		return 0
	var target: Dictionary = get_front_enemy_in_lane(owner.selected_lane)
	if target.is_empty():
		return 0
	var center_lane: int = int(target.get("lane", -1))
	var center_row: int = int(target.get("row", -1))
	if lane_index == center_lane and row_index == center_row:
		return 2
	var aoe_bonus: int = max(owner.aoe_range_bonus_this_turn, 0)
	var row_distance: int = abs(row_index - center_row)
	var lane_distance: int = abs(lane_index - center_lane)
	var manhattan: int = row_distance + lane_distance
	if manhattan <= 1:
		return 1
	return 3 if aoe_bonus > 0 and manhattan <= aoe_bonus + 1 else 0


func damage_enemy(enemy: Dictionary, amount: int, from_damage_card: bool = false) -> void:
	var lane_index: int = int(enemy.get("lane", -1))
	var row_index: int = int(enemy.get("row", -1))
	var traits: Array = enemy.get("traits", [])
	var advance_on_hit: bool = enemy.get("traits", []).has("advance_others_on_hit")
	var applied_amount: int = amount
	if bool(enemy.get("shield_active", false)) and applied_amount > 0:
		enemy["shield_active"] = false
		owner._refresh_tile_ui(lane_index, row_index)
		return
	if from_damage_card and applied_amount > 0 and RUN_STATE.has_relic("sharpness") and applied_amount < 10:
		applied_amount = 10
	if traits.has("damage_cap_10"):
		applied_amount = min(applied_amount, 10)
	enemy["hp"] = max(enemy["hp"] - applied_amount, 0)
	if applied_amount > 0:
		owner._play_combat_sfx("hit")
	if String(enemy.get("move_pattern_id", "")) == "act1_boss_anchor" and applied_amount > 0:
		enemy["skip_attack_this_turn"] = true
	if advance_on_hit:
		_advance_other_enemies_on_hit(int(enemy.get("instance_id", -1)))
	if enemy["hp"] <= 0:
		owner._play_combat_sfx("kill")
		var should_split: bool = enemy.get("traits", []).has("split_on_death")
		var advance_on_death: bool = enemy.get("traits", []).has("advance_others_on_death")
		var revive_by_necro: bool = false
		var linked_twin_id: int = int(enemy.get("linked_twin_id", -1))
		owner.enemy_state.detach_followers_from_host(int(enemy.get("instance_id", -1)))
		owner._remove_enemy_from_tile(enemy, enemy["lane"], enemy["row"])
		if advance_on_death:
			_advance_other_enemies_on_hit(int(enemy.get("instance_id", -1)))
		if linked_twin_id != -1:
			var twin_partner: Dictionary = owner._find_enemy_by_instance_id(linked_twin_id)
			if not twin_partner.is_empty():
				twin_partner["attack"] = 5
				twin_partner["speed"] = 2
				twin_partner["move_pattern_id"] = "straight_2"
				owner._refresh_tile_ui(int(twin_partner.get("lane", -1)), int(twin_partner.get("row", -1)))
		revive_by_necro = _has_enemy_trait_on_field("necromancy_aura") and not bool(enemy.get("revived_by_necro", false))
		if should_split and lane_index >= 0 and row_index >= owner.FIRST_BATTLE_ROW:
			for insert_mode in ["front", "back"]:
				var split_enemy: Dictionary = owner._make_enemy_instance(String(enemy.get("type", "slime")))
				split_enemy["hp"] = 20
				split_enemy["max_hp"] = 20
				split_enemy["attack"] = 1
				split_enemy["icon"] = SLIME_SINGLE_ICON
				split_enemy["traits"] = []
				split_enemy["keywords"] = PackedStringArray(["Slime"])
				owner._add_enemy_to_tile(split_enemy, lane_index, row_index, insert_mode)
		if revive_by_necro and lane_index >= 0 and row_index >= owner.FIRST_BATTLE_ROW:
			var revived_enemy: Dictionary = owner._make_enemy_instance(String(enemy.get("type", "")))
			if not revived_enemy.is_empty():
				revived_enemy["hp"] = 10
				revived_enemy["max_hp"] = max(int(revived_enemy.get("max_hp", 10)), 10)
				revived_enemy["revived_by_necro"] = true
				owner._add_enemy_to_tile(revived_enemy, lane_index, row_index, "back")
	else:
		owner._refresh_tile_ui(enemy["lane"], enemy["row"])


func _advance_other_enemies_on_hit(source_instance_id: int) -> void:
	var moving_targets: Array = []
	for row_idx in range(owner.LAST_BATTLE_ROW, owner.FIRST_BATTLE_ROW - 1, -1):
		for lane_idx in range(owner.LANE_COUNT):
			for occupant in owner.board_state[lane_idx][row_idx]:
				var occupant_id: int = int(occupant.get("instance_id", -1))
				if occupant_id == source_instance_id:
					continue
				moving_targets.append(occupant)

	for enemy in moving_targets:
		if enemy.is_empty():
			continue
		if not owner._enemy_exists(enemy):
			continue
		owner._advance_enemy_one_row(enemy, "front")


func _has_enemy_trait_on_field(trait_id: String) -> bool:
	if trait_id.is_empty():
		return false
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index]:
				if enemy.get("traits", []).has(trait_id):
					return true
	return false


func heal_enemy(enemy: Dictionary, amount: int) -> void:
	if enemy.is_empty():
		return
	if amount <= 0:
		return
	var max_hp: int = int(enemy.get("max_hp", enemy.get("hp", 0)))
	enemy["hp"] = min(int(enemy.get("hp", 0)) + amount, max_hp)
	owner._refresh_tile_ui(int(enemy.get("lane", -1)), int(enemy.get("row", -1)))


func apply_life_damage(amount: int) -> void:
	if amount <= 0:
		return
	owner.life = max(owner.life - amount, 0)
	if owner.RUN_STATE.has_relic("pain_engine"):
		owner.pending_bonus_actions_next_turn += 1
	if owner.life <= 0 and owner.RUN_STATE.has_relic("last_bell") and not owner.RUN_STATE.current_boss_revive_used:
		owner.RUN_STATE.current_boss_revive_used = true
		owner.life = 5
		var all_enemies: Array = []
		for lane_index in range(owner.LANE_COUNT):
			for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
				for enemy in owner.board_state[lane_index][row_index]:
					all_enemies.append(enemy)
		for enemy in all_enemies:
			if enemy.is_empty():
				continue
			if not owner._enemy_exists(enemy):
				continue
			var current_row: int = int(enemy.get("row", owner.FIRST_BATTLE_ROW))
			var new_row: int = max(current_row - 1, owner.FIRST_BATTLE_ROW)
			if new_row == current_row:
				continue
			owner._move_enemy_to_position(enemy, int(enemy.get("lane", -1)), new_row, "front")
	RUN_STATE.set_current_life(owner.life)
	if owner.life <= 0:
		owner._handle_battle_result("Defeat")


func post_action_cleanup() -> void:
	owner.pending_skill_id = ""
	owner.pending_push_target_id = -1
	owner.pending_push_destinations.clear()
	owner.pending_pull_target_id = -1
	owner.pending_pull_destinations.clear()
	owner.pending_retreat_target_id = -1
	owner.pending_retreat_destinations.clear()
	owner._check_wave_clear()
	owner._refresh_ui()


func reduce_cooldowns() -> void:
	for index in range(owner.skills.size()):
		var current_cd: int = int(owner.skills[index].get("current_cd", 0))
		if current_cd > 0:
			owner.skills[index]["current_cd"] = current_cd - 1


func reduce_damage_skill_cooldowns(amount: int) -> bool:
	if amount <= 0:
		return false

	var changed := false
	for index in range(owner.skills.size()):
		var skill: Dictionary = owner.skills[index]
		var category := String(skill.get("category", "")).to_lower()
		if category != "damage" and category != "attack":
			continue
		var current_cd: int = int(skill.get("current_cd", 0))
		if current_cd <= 0:
			continue
		owner.skills[index]["current_cd"] = max(current_cd - amount, 0)
		changed = true

	return changed


func gain_actions_this_turn(amount: int) -> bool:
	return owner.turn_manager.add_actions(amount)


func gain_aoe_range_this_turn(amount: int) -> bool:
	if amount <= 0:
		return false
	owner.aoe_range_bonus_this_turn += amount
	owner._refresh_ui()
	return true


func gain_turret_damage_multiplier_this_turn(multiplier: int) -> bool:
	if multiplier <= 1:
		return false
	owner.turret_damage_multiplier_this_turn *= multiplier
	owner._refresh_ui()
	return true


func begin_pending_cooldown_swap(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	owner.pending_cooldown_swap_active = true
	owner.pending_cooldown_swap_card_id = skill_id
	owner.pending_cooldown_swap_selected_ids.clear()
	owner._refresh_ui()


func apply_pending_cooldown_swap_selection(skill_id: String) -> bool:
	if not owner.pending_cooldown_swap_active:
		return false
	if skill_id.is_empty():
		return false
	if skill_id == owner.pending_cooldown_swap_card_id:
		return false
	if owner.pending_cooldown_swap_selected_ids.has(skill_id):
		return false

	var skill_index: int = owner._get_skill_index(skill_id)
	if skill_index == -1:
		return false

	owner.pending_cooldown_swap_selected_ids.append(skill_id)
	if owner.pending_cooldown_swap_selected_ids.size() < 2:
		owner.selected_skill_id = skill_id
		owner._refresh_ui()
		return true

	var first_id: String = String(owner.pending_cooldown_swap_selected_ids[0])
	var second_id: String = String(owner.pending_cooldown_swap_selected_ids[1])
	var first_index: int = owner._get_skill_index(first_id)
	var second_index: int = owner._get_skill_index(second_id)
	if first_index == -1 or second_index == -1:
		owner.pending_cooldown_swap_active = false
		owner.pending_cooldown_swap_card_id = ""
		owner.pending_cooldown_swap_selected_ids.clear()
		owner._refresh_ui()
		return false

	var first_cd: int = int(owner.skills[first_index].get("current_cd", 0))
	var second_cd: int = int(owner.skills[second_index].get("current_cd", 0))
	owner.skills[first_index]["current_cd"] = second_cd
	owner.skills[second_index]["current_cd"] = first_cd

	var swap_skill_id: String = owner.pending_cooldown_swap_card_id
	var swap_skill: Dictionary = owner._get_skill(swap_skill_id)
	owner._set_skill_current_cooldown(swap_skill_id, owner._get_skill_effective_cooldown(swap_skill))
	if bool(swap_skill.get("consumes_action", true)):
		owner.turn_manager.spend_action(max(int(swap_skill.get("action_cost", 1)), 0))

	owner.pending_cooldown_swap_active = false
	owner.pending_cooldown_swap_card_id = ""
	owner.pending_cooldown_swap_selected_ids.clear()
	owner.selected_skill_id = ""
	post_action_cleanup()
	return true


func on_energy_pressed() -> void:
	if owner.battle_finished:
		return
	owner.open_energy_popup()


func use_energy_for_action() -> bool:
	if owner.battle_finished:
		return false
	if owner.RUN_STATE.has_relic("overcharge"):
		return use_energy_with_overcharge()
	if not owner.turn_manager.consume_energy():
		return false
	owner.turn_manager.add_actions(1)
	owner.close_energy_popup()
	owner._refresh_ui()
	return true


func use_energy_for_selected_cooldown() -> bool:
	if owner.battle_finished:
		return false
	if owner.RUN_STATE.has_relic("overcharge"):
		return use_energy_with_overcharge()
	var selected_skill_id: String = String(owner.selected_skill_id)
	if selected_skill_id.is_empty():
		return false
	var skill_index: int = owner._get_skill_index(selected_skill_id)
	if skill_index == -1:
		return false
	var current_cd: int = int(owner.skills[skill_index].get("current_cd", 0))
	if current_cd <= 0:
		return false
	if not owner.turn_manager.consume_energy():
		return false
	owner.skills[skill_index]["current_cd"] = max(current_cd - 1, 0)
	owner.close_energy_popup()
	owner._refresh_ui()
	return true


func use_energy_with_overcharge() -> bool:
	if owner.battle_finished:
		return false
	if not owner.turn_manager.consume_energy():
		return false
	owner.turn_manager.add_actions(1)
	var selected_skill_id: String = String(owner.selected_skill_id)
	if not selected_skill_id.is_empty():
		var selected_index: int = owner._get_skill_index(selected_skill_id)
		if selected_index != -1:
			var selected_cd: int = int(owner.skills[selected_index].get("current_cd", 0))
			if selected_cd > 0:
				owner.skills[selected_index]["current_cd"] = max(selected_cd - 1, 0)
				owner.pending_energy_mode = ""
				owner.pending_energy_prepaid = false
				owner.close_energy_popup()
				owner._refresh_ui()
				return true

	owner.pending_energy_mode = "reduce_cd"
	owner.pending_energy_prepaid = true
	if owner.energy_overlay != null:
		owner.energy_overlay.visible = false
	owner._refresh_ui()
	return true


func apply_pending_energy_reduce_cd(skill_id: String) -> bool:
	if owner.battle_finished:
		return false
	if owner.pending_energy_mode != "reduce_cd":
		return false
	if not owner.pending_energy_prepaid and not owner.turn_manager.can_use_energy():
		owner.pending_energy_mode = ""
		owner.pending_energy_prepaid = false
		owner._refresh_ui()
		return false
	var skill_index: int = owner._get_skill_index(skill_id)
	if skill_index == -1:
		return false
	var current_cd: int = int(owner.skills[skill_index].get("current_cd", 0))
	if current_cd <= 0:
		owner.selected_skill_id = skill_id
		owner._refresh_ui()
		return false
	if not owner.pending_energy_prepaid and not owner.turn_manager.consume_energy():
		return false
	owner.skills[skill_index]["current_cd"] = max(current_cd - 1, 0)
	owner.pending_energy_mode = ""
	owner.pending_energy_prepaid = false
	owner.selected_skill_id = skill_id
	owner._refresh_ui()
	return true


func on_end_turn_pressed() -> void:
	if owner.battle_finished:
		return
	var unused_actions: int = owner.turn_manager.get_actions_left()
	owner.pending_skill_id = ""
	owner.pending_push_target_id = -1
	owner.pending_push_destinations.clear()
	owner.pending_pull_target_id = -1
	owner.pending_pull_destinations.clear()
	owner.pending_retreat_target_id = -1
	owner.pending_retreat_destinations.clear()
	owner.pending_structure_move_source.clear()
	owner.pending_structure_move_destinations.clear()
	owner.pending_energy_mode = ""
	owner.pending_energy_prepaid = false
	process_plague_end_turn()
	process_structures_turn()
	owner._run_enemy_movement()
	process_delayed_strikes_end_turn()
	if owner.wave_turns_remaining > 0:
		owner.wave_turns_remaining -= 1
	reduce_cooldowns()
	if owner.RUN_STATE.has_relic("reserve") and unused_actions > 0:
		for _i in range(unused_actions):
			reduce_cooldowns()
	owner.aoe_range_bonus_this_turn = 0
	owner.turret_damage_multiplier_this_turn = 1
	owner.turn_manager.begin_next_turn()
	owner._reset_discipline_lock()
	if owner.pending_bonus_actions_next_turn > 0:
		owner.turn_manager.add_actions(owner.pending_bonus_actions_next_turn)
		owner.pending_bonus_actions_next_turn = 0
	owner.wave_flow.advance_wave_on_timeout()
	owner._fill_preview_tiles()
	owner._check_wave_clear()
	owner._refresh_ui()


func process_delayed_strikes_end_turn() -> void:
	var remaining: Array = []
	for strike in owner.pending_delayed_strikes:
		var turns_remaining: int = int(strike.get("turns_remaining", 0)) - 1
		if turns_remaining > 0:
			strike["turns_remaining"] = turns_remaining
			remaining.append(strike)
			continue
		var lane_index: int = int(strike.get("lane", -1))
		var row_index: int = int(strike.get("row", -1))
		var damage: int = int(strike.get("damage", 30))
		if lane_index < 0 or lane_index >= owner.LANE_COUNT:
			continue
		if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
			continue
		for enemy in owner.board_state[lane_index][row_index].duplicate():
			damage_enemy(enemy, damage)
	owner.pending_delayed_strikes = remaining


func process_plague_end_turn() -> void:
	var to_refresh := {}
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index].duplicate():
				if not bool(enemy.get("plague_active", false)):
					continue
				if bool(enemy.get("plague_pending", false)):
					continue
				var plague_damage: int = int(enemy.get("plague_damage", 0))
				if plague_damage <= 0:
					continue
				damage_enemy(enemy, plague_damage)
				if owner._enemy_exists(enemy):
					enemy["plague_damage"] = plague_damage + 3
					to_refresh["%d_%d" % [int(enemy.get("lane", -1)), int(enemy.get("row", -1))]] = {
						"lane": int(enemy.get("lane", -1)),
						"row": int(enemy.get("row", -1)),
					}

	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index]:
				if bool(enemy.get("plague_active", false)) and bool(enemy.get("plague_pending", false)):
					enemy["plague_pending"] = false
					to_refresh["%d_%d" % [lane_index, row_index]] = {"lane": lane_index, "row": row_index}

	for tile_info in to_refresh.values():
		owner._refresh_tile_ui(int(tile_info.get("lane", -1)), int(tile_info.get("row", -1)))


func process_structures_turn() -> void:
	var turret_bonus := get_turret_bonus_damage()
	var turret_multiplier: int = max(int(owner.turret_damage_multiplier_this_turn), 1)
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			var structure = owner._get_structure_in_tile(lane_index, row_index)
			if structure == null:
				continue
			var structure_id := String(structure.get("id", ""))
			match structure_id:
				"turret":
					var target: Dictionary = get_front_enemy_in_lane(lane_index)
					if target.is_empty():
						continue
					owner._play_projectile_from_structure(lane_index, row_index, target, Color(0.92, 0.54, 1.0, 0.96))
					var turret_damage: int = (int(structure.get("attack", 0)) + turret_bonus) * turret_multiplier
					damage_enemy(target, turret_damage)
				"aim_turret":
					var target: Dictionary = get_front_enemy_in_lane(lane_index)
					if target.is_empty():
						structure["focus_stacks"] = 0
						structure["last_target_id"] = -1
						owner.board_structures[lane_index][row_index] = structure
						continue
					var target_id: int = int(target.get("instance_id", -1))
					var focus_stacks: int = int(structure.get("focus_stacks", 0))
					if int(structure.get("last_target_id", -1)) == target_id:
						focus_stacks += 1
					else:
						focus_stacks = 0
					structure["focus_stacks"] = focus_stacks
					structure["last_target_id"] = target_id
					owner.board_structures[lane_index][row_index] = structure
					owner._play_projectile_from_structure(lane_index, row_index, target, Color(1.0, 0.62, 0.96, 0.98))
					var aim_damage: int = (int(structure.get("attack", 0)) + turret_bonus + int(structure.get("focus_bonus", 0)) * focus_stacks) * turret_multiplier
					damage_enemy(
						target,
						aim_damage
					)
				"rapid_turret":
					var rapid_shots: int = max(int(structure.get("shots", 3)), 1)
					for _i in range(rapid_shots):
						var target: Dictionary = get_front_enemy_in_lane(lane_index)
						if target.is_empty():
							break
						owner._play_projectile_from_structure(lane_index, row_index, target, Color(1.0, 0.68, 0.98, 0.98))
						var rapid_damage: int = (int(structure.get("attack", 0)) + turret_bonus) * turret_multiplier
						damage_enemy(target, rapid_damage)
				"pierce_turret":
					var row_targets: Array = []
					for target_row in range(owner.LAST_BATTLE_ROW, owner.FIRST_BATTLE_ROW - 1, -1):
						for enemy in owner.board_state[lane_index][target_row]:
							if int(enemy.get("attached_host_id", -1)) != -1:
								continue
							row_targets.append(enemy)
					if row_targets.is_empty():
						continue
					for enemy in row_targets:
						owner._play_projectile_from_structure(lane_index, row_index, enemy, Color(0.98, 0.62, 1.0, 0.96))
						var pierce_damage: int = (int(structure.get("attack", 0)) + turret_bonus) * turret_multiplier
						damage_enemy(enemy, pierce_damage)


func get_turret_bonus_damage() -> int:
	var bonus := 0
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			var structure = owner._get_structure_in_tile(lane_index, row_index)
			if structure == null:
				continue
			if String(structure.get("id", "")) != "boost_turret":
				continue
			bonus += int(structure.get("bonus_damage", 0)) * int(structure.get("stacks", 1))
	return bonus


func resolve_pending_skill_on_tile(lane_index: int, row_index: int) -> bool:
	if owner.pending_skill_id == "push":
		if resolve_push_to(lane_index, row_index):
			var push_skill: Dictionary = owner._get_skill("push")
			owner._process_skill_counters_on_use(push_skill)
			owner._process_card_use_relics()
			owner._set_skill_current_cooldown("push", owner._get_skill_effective_cooldown(push_skill))
			owner.turn_manager.spend_action(max(int(push_skill.get("action_cost", 1)), 0))
			post_action_cleanup()
			return true
	elif owner.pending_skill_id == "pull_forward":
		if resolve_pull_forward_to(lane_index, row_index):
			var hook_skill: Dictionary = owner._get_skill("hook")
			owner._process_skill_counters_on_use(hook_skill)
			owner._process_card_use_relics()
			owner._set_skill_current_cooldown("hook", owner._get_skill_effective_cooldown(hook_skill))
			owner.turn_manager.spend_action(max(int(hook_skill.get("action_cost", 1)), 0))
			post_action_cleanup()
			return true
	elif owner.pending_skill_id == "retreat":
		if resolve_retreat_to(lane_index, row_index):
			var retreat_skill: Dictionary = owner._get_skill("retreat")
			owner._process_skill_counters_on_use(retreat_skill)
			owner._process_card_use_relics()
			owner._set_skill_current_cooldown("retreat", owner._get_skill_effective_cooldown(retreat_skill))
			owner.turn_manager.spend_action(max(int(retreat_skill.get("action_cost", 1)), 0))
			post_action_cleanup()
			return true

	return false


func resolve_bomb_at(lane_index: int, row_index: int) -> bool:
	if row_index < owner.FIRST_BATTLE_ROW:
		return false

	var center_target: Dictionary = get_front_enemy_in_tile(lane_index, row_index)
	if center_target.is_empty():
		return false

	var skill: Dictionary = owner._get_skill("bomb")
	var bonus: int = owner._peek_next_damage_card_bonus()
	var damage: int = int(skill.get("values", {}).get("damage", 10)) + bonus
	var affected_ids := {}
	var aoe_bonus: int = max(owner.aoe_range_bonus_this_turn, 0)
	for target_row in range(row_index - aoe_bonus, row_index + aoe_bonus + 1):
		if target_row < owner.FIRST_BATTLE_ROW or target_row > owner.LAST_BATTLE_ROW:
			continue
		for target_lane in range(lane_index - aoe_bonus, lane_index + aoe_bonus + 1):
			if target_lane < 0 or target_lane >= owner.LANE_COUNT:
				continue
			var manhattan: int = abs(target_lane - lane_index) + abs(target_row - row_index)
			if manhattan > aoe_bonus:
				continue
			for enemy in owner.board_state[target_lane][target_row].duplicate():
				var enemy_id: int = int(enemy.get("instance_id", -1))
				if affected_ids.has(enemy_id):
					continue
				affected_ids[enemy_id] = true
				damage_enemy(enemy, damage)
	if not affected_ids.is_empty() and bonus > 0:
		owner._consume_next_damage_card_bonus()
	return true


func resolve_cross_at(lane_index: int, row_index: int) -> bool:
	if row_index < owner.FIRST_BATTLE_ROW:
		return false

	var center_target: Dictionary = get_front_enemy_in_tile(lane_index, row_index)
	if center_target.is_empty():
		return false

	var skill: Dictionary = owner._get_skill("cross")
	var values: Dictionary = skill.get("values", {})
	var bonus: int = owner._peek_next_damage_card_bonus()
	var damage: int = int(values.get("damage", 8)) + bonus
	var full_damage: int = int(values.get("full_damage", 25)) + bonus
	var threshold: int = int(values.get("threshold", 3))
	var aoe_bonus: int = max(owner.aoe_range_bonus_this_turn, 0)
	var affected_targets: Array = []
	var affected_ids := {}
	var max_manhattan: int = aoe_bonus + 1
	for target_row in range(row_index - max_manhattan, row_index + max_manhattan + 1):
		if target_row < owner.FIRST_BATTLE_ROW or target_row > owner.LAST_BATTLE_ROW:
			continue
		for target_lane in range(lane_index - max_manhattan, lane_index + max_manhattan + 1):
			if target_lane < 0 or target_lane >= owner.LANE_COUNT:
				continue
			var manhattan: int = abs(target_lane - lane_index) + abs(target_row - row_index)
			if manhattan > max_manhattan:
				continue
			for enemy in owner.board_state[target_lane][target_row].duplicate():
				var enemy_id: int = int(enemy.get("instance_id", -1))
				if affected_ids.has(enemy_id):
					continue
				affected_ids[enemy_id] = true
				affected_targets.append(enemy)

	if affected_targets.is_empty():
		return false

	var applied_damage := full_damage if affected_targets.size() >= threshold else damage
	for enemy in affected_targets:
		damage_enemy(enemy, applied_damage)
	if bonus > 0:
		owner._consume_next_damage_card_bonus()
	return true


func resolve_push_to(lane_index: int, row_index: int) -> bool:
	if row_index == owner.PREVIEW_ROW:
		return false

	var destination: Dictionary = get_pending_push_destination_for_lane(lane_index)
	if destination.is_empty():
		return false

	var target: Dictionary = owner._find_enemy_by_instance_id(owner.pending_push_target_id)
	if target.is_empty():
		return false

	var source_lane: int = int(target.get("lane", -1))
	var source_row: int = int(target.get("row", -1))
	owner._move_enemy_to_position(target, int(destination["lane"]), int(destination["row"]), "back")
	owner._play_control_move_impact(source_lane, source_row, int(destination["lane"]), int(destination["row"]))
	owner._play_combat_sfx("push")
	return true


func resolve_push_from_keyboard(lane_index: int) -> bool:
	var destination: Dictionary = get_pending_push_destination_for_lane(lane_index)
	if destination.is_empty():
		return false

	var target: Dictionary = owner._find_enemy_by_instance_id(owner.pending_push_target_id)
	if target.is_empty():
		return false

	var source_lane: int = int(target.get("lane", -1))
	var source_row: int = int(target.get("row", -1))
	owner._move_enemy_to_position(target, int(destination["lane"]), int(destination["row"]), "back")
	owner._play_control_move_impact(source_lane, source_row, int(destination["lane"]), int(destination["row"]))
	owner._play_combat_sfx("push")
	return true


func resolve_pull_forward_to(lane_index: int, row_index: int) -> bool:
	var destination: Dictionary = get_pending_pull_destination(lane_index, row_index)
	if destination.is_empty():
		return false

	var target: Dictionary = owner._find_enemy_by_instance_id(owner.pending_pull_target_id)
	if target.is_empty():
		return false

	var source_lane: int = int(target.get("lane", -1))
	var source_row: int = int(target.get("row", -1))
	owner._move_enemy_to_position(target, int(destination["lane"]), int(destination["row"]), "back")
	owner._play_control_move_impact(source_lane, source_row, int(destination["lane"]), int(destination["row"]))
	owner._play_combat_sfx("push")
	return true


func resolve_retreat_to(lane_index: int, row_index: int) -> bool:
	var destination: Dictionary = get_pending_retreat_destination(lane_index, row_index)
	if destination.is_empty():
		return false

	var target: Dictionary = owner._find_enemy_by_instance_id(owner.pending_retreat_target_id)
	if target.is_empty():
		return false

	var source_lane: int = int(target.get("lane", -1))
	var source_row: int = int(target.get("row", -1))
	owner._move_enemy_to_position(target, int(destination["lane"]), int(destination["row"]), "back")
	owner._play_control_move_impact(source_lane, source_row, int(destination["lane"]), int(destination["row"]))
	owner._play_combat_sfx("push")
	return true


func resolve_structure_move_to(lane_index: int, row_index: int) -> bool:
	var source: Dictionary = owner.pending_structure_move_source
	if source.is_empty():
		return false
	if not is_pending_structure_move_destination(lane_index, row_index):
		return false
	return owner._move_structure_to(
		int(source.get("lane", -1)),
		int(source.get("row", -1)),
		lane_index,
		row_index
	)


func retreat_all_enemies_one_row() -> bool:
	var moved := false
	var moving_targets: Array = []
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index]:
				moving_targets.append({
					"instance_id": int(enemy.get("instance_id", -1)),
					"lane": lane_index,
					"row": row_index,
				})

	for target_info in moving_targets:
		var enemy: Dictionary = owner._find_enemy_by_instance_id(int(target_info.get("instance_id", -1)))
		if enemy.is_empty():
			continue
		if enemy.get("traits", []).has("control_immune"):
			continue
		var row_index: int = int(enemy.get("row", -1))
		if row_index <= owner.FIRST_BATTLE_ROW:
			continue
		owner._move_enemy_to_position(
			enemy,
			int(enemy.get("lane", -1)),
			row_index - 1,
			"front"
		)
		moved = true
	if moved:
		owner._play_combat_sfx("push")
	return moved


func is_pending_push_destination(lane_index: int, row_index: int) -> bool:
	for destination in owner.pending_push_destinations:
		if int(destination["lane"]) == lane_index and int(destination["row"]) == row_index:
			return true
	return false


func is_pending_retreat_destination(lane_index: int, row_index: int) -> bool:
	for destination in owner.pending_retreat_destinations:
		if int(destination["lane"]) == lane_index and int(destination["row"]) == row_index:
			return true
	return false


func is_pending_pull_destination(lane_index: int, row_index: int) -> bool:
	for destination in owner.pending_pull_destinations:
		if int(destination["lane"]) == lane_index and int(destination["row"]) == row_index:
			return true
	return false


func is_pending_structure_move_source(lane_index: int, row_index: int) -> bool:
	return int(owner.pending_structure_move_source.get("lane", -1)) == lane_index and int(owner.pending_structure_move_source.get("row", -1)) == row_index


func is_pending_structure_move_destination(lane_index: int, row_index: int) -> bool:
	for destination in owner.pending_structure_move_destinations:
		if int(destination.get("lane", -1)) == lane_index and int(destination.get("row", -1)) == row_index:
			return true
	return false


func is_pending_push_lane(lane_index: int) -> bool:
	for destination in owner.pending_push_destinations:
		if int(destination["lane"]) == lane_index:
			return true
	return false


func get_pending_push_destination_for_lane(lane_index: int) -> Dictionary:
	for destination in owner.pending_push_destinations:
		if int(destination["lane"]) == lane_index:
			return destination
	return {}


func get_pending_retreat_destination(lane_index: int, row_index: int) -> Dictionary:
	for destination in owner.pending_retreat_destinations:
		if int(destination["lane"]) == lane_index and int(destination["row"]) == row_index:
			return destination
	return {}


func get_pending_pull_destination(lane_index: int, row_index: int) -> Dictionary:
	for destination in owner.pending_pull_destinations:
		if int(destination["lane"]) == lane_index and int(destination["row"]) == row_index:
			return destination
	return {}
