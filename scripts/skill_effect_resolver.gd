extends RefCounted
class_name SkillEffectResolver

const SKILL_CATALOG = preload("res://scripts/skill_catalog.gd")


static func resolve_skill(battle: Control, skill: Dictionary) -> bool:
	var effect_key: String = String(skill.get("effect_key", skill.get("id", "")))
	match effect_key:
		"bullet":
			return _resolve_bullet(battle, skill)
		"burst_fire":
			return _resolve_burst_fire(battle, skill)
		"blood_blade":
			return _resolve_blood_blade(battle, skill)
		"crescendo":
			return _resolve_crescendo(battle, skill)
		"bomb":
			return _resolve_bomb(battle, skill)
		"cross_blast":
			return _resolve_cross_blast(battle, skill)
		"excalibur":
			return _resolve_excalibur(battle, skill)
		"smite":
			return _resolve_smite(battle, skill)
		"shuriken":
			return _resolve_shuriken(battle, skill)
		"plague":
			return _resolve_plague(battle, skill)
		"forecast":
			return _resolve_forecast(battle, skill)
		"combo":
			return _resolve_combo(battle, skill)
		"combo_stack":
			return _resolve_combo_stack(battle, skill)
		"install_wall":
			return _resolve_install_wall(battle, skill)
		"install_mine":
			return _resolve_install_mine(battle, skill)
		"install_turret":
			return _resolve_install_turret(battle, skill)
		"install_aim_turret":
			return _resolve_install_aim_turret(battle, skill)
		"install_rapid_turret":
			return _resolve_install_rapid_turret(battle, skill)
		"install_boost_turret":
			return _resolve_install_boost_turret(battle, skill)
		"install_pierce_turret":
			return _resolve_install_pierce_turret(battle, skill)
		"grant_structure_shield":
			return _resolve_grant_structure_shield(battle, skill)
		"back_shot":
			return _resolve_back_shot(battle, skill)
		"gain_action":
			return _resolve_gain_action(battle, skill)
		"gamble":
			return _resolve_gamble(battle, skill)
		"expand_aoe":
			return _resolve_expand_aoe(battle, skill)
		"double_mines":
			return _resolve_double_mines(battle, skill)
		"turret_amplify":
			return _resolve_turret_amplify(battle, skill)
		"swap_cooldowns":
			return _resolve_swap_cooldowns(battle, skill)
		"scare":
			return _resolve_scare(battle, skill)
		"refresh_damage":
			return _resolve_refresh_damage(battle, skill)
		"retreat":
			return _resolve_retreat(battle)
		"tsunami":
			return _resolve_tsunami(battle)
		"pull_forward":
			return _resolve_pull_forward(battle)
		"grab":
			return _resolve_grab(battle)
		"send_to_back":
			return _resolve_send_to_back(battle)
		"sweep":
			return _resolve_sweep(battle, skill)
		"push_side":
			return _resolve_push_side(battle)
		"move_structure":
			return _resolve_move_structure(battle)
		"pull":
			return _resolve_pull(battle)
		_:
			return false


static func _get_pending_damage_card_bonus(battle: Control, skill: Dictionary) -> int:
	if String(skill.get("category", "")) != "damage":
		return 0
	return int(battle._peek_next_damage_card_bonus()) + int(battle._get_same_card_damage_bonus(skill))


static func _consume_damage_card_bonus_if_needed(battle: Control, bonus: int) -> void:
	if bonus <= 0:
		return
	battle._consume_next_damage_card_bonus()


static func _is_control_immune(target: Dictionary) -> bool:
	return target.get("traits", []).has("control_immune")


