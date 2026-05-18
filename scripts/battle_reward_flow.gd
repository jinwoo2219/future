extends RefCounted
class_name BattleRewardFlow

const RELIC_CATALOG = preload("res://scripts/relic_catalog.gd")

var owner: Control
var reward_title_label: Label
var reward_subtitle_label: Label
var reward_nav_button: Button
var reward_reroll_button: Button
var reward_mode := "choose_reward"
var pending_selected_reward_skill_id := ""
var pending_reward_relic_ids: Array[String] = []
var pending_reward_relic_source := "normal"
var reward_reroll_available := false
var reward_pick_reroll := false
var pending_post_boss_card_rewards := 0
var pending_trim_for_boss_relic := false
var reward_detail_panel: PanelContainer
var reward_detail_title: Label
var reward_detail_body: Label
var current_reward_detail_skill_id := ""
var reward_input_unlock_time_ms: int = 0


func setup(battle_owner: Control) -> void:
	owner = battle_owner


func _get_rarity_border_color(rarity: String) -> Color:
	match rarity.to_lower():
		"common":
			return Color(0.68, 0.86, 0.5, 0.92)
		"rare":
			return Color(0.52, 0.82, 0.98, 0.94)
		"epic":
			return Color(0.78, 0.5, 0.96, 0.96)
		_:
			return Color(0.72, 0.78, 0.84, 0.88)


func _resolve_visual_category(category: String) -> String:
	var normalized := category.to_lower()
	if normalized.contains("control"):
		return "control"
	if normalized.contains("install"):
		return "install"
	if normalized.contains("attack") or normalized.contains("damage"):
		return "damage"
	if normalized.contains("utility"):
		return "utility"
	return normalized


func _get_category_fill_color(category: String) -> Color:
	match _resolve_visual_category(category):
		"attack", "damage":
			return Color(0.42, 0.14, 0.14, 0.97)
		"utility":
			return Color(0.14, 0.22, 0.38, 0.97)
		"control":
			return Color(0.15, 0.32, 0.17, 0.97)
		"install":
			return Color(0.36, 0.18, 0.52, 0.97)
		_:
			return Color(0.16, 0.18, 0.2, 0.97)


func build_result_overlay() -> void:
	owner.result_overlay = ColorRect.new()
	owner.result_overlay.name = "ResultOverlay"
	owner.result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	owner.result_overlay.color = Color(0.03, 0.04, 0.06, 0.82)
	owner.result_overlay.visible = false
	owner.add_child(owner.result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.result_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 180)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.15, 0.2, 0.96)
	panel_style.border_color = Color(0.84, 0.9, 0.98, 0.9)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)

	var center_text := CenterContainer.new()
	center_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center_text)

	owner.result_label = Label.new()
	owner.result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner.result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	owner.result_label.add_theme_font_size_override("font_size", 32)
	owner.result_label.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92, 1.0))
	owner.result_label.add_theme_color_override("font_outline_color", Color(0.06, 0.07, 0.1, 1.0))
	owner.result_label.add_theme_constant_override("outline_size", 2)
	owner.result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_text.add_child(owner.result_label)


