extends RefCounted

const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")
const ENEMY_BEHAVIOR_RESOLVER = preload("res://scripts/enemy_behavior_resolver.gd")

var owner: Control


func setup(target_owner: Control) -> void:
	owner = target_owner


func make_enemy_instance(enemy_type: String) -> Dictionary:
	var def: Dictionary = ENEMY_CATALOG.get_enemy(enemy_type)
	var enemy := {
		"instance_id": owner.next_enemy_id,
		"type": enemy_type,
		"name": def["name"],
		"hp": def["hp"],
		"max_hp": def["hp"],
		"attack": def["attack"],
		"speed": def["speed"],
		"rank": def["rank"],
		"color": def["color"],
		"icon": def.get("icon", null),
		"move_pattern_id": def["move_pattern_id"],
		"traits": def["traits"],
		"keywords": def["keywords"],
		"special": def["special"],
		"reverse_move_turns": 0,
		"reverse_move_pending": false,
		"attack_debuff_turns": 0,
		"attack_debuff_pending": false,
		"attack_debuff_amount": 0,
		"stun_turns": 0,
		"plague_active": false,
		"plague_damage": 0,
		"plague_pending": false,
		"stealth_active": false,
		"shield_active": false,
		"revived_by_necro": false,
		"linked_twin_id": -1,
		"attached_host_id": -1,
		"skip_attack_this_turn": false,
		"behavior_state": {},
		"lane": -1,
		"row": -1,
	}
	if String(def.get("move_pattern_id", "")) == "dash_countdown":
		enemy["behavior_state"] = {"turns_remaining": 3}
	owner.next_enemy_id += 1
	return enemy


func add_enemy_to_tile(enemy: Dictionary, lane_index: int, row_index: int, insert_mode: String) -> void:
	enemy["lane"] = lane_index
	enemy["row"] = row_index

	var occupants: Array = owner.board_state[lane_index][row_index]
	if insert_mode == "front":
		occupants.push_front(enemy)
	else:
		occupants.push_back(enemy)

	_update_tile_attachments(lane_index, row_index)
	owner._refresh_tile_ui(lane_index, row_index)


func remove_enemy_from_tile(enemy: Dictionary, lane_index: int, row_index: int) -> void:
	var occupants: Array = owner.board_state[lane_index][row_index]
	for index in range(occupants.size()):
		if occupants[index]["instance_id"] == enemy["instance_id"]:
			occupants.remove_at(index)
			break

	_update_tile_attachments(lane_index, row_index)
	owner._refresh_tile_ui(lane_index, row_index)


func move_enemy_to_row(enemy: Dictionary, new_row: int, insert_mode: String) -> bool:
	var attached_followers: Array = get_attached_followers(int(enemy.get("instance_id", -1)))
	var source_lane: int = int(enemy.get("lane", -1))
	var source_row: int = int(enemy.get("row", -1))
	var enemy_snapshot: Dictionary = _capture_enemy_vfx_snapshot(enemy)
	var follower_snapshots: Array = []
	for follower in attached_followers:
		follower_snapshots.append(_capture_enemy_vfx_snapshot(follower))
	var structure = owner._get_structure_in_tile(int(enemy["lane"]), new_row)
	if structure != null:
		if String(structure.get("id", "")) == "mine":
			var current_lane: int = int(enemy.get("lane", -1))
			var current_row: int = int(enemy.get("row", -1))
			remove_enemy_from_tile(enemy, current_lane, current_row)
			for follower in attached_followers:
				if enemy_exists(follower):
					remove_enemy_from_tile(follower, current_lane, current_row)
			add_enemy_to_tile(enemy, current_lane, new_row, insert_mode)
			for follower in attached_followers:
				add_enemy_to_tile(follower, current_lane, new_row, "back")
			owner._play_enemy_move_effect(enemy_snapshot, current_lane, current_row, current_lane, new_row)
			for index in range(min(attached_followers.size(), follower_snapshots.size())):
				owner._play_enemy_move_effect(follower_snapshots[index], current_lane, current_row, current_lane, new_row)
			return true
		owner._damage_structure(int(enemy["lane"]), new_row, owner._get_enemy_effective_attack(enemy))
		return false
	var lane_index: int = int(enemy.get("lane", -1))
	var row_index: int = int(enemy.get("row", -1))
	remove_enemy_from_tile(enemy, lane_index, row_index)
	for follower in attached_followers:
		if enemy_exists(follower):
			remove_enemy_from_tile(follower, lane_index, row_index)
	add_enemy_to_tile(enemy, lane_index, new_row, insert_mode)
	for follower in attached_followers:
		add_enemy_to_tile(follower, lane_index, new_row, "back")
	owner._play_enemy_move_effect(enemy_snapshot, source_lane, source_row, lane_index, new_row)
	for index in range(min(attached_followers.size(), follower_snapshots.size())):
		owner._play_enemy_move_effect(follower_snapshots[index], source_lane, source_row, lane_index, new_row)
	return true


