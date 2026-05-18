extends RefCounted
class_name BattleUIRenderer

const RELIC_CATALOG = preload("res://scripts/relic_catalog.gd")
const CARD_FILL_CONTROL_PATH := "res://asset/card_new/card_fill_control.png"
const CARD_FILL_DAMAGE_PATH := "res://asset/card_new/card_fill_damage.png"
const CARD_FILL_STRUCTURE_PATH := "res://asset/card_new/card_fill_structure.png"
const CARD_FILL_UTILITY_PATH := "res://asset/card_new/card_fill_utility.png"
const CARD_FILL_UTILITY_FALLBACK_PATH := "res://asset/card_new/card_fill_utill.png"
const CARD_MASK_COMMON_PATH := "res://asset/card_new/card_mask_common.png"
const CARD_MASK_EMPTY_PATH := "res://asset/card_new/card_mask_empty.png"
const CARD_MASK_RARE_PATH := "res://asset/card_new/card_mask_rare.png"
const CARD_MASK_EPIC_PATH := "res://asset/card_new/card_mask_epic.png"
const CARD_MASK_PICK_PATH := "res://asset/card_new/card_mask_pick.png"
const CARD_TIMEBOX_NOTREADY_PATH := "res://asset/card_new/card_timebox_notready.png"
const CARD_TIMEBOX_READY_PATH := "res://asset/card_new/card_timebox_ready.png"
const CARD_FONT_PATH := "res://fonts/Galmuri11.ttf"
const ACTION_COUNT_READY_PATH := "res://asset/turn_action/useablecount.png"
const ACTION_COUNT_ZERO_PATH := "res://asset/turn_action/countzero.png"
const ENERGY_BUTTON_PATH := "res://asset/turn_action/energy.png"
const END_BUTTON_PATH := "res://asset/turn_action/end.png"
const CARD_TEXT_COLOR := Color(0.239216, 0.145098, 0.231373, 1.0)
const CARD_TEXT_OUTLINE_COLOR := Color(0.12, 0.07, 0.11, 1.0)

var owner: Control
var relic_detail_panel: PanelContainer
var relic_detail_title: Label
var relic_detail_body: Label


func setup(battle_owner: Control) -> void:
	owner = battle_owner
	_ensure_relic_panel()
	_ensure_relic_detail_panel()


func _get_rarity_border_color(rarity: String) -> Color:
	match rarity.to_lower():
		"common":
			return Color(0.68, 0.86, 0.5, 0.82)
		"rare":
			return Color(0.52, 0.82, 0.98, 0.9)
		"epic":
			return Color(0.78, 0.5, 0.96, 0.92)
		_:
			return Color(0.6, 0.72, 0.6, 0.8)


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
			return Color(0.42, 0.14, 0.14, 0.96)
		"utility":
			return Color(0.14, 0.22, 0.38, 0.96)
		"control":
			return Color(0.15, 0.32, 0.17, 0.96)
		"install":
			return Color(0.36, 0.18, 0.52, 0.96)
		_:
			return Color(0.18, 0.18, 0.18, 0.96)


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func _get_card_fill_texture(skill: Dictionary) -> Texture2D:
	match _resolve_visual_category(String(skill.get("category", ""))):
		"damage":
			return _load_texture_if_exists(CARD_FILL_DAMAGE_PATH)
		"utility":
			var utility_texture: Texture2D = _load_texture_if_exists(CARD_FILL_UTILITY_PATH)
			if utility_texture == null:
				utility_texture = _load_texture_if_exists(CARD_FILL_UTILITY_FALLBACK_PATH)
			return utility_texture
		"control":
			return _load_texture_if_exists(CARD_FILL_CONTROL_PATH)
		"install":
			return _load_texture_if_exists(CARD_FILL_STRUCTURE_PATH)
		_:
			return null


func _get_card_mask_texture(skill: Dictionary) -> Texture2D:
	match String(skill.get("rarity", "")).to_lower():
		"common":
			return _load_texture_if_exists(CARD_MASK_COMMON_PATH)
		"rare":
			return _load_texture_if_exists(CARD_MASK_RARE_PATH)
		"epic":
			return _load_texture_if_exists(CARD_MASK_EPIC_PATH)
		_:
			return _load_texture_if_exists(CARD_MASK_COMMON_PATH)