func build_reward_overlay() -> void:
	owner.reward_overlay = ColorRect.new()
	owner.reward_overlay.name = "RewardOverlay"
	owner.reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	owner.reward_overlay.color = Color(0.03, 0.04, 0.06, 0.88)
	owner.reward_overlay.visible = false
	owner.add_child(owner.reward_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.reward_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(960, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.13, 0.18, 0.98)
	panel_style.border_color = Color(0.84, 0.9, 0.98, 0.9)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 16)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	reward_title_label = Label.new()
	reward_title_label.text = "Choose A Card"
	reward_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_title_label.add_theme_font_size_override("font_size", 28)
	reward_title_label.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92, 1.0))
	reward_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(reward_title_label)

	reward_subtitle_label = Label.new()
	reward_subtitle_label.text = ""
	reward_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_subtitle_label.add_theme_font_size_override("font_size", 14)
	reward_subtitle_label.add_theme_color_override("font_color", Color(0.76, 0.8, 0.88, 1.0))
	reward_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(reward_subtitle_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(grid)

	owner.reward_card_buttons.clear()
	for index in range(6):
		var button := Button.new()
		button.name = "RewardCard_%d" % index
		button.custom_minimum_size = Vector2(0, 240)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(on_reward_card_pressed.bind(index))
		button.gui_input.connect(_on_reward_card_gui_input.bind(index))
		grid.add_child(button)
		owner.reward_card_buttons.append(button)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(footer)

	reward_nav_button = Button.new()
	reward_nav_button.custom_minimum_size = Vector2(140, 44)
	reward_nav_button.focus_mode = Control.FOCUS_NONE
	reward_nav_button.text = "Skip"
	reward_nav_button.pressed.connect(_on_reward_nav_pressed)
	footer.add_child(reward_nav_button)

	reward_reroll_button = Button.new()
	reward_reroll_button.custom_minimum_size = Vector2(180, 44)
	reward_reroll_button.focus_mode = Control.FOCUS_NONE
	reward_reroll_button.text = "Reroll 1 Card"
	reward_reroll_button.visible = false
	reward_reroll_button.pressed.connect(_on_reward_reroll_pressed)
	footer.add_child(reward_reroll_button)

	reward_detail_panel = PanelContainer.new()
	reward_detail_panel.top_level = true
	reward_detail_panel.visible = false
	reward_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_detail_panel.custom_minimum_size = Vector2(320, 190)
	reward_detail_panel.z_index = 50
	reward_detail_panel.add_theme_stylebox_override("panel", panel_style)
	owner.reward_overlay.add_child(reward_detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_margin.add_theme_constant_override("margin_left", 12)
	detail_margin.add_theme_constant_override("margin_top", 12)
	detail_margin.add_theme_constant_override("margin_right", 12)
	detail_margin.add_theme_constant_override("margin_bottom", 12)
	reward_detail_panel.add_child(detail_margin)

	var detail_content := VBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_content)

	reward_detail_title = Label.new()
	reward_detail_title.add_theme_font_size_override("font_size", 19)
	reward_detail_title.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92, 1.0))
	detail_content.add_child(reward_detail_title)

	reward_detail_body = Label.new()
	reward_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reward_detail_body.add_theme_font_size_override("font_size", 15)
	reward_detail_body.add_theme_color_override("font_color", Color(0.84, 0.87, 0.92, 1.0))
	detail_content.add_child(reward_detail_body)


func handle_battle_result(message: String) -> void:
	if owner.battle_finished:
		return
	owner.battle_finished = true
	owner.pending_skill_id = ""
	owner.pending_push_target_id = -1
	owner.pending_push_destinations.clear()
	owner.pending_retreat_target_id = -1
	owner.pending_retreat_destinations.clear()
	if message == "Stage Clear":
		if owner.RUN_STATE.get_current_stage_encounter_type() == "boss":
			show_boss_relic_reward_popup()
			return
		if owner.RUN_STATE.get_current_stage_encounter_type() == "elite":
			grant_random_elite_relic()
		else:
			show_card_reward_popup()
	else:
		if owner.result_label != null:
			owner.result_label.text = message
		if owner.result_overlay != null:
			owner.result_overlay.visible = true
		owner._refresh_ui()
		if message == "Defeat":
			owner.RUN_STATE.reset_run()
			return_to_title_after_delay()
		else:
			return_to_stage_select_after_delay()


func return_to_stage_select_after_delay() -> void:
	await owner.get_tree().create_timer(1.6).timeout
	owner.get_tree().change_scene_to_file("res://scenes/stage_select_screen.tscn")


func return_to_title_after_delay() -> void:
	await owner.get_tree().create_timer(1.6).timeout
	owner.get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _lock_reward_input_briefly() -> void:
	reward_input_unlock_time_ms = Time.get_ticks_msec() + 500


func _is_reward_input_locked() -> bool:
	return Time.get_ticks_msec() < reward_input_unlock_time_ms


func show_card_reward_popup() -> void:
	pending_reward_relic_ids.clear()
	pending_reward_relic_source = "normal"
	owner.pending_reward_skill_ids = generate_reward_skill_choices()
	if owner.pending_reward_skill_ids.is_empty():
		_finish_reward_sequence()
		return
	_hide_reward_card_detail()
	reward_mode = "choose_reward"
	pending_selected_reward_skill_id = ""
	reward_reroll_available = owner.RUN_STATE.has_relic("redraw")
	reward_pick_reroll = false
	populate_reward_cards()
	if owner.reward_overlay != null:
		owner.reward_overlay.visible = true
	_lock_reward_input_briefly()
	owner._refresh_ui()