static func _resolve_bullet(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = int(values.get("damage", 15)) + bonus
	battle._damage_enemy_from_card(target, damage)
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_blood_blade(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var base_damage: int = int(values.get("damage", 10))
	var lost_life: int = max(int(battle._get_effective_max_life()) - int(battle.life), 0)
	var bonus_damage: int = lost_life * int(values.get("lost_life_multiplier", 3))
	battle._damage_enemy_from_card(target, base_damage + bonus_damage + bonus)
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_crescendo(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var cycle_hit: int = int(values.get("cycle_hit", 3))
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var base_damage: int = int(values.get("damage", 5))
	var burst_damage: int = int(values.get("burst_damage", 30))
	var cycle_count: int = battle._advance_skill_cycle(String(skill.get("id", "")), cycle_hit)
	var damage: int = (burst_damage if cycle_count >= cycle_hit else base_damage) + bonus
	battle._damage_enemy_from_card(target, damage)
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_burst_fire(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = int(values.get("damage", 5)) + bonus
	var hit_count: int = int(values.get("hit_count", 3))
	var hit_any := false

	for _i in range(hit_count):
		var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
		if target.is_empty():
			break
		battle._damage_enemy_from_card(target, damage)
		hit_any = true

	if hit_any:
		_consume_damage_card_bonus_if_needed(battle, bonus)
	return hit_any


static func _resolve_bomb(battle: Control, _skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	return battle._resolve_bomb_at(int(target["lane"]), int(target["row"]))


static func _resolve_cross_blast(battle: Control, _skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	return battle._resolve_cross_at(int(target["lane"]), int(target["row"]))


static func _resolve_excalibur(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var lane_index: int = battle.selected_lane
	var targets: Array = []
	var target_ids := {}
	var every_tile_has_enemy := true
	for row_index in range(battle.FIRST_BATTLE_ROW, battle.LAST_BATTLE_ROW + 1):
		var tile_target: Dictionary = battle._get_front_enemy_in_tile(lane_index, row_index)
		var occupants: Array = battle.board_state[lane_index][row_index]
		if occupants.is_empty() and tile_target.is_empty():
			every_tile_has_enemy = false
		for enemy in occupants.duplicate():
			var enemy_id: int = int(enemy.get("instance_id", -1))
			if target_ids.has(enemy_id):
				continue
			target_ids[enemy_id] = true
			targets.append(enemy)
		if not tile_target.is_empty():
			var tile_target_id: int = int(tile_target.get("instance_id", -1))
			if not target_ids.has(tile_target_id):
				target_ids[tile_target_id] = true
				targets.append(tile_target)

	if targets.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = int(values.get("damage", 15)) + bonus
	var dealt_damage := false
	if every_tile_has_enemy:
		for enemy in targets:
			if battle._enemy_exists(enemy):
				battle._damage_enemy_from_card(enemy, int(enemy.get("hp", 0)) + 9999)
				dealt_damage = true
	else:
		for enemy in targets:
			if battle._enemy_exists(enemy):
				battle._damage_enemy_from_card(enemy, damage)
				dealt_damage = true

	if dealt_damage:
		_consume_damage_card_bonus_if_needed(battle, bonus)
	return dealt_damage


static func _resolve_smite(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = int(values.get("damage", 15)) + bonus
	var stun_turns: int = int(values.get("stun_turns", 1))
	battle._damage_enemy_from_card(target, damage)
	if battle._enemy_exists(target):
		target["stun_turns"] = max(int(target.get("stun_turns", 0)), stun_turns)
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_shuriken(battle: Control, skill: Dictionary) -> bool:
	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = int(values.get("damage", 8)) + bonus
	var hit_any := false
	for lane_index in range(battle.LANE_COUNT):
		var target: Dictionary = battle._get_front_enemy_in_lane(lane_index)
		if target.is_empty():
			continue
		battle._damage_enemy_from_card(target, damage)
		hit_any = true
	if hit_any:
		_consume_damage_card_bonus_if_needed(battle, bonus)
	return hit_any


static func _resolve_plague(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if bool(target.get("plague_active", false)):
		return false

	var values: Dictionary = skill.get("values", {})
	var plague_damage: int = int(values.get("plague_damage", 3))
	target["plague_active"] = true
	target["plague_damage"] = plague_damage
	target["plague_pending"] = false
	battle._refresh_tile_ui(int(target.get("lane", -1)), int(target.get("row", -1)))
	return true


static func _resolve_forecast(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1 or battle.selected_row == -1:
		return false
	var values: Dictionary = skill.get("values", {})
	battle.pending_delayed_strikes.append({
		"lane": battle.selected_lane,
		"row": battle.selected_row,
		"turns_remaining": int(values.get("delay_turns", 3)),
		"damage": int(values.get("damage", 30)),
	})
	return true


static func _resolve_install_wall(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"wall",
		"Wall",
		Color(0.58, 0.38, 0.74, 1.0)
	)


static func _resolve_install_mine(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"mine",
		"Mine",
		Color(0.76, 0.48, 0.86, 1.0)
	)


static func _resolve_install_turret(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"turret",
		"Turret",
		Color(0.74, 0.42, 0.88, 1.0)
	)


static func _resolve_install_aim_turret(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"aim_turret",
		"Aim Turret",
		Color(0.92, 0.48, 0.9, 1.0)
	)


static func _resolve_install_rapid_turret(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"rapid_turret",
		"Rapid Turret",
		Color(0.96, 0.54, 0.98, 1.0)
	)


static func _resolve_install_pierce_turret(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"pierce_turret",
		"Pierce Turret",
		Color(0.86, 0.46, 0.98, 1.0)
	)


static func _resolve_install_boost_turret(battle: Control, skill: Dictionary) -> bool:
	return _resolve_install_structure(
		battle,
		skill,
		"boost_turret",
		"Boost Turret",
		Color(0.7, 0.3, 0.9, 1.0)
	)


static func _resolve_grant_structure_shield(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1 or battle.selected_row == -1:
		return false
	var structure = battle._get_structure_in_tile(battle.selected_lane, battle.selected_row)
	if structure == null:
		return false
	if int(structure.get("shield_hits", 0)) > 0:
		return false
	var values: Dictionary = skill.get("values", {})
	structure["shield_hits"] = max(int(values.get("shield_hits", 1)), 1)
	battle.board_structures[battle.selected_lane][battle.selected_row] = structure
	battle._refresh_tile_ui(battle.selected_lane, battle.selected_row)
	return true


static func _resolve_gamble(battle: Control, skill: Dictionary) -> bool:
	var current_skill_id: String = String(skill.get("id", ""))
	if current_skill_id.is_empty():
		return false

	var candidate_ids: Array[String] = []
	for skill_id in SKILL_CATALOG.all_skill_ids():
		if skill_id == current_skill_id:
			continue
		var candidate: Dictionary = SKILL_CATALOG.get_skill(skill_id)
		if String(candidate.get("category", "")) != "damage":
			continue
		candidate_ids.append(skill_id)

	if candidate_ids.is_empty():
		return false

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chosen_id: String = candidate_ids[rng.randi_range(0, candidate_ids.size() - 1)]
	var chosen_skill: Dictionary = SKILL_CATALOG.get_skill(chosen_id)
	if chosen_skill.is_empty():
		return false

	var skill_index: int = battle._get_skill_index(current_skill_id)
	if skill_index == -1:
		return false

	var transformed_skill: Dictionary = chosen_skill.duplicate(true)
	transformed_skill["id"] = current_skill_id
	transformed_skill["name"] = String(chosen_skill.get("name", "Gamble"))
	transformed_skill["current_cd"] = 0
	transformed_skill["transformed_from"] = "gamble"
	transformed_skill["transformed_skill_id"] = chosen_id
	battle.skills[skill_index] = transformed_skill
	battle.selected_skill_id = current_skill_id
	battle._refresh_ui()
	return true


static func _resolve_install_structure(
	battle: Control,
	skill: Dictionary,
	structure_id: String,
	structure_name: String,
	structure_color: Color
) -> bool:
	if battle.selected_lane == -1 or battle.selected_row == -1:
		return false
	if not battle._can_install_structure_at(battle.selected_lane, battle.selected_row, structure_id):
		return false

	var values: Dictionary = skill.get("values", {})
	var hp: int = int(values.get("hp", 4))
	hp += battle._get_module_structure_hp_bonus(skill)
	var attack: int = int(values.get("attack", 0))
	var max_stacks: int = int(values.get("max_stacks", 1))
	var bonus_damage: int = int(values.get("bonus_damage", 0))
	var focus_bonus: int = int(values.get("focus_bonus", 0))
	if battle.RUN_STATE.has_relic("barricade"):
		hp *= 2
	var structure := {
		"id": structure_id,
		"name": structure_name,
		"hp": hp,
		"max_hp": hp,
		"attack": attack,
		"bonus_damage": bonus_damage,
		"focus_bonus": focus_bonus,
		"focus_stacks": 0,
		"last_target_id": -1,
		"shield_hits": 0,
		"stacks": 1,
		"max_stacks": max_stacks,
		"color": structure_color,
	}
	var installed: bool = battle._install_structure(battle.selected_lane, battle.selected_row, structure)
	if installed:
		battle._play_combat_sfx("install")
	return installed


static func _resolve_combo(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var start_target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if start_target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var base_damage: int = int(values.get("damage", 8)) + bonus
	var bonus_per_link: int = int(values.get("combo_bonus", 5))
	var current_target: Dictionary = start_target
	var hit_ids := {}
	var chain_targets: Array = []

	while not current_target.is_empty():
		var instance_id: int = int(current_target.get("instance_id", -1))
		if hit_ids.has(instance_id):
			break

		hit_ids[instance_id] = true
		chain_targets.append({
			"instance_id": instance_id,
			"lane": int(current_target.get("lane", -1)),
			"row": int(current_target.get("row", -1)),
			"stack_index": battle._get_enemy_stack_index(current_target),
		})
		current_target = battle._get_next_combo_target(current_target, hit_ids)

	battle._play_combo_sequence(chain_targets, base_damage, bonus_per_link)
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_combo_stack(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var stack_count: int = battle._get_skill_counter(String(skill.get("id", "")))
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = stack_count * int(values.get("damage_per_stack", 3)) + bonus
	battle._damage_enemy_from_card(target, damage)
	battle._consume_skill_counter(String(skill.get("id", "")))
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_back_shot(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var main_damage: int = int(values.get("damage", 8)) + bonus
	var rear_damage: int = int(values.get("rear_damage", 20)) + bonus
	var rear_target: Dictionary = battle._get_closest_enemy_behind(target)

	if not rear_target.is_empty():
		battle._damage_enemy_from_card(rear_target, rear_damage)
		_consume_damage_card_bonus_if_needed(battle, bonus)
		return true

	battle._damage_enemy_from_card(target, main_damage)
	_consume_damage_card_bonus_if_needed(battle, bonus)
	return true


static func _resolve_gain_action(battle: Control, skill: Dictionary) -> bool:
	var values: Dictionary = skill.get("values", {})
	var extra_actions: int = int(values.get("extra_actions", 1))
	return battle._gain_actions_this_turn(extra_actions)


static func _resolve_expand_aoe(battle: Control, skill: Dictionary) -> bool:
	var values: Dictionary = skill.get("values", {})
	var aoe_bonus: int = int(values.get("aoe_bonus", 1))
	return battle._gain_aoe_range_this_turn(aoe_bonus)


static func _resolve_double_mines(battle: Control, _skill: Dictionary) -> bool:
	return battle._double_all_mines()


static func _resolve_turret_amplify(battle: Control, skill: Dictionary) -> bool:
	var values: Dictionary = skill.get("values", {})
	var multiplier: int = max(int(values.get("multiplier", 2)), 1)
	return battle._gain_turret_damage_multiplier_this_turn(multiplier)


static func _resolve_swap_cooldowns(battle: Control, skill: Dictionary) -> bool:
	battle._begin_pending_cooldown_swap(String(skill.get("id", "")))
	return false


static func _resolve_scare(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false
	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if _is_control_immune(target):
		return false
	var values: Dictionary = skill.get("values", {})
	var turns: int = int(values.get("reverse_turns", 2))
	target["reverse_move_turns"] = max(int(target.get("reverse_move_turns", 0)), turns)
	target["reverse_move_pending"] = true
	return true


static func _resolve_refresh_damage(battle: Control, skill: Dictionary) -> bool:
	var values: Dictionary = skill.get("values", {})
	var cooldown_reduction: int = int(values.get("cooldown_reduction", 1))
	return battle._reduce_damage_skill_cooldowns(cooldown_reduction)


static func _resolve_retreat(battle: Control) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if _is_control_immune(target):
		return false

	var target_row: int = int(target.get("row", -1))
	if target_row <= battle.FIRST_BATTLE_ROW:
		return false

	var source_lane: int = int(target.get("lane", -1))
	var source_row: int = target_row
	battle._move_enemy_to_row(target, target_row - 1, "back")
	battle._play_control_move_impact(source_lane, source_row, source_lane, target_row - 1)
	battle._play_combat_sfx("push")
	return true


static func _resolve_tsunami(battle: Control) -> bool:
	battle._play_tsunami_effect()
	return battle._retreat_all_enemies_one_row()


static func _resolve_pull_forward(battle: Control) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if _is_control_immune(target):
		return false

	var destinations: Array = battle._get_rows_in_front_of_target(target)
	if destinations.is_empty():
		return false

	battle.pending_skill_id = "pull_forward"
	battle.pending_pull_target_id = int(target["instance_id"])
	battle.pending_pull_destinations = destinations
	battle._refresh_ui()
	return false


static func _resolve_grab(battle: Control) -> bool:
	if battle.selected_lane == -1:
		return false

	var back_target: Dictionary = battle._get_back_enemy_in_lane(battle.selected_lane)
	if back_target.is_empty():
		return false
	if _is_control_immune(back_target):
		return false

	var front_target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if front_target.is_empty():
		return false

	var lane_index: int = int(front_target.get("lane", -1))
	var row_index: int = int(front_target.get("row", -1))
	if lane_index < 0 or row_index < battle.FIRST_BATTLE_ROW:
		return false

	var source_lane: int = int(back_target.get("lane", -1))
	var source_row: int = int(back_target.get("row", -1))
	battle._move_enemy_to_position(back_target, lane_index, row_index, "front")
	battle._play_control_move_impact(source_lane, source_row, lane_index, row_index)
	battle._play_combat_sfx("push")
	return true


static func _resolve_send_to_back(battle: Control) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if _is_control_immune(target):
		return false

	var lane_index: int = int(target["lane"])
	var row_index: int = int(target["row"])
	battle._move_enemy_to_position(target, lane_index, row_index, "back")
	battle._play_control_move_impact(lane_index, row_index, lane_index, row_index)
	battle._play_combat_sfx("push")
	return true


static func _resolve_sweep(battle: Control, skill: Dictionary) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false

	var target_row: int = int(target["row"])
	var values: Dictionary = skill.get("values", {})
	var bonus: int = _get_pending_damage_card_bonus(battle, skill)
	var damage: int = int(values.get("damage", 8)) + bonus
	var full_row_damage: int = int(values.get("full_row_damage", 25)) + bonus
	var aoe_bonus: int = max(int(battle.aoe_range_bonus_this_turn), 0)
	var affected_ids := {}
	var hit_any := false

	for affected_row in range(target_row - aoe_bonus, target_row + aoe_bonus + 1):
		if affected_row < battle.FIRST_BATTLE_ROW or affected_row > battle.LAST_BATTLE_ROW:
			continue
		var row_enemies: Array = battle._get_all_enemies_in_row(affected_row)
		if row_enemies.is_empty():
			continue
		var applied_damage := full_row_damage if battle._is_row_fully_occupied(affected_row) else damage
		for enemy in row_enemies:
			var enemy_id: int = int(enemy.get("instance_id", -1))
			if affected_ids.has(enemy_id):
				continue
			affected_ids[enemy_id] = true
			battle._damage_enemy_from_card(enemy, applied_damage)
			hit_any = true

	if hit_any:
		_consume_damage_card_bonus_if_needed(battle, bonus)
	return hit_any


static func _resolve_push_side(battle: Control) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if _is_control_immune(target):
		return false

	var target_lane: int = int(target["lane"])
	var target_row: int = int(target["row"])
	var destinations: Array = []

	if target_lane > 0:
		destinations.append({"lane": target_lane - 1, "row": target_row})
	if target_lane < battle.LANE_COUNT - 1:
		destinations.append({"lane": target_lane + 1, "row": target_row})

	if destinations.is_empty():
		return false

	battle.pending_skill_id = "push"
	battle.pending_push_target_id = int(target["instance_id"])
	battle.pending_push_destinations = destinations
	battle._refresh_ui()
	return false


static func _resolve_move_structure(battle: Control) -> bool:
	if battle.selected_lane == -1 or battle.selected_row == -1:
		return false
	var structure = battle._get_structure_in_tile(battle.selected_lane, battle.selected_row)
	if structure == null:
		return false
	var destinations: Array = battle._get_structure_move_destinations(battle.selected_lane, battle.selected_row)
	if destinations.is_empty():
		return false
	battle.pending_skill_id = "move_structure"
	battle.pending_structure_move_source = {
		"lane": battle.selected_lane,
		"row": battle.selected_row,
	}
	battle.pending_structure_move_destinations = destinations
	battle._refresh_ui()
	return false


static func _resolve_pull(battle: Control) -> bool:
	if battle.selected_lane == -1:
		return false

	var target: Dictionary = battle._get_front_enemy_in_lane(battle.selected_lane)
	if target.is_empty():
		return false
	if _is_control_immune(target):
		return false

	var target_lane: int = int(target["lane"])
	var target_row: int = int(target["row"])
	var moved := false

	for side_lane in [target_lane - 1, target_lane + 1]:
		if side_lane < 0 or side_lane >= battle.LANE_COUNT:
			continue
		var side_target: Dictionary = battle._get_front_enemy_in_tile(side_lane, target_row)
		if side_target.is_empty():
			continue
		battle._move_enemy_to_position(side_target, target_lane, target_row, "back")
		moved = true

	if moved:
		battle._play_combat_sfx("push")
	return moved
