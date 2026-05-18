extends RefCounted
class_name EnemyBehaviorResolver


static func process_enemy_turn(battle: Control, enemy: Dictionary, insert_mode: String) -> void:
	if int(enemy.get("row", battle.FIRST_BATTLE_ROW)) == battle.PREVIEW_ROW:
		if not battle._enemy_exists(enemy):
			return
		if battle._get_structure_in_tile(int(enemy.get("lane", -1)), battle.FIRST_BATTLE_ROW) != null:
			battle._damage_structure(int(enemy.get("lane", -1)), battle.FIRST_BATTLE_ROW, battle._get_enemy_effective_attack(enemy))
			_apply_post_turn_state_updates(battle, enemy)
			return
		battle._move_enemy_to_row(enemy, battle.FIRST_BATTLE_ROW, insert_mode)
		_apply_post_turn_state_updates(battle, enemy)
		return

	_apply_start_of_turn_traits(battle, enemy)
	if not battle._enemy_exists(enemy):
		return
	if int(enemy.get("stun_turns", 0)) > 0:
		enemy["stun_turns"] = max(int(enemy.get("stun_turns", 0)) - 1, 0)
		return
	if _process_attach_support_seek(battle, enemy):
		_apply_post_turn_state_updates(battle, enemy)
		return

	var move_pattern_id: String = String(enemy.get("move_pattern_id", "straight_1"))
	var reverse_active: bool = int(enemy.get("reverse_move_turns", 0)) > 0
	var speed_bonus: int = max(int(battle.enemy_state.get_attached_speed_bonus(enemy)) + int(battle._get_totem_speed_bonus(enemy)), 0)

	match move_pattern_id:
		"act1_boss_anchor":
			_process_act1_boss_anchor(battle, enemy)
		"rocket_boss_anchor":
			_process_rocket_boss_anchor(battle, enemy)
		"king_kong_launch":
			_process_king_kong_launch(battle, enemy, insert_mode, speed_bonus)
		"dash_countdown":
			_process_dash_countdown(battle, enemy)
		"seek_crowd_1":
			_process_seek_crowd_1(battle, enemy, insert_mode)
		"straight_2":
			_move_forward_steps(battle, enemy, 2 + speed_bonus, insert_mode)
		"hold_then_move":
			_process_hold_then_move(battle, enemy, insert_mode, speed_bonus)
		"archer_fire_line":
			_process_archer_fire_line(battle, enemy, insert_mode, reverse_active, speed_bonus)
		"side_shift":
			_process_side_shift(battle, enemy, speed_bonus)
		"static_support":
			_process_static_support(battle, enemy)
		_:
			_move_forward_steps(battle, enemy, 1 + speed_bonus, insert_mode)

	if reverse_active and battle._enemy_exists(enemy):
		if bool(enemy.get("reverse_move_pending", false)):
			enemy["reverse_move_pending"] = false
		else:
			enemy["reverse_move_turns"] = max(int(enemy.get("reverse_move_turns", 0)) - 1, 0)
	if battle._enemy_exists(enemy) and int(enemy.get("attack_debuff_turns", 0)) > 0:
		if bool(enemy.get("attack_debuff_pending", false)):
			enemy["attack_debuff_pending"] = false
		else:
			enemy["attack_debuff_turns"] = max(int(enemy.get("attack_debuff_turns", 0)) - 1, 0)
			if int(enemy.get("attack_debuff_turns", 0)) <= 0:
				enemy["attack_debuff_amount"] = 0
	_apply_post_turn_state_updates(battle, enemy)


static func process_plague_spread(battle: Control) -> void:
	var infectors: Array = []
	for lane_index in range(battle.LANE_COUNT):
		for row_index in range(battle.FIRST_BATTLE_ROW, battle.LAST_BATTLE_ROW + 1):
			for enemy in battle.board_state[lane_index][row_index]:
				if bool(enemy.get("plague_active", false)):
					infectors.append(enemy)

	for enemy in infectors:
		if not battle._enemy_exists(enemy):
			continue
		var lane_index: int = int(enemy.get("lane", -1))
		var row_index: int = int(enemy.get("row", -1))
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_lane: int = lane_index + offset.x
			var next_row: int = row_index + offset.y
			if next_lane < 0 or next_lane >= battle.LANE_COUNT:
				continue
			if next_row < battle.FIRST_BATTLE_ROW or next_row > battle.LAST_BATTLE_ROW:
				continue
			for target in battle.board_state[next_lane][next_row]:
				if bool(target.get("plague_active", false)):
					continue
				target["plague_active"] = true
				target["plague_damage"] = 3
				target["plague_pending"] = true
				battle._refresh_tile_ui(next_lane, next_row)
				break