func _uses_pixel_card_art(skill: Dictionary) -> bool:
	return _get_card_mask_texture(skill) != null


func _get_card_font() -> Font:
	return load(CARD_FONT_PATH)


func _build_texture_stylebox(texture_path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(texture_path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 8
	style.texture_margin_top = 8
	style.texture_margin_right = 8
	style.texture_margin_bottom = 8
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style


func build_skill_buttons() -> void:
	owner.skills.clear()
	owner.skill_buttons.clear()
	owner.skill_list_body.visible = false

	for child in owner.skill_list_content.get_children():
		if child is Button and (child.name.begins_with("SkillButton_") or child.name.begins_with("EmptySkillSlot_")):
			child.queue_free()

	var equipped_skill_ids: Array[String] = owner.RUN_STATE.get_equipped_skill_ids()
	for skill_id in equipped_skill_ids:
		var skill_data: Dictionary = owner.SKILL_CATALOG.get_skill(skill_id)
		if skill_data.is_empty():
			continue
		var skill := {
			"id": skill_id,
			"name": skill_data["name"],
			"rarity": String(skill_data.get("rarity", "common")),
			"category": String(skill_data["category"]),
			"cooldown": int(skill_data["cooldown"]),
			"consumes_action": bool(skill_data.get("consumes_action", true)),
			"action_cost": int(skill_data.get("action_cost", 1)),
			"current_cd": 0,
			"current_stack": 0,
			"description": skill_data["description"],
			"detail_description": skill_data.get("detail_description", ""),
			"values": skill_data["values"].duplicate(true),
			"targeting_type": String(skill_data["targeting_type"]),
			"effect_key": String(skill_data["effect_key"]),
		}
		owner.skills.append(skill)

	for skill in owner.skills:
		var button := create_skill_card(skill)
		owner.skill_list_content.add_child(button)
		owner.skill_buttons[skill["id"]] = button

	for index in range(owner.skills.size(), 6):
		var empty_slot := create_empty_skill_slot(index)
		owner.skill_list_content.add_child(empty_slot)


func refresh_ui() -> void:
	var current_actions: int = owner.turn_manager.get_actions_left()
	var current_turn: int = owner.turn_manager.get_turn_number()
	if owner.basic_info_label != null:
		var total_waves: int = max(owner.wave_defs.size(), 1)
		var wave_turn_text := "Final"
		if owner.wave_turns_remaining >= 0:
			wave_turn_text = str(owner.wave_turns_remaining)
		var info_text := "Wave %d / %d\nTurn %d\nActions %d" % [owner.wave_index + 1, total_waves, current_turn, current_actions]
		if owner.wave_turns_remaining >= 0:
			info_text += "\nWave Turns %s" % wave_turn_text
		owner.basic_info_label.text = info_text
	if owner.player_life_label != null:
		owner.player_life_label.text = "Life %d/%d" % [owner.life, owner.max_life]
	if owner.action_count_label != null:
		owner.action_count_label.text = str(current_actions)
		owner.action_count_label.add_theme_font_override("font", _get_card_font())
		owner.action_count_label.add_theme_font_size_override("font_size", 60)
		owner.action_count_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
		owner.action_count_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
		owner.action_count_label.add_theme_constant_override("outline_size", 2)
	if owner.energy_button != null:
		owner.energy_button.add_theme_font_override("font", _get_card_font())
		owner.energy_button.add_theme_font_size_override("font_size", 22)
		owner.energy_button.add_theme_color_override("font_color", CARD_TEXT_COLOR)
		owner.energy_button.add_theme_color_override("font_hover_color", CARD_TEXT_COLOR)
		owner.energy_button.add_theme_color_override("font_pressed_color", CARD_TEXT_COLOR)
		owner.energy_button.add_theme_color_override("font_focus_color", CARD_TEXT_COLOR)
		owner.energy_button.add_theme_color_override("font_disabled_color", CARD_TEXT_COLOR.darkened(0.2))
		owner.energy_button.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
		owner.energy_button.add_theme_constant_override("outline_size", 2)
		var energy_style := _build_texture_stylebox(ENERGY_BUTTON_PATH)
		if energy_style != null:
			owner.energy_button.add_theme_stylebox_override("normal", energy_style)
			owner.energy_button.add_theme_stylebox_override("hover", energy_style)
			owner.energy_button.add_theme_stylebox_override("pressed", energy_style)
			owner.energy_button.add_theme_stylebox_override("focus", energy_style)
			owner.energy_button.add_theme_stylebox_override("disabled", energy_style)
		owner.energy_button.modulate = Color(0.6, 0.6, 0.6, 1.0) if owner.battle_finished or not owner.turn_manager.can_use_energy() else Color(1, 1, 1, 1)
	if owner.end_turn_button != null:
		owner.end_turn_button.add_theme_font_override("font", _get_card_font())
		owner.end_turn_button.add_theme_font_size_override("font_size", 22)
		owner.end_turn_button.add_theme_color_override("font_color", CARD_TEXT_COLOR)
		owner.end_turn_button.add_theme_color_override("font_hover_color", CARD_TEXT_COLOR)
		owner.end_turn_button.add_theme_color_override("font_pressed_color", CARD_TEXT_COLOR)
		owner.end_turn_button.add_theme_color_override("font_focus_color", CARD_TEXT_COLOR)
		owner.end_turn_button.add_theme_color_override("font_disabled_color", CARD_TEXT_COLOR.darkened(0.2))
		owner.end_turn_button.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
		owner.end_turn_button.add_theme_constant_override("outline_size", 2)
		var end_style := _build_texture_stylebox(END_BUTTON_PATH)
		if end_style != null:
			owner.end_turn_button.add_theme_stylebox_override("normal", end_style)
			owner.end_turn_button.add_theme_stylebox_override("hover", end_style)
			owner.end_turn_button.add_theme_stylebox_override("pressed", end_style)
			owner.end_turn_button.add_theme_stylebox_override("focus", end_style)
			owner.end_turn_button.add_theme_stylebox_override("disabled", end_style)
	owner._update_action_count_visual(current_actions)
	owner.end_turn_button.disabled = owner.battle_finished
	owner.energy_button.disabled = owner.battle_finished or not owner.turn_manager.can_use_energy()
	refresh_enemy_deck_panel()
	refresh_relic_panel()
	update_skill_buttons()
	owner._refresh_energy_popup_state()
	owner._refresh_tile_selection_visuals()


func refresh_enemy_deck_panel() -> void:
	var deck_tiles: Array = owner.enemy_pool_grid.get_children()
	var deck: Array[String] = owner.RUN_STATE.get_enemy_deck()

	for index in range(deck_tiles.size()):
		var tile: PanelContainer = deck_tiles[index]
		clear_enemy_pool_tile(tile)
		if index < deck.size():
			fill_enemy_pool_tile(tile, String(deck[index]))
		else:
			fill_empty_enemy_pool_tile(tile)


func fill_enemy_pool_tile(tile: PanelContainer, enemy_id: String) -> void:
	var enemy: Dictionary = owner.ENEMY_CATALOG.get_enemy(enemy_id)

	var color_rect := ColorRect.new()
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(enemy.get("color", Color(0.3, 0.3, 0.3, 1.0)))
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(color_rect)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(center)

	var label := Label.new()
	label.text = String(enemy.get("short", "?"))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.9, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
	label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(label)


func fill_empty_enemy_pool_tile(tile: PanelContainer) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(center)

	var label := Label.new()
	label.text = "-"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.78, 0.8, 0.84, 0.8))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(label)


