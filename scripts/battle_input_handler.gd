extends RefCounted

var owner: Control


func setup(target_owner: Control) -> void:
	owner = target_owner


func on_tile_gui_input(event: InputEvent, lane_index: int, row_index: int) -> void:
	if owner.battle_finished:
		return
	if owner.drag_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		owner._play_ui_sound("select")
		if owner._resolve_pending_skill_on_tile(lane_index, row_index):
			return
		select_lane(lane_index, row_index)
		var active_skill: Dictionary = owner._get_skill(owner.selected_skill_id)
		if not active_skill.is_empty():
			var targeting_type: String = String(active_skill.get("targeting_type", ""))
			if targeting_type == "tile_install" and owner._is_install_preview_tile(lane_index, row_index):
				owner._on_skill_pressed(owner.selected_skill_id)
				return
		owner._refresh_ui()


func on_tile_mouse_entered(lane_index: int, row_index: int) -> void:
	if owner.battle_finished or owner.drag_active:
		return
	owner.enemy_info_hover_lane = lane_index
	owner.enemy_info_hover_row = row_index
	owner._show_enemy_tile_info(lane_index, row_index)


func on_tile_mouse_exited(lane_index: int, row_index: int) -> void:
	if owner.enemy_info_hover_lane != lane_index or owner.enemy_info_hover_row != row_index:
		return
	owner.enemy_info_hover_lane = -1
	owner.enemy_info_hover_row = -1
	owner._hide_enemy_tile_info()


func on_skill_card_gui_input(event: InputEvent, skill_id: String) -> void:
	if owner.battle_finished:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			owner._play_ui_sound("cursor")
			owner._toggle_battle_skill_detail(skill_id)
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			owner._hide_battle_skill_detail()
			owner._start_drag_skill(skill_id, event.global_position)