static func _apply_start_of_turn_traits(battle: Control, enemy: Dictionary) -> void:
	var traits: Array = enemy.get("traits", [])
	if traits.has("heal_front_ally"):
		var lane_index: int = int(enemy.get("lane", -1))
		var target: Dictionary = battle._get_front_enemy_in_lane(lane_index)
		if not target.is_empty() and int(target.get("instance_id", -1)) != int(enemy.get("instance_id", -1)):
			battle.combat_resolver.heal_enemy(target, 10)
	battle._apply_totem_turn_start_effects(enemy)
	if traits.has("self_regen_5"):
		battle.combat_resolver.heal_enemy(enemy, 5)
	if traits.has("shield_regen") and not bool(enemy.get("shield_active", false)):
		enemy["shield_active"] = true
		battle._refresh_tile_ui(int(enemy.get("lane", -1)), int(enemy.get("row", -1)))
	if traits.has("attach_support") and int(enemy.get("attached_host_id", -1)) == -1:
		var behavior_state: Dictionary = enemy.get("behavior_state", {})
		behavior_state["turns_on_field"] = int(behavior_state.get("turns_on_field", 0)) + 1
		enemy["behavior_state"] = behavior_state


static func _apply_post_turn_state_updates(battle: Control, enemy: Dictionary) -> void:
	if not battle._enemy_exists(enemy):
		return
	if enemy.get("traits", []).has("stealth_cycle"):
		enemy["stealth_active"] = not bool(enemy.get("stealth_active", false))
		battle._refresh_tile_ui(int(enemy.get("lane", -1)), int(enemy.get("row", -1)))


static func _process_hold_then_move(battle: Control, enemy: Dictionary, insert_mode: String, speed_bonus: int = 0) -> void:
	var behavior_state: Dictionary = enemy.get("behavior_state", {})
	var charged: bool = bool(behavior_state.get("charged", false))
	if not charged:
		behavior_state["charged"] = true
		enemy["behavior_state"] = behavior_state
		return

	behavior_state["charged"] = false
	enemy["behavior_state"] = behavior_state
	_move_forward_steps(battle, enemy, 1 + speed_bonus, insert_mode)


static func _process_attach_support_seek(battle: Control, enemy: Dictionary) -> bool:
	if not enemy.get("traits", []).has("attach_support"):
		return false
	if int(enemy.get("attached_host_id", -1)) != -1:
		return false
	var behavior_state: Dictionary = enemy.get("behavior_state", {})
	var turns_on_field: int = int(behavior_state.get("turns_on_field", 0))
	if turns_on_field < 3:
		return false
	var target: Dictionary = _find_closest_attach_host(battle, enemy)
	if target.is_empty():
		return false
	var current_lane: int = int(enemy.get("lane", -1))
	var current_row: int = int(enemy.get("row", -1))
	var target_lane: int = int(target.get("lane", -1))
	var target_row: int = int(target.get("row", -1))
	if current_lane == target_lane and current_row == target_row:
		return false
	battle._move_enemy_to_position(enemy, target_lane, target_row, "back")
	return true


static func _find_closest_attach_host(battle: Control, enemy: Dictionary) -> Dictionary:
	var current_lane: int = int(enemy.get("lane", -1))
	var current_row: int = int(enemy.get("row", -1))
	var best_target: Dictionary = {}
	var best_distance: int = 999999
	var best_row_score: int = -999999
	for lane_index in range(battle.LANE_COUNT):
		for row_index in range(battle.FIRST_BATTLE_ROW, battle.LAST_BATTLE_ROW + 1):
			for candidate in battle.board_state[lane_index][row_index]:
				if int(candidate.get("instance_id", -1)) == int(enemy.get("instance_id", -1)):
					continue
				if candidate.get("traits", []).has("attach_support"):
					continue
				var distance: int = abs(lane_index - current_lane) + abs(row_index - current_row)
				if distance < best_distance:
					best_distance = distance
					best_row_score = row_index
					best_target = candidate
					continue
				if distance == best_distance:
					if row_index > best_row_score:
						best_row_score = row_index
						best_target = candidate
						continue
					if row_index == best_row_score and abs(lane_index - current_lane) < abs(int(best_target.get("lane", current_lane)) - current_lane):
						best_target = candidate
	return best_target