func show_relic_reward_popup() -> void:
	owner.pending_reward_skill_ids.clear()
	pending_selected_reward_skill_id = ""
	reward_mode = "choose_relic"
	pending_reward_relic_source = "normal"
	reward_reroll_available = false
	reward_pick_reroll = false
	_hide_reward_card_detail()
	pending_reward_relic_ids = generate_reward_relic_choices()
	if pending_reward_relic_ids.is_empty():
		_finish_reward_sequence()
		return
	populate_reward_cards()
	if owner.reward_overlay != null:
		owner.reward_overlay.visible = true
	_lock_reward_input_briefly()
	owner._refresh_ui()


func show_boss_relic_reward_popup() -> void:
	owner.pending_reward_skill_ids.clear()
	pending_selected_reward_skill_id = ""
	reward_mode = "choose_relic"
	pending_reward_relic_source = "boss"
	reward_reroll_available = false
	reward_pick_reroll = false
	_hide_reward_card_detail()
	pending_reward_relic_ids = generate_boss_reward_relic_choices()
	if pending_reward_relic_ids.is_empty():
		owner.RUN_STATE.advance_after_stage_clear()
		if owner.result_label != null:
			owner.result_label.text = "Act 1 Clear"
		if owner.result_overlay != null:
			owner.result_overlay.visible = true
		owner._refresh_ui()
		return_to_stage_select_after_delay()
		return
	populate_reward_cards()
	if owner.reward_overlay != null:
		owner.reward_overlay.visible = true
	_lock_reward_input_briefly()
	owner._refresh_ui()


func grant_random_elite_relic() -> void:
	RELIC_CATALOG.reload()
	var owned_relic_ids: Array[String] = owner.RUN_STATE.get_relic_ids()
	var pool: Array[String] = []
	for relic_id in RELIC_CATALOG.get_relic_ids_by_source("normal"):
		if owned_relic_ids.has(relic_id):
			continue
		pool.append(relic_id)
	if pool.is_empty():
		_finish_reward_sequence()
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var reward_count := 2 if owner.RUN_STATE.has_relic("crown_of_plenty") else 1
	var picked_names: Array[String] = []
	for _i in range(min(reward_count, pool.size())):
		if pool.is_empty():
			break
		var pick_index: int = rng.randi_range(0, pool.size() - 1)
		var picked_relic_id: String = pool[pick_index]
		pool.remove_at(pick_index)
		owner.RUN_STATE.add_relic(picked_relic_id)
		var relic: Dictionary = RELIC_CATALOG.get_relic(picked_relic_id)
		picked_names.append(String(relic.get("name", picked_relic_id)))
	owner.RUN_STATE.advance_after_stage_clear()
	if owner.result_label != null:
		owner.result_label.text = "Relic Acquired\n%s" % "\n".join(picked_names)
	if owner.result_overlay != null:
		owner.result_overlay.visible = true
	owner._refresh_ui()
	return_to_stage_select_after_delay()