func move_enemy_to_position(enemy: Dictionary, new_lane: int, new_row: int, insert_mode: String) -> bool:
	var attached_followers: Array = get_attached_followers(int(enemy.get("instance_id", -1)))
	var source_lane: int = int(enemy.get("lane", -1))
	var source_row: int = int(enemy.get("row", -1))
	var enemy_snapshot: Dictionary = _capture_enemy_vfx_snapshot(enemy)
	var follower_snapshots: Array = []
	for follower in attached_followers:
		follower_snapshots.append(_capture_enemy_vfx_snapshot(follower))
	var structure = owner._get_structure_in_tile(new_lane, new_row)
	if structure != null:
		if String(structure.get("id", "")) == "mine":
			var current_lane: int = int(enemy.get("lane", -1))
			var current_row: int = int(enemy.get("row", -1))
			remove_enemy_from_tile(enemy, current_lane, current_row)
			for follower in attached_followers:
				if enemy_exists(follower):
					remove_enemy_from_tile(follower, current_lane, current_row)
			add_enemy_to_tile(enemy, new_lane, new_row, insert_mode)
			for follower in attached_followers:
				add_enemy_to_tile(follower, new_lane, new_row, "back")
			owner._play_enemy_move_effect(enemy_snapshot, current_lane, current_row, new_lane, new_row)
			for index in range(min(attached_followers.size(), follower_snapshots.size())):
				owner._play_enemy_move_effect(follower_snapshots[index], current_lane, current_row, new_lane, new_row)
			return true
		owner._damage_structure(new_lane, new_row, owner._get_enemy_effective_attack(enemy))
		return false
	var lane_index: int = int(enemy.get("lane", -1))
	var row_index: int = int(enemy.get("row", -1))
	remove_enemy_from_tile(enemy, lane_index, row_index)
	for follower in attached_followers:
		if enemy_exists(follower):
			remove_enemy_from_tile(follower, lane_index, row_index)
	add_enemy_to_tile(enemy, new_lane, new_row, insert_mode)
	for follower in attached_followers:
		add_enemy_to_tile(follower, new_lane, new_row, "back")
	owner._play_enemy_move_effect(enemy_snapshot, source_lane, source_row, new_lane, new_row)
	for index in range(min(attached_followers.size(), follower_snapshots.size())):
		owner._play_enemy_move_effect(follower_snapshots[index], source_lane, source_row, new_lane, new_row)
	return true


func advance_enemy_one_row(enemy: Dictionary, insert_mode: String = "front") -> void:
	if enemy.is_empty():
		return
	if not enemy_exists(enemy):
		return
	var next_row: int = int(enemy.get("row", owner.FIRST_BATTLE_ROW)) + 1
	if next_row > owner.LAST_BATTLE_ROW:
		remove_enemy_from_tile(enemy, int(enemy.get("lane", -1)), int(enemy.get("row", -1)))
		owner._apply_life_damage(owner._get_enemy_effective_attack(enemy))
		return
	move_enemy_to_row(enemy, next_row, insert_mode)


func run_enemy_movement() -> void:
	ENEMY_BEHAVIOR_RESOLVER.process_plague_spread(owner)
	for row_index in range(owner.LAST_BATTLE_ROW, owner.PREVIEW_ROW - 1, -1):
		for lane_index in range(owner.LANE_COUNT):
			var moving_group: Array = owner.board_state[lane_index][row_index].duplicate()
			for index in range(moving_group.size()):
				var enemy: Dictionary = moving_group[index]
				if enemy["hp"] <= 0:
					continue
				if not enemy_exists(enemy):
					continue
				if int(enemy.get("attached_host_id", -1)) != -1:
					continue
				var insert_mode := "front" if index == 0 else "back"
				ENEMY_BEHAVIOR_RESOLVER.process_enemy_turn(owner, enemy, insert_mode)
	_resolve_mines_after_movement()


func _resolve_mines_after_movement() -> void:
	var pending_mines: Array[Dictionary] = []
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			var structure = owner._get_structure_in_tile(lane_index, row_index)
			if structure == null:
				continue
			if String(structure.get("id", "")) != "mine":
				continue
			if owner.board_state[lane_index][row_index].is_empty():
				continue
			pending_mines.append({
				"lane": lane_index,
				"row": row_index,
			})

	for mine_info in pending_mines:
		owner._trigger_mine_at(int(mine_info.get("lane", -1)), int(mine_info.get("row", -1)))