static func _process_king_kong_launch(battle: Control, enemy: Dictionary, insert_mode: String, speed_bonus: int = 0) -> void:
	var behavior_state: Dictionary = enemy.get("behavior_state", {})
	var charged: bool = bool(behavior_state.get("charged", false))
	if not charged:
		behavior_state["charged"] = true
		enemy["behavior_state"] = behavior_state
		return

	behavior_state["charged"] = false
	enemy["behavior_state"] = behavior_state
	var before_row: int = int(enemy.get("row", battle.FIRST_BATTLE_ROW))
	_move_forward_steps(battle, enemy, 1 + speed_bonus, insert_mode)
	if not battle._enemy_exists(enemy):
		return
	var after_row: int = int(enemy.get("row", battle.FIRST_BATTLE_ROW))
	if after_row == before_row:
		return
	_launch_king_kong_minion(battle, enemy)


static func _process_seek_crowd_1(battle: Control, enemy: Dictionary, insert_mode: String) -> void:
	var current_lane: int = int(enemy.get("lane", -1))
	var current_row: int = int(enemy.get("row", battle.FIRST_BATTLE_ROW))
	var best_target := {"lane": -1, "row": -1, "count": 0, "distance": 999}

	for lane_index in range(battle.LANE_COUNT):
		var lane_count := 0
		var front_row := -1
		for row_index in range(battle.FIRST_BATTLE_ROW, battle.LAST_BATTLE_ROW + 1):
			for occupant in battle.board_state[lane_index][row_index]:
				if int(occupant.get("instance_id", -1)) == int(enemy.get("instance_id", -1)):
					continue
				lane_count += 1
				if front_row == -1 or row_index > front_row:
					front_row = row_index
		if lane_count <= 0 or front_row == -1:
			continue
		var distance: int = abs(lane_index - current_lane) + abs(front_row - current_row)
		if lane_count > int(best_target["count"]):
			best_target = {"lane": lane_index, "row": front_row, "count": lane_count, "distance": distance}
			continue
		if lane_count == int(best_target["count"]):
			if distance < int(best_target["distance"]):
				best_target = {"lane": lane_index, "row": front_row, "count": lane_count, "distance": distance}
				continue
			if distance == int(best_target["distance"]):
				if front_row > int(best_target["row"]):
					best_target = {"lane": lane_index, "row": front_row, "count": lane_count, "distance": distance}
					continue
				if front_row == int(best_target["row"]) and abs(lane_index - current_lane) < abs(int(best_target["lane"]) - current_lane):
					best_target = {"lane": lane_index, "row": front_row, "count": lane_count, "distance": distance}

	if int(best_target["count"]) <= 0:
		_move_forward_steps(battle, enemy, 1, insert_mode)
		return
	if int(best_target["lane"]) == current_lane and int(best_target["row"]) == current_row:
		_move_forward_steps(battle, enemy, 1, insert_mode)
		return

	battle._move_enemy_to_position(enemy, int(best_target["lane"]), int(best_target["row"]), "front")


static func _process_dash_countdown(battle: Control, enemy: Dictionary) -> void:
	var behavior_state: Dictionary = enemy.get("behavior_state", {})
	var turns_remaining: int = max(int(behavior_state.get("turns_remaining", 3)), 0)
	if turns_remaining <= 1:
		battle._play_enemy_dash_to_core({
			"type": String(enemy.get("type", "")),
			"name": String(enemy.get("name", "Dash")),
			"attack": int(enemy.get("attack", 0)),
			"hp": int(enemy.get("hp", 0)),
			"max_hp": int(enemy.get("max_hp", 0)),
			"rank": String(enemy.get("rank", "normal")),
			"color": Color(enemy.get("color", Color.WHITE)),
		}, int(enemy.get("lane", -1)), int(enemy.get("row", -1)))
		battle._remove_enemy_from_tile(enemy, int(enemy.get("lane", -1)), int(enemy.get("row", -1)))
		battle._apply_life_damage(battle._get_enemy_effective_attack(enemy))
		return
	behavior_state["turns_remaining"] = turns_remaining - 1
	enemy["behavior_state"] = behavior_state
	battle._refresh_tile_ui(int(enemy.get("lane", -1)), int(enemy.get("row", -1)))