func clear_enemy_pool_tile(tile: PanelContainer) -> void:
	for child in tile.get_children():
		child.queue_free()


func _ensure_relic_panel() -> void:
	if owner.get_node_or_null("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/LeftColumn/RelicPanelRuntime") != null:
		return
	var left_column: VBoxContainer = owner.get_node("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/LeftColumn")
	var enemy_pool: Control = left_column.get_node("EnemyPool")
	var basic_info: Control = left_column.get_node("BasicInfo")

	var relic_panel := PanelContainer.new()
	relic_panel.name = "RelicPanelRuntime"
	relic_panel.custom_minimum_size = Vector2(0, 92)
	relic_panel.add_theme_stylebox_override("panel", basic_info.get_theme_stylebox("panel"))

	var margin := MarginContainer.new()
	margin.name = "RelicMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	relic_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "RelicContent"
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var title := Label.new()
	title.name = "RelicTitle"
	title.text = "Relics"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1.0))
	content.add_child(title)

	var list := VBoxContainer.new()
	list.name = "RelicList"
	list.add_theme_constant_override("separation", 4)
	content.add_child(list)

	var enemy_pool_index := enemy_pool.get_index()
	left_column.add_child(relic_panel)
	left_column.move_child(relic_panel, enemy_pool_index + 1)