func generate_reward_relic_choices() -> Array[String]:
	RELIC_CATALOG.reload()
	var offered: Array[String] = []
	var owned_relic_ids: Array[String] = owner.RUN_STATE.get_relic_ids()
	var pool: Array[String] = []
	for relic_id in RELIC_CATALOG.get_relic_ids_by_source("normal"):
		if owned_relic_ids.has(relic_id):
			continue
		pool.append(relic_id)
	if pool.is_empty():
		return offered
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in range(pool.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp: String = pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = temp
	for relic_id in pool.slice(0, min(3, pool.size())):
		offered.append(relic_id)
	return offered


func generate_boss_reward_relic_choices() -> Array[String]:
	RELIC_CATALOG.reload()
	var owned_relic_ids: Array[String] = owner.RUN_STATE.get_relic_ids()
	var action_pool: Array[String] = []
	var other_pool: Array[String] = []
	var all_boss_pool: Array[String] = []
	for relic_id in RELIC_CATALOG.get_relic_ids_by_source("boss"):
		if owned_relic_ids.has(relic_id):
			continue
		all_boss_pool.append(relic_id)
		var relic: Dictionary = RELIC_CATALOG.get_relic(relic_id)
		if String(relic.get("boss_group", "")) == "action":
			action_pool.append(relic_id)
		else:
			other_pool.append(relic_id)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var offered: Array[String] = []

	if not action_pool.is_empty():
		offered.append(action_pool[rng.randi_range(0, action_pool.size() - 1)])
	if not other_pool.is_empty():
		var other_pick: String = other_pool[rng.randi_range(0, other_pool.size() - 1)]
		if not offered.has(other_pick):
			offered.append(other_pick)

	var remaining_pool: Array[String] = []
	for relic_id in all_boss_pool:
		if offered.has(relic_id):
			continue
		remaining_pool.append(relic_id)
	if not remaining_pool.is_empty():
		offered.append(remaining_pool[rng.randi_range(0, remaining_pool.size() - 1)])

	return offered


func generate_reward_skill_choices() -> Array[String]:
	var offered: Array[String] = []
	var owned_skill_ids: Array[String] = owner.RUN_STATE.get_owned_skill_ids()
	var rarity_chances: Dictionary = owner.RUN_STATE.get_card_rarity_chances()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var reward_count := 3
	if owner.RUN_STATE.has_relic("open_options"):
		reward_count += 1
	if owner.RUN_STATE.has_relic("short_draft"):
		reward_count -= 1
	reward_count = max(reward_count, 1)
	for _index in range(reward_count):
		var choice := roll_reward_skill_id(rng, owned_skill_ids, offered, rarity_chances)
		if choice.is_empty():
			break
		offered.append(choice)

	return offered


func roll_reward_skill_id(rng: RandomNumberGenerator, owned_skill_ids: Array[String], offered: Array[String], rarity_chances: Dictionary, extra_excluded: Array[String] = []) -> String:
	var rarity_order := ["common", "rare", "epic", "elite"]
	var available_rarities: Array[String] = []
	var weighted: Array = []
	var total_weight := 0

	for rarity in rarity_order:
		var candidates := get_available_reward_skill_ids(rarity, owned_skill_ids, offered, extra_excluded)
		if candidates.is_empty():
			continue
		var weight: int = int(rarity_chances.get(rarity, 0))
		if weight <= 0:
			continue
		available_rarities.append(rarity)
		weighted.append({"rarity": rarity, "weight": weight})
		total_weight += weight

	if total_weight <= 0:
		for rarity in rarity_order:
			var fallback_candidates := get_available_reward_skill_ids(rarity, owned_skill_ids, offered, extra_excluded)
			if not fallback_candidates.is_empty():
				available_rarities.append(rarity)
		if available_rarities.is_empty():
			return ""
		var fallback_rarity: String = available_rarities[rng.randi_range(0, available_rarities.size() - 1)]
		var fallback_pool: Array[String] = get_available_reward_skill_ids(fallback_rarity, owned_skill_ids, offered, extra_excluded)
		return fallback_pool[rng.randi_range(0, fallback_pool.size() - 1)]

	var roll: int = rng.randi_range(1, total_weight)
	var cumulative := 0
	var chosen_rarity := "common"
	for entry in weighted:
		cumulative += int(entry["weight"])
		if roll <= cumulative:
			chosen_rarity = String(entry["rarity"])
			break

	var pool: Array[String] = get_available_reward_skill_ids(chosen_rarity, owned_skill_ids, offered, extra_excluded)
	if pool.is_empty():
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]


func get_available_reward_skill_ids(rarity: String, owned_skill_ids: Array[String], offered: Array[String], extra_excluded: Array[String] = []) -> Array[String]:
	var ids: Array[String] = []
	for skill_id in owner.SKILL_CATALOG.get_skill_ids_by_rarity(rarity):
		if owned_skill_ids.has(skill_id):
			continue
		if offered.has(skill_id):
			continue
		if extra_excluded.has(skill_id):
			continue
		ids.append(skill_id)
	return ids


func populate_reward_cards() -> void:
	_hide_reward_card_detail()
	_update_reward_header()
	for index in range(owner.reward_card_buttons.size()):
		var button: Button = owner.reward_card_buttons[index]
		for child in button.get_children():
			child.queue_free()

		var visible := false
		var skill_id := ""
		if reward_mode == "choose_reward":
			visible = index < owner.pending_reward_skill_ids.size()
			if visible:
				skill_id = owner.pending_reward_skill_ids[index]
		elif reward_mode == "choose_relic":
			visible = index < pending_reward_relic_ids.size()
			if visible:
				skill_id = pending_reward_relic_ids[index]
		else:
			var equipped_skill_ids: Array[String] = owner.RUN_STATE.get_equipped_skill_ids()
			visible = index < equipped_skill_ids.size()
			if visible:
				skill_id = equipped_skill_ids[index]

		button.visible = visible
		button.disabled = not visible
		if not visible:
			continue
		if reward_mode == "choose_relic":
			build_reward_relic_ui(button, skill_id)
		else:
			build_reward_card_ui(button, skill_id)