func raw_input(event: InputEvent) -> void:
	if not owner.drag_active:
		return
	if event is InputEventMouseMotion:
		owner._update_drag_state(event.global_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		owner._finish_drag_skill(event.global_position)


func unhandled_input(event: InputEvent) -> void:
	if owner.battle_finished or owner.reward_overlay != null and owner.reward_overlay.visible:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_Q:
			select_skill_by_index(0)
			owner.get_viewport().set_input_as_handled()
		KEY_W:
			select_skill_by_index(1)
			owner.get_viewport().set_input_as_handled()
		KEY_E:
			select_skill_by_index(2)
			owner.get_viewport().set_input_as_handled()
		KEY_R:
			select_skill_by_index(3)
			owner.get_viewport().set_input_as_handled()
		KEY_T:
			select_skill_by_index(4)
			owner.get_viewport().set_input_as_handled()
		KEY_Y:
			select_skill_by_index(5)
			owner.get_viewport().set_input_as_handled()
		KEY_SPACE:
			owner._on_end_turn_pressed()
			owner.get_viewport().set_input_as_handled()
		KEY_PLUS, KEY_KP_ADD, KEY_EQUAL:
			owner._on_energy_pressed()
			owner.get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			clear_current_selection()
			owner.get_viewport().set_input_as_handled()


func select_skill_by_index(index: int) -> void:
	if index < 0 or index >= owner.skills.size():
		return

	var skill_id: String = String(owner.skills[index]["id"])
	select_skill(skill_id, true)


func select_skill(skill_id: String, allow_immediate_use: bool = false) -> void:
	if owner.pending_energy_mode == "reduce_cd":
		owner.combat_resolver.apply_pending_energy_reduce_cd(skill_id)
		return
	if owner.pending_cooldown_swap_active:
		owner.combat_resolver.apply_pending_cooldown_swap_selection(skill_id)
		return
	if owner.selected_skill_id == skill_id:
		if allow_immediate_use and owner.selected_lane != -1 and _try_use_selected_skill_from_keyboard(owner.selected_skill_id):
			return
		owner._play_ui_sound("cancel")
		owner.selected_skill_id = ""
		owner._refresh_ui()
		return
	var previous_selected_skill_id: String = owner.selected_skill_id
	owner.selected_skill_id = skill_id
	var newly_selected_skill: Dictionary = owner._get_skill(skill_id)
	if String(newly_selected_skill.get("targeting_type", "")) == "tile_install":
		clear_lane_selection()
	if allow_immediate_use and owner.selected_skill_id == skill_id and owner.selected_lane != -1:
		if _try_use_selected_skill_from_keyboard(previous_selected_skill_id):
			return
	owner._play_ui_sound("select")
	owner._refresh_ui()


func select_lane(lane_index: int, row_index: int = -1) -> void:
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return

	owner.selected_lane = lane_index
	var skill: Dictionary = owner._get_skill(owner.selected_skill_id)
	var targeting_type: String = String(skill.get("targeting_type", ""))
	if row_index >= owner.FIRST_BATTLE_ROW and row_index <= owner.LAST_BATTLE_ROW:
		owner.selected_row = row_index
	elif targeting_type == "tile_install" or targeting_type == "tile_structure" or targeting_type == "tile_any":
		owner.selected_row = -1
	else:
		var front_enemy: Dictionary = owner._get_front_enemy_in_lane(lane_index)
		owner.selected_row = int(front_enemy.get("row", owner.FIRST_BATTLE_ROW))


func use_selected_input_state() -> void:
	if owner.pending_skill_id != "":
		if owner.selected_lane == -1:
			return
		if owner.pending_skill_id == "push":
			if owner._resolve_push_from_keyboard(owner.selected_lane):
				var push_skill: Dictionary = owner._get_skill("push")
				owner._set_skill_current_cooldown("push", owner._get_skill_effective_cooldown(push_skill))
				if bool(push_skill.get("consumes_action", true)):
					owner.turn_manager.spend_action(max(int(push_skill.get("action_cost", 1)), 0))
				owner._post_action_cleanup()
			return
		if owner.selected_row == -1:
			return
		owner._resolve_pending_skill_on_tile(owner.selected_lane, owner.selected_row)
		return

	if owner.selected_skill_id.is_empty():
		return
	var skill: Dictionary = owner._get_skill(owner.selected_skill_id)
	if not skill.is_empty() and String(skill.get("targeting_type", "")) == "self_state":
		owner._on_skill_pressed(owner.selected_skill_id)
		return
	owner._on_skill_pressed(owner.selected_skill_id)


func _try_use_selected_skill_from_keyboard(previous_selected_skill_id: String) -> bool:
	var skill_id: String = owner.selected_skill_id
	if skill_id.is_empty():
		return false
	var skill: Dictionary = owner._get_skill(skill_id)
	if skill.is_empty():
		return false
	var targeting_type: String = String(skill.get("targeting_type", ""))
	if targeting_type == "self_state":
		owner._play_ui_sound("confirm")
		owner._on_skill_pressed(skill_id)
		return true
	if targeting_type == "pending_push" or targeting_type == "pending_retreat" or targeting_type == "tile_structure":
		owner._play_ui_sound("error")
		return false
	if targeting_type == "tile_install" or targeting_type == "tile_any":
		if owner.selected_row == -1:
			owner._play_ui_sound("error")
			return false
		owner._play_ui_sound("confirm")
		owner._on_skill_pressed(skill_id)
		return owner.selected_skill_id != skill_id or previous_selected_skill_id != skill_id
	owner._play_ui_sound("confirm")
	owner._on_skill_pressed(skill_id)
	return owner.selected_skill_id != skill_id or previous_selected_skill_id != skill_id


func clear_current_selection() -> void:
	owner._play_ui_sound("cancel")
	if owner.drag_active:
		owner._cancel_drag_skill(false)
	owner.close_energy_popup()
	owner.selected_skill_id = ""
	clear_lane_selection()
	owner.pending_skill_id = ""
	owner.pending_push_target_id = -1
	owner.pending_push_destinations.clear()
	owner.pending_pull_target_id = -1
	owner.pending_pull_destinations.clear()
	owner.pending_retreat_target_id = -1
	owner.pending_retreat_destinations.clear()
	owner.pending_structure_move_source.clear()
	owner.pending_structure_move_destinations.clear()
	owner.pending_cooldown_swap_active = false
	owner.pending_cooldown_swap_card_id = ""
	owner.pending_cooldown_swap_selected_ids.clear()
	owner._hide_enemy_tile_info()
	owner._refresh_ui()


func clear_lane_selection() -> void:
	owner.selected_lane = -1
	owner.selected_row = -1