func _ensure_relic_detail_panel() -> void:
	if relic_detail_panel != null:
		return
	relic_detail_panel = PanelContainer.new()
	relic_detail_panel.top_level = true
	relic_detail_panel.visible = false
	relic_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_detail_panel.custom_minimum_size = Vector2(280, 140)
	relic_detail_panel.z_index = 950
	relic_detail_panel.add_theme_stylebox_override("panel", owner.player_core_panel.get_theme_stylebox("panel"))
	owner.add_child(relic_detail_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	relic_detail_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	relic_detail_title = Label.new()
	relic_detail_title.add_theme_font_size_override("font_size", 18)
	relic_detail_title.add_theme_color_override("font_color", Color(0.93, 0.94, 0.82, 1.0))
	content.add_child(relic_detail_title)

	relic_detail_body = Label.new()
	relic_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relic_detail_body.add_theme_font_size_override("font_size", 14)
	relic_detail_body.add_theme_color_override("font_color", Color(0.79, 0.84, 0.77, 1.0))
	relic_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(relic_detail_body)


func refresh_relic_panel() -> void:
	var relic_panel: PanelContainer = owner.get_node_or_null("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/LeftColumn/RelicPanelRuntime")
	if relic_panel == null:
		return
	var relic_list: VBoxContainer = relic_panel.get_node("RelicMargin/RelicContent/RelicList")
	for child in relic_list.get_children():
		child.queue_free()

	var relic_ids: Array[String] = owner.RUN_STATE.get_relic_ids()
	if relic_ids.is_empty():
		_hide_relic_detail()
		var empty_label := Label.new()
		empty_label.text = "-"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.74, 0.7, 0.95))
		relic_list.add_child(empty_label)
		return

	for relic_id in relic_ids:
		var relic: Dictionary = RELIC_CATALOG.get_relic(String(relic_id))
		var relic_label := Label.new()
		var relic_name: String = String(relic.get("name", relic_id))
		if String(relic_id) == "decimator":
			var decimator_progress: int = int(owner.RUN_STATE.get_card_use_count()) % 10
			relic_name = "%s %d/10" % [relic_name, decimator_progress]
		elif String(relic_id) == "momentum":
			relic_name = "%s %d" % [relic_name, max(int(owner.same_card_damage_streak), 0)]
		relic_label.text = relic_name
		relic_label.add_theme_font_size_override("font_size", 14)
		relic_label.add_theme_color_override("font_color", Color(0.87, 0.9, 0.78, 1.0))
		relic_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
		relic_label.add_theme_constant_override("outline_size", 1)
		relic_label.tooltip_text = String(relic.get("description", ""))
		relic_label.mouse_filter = Control.MOUSE_FILTER_STOP
		relic_label.mouse_entered.connect(_show_relic_detail.bind(relic_label, relic))
		relic_label.mouse_exited.connect(_hide_relic_detail)
		relic_list.add_child(relic_label)


func _show_relic_detail(target: Control, relic: Dictionary) -> void:
	if relic_detail_panel == null or target == null:
		return
	relic_detail_title.text = String(relic.get("name", "Relic"))
	relic_detail_body.text = String(relic.get("description", ""))
	var rect: Rect2 = target.get_global_rect()
	relic_detail_panel.global_position = Vector2(rect.end.x + 12.0, rect.position.y - 6.0)
	relic_detail_panel.visible = true