func build_reward_card_ui(button: Button, skill_id: String) -> void:
	var skill: Dictionary = owner.SKILL_CATALOG.get_skill(skill_id)
	var rarity: String = String(skill.get("rarity", "common"))
	var rarity_color: Color = _get_rarity_border_color(rarity)
	var category_fill_color: Color = _get_category_fill_color(String(skill.get("category", "utility")))

	var style := StyleBoxFlat.new()
	style.bg_color = category_fill_color
	style.border_color = rarity_color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("disabled", style)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var rarity_label := Label.new()
	rarity_label.text = rarity.capitalize()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 16)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(rarity_label)

	var name_label := Label.new()
	name_label.text = String(skill.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	var meta_label := Label.new()
	meta_label.text = "%s | CD %d" % [String(skill.get("category", "")).to_upper(), int(skill.get("cooldown", 0))]
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_label.add_theme_font_size_override("font_size", 14)
	meta_label.add_theme_color_override("font_color", Color(0.72, 0.77, 0.86, 1.0))
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(meta_label)

	var desc_label := Label.new()
	desc_label.text = String(skill.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.84, 0.87, 0.92, 1.0))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(desc_label)


func build_empty_reward_card_ui(button: Button) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)

	var label := Label.new()
	label.text = "No Card"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.74, 0.8, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(label)


func build_reward_relic_ui(button: Button, relic_id: String) -> void:
	var relic: Dictionary = RELIC_CATALOG.get_relic(relic_id)
	var relic_source: String = String(relic.get("source", "normal"))
	var relic_color: Color = Color(0.84, 0.8, 0.58, 1.0) if relic_source == "normal" else Color(0.95, 0.58, 0.34, 1.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.18, 0.12, 0.97)
	style.border_color = relic_color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("disabled", style)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var name_label := Label.new()
	name_label.text = String(relic.get("name", relic_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92, 1.0))
	content.add_child(name_label)

	var type_label := Label.new()
	type_label.text = "BOSS RELIC" if relic_source == "boss" else "RELIC"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", relic_color)
	content.add_child(type_label)

	var desc_label := Label.new()
	desc_label.text = String(relic.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.8, 1.0))
	content.add_child(desc_label)


func on_reward_card_pressed(index: int) -> void:
	if _is_reward_input_locked():
		return
	_hide_reward_card_detail()
	if reward_mode == "choose_relic":
		if index < 0 or index >= pending_reward_relic_ids.size():
			owner._play_ui_sound("error")
			return
		owner._play_ui_sound("confirm")
		var picked_relic_id: String = pending_reward_relic_ids[index]
		owner.RUN_STATE.add_relic(picked_relic_id)
		pending_reward_relic_ids.clear()
		if pending_reward_relic_source == "boss":
			if owner.RUN_STATE.get_owned_skill_ids().size() > owner.RUN_STATE.get_skill_limit():
				pending_trim_for_boss_relic = true
				reward_mode = "trim_existing"
				populate_reward_cards()
				return
			if owner.RUN_STATE.has_relic("burst_archive"):
				owner.RUN_STATE.advance_after_stage_clear()
				pending_post_boss_card_rewards = 3
				show_card_reward_popup()
				return
			owner.RUN_STATE.advance_after_stage_clear()
			if owner.reward_overlay != null:
				owner.reward_overlay.visible = false
			if owner.result_label != null:
				owner.result_label.text = "Act 1 Clear"
			if owner.result_overlay != null:
				owner.result_overlay.visible = true
			owner._refresh_ui()
			return_to_stage_select_after_delay()
			return
		_finish_reward_sequence()
		return
	if reward_mode == "choose_reward":
		if index < 0 or index >= owner.pending_reward_skill_ids.size():
			owner._play_ui_sound("error")
			return
		if reward_pick_reroll:
			owner._play_ui_sound("confirm")
			_reroll_reward_card(index)
			return
		var chosen_skill_id: String = owner.pending_reward_skill_ids[index]
		if owner.RUN_STATE.is_skill_inventory_full():
			owner._play_ui_sound("select")
			pending_selected_reward_skill_id = chosen_skill_id
			reward_mode = "remove_existing"
			reward_pick_reroll = false
			populate_reward_cards()
			return
		owner._play_ui_sound("confirm")
		owner.RUN_STATE.add_owned_skill(chosen_skill_id)
		_finish_reward_sequence()
		return

	var equipped_skill_ids: Array[String] = owner.RUN_STATE.get_equipped_skill_ids()
	if index < 0 or index >= equipped_skill_ids.size():
		return
	if reward_mode == "trim_existing":
		owner._play_ui_sound("confirm")
		owner.RUN_STATE.remove_owned_skill(equipped_skill_ids[index])
		pending_trim_for_boss_relic = false
		if owner.RUN_STATE.has_relic("burst_archive"):
			owner.RUN_STATE.advance_after_stage_clear()
			pending_post_boss_card_rewards = 3
			show_card_reward_popup()
			return
		owner.RUN_STATE.advance_after_stage_clear()
		if owner.reward_overlay != null:
			owner.reward_overlay.visible = false
		if owner.result_label != null:
			owner.result_label.text = "Act 1 Clear"
		if owner.result_overlay != null:
			owner.result_overlay.visible = true
		owner._refresh_ui()
		return_to_stage_select_after_delay()
		return
	if pending_selected_reward_skill_id.is_empty():
		owner._play_ui_sound("error")
		return
	owner._play_ui_sound("confirm")
	var removed_skill_id: String = equipped_skill_ids[index]
	owner.RUN_STATE.replace_owned_skill(removed_skill_id, pending_selected_reward_skill_id)
	_finish_reward_sequence()