static func _process_side_shift(battle: Control, enemy: Dictionary, speed_bonus: int = 0) -> void:
	var target_lane: int = int(enemy["lane"])
	if target_lane == 0:
		target_lane = 1
	elif target_lane == battle.LANE_COUNT - 1:
		target_lane = battle.LANE_COUNT - 2
	else:
		target_lane += 1 if int(enemy["instance_id"]) % 2 == 0 else -1

	battle._move_enemy_to_position(enemy, target_lane, int(enemy["row"]), "back")
	_move_forward_steps(battle, enemy, 1 + speed_bonus, "back")


static func _process_archer_fire_line(battle: Control, enemy: Dictionary, insert_mode: String, reverse_active: bool, speed_bonus: int = 0) -> void:
	var hold_row := 4
	if not reverse_active and int(enemy.get("row", battle.FIRST_BATTLE_ROW)) >= hold_row:
		battle._play_projectile_from_enemy(enemy)
		battle._apply_life_damage(battle._get_enemy_effective_attack(enemy))
		return
	_move_forward_steps(battle, enemy, 1 + speed_bonus, insert_mode)


static func _process_static_support(_battle: Control, _enemy: Dictionary) -> void:
	return


static func _process_act1_boss_anchor(battle: Control, enemy: Dictionary) -> void:
	var spawn_count: int = 2 if int(enemy.get("hp", 0)) < 90 else 1
	battle._spawn_boss_minions(enemy, spawn_count)
	if bool(enemy.get("skip_attack_this_turn", false)):
		enemy["skip_attack_this_turn"] = false
		return
	battle._play_boss_attack(enemy)
	battle._apply_life_damage(battle._get_enemy_effective_attack(enemy))


static func _process_rocket_boss_anchor(battle: Control, enemy: Dictionary) -> void:
	battle._spawn_rocket_boss_minion(enemy)


static func _launch_king_kong_minion(battle: Control, enemy: Dictionary) -> void:
	var target_row: int = int(enemy.get("row", battle.FIRST_BATTLE_ROW)) + 2
	if target_row < battle.FIRST_BATTLE_ROW or target_row > battle.LAST_BATTLE_ROW:
		battle._apply_life_damage(1)
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lane_index: int = rng.randi_range(0, battle.LANE_COUNT - 1)
	var landing_row: int = _resolve_king_kong_minion_landing_row(battle, lane_index, target_row)
	if landing_row < battle.FIRST_BATTLE_ROW or landing_row > battle.LAST_BATTLE_ROW:
		return
	battle._play_king_kong_throw(enemy, lane_index, landing_row)
	battle._spawn_enemy_entry({"type": "king_kong_minion"}, lane_index, landing_row, "back")


static func _resolve_king_kong_minion_landing_row(battle: Control, lane_index: int, target_row: int) -> int:
	var structure = battle._get_structure_in_tile(lane_index, target_row)
	if structure == null:
		return target_row
	battle._damage_structure(lane_index, target_row, 1)
	if battle._get_structure_in_tile(lane_index, target_row) == null:
		return target_row
	var fallback_row: int = target_row - 1
	while fallback_row >= battle.FIRST_BATTLE_ROW:
		if battle._get_structure_in_tile(lane_index, fallback_row) == null:
			return fallback_row
		fallback_row -= 1
	return -1


static func _move_forward_steps(battle: Control, enemy: Dictionary, step_count: int, insert_mode: String) -> void:
	for _step in range(step_count):
		if not battle._enemy_exists(enemy):
			return

		var direction: int = -1 if int(enemy.get("reverse_move_turns", 0)) > 0 else 1
		var next_row: int = int(enemy["row"]) + direction
		if direction > 0 and next_row > battle.LAST_BATTLE_ROW:
			battle._remove_enemy_from_tile(enemy, int(enemy["lane"]), int(enemy["row"]))
			battle._apply_life_damage(battle._get_enemy_effective_attack(enemy))
			return
		if direction < 0 and next_row < battle.FIRST_BATTLE_ROW:
			return

		var moved: bool = battle._move_enemy_to_row(enemy, next_row, insert_mode)
		if not moved:
			return