func _hide_relic_detail() -> void:
	if relic_detail_panel != null:
		relic_detail_panel.visible = false


func update_skill_buttons() -> void:
	var current_actions: int = owner.turn_manager.get_actions_left()
	for skill in owner.skills:
		var button: Button = owner.skill_buttons.get(skill["id"], null)
		if button == null:
			continue
		var consumes_action: bool = bool(skill.get("consumes_action", true))
		var action_cost: int = max(int(skill.get("action_cost", 1)), 0)
		var has_actions: bool = current_actions >= action_cost or not consumes_action
		var usable: bool = not owner.battle_finished and int(skill["current_cd"]) <= 0 and has_actions
		button.disabled = owner.battle_finished
		apply_skill_card_state(button, skill, usable, current_actions)


func create_skill_card(skill: Dictionary) -> Button:
	var button := Button.new()
	button.name = "SkillButton_%s" % skill["id"]
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = ""
	button.flat = false
	button.pressed.connect(owner._select_skill.bind(skill["id"]))
	button.gui_input.connect(owner._on_skill_card_gui_input.bind(skill["id"]))

	var art_fill := TextureRect.new()
	art_fill.name = "ArtFill"
	art_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_fill.stretch_mode = TextureRect.STRETCH_SCALE
	art_fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art_fill.visible = false
	button.add_child(art_fill)

	var art_mask := TextureRect.new()
	art_mask.name = "ArtMask"
	art_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_mask.stretch_mode = TextureRect.STRETCH_SCALE
	art_mask.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art_mask.visible = false
	button.add_child(art_mask)

	var cooldown_art := TextureRect.new()
	cooldown_art.name = "CooldownArt"
	cooldown_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_art.stretch_mode = TextureRect.STRETCH_SCALE
	cooldown_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cooldown_art.visible = false
	button.add_child(cooldown_art)

	var art_pick := TextureRect.new()
	art_pick.name = "ArtPick"
	art_pick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_pick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_pick.stretch_mode = TextureRect.STRETCH_SCALE
	art_pick.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art_pick.texture = load(CARD_MASK_PICK_PATH)
	art_pick.visible = false
	button.add_child(art_pick)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	button.add_child(row)

	var text_margin := MarginContainer.new()
	text_margin.name = "TextMargin"
	text_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_margin.add_theme_constant_override("margin_left", 19)
	text_margin.add_theme_constant_override("margin_top", 16)
	text_margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(text_margin)

	var text_column := VBoxContainer.new()
	text_column.name = "TextColumn"
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_theme_constant_override("separation", 4)
	text_margin.add_child(text_column)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = skill["name"]
	name_label.add_theme_font_override("font", _get_card_font())
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	name_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(name_label)

	var desc_label := Label.new()
	desc_label.name = "DescriptionLabel"
	desc_label.text = String(skill["description"])
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.clip_text = true
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_override("font", _get_card_font())
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	desc_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	desc_label.add_theme_constant_override("outline_size", 2)
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(desc_label)

	var cooldown_box := PanelContainer.new()
	cooldown_box.name = "CooldownBox"
	cooldown_box.custom_minimum_size = Vector2(70, 70)
	cooldown_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cooldown_box)

	var cooldown_margin := MarginContainer.new()
	cooldown_margin.name = "CooldownMargin"
	cooldown_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cooldown_margin.add_theme_constant_override("margin_left", 9)
	cooldown_margin.add_theme_constant_override("margin_top", 4)
	cooldown_margin.add_theme_constant_override("margin_right", -1)
	cooldown_margin.add_theme_constant_override("margin_bottom", 4)
	cooldown_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_box.add_child(cooldown_margin)

	var cooldown_column := VBoxContainer.new()
	cooldown_column.name = "CooldownColumn"
	cooldown_column.alignment = BoxContainer.ALIGNMENT_CENTER
	cooldown_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cooldown_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_column.add_theme_constant_override("separation", 0)
	cooldown_margin.add_child(cooldown_column)

	var cooldown_label := Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_override("font", _get_card_font())
	cooldown_label.add_theme_font_size_override("font_size", 42)
	cooldown_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	cooldown_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	cooldown_label.add_theme_constant_override("outline_size", 2)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_column.add_child(cooldown_label)

	var state_label := Label.new()
	state_label.name = "StateLabel"
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_override("font", _get_card_font())
	state_label.add_theme_font_size_override("font_size", 14)
	state_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	state_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	state_label.add_theme_constant_override("outline_size", 2)
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_column.add_child(state_label)

	apply_skill_card_state(button, skill, true, owner.turn_manager.get_actions_left())
	return button