func _update_reward_header() -> void:
	if reward_title_label == null or reward_subtitle_label == null or reward_nav_button == null:
		return
	if reward_mode == "choose_reward":
		reward_title_label.text = "Choose A Card"
		if reward_pick_reroll:
			reward_subtitle_label.text = "Choose 1 card to reroll."
		else:
			reward_subtitle_label.text = "Pick a reward card or skip."
		reward_nav_button.text = "Skip"
	elif reward_mode == "choose_relic":
		reward_title_label.text = "Choose A Boss Relic" if pending_reward_relic_source == "boss" else "Choose A Relic"
		reward_subtitle_label.text = "Pick 1 boss relic reward." if pending_reward_relic_source == "boss" else "Pick 1 relic reward."
		reward_nav_button.text = "Skip"
		reward_nav_button.disabled = true
	elif reward_mode == "trim_existing":
		reward_title_label.text = "Remove A Card"
		reward_subtitle_label.text = "This relic lowers your card limit. Choose 1 card to remove."
		reward_nav_button.text = "Locked"
		reward_nav_button.disabled = true
	else:
		var chosen_skill: Dictionary = owner.SKILL_CATALOG.get_skill(pending_selected_reward_skill_id)
		reward_title_label.text = "Remove A Card"
		reward_subtitle_label.text = "To take %s, choose 1 card to remove." % String(chosen_skill.get("name", pending_selected_reward_skill_id))
		reward_nav_button.text = "Back"
		reward_nav_button.disabled = false
	if reward_mode == "choose_reward":
		reward_nav_button.disabled = false
	if reward_reroll_button != null:
		reward_reroll_button.visible = reward_mode == "choose_reward" and reward_reroll_available
		reward_reroll_button.disabled = not reward_reroll_available
		if reward_pick_reroll:
			reward_reroll_button.text = "Reroll Ready"
		else:
			reward_reroll_button.text = "Reroll 1 Card"


func _on_reward_nav_pressed() -> void:
	if _is_reward_input_locked():
		return
	_hide_reward_card_detail()
	if reward_mode == "choose_relic":
		owner._play_ui_sound("error")
		return
	if reward_mode == "trim_existing":
		owner._play_ui_sound("error")
		return
	if reward_mode == "choose_reward":
		owner._play_ui_sound("cancel")
		reward_pick_reroll = false
		_finish_reward_sequence()
		return
	owner._play_ui_sound("cancel")
	reward_mode = "choose_reward"
	pending_selected_reward_skill_id = ""
	reward_pick_reroll = false
	populate_reward_cards()