func enemy_exists(enemy: Dictionary) -> bool:
	var occupants: Array = owner.board_state[enemy["lane"]][enemy["row"]]
	for existing in occupants:
		if existing["instance_id"] == enemy["instance_id"]:
			return true
	return false


func find_enemy_by_instance_id(instance_id: int) -> Dictionary:
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index]:
				if int(enemy["instance_id"]) == instance_id:
					return enemy
	return {}


func get_attached_followers(host_instance_id: int) -> Array:
	var followers: Array = []
	if host_instance_id == -1:
		return followers
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			for enemy in owner.board_state[lane_index][row_index]:
				if int(enemy.get("attached_host_id", -1)) != host_instance_id:
					continue
				followers.append(enemy)
	return followers


func detach_followers_from_host(host_instance_id: int) -> void:
	for follower in get_attached_followers(host_instance_id):
		follower["attached_host_id"] = -1
		owner._refresh_tile_ui(int(follower.get("lane", -1)), int(follower.get("row", -1)))


func get_attached_attack_bonus(enemy: Dictionary) -> int:
	var bonus := 0
	for follower in get_attached_followers(int(enemy.get("instance_id", -1))):
		bonus += int(follower.get("attack", 0))
	return bonus


func get_attached_speed_bonus(enemy: Dictionary) -> int:
	var bonus := 0
	for follower in get_attached_followers(int(enemy.get("instance_id", -1))):
		bonus += int(follower.get("speed", 0))
	return bonus


func _update_tile_attachments(lane_index: int, row_index: int) -> void:
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return
	if row_index < owner.PREVIEW_ROW or row_index > owner.LAST_BATTLE_ROW:
		return
	var occupants: Array = owner.board_state[lane_index][row_index]
	var hosts: Array = []
	var attachers: Array = []
	for enemy in occupants:
		if enemy.get("traits", []).has("attach_support"):
			attachers.append(enemy)
		else:
			hosts.append(enemy)
	for attacher in attachers:
		if hosts.is_empty():
			attacher["attached_host_id"] = -1
			continue
		attacher["attached_host_id"] = int(hosts[0].get("instance_id", -1))


func spawn_boss_minions(enemy: Dictionary, spawn_count: int) -> void:
	var enemy_deck: Array[String] = owner.RUN_STATE.get_enemy_deck()
	if enemy_deck.is_empty() or spawn_count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var used_lanes: Dictionary = {}
	var max_spawn_count: int = min(spawn_count, owner.LANE_COUNT)
	for _index in range(max_spawn_count):
		var lane_pool: Array[int] = []
		for lane_index in range(owner.LANE_COUNT):
			if used_lanes.has(lane_index):
				continue
			lane_pool.append(lane_index)
		if lane_pool.is_empty():
			break
		var lane_index: int = lane_pool[rng.randi_range(0, lane_pool.size() - 1)]
		used_lanes[lane_index] = true
		var row_index: int = int(enemy.get("row", owner.FIRST_BATTLE_ROW)) + 1
		var enemy_id: String = enemy_deck[rng.randi_range(0, enemy_deck.size() - 1)]
		owner._spawn_enemy_entry({"type": enemy_id}, lane_index, row_index, "front")


func spawn_rocket_boss_minion(enemy: Dictionary) -> void:
	var enemy_deck: Array[String] = owner.RUN_STATE.get_enemy_deck()
	if enemy_deck.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lane_index: int = rng.randi_range(0, owner.LANE_COUNT - 1)
	var enemy_id: String = enemy_deck[rng.randi_range(0, enemy_deck.size() - 1)]
	owner._play_rocket_boss_launch(enemy, lane_index, 3, enemy_id)
	owner._spawn_enemy_entry({"type": enemy_id}, lane_index, 3, "back")


func _capture_enemy_vfx_snapshot(enemy: Dictionary) -> Dictionary:
	return {
		"type": String(enemy.get("type", "")),
		"name": String(enemy.get("name", "Enemy")),
		"attack": int(enemy.get("attack", 0)),
		"hp": int(enemy.get("hp", 0)),
		"max_hp": int(enemy.get("max_hp", 0)),
		"rank": String(enemy.get("rank", "normal")),
		"color": Color(enemy.get("color", Color.WHITE)),
		"icon": enemy.get("icon", null),
		"move_pattern_id": String(enemy.get("move_pattern_id", "straight_1")),
		"traits": enemy.get("traits", []).duplicate(),
		"plague_active": bool(enemy.get("plague_active", false)),
		"plague_damage": int(enemy.get("plague_damage", 0)),
		"stealth_active": bool(enemy.get("stealth_active", false)),
		"attached_active": int(enemy.get("attached_host_id", -1)) != -1,
		"shield_active": bool(enemy.get("shield_active", false)),
		"turn_counter": int(enemy.get("behavior_state", {}).get("turns_remaining", 0)),
	}