func create_empty_skill_slot(index: int) -> Button:
	var button := Button.new()
	button.name = "EmptySkillSlot_%d" % index
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = true
	button.text = ""

	var empty_mask := TextureRect.new()
	empty_mask.name = "EmptyMask"
	empty_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_mask.texture = load(CARD_MASK_EMPTY_PATH)
	empty_mask.stretch_mode = TextureRect.STRETCH_SCALE
	empty_mask.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_child(empty_mask)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0, 0, 0, 0)
	slot_style.border_color = Color(0, 0, 0, 0)
	slot_style.content_margin_left = 0
	slot_style.content_margin_top = 0
	slot_style.content_margin_right = 0
	slot_style.content_margin_bottom = 0
	button.add_theme_stylebox_override("normal", slot_style)
	button.add_theme_stylebox_override("hover", slot_style)
	button.add_theme_stylebox_override("pressed", slot_style)
	button.add_theme_stylebox_override("focus", slot_style)
	button.add_theme_stylebox_override("disabled", slot_style)

	return button


func apply_skill_card_state(button: Button, skill: Dictionary, usable: bool, current_actions: int) -> void:
	var name_label: Label = button.get_node_or_null("Row/TextMargin/TextColumn/NameLabel")
	var desc_label: Label = button.get_node_or_null("Row/TextMargin/TextColumn/DescriptionLabel")
	var cooldown_box: PanelContainer = button.get_node_or_null("Row/CooldownBox")
	var cooldown_art: TextureRect = button.get_node_or_null("CooldownArt")
	var cooldown_label: Label = button.get_node_or_null("Row/CooldownBox/CooldownMargin/CooldownColumn/CooldownLabel")
	var state_label: Label = button.get_node_or_null("Row/CooldownBox/CooldownMargin/CooldownColumn/StateLabel")
	var art_fill: TextureRect = button.get_node_or_null("ArtFill")
	var art_mask: TextureRect = button.get_node_or_null("ArtMask")
	var art_pick: TextureRect = button.get_node_or_null("ArtPick")

	if name_label == null or desc_label == null or cooldown_box == null or cooldown_label == null or state_label == null:
		return

	cooldown_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	cooldown_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	cooldown_label.add_theme_constant_override("outline_size", 2)
	state_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	state_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	state_label.add_theme_constant_override("outline_size", 2)
	desc_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	desc_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	desc_label.add_theme_constant_override("outline_size", 2)

	name_label.text = String(skill["name"])
	desc_label.text = String(owner._get_runtime_skill_description(skill))
	var consumes_action: bool = bool(skill.get("consumes_action", true))
	var action_cost: int = max(int(skill.get("action_cost", 1)), 0)
	var has_actions: bool = current_actions >= action_cost or not consumes_action
	var skill_id: String = String(skill.get("id", ""))
	var is_cd_pick_mode: bool = owner.pending_energy_mode == "reduce_cd"
	var is_swap_mode: bool = owner.pending_cooldown_swap_active
	var is_cd_pick_candidate: bool = is_cd_pick_mode and int(skill.get("current_cd", 0)) > 0
	var is_swap_candidate: bool = false
	var is_discipline_locked: bool = false
	if is_swap_mode:
		is_swap_candidate = skill_id != String(owner.pending_cooldown_swap_card_id) and not owner.pending_cooldown_swap_selected_ids.has(skill_id)
	if not is_cd_pick_mode and not is_swap_mode:
		is_discipline_locked = owner._is_same_category_restricted(skill)
	var use_pixel_art: bool = _uses_pixel_card_art(skill)
	var fill_texture: Texture2D = _get_card_fill_texture(skill)
	var mask_texture: Texture2D = _get_card_mask_texture(skill)
	var rarity_border_color: Color = _get_rarity_border_color(String(skill.get("rarity", "common")))
	var category_fill_color: Color = _get_category_fill_color(String(skill.get("category", "utility")))

	var card_style := StyleBoxFlat.new()
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.content_margin_left = 12
	card_style.content_margin_top = 10
	card_style.content_margin_right = 10
	card_style.content_margin_bottom = 10

	var cooldown_style := StyleBoxFlat.new()
	cooldown_style.corner_radius_top_left = 8
	cooldown_style.corner_radius_top_right = 8
	cooldown_style.corner_radius_bottom_right = 8
	cooldown_style.corner_radius_bottom_left = 8
	cooldown_style.border_width_left = 2
	cooldown_style.border_width_top = 2
	cooldown_style.border_width_right = 2
	cooldown_style.border_width_bottom = 2
	if skill["current_cd"] > 0:
		card_style.bg_color = category_fill_color.darkened(0.45)
		card_style.border_color = rarity_border_color.lerp(Color(0.24, 0.24, 0.24, 0.8), 0.45)
		cooldown_style.bg_color = rarity_border_color.lerp(Color(0.24, 0.12, 0.1, 0.96), 0.78)
		cooldown_style.border_color = Color(0.86, 0.42, 0.36, 0.88)
		cooldown_label.text = str(skill["current_cd"])
		state_label.text = "WAIT"
	elif not has_actions:
		card_style.bg_color = category_fill_color.darkened(0.56)
		card_style.border_color = rarity_border_color.lerp(Color(0.22, 0.24, 0.28, 0.86), 0.5)
		cooldown_style.bg_color = rarity_border_color.lerp(Color(0.13, 0.15, 0.18, 0.96), 0.82)
		cooldown_style.border_color = rarity_border_color.lerp(Color(0.36, 0.41, 0.48, 0.85), 0.35)
		cooldown_label.text = str(owner._get_skill_effective_cooldown(skill))
		state_label.text = "WAIT"
	else:
		card_style.bg_color = category_fill_color
		card_style.border_color = rarity_border_color
		cooldown_style.bg_color = rarity_border_color.lerp(Color(0.1, 0.14, 0.1, 0.98), 0.78)
		cooldown_style.border_color = rarity_border_color
		cooldown_label.text = str(owner._get_skill_effective_cooldown(skill))
		state_label.text = "READY"

	if is_discipline_locked:
		card_style.bg_color = category_fill_color.darkened(0.48)
		card_style.border_color = rarity_border_color.lerp(Color(0.28, 0.26, 0.32, 0.9), 0.5)
		cooldown_style.bg_color = rarity_border_color.lerp(Color(0.16, 0.15, 0.19, 0.96), 0.8)
		cooldown_style.border_color = rarity_border_color.lerp(Color(0.4, 0.38, 0.46, 0.9), 0.35)
		state_label.text = "LOCKED"

	if skill_id == owner.selected_skill_id:
		card_style.border_width_left = 4
		card_style.border_width_top = 4
		card_style.border_width_right = 4
		card_style.border_width_bottom = 4
		card_style.border_color = Color(0.95, 0.86, 0.45, 1.0)
		cooldown_style.border_width_left = 3
		cooldown_style.border_width_top = 3
		cooldown_style.border_width_right = 3
		cooldown_style.border_width_bottom = 3
		cooldown_style.border_color = Color(0.95, 0.86, 0.45, 1.0)
		state_label.text = "SELECTED"

	if is_cd_pick_mode:
		if is_cd_pick_candidate:
			card_style.border_width_left = max(card_style.border_width_left, 3)
			card_style.border_width_top = max(card_style.border_width_top, 3)
			card_style.border_width_right = max(card_style.border_width_right, 3)
			card_style.border_width_bottom = max(card_style.border_width_bottom, 3)
			card_style.border_color = Color(0.5, 0.88, 1.0, 1.0)
			state_label.text = "PICK CD"
		else:
			state_label.text = "LOCKED"

	if is_swap_mode:
		if skill_id == String(owner.pending_cooldown_swap_card_id):
			card_style.border_width_left = max(card_style.border_width_left, 3)
			card_style.border_width_top = max(card_style.border_width_top, 3)
			card_style.border_width_right = max(card_style.border_width_right, 3)
			card_style.border_width_bottom = max(card_style.border_width_bottom, 3)
			card_style.border_color = Color(0.84, 0.56, 1.0, 1.0)
			state_label.text = "REWIRE"
		elif owner.pending_cooldown_swap_selected_ids.has(skill_id):
			card_style.border_width_left = max(card_style.border_width_left, 3)
			card_style.border_width_top = max(card_style.border_width_top, 3)
			card_style.border_width_right = max(card_style.border_width_right, 3)
			card_style.border_width_bottom = max(card_style.border_width_bottom, 3)
			card_style.border_color = Color(1.0, 0.82, 0.36, 1.0)
			state_label.text = "PICKED"
		elif is_swap_candidate:
			card_style.border_width_left = max(card_style.border_width_left, 3)
			card_style.border_width_top = max(card_style.border_width_top, 3)
			card_style.border_width_right = max(card_style.border_width_right, 3)
			card_style.border_width_bottom = max(card_style.border_width_bottom, 3)
			card_style.border_color = Color(0.56, 0.92, 0.78, 1.0)
			state_label.text = "SWAP"
		else:
			state_label.text = "LOCKED"

	if consumes_action and action_cost > 1:
		state_label.text = "%s C%d" % [state_label.text, action_cost]

	if use_pixel_art:
		if fill_texture != null:
			card_style.bg_color = Color(0, 0, 0, 0)
		card_style.border_color = Color(0, 0, 0, 0)
		cooldown_style.bg_color = Color(0, 0, 0, 0)
		cooldown_style.border_color = Color(0, 0, 0, 0)
		name_label.add_theme_font_size_override("font_size", 18)
		desc_label.add_theme_font_size_override("font_size", 14)
		if art_fill != null:
			art_fill.texture = fill_texture
			art_fill.visible = fill_texture != null
			if fill_texture != null:
				art_fill.modulate = Color(0.6, 0.6, 0.6, 0.92) if skill["current_cd"] > 0 else (Color(0.6, 0.6, 0.6, 0.9) if not has_actions or is_discipline_locked else Color(1, 1, 1, 0.92))
		if art_mask != null:
			art_mask.texture = mask_texture
			art_mask.visible = mask_texture != null
			art_mask.modulate = Color(0.6, 0.6, 0.6, 1.0) if skill["current_cd"] > 0 or not has_actions or is_discipline_locked else Color(1, 1, 1, 1)
		if cooldown_art != null:
			cooldown_art.visible = true
			cooldown_art.texture = load(CARD_TIMEBOX_NOTREADY_PATH) if skill["current_cd"] > 0 else load(CARD_TIMEBOX_READY_PATH)
			cooldown_art.modulate = Color(0.6, 0.6, 0.6, 1.0) if skill["current_cd"] > 0 or not has_actions or is_discipline_locked else Color(1, 1, 1, 1)
		if art_pick != null:
			art_pick.visible = skill_id == owner.selected_skill_id
			art_pick.modulate = Color(1, 1, 1, 1)
		state_label.visible = false
		if skill_id == owner.selected_skill_id:
			card_style.border_width_left = 0
			card_style.border_width_top = 0
			card_style.border_width_right = 0
			card_style.border_width_bottom = 0
			card_style.border_color = Color(0, 0, 0, 0)
	else:
		if art_fill != null:
			art_fill.visible = false
		if art_mask != null:
			art_mask.visible = false
		if art_pick != null:
			art_pick.visible = false
		if cooldown_art != null:
			cooldown_art.visible = false
		cooldown_label.visible = true
		state_label.visible = true

	button.add_theme_stylebox_override("normal", card_style)
	button.add_theme_stylebox_override("hover", card_style)
	button.add_theme_stylebox_override("pressed", card_style)
	button.add_theme_stylebox_override("focus", card_style)
	button.add_theme_stylebox_override("disabled", card_style)
	cooldown_box.add_theme_stylebox_override("panel", cooldown_style)