func _on_reward_reroll_pressed() -> void:
	if _is_reward_input_locked():
		return
	_hide_reward_card_detail()
	if reward_mode != "choose_reward":
		owner._play_ui_sound("error")
		return
	if not reward_reroll_available:
		owner._play_ui_sound("error")
		return
	owner._play_ui_sound("select")
	reward_pick_reroll = true
	_update_reward_header()


func _reroll_reward_card(index: int) -> void:
	_hide_reward_card_detail()
	if index < 0 or index >= owner.pending_reward_skill_ids.size():
		return
	var old_skill_id: String = owner.pending_reward_skill_ids[index]
	var owned_skill_ids: Array[String] = owner.RUN_STATE.get_owned_skill_ids()
	var rarity_chances: Dictionary = owner.RUN_STATE.get_card_rarity_chances()
	var offered: Array[String] = owner.pending_reward_skill_ids.duplicate()
	offered.remove_at(index)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var new_skill_id: String = roll_reward_skill_id(rng, owned_skill_ids, offered, rarity_chances, [old_skill_id])
	if new_skill_id.is_empty():
		reward_pick_reroll = false
		reward_reroll_available = false
		populate_reward_cards()
		return
	owner.pending_reward_skill_ids[index] = new_skill_id
	reward_pick_reroll = false
	reward_reroll_available = false
	populate_reward_cards()


func _finish_reward_sequence() -> void:
	_hide_reward_card_detail()
	if pending_post_boss_card_rewards > 0:
		pending_post_boss_card_rewards -= 1
		if pending_post_boss_card_rewards > 0:
			show_card_reward_popup()
			return
		if owner.reward_overlay != null:
			owner.reward_overlay.visible = false
		if owner.result_label != null:
			owner.result_label.text = "Act 1 Clear"
		if owner.result_overlay != null:
			owner.result_overlay.visible = true
		owner._refresh_ui()
		return_to_stage_select_after_delay()
		return
	owner.RUN_STATE.advance_after_stage_clear()
	if owner.reward_overlay != null:
		owner.reward_overlay.visible = false
	reward_pick_reroll = false
	reward_reroll_available = false
	pending_reward_relic_source = "normal"
	pending_trim_for_boss_relic = false
	owner.get_tree().change_scene_to_file("res://scenes/stage_select_screen.tscn")


func _get_reward_skill_id_for_index(index: int) -> String:
	if reward_mode == "choose_reward":
		if index >= 0 and index < owner.pending_reward_skill_ids.size():
			return owner.pending_reward_skill_ids[index]
	elif reward_mode == "remove_existing" or reward_mode == "trim_existing":
		var equipped_skill_ids: Array[String] = owner.RUN_STATE.get_equipped_skill_ids()
		if index >= 0 and index < equipped_skill_ids.size():
			return equipped_skill_ids[index]
	return ""


func _show_reward_card_detail(index: int) -> void:
	var skill_id: String = _get_reward_skill_id_for_index(index)
	if skill_id.is_empty():
		return
	var skill: Dictionary = owner.SKILL_CATALOG.get_skill(skill_id)
	if skill.is_empty():
		return
	current_reward_detail_skill_id = skill_id
	var detail_description: String = String(skill.get("detail_description", ""))
	if detail_description.is_empty():
		detail_description = String(skill.get("description", ""))
	reward_detail_title.text = "%s [%s]" % [
		String(skill.get("name", skill_id)),
		String(skill.get("rarity", "common")).capitalize()
	]
	reward_detail_body.text = "%s  |  CD %d\n%s" % [
		String(skill.get("category", "utility")).capitalize(),
		int(skill.get("cooldown", 0)),
		detail_description
	]
	var button: Button = owner.reward_card_buttons[index]
	var button_rect: Rect2 = button.get_global_rect()
	reward_detail_panel.global_position = Vector2(button_rect.position.x + button_rect.size.x + 12.0, button_rect.position.y)
	reward_detail_panel.visible = true


func _hide_reward_card_detail() -> void:
	if reward_detail_panel != null:
		reward_detail_panel.visible = false
	current_reward_detail_skill_id = ""


func _on_reward_card_gui_input(event: InputEvent, index: int) -> void:
	if reward_mode == "choose_relic":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var skill_id: String = _get_reward_skill_id_for_index(index)
		if skill_id.is_empty():
			return
		if reward_detail_panel != null and reward_detail_panel.visible and current_reward_detail_skill_id == skill_id:
			_hide_reward_card_detail()
		else:
			_show_reward_card_detail(index)
