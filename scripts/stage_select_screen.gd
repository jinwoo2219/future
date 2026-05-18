extends Control

const RUN_STATE = preload("res://scripts/run_state.gd")
const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")
const SKILL_CATALOG = preload("res://scripts/skill_catalog.gd")
const TOTEM_CATALOG = preload("res://scripts/totem_catalog.gd")
const ENEMY_UI_SCENE = preload("res://scenes/enemy_ui.tscn")
const UI_SOUND_CANCEL_1 = "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Cancel - 1.wav"
const UI_SOUND_CANCEL_2 = "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Cancel - 2.wav"
const UI_SOUND_CONFIRM_1 = "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Confirm - 1.wav"
const UI_SOUND_CURSOR_1 = "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Cursor - 1.wav"
const UI_SOUND_ERROR_1 = "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Error - 1.wav"
const UI_SOUND_SELECT_1 = "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Select - 1.wav"

@onready var stage_map_title: Label = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/StageMapTitle")
@onready var map_hint: Label = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/MapHint")
@onready var map_scroll: ScrollContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll")
@onready var route_history_list: GridContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/RouteHistoryList")
@onready var stage1_card: Button = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage1Card")
@onready var stage1_card_panel: PanelContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage1Card/Stage1CardPanel")
@onready var stage1_title: Label = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage1Card/Stage1CardPanel/Stage1CardMargin/Stage1CardContent/Stage1CardTitle")
@onready var stage1_icon: PanelContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage1Card/Stage1CardPanel/Stage1CardMargin/Stage1CardContent/Stage1BodyRow/Stage1EnemyIcon")
@onready var stage1_desc_panel: PanelContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage1Card/Stage1CardPanel/Stage1CardMargin/Stage1CardContent/Stage1BodyRow/Stage1DescPanel")
@onready var stage1_desc: Label = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage1Card/Stage1CardPanel/Stage1CardMargin/Stage1CardContent/Stage1BodyRow/Stage1DescPanel/Stage1DescMargin/Stage1Desc")
@onready var stage2_card: Button = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage2Card")
@onready var stage2_card_panel: PanelContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage2Card/Stage2CardPanel")
@onready var stage2_title: Label = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage2Card/Stage2CardPanel/Stage2CardMargin/Stage2CardContent/Stage2CardTitle")
@onready var stage2_icon: PanelContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage2Card/Stage2CardPanel/Stage2CardMargin/Stage2CardContent/Stage2BodyRow/Stage2EnemyIcon")
@onready var stage2_desc_panel: PanelContainer = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage2Card/Stage2CardPanel/Stage2CardMargin/Stage2CardContent/Stage2BodyRow/Stage2DescPanel")
@onready var stage2_desc: Label = get_node("Margin/Root/Body/MapViewport/MapViewportMargin/MapViewportContent/StageMapArea/StageMapPanel/StageMapMargin/StageMapContent/MapScroll/MapRouteContent/ChoiceCenter/ChoiceColumn/ChoiceRow/Stage2Card/Stage2CardPanel/Stage2CardMargin/Stage2CardContent/Stage2BodyRow/Stage2DescPanel/Stage2DescMargin/Stage2Desc")
@onready var owned_skill_grid: VBoxContainer = get_node("Margin/Root/Body/LeftSkillColumn/LeftSkillPanel/LeftSkillMargin/LeftSkillContent/OwnedSkillGrid")
@onready var deck_grid: GridContainer = get_node("Margin/Root/Body/RightInfoColumn/EnemyDeckPanel/EnemyDeckMargin/EnemyDeckContent/EnemyDeckGrid")
@onready var deck_score_value: Label = get_node("Margin/Root/Body/RightInfoColumn/DeckInfoPanel/DeckInfoMargin/DeckInfoContent/DeckScoreValue")
@onready var common_value: Label = get_node("Margin/Root/Body/RightInfoColumn/DeckInfoPanel/DeckInfoMargin/DeckInfoContent/ProbabilityRows/CommonRow/CommonValue")
@onready var rare_value: Label = get_node("Margin/Root/Body/RightInfoColumn/DeckInfoPanel/DeckInfoMargin/DeckInfoContent/ProbabilityRows/RareRow/RareValue")
@onready var epic_value: Label = get_node("Margin/Root/Body/RightInfoColumn/DeckInfoPanel/DeckInfoMargin/DeckInfoContent/ProbabilityRows/EpicRow/EpicValue")
@onready var legendary_value: Label = get_node("Margin/Root/Body/RightInfoColumn/DeckInfoPanel/DeckInfoMargin/DeckInfoContent/ProbabilityRows/LegendaryRow/LegendaryValue")
@onready var back_button: Button = get_node("Margin/Root/Header/BackButton")

var enemy_replace_overlay: ColorRect
var enemy_replace_panel: PanelContainer
var enemy_replace_title: Label
var enemy_replace_subtitle: Label
var enemy_replace_choice_icon: PanelContainer
var enemy_replace_grid: GridContainer
var enemy_replace_back_button: Button
var pending_enemy_choice_id: String = ""
var pending_enemy_choice_totem_id: String = ""
var pending_enemy_choice_mode: String = "stage"
var test_mode_overlay: ColorRect
var test_mode_panel: PanelContainer
var card_add_overlay: ColorRect
var card_add_panel: PanelContainer
var card_add_subtitle: Label
var card_add_scroll: ScrollContainer
var card_add_content: VBoxContainer
var card_replace_overlay: ColorRect
var card_replace_panel: PanelContainer
var card_replace_subtitle: Label
var card_replace_grid: GridContainer
var pending_card_choice_id: String = ""
var enemy_add_overlay: ColorRect
var enemy_add_panel: PanelContainer
var enemy_add_subtitle: Label
var enemy_add_scroll: ScrollContainer
var enemy_add_grid: GridContainer
var enemy_hover_detail_panel: PanelContainer
var enemy_hover_detail_title: Label
var ui_sfx_player: AudioStreamPlayer
var enemy_hover_detail_body: Label
var card_hover_detail_panel: PanelContainer
var card_hover_detail_title: Label
var card_hover_detail_body: Label


func _ready() -> void:
	ENEMY_CATALOG.reload()
	back_button.text = "Test Mode"
	_set_mouse_ignore_recursive(stage1_card_panel)
	_set_mouse_ignore_recursive(stage2_card_panel)
	stage1_card.gui_input.connect(_on_stage_card_gui_input.bind(0))
	stage2_card.gui_input.connect(_on_stage_card_gui_input.bind(1))
	_build_test_mode_popup()
	_build_card_add_popup()
	_build_card_replace_popup()
	_build_enemy_replace_popup()
	_build_enemy_add_popup()
	_build_enemy_hover_detail_panel()
	_build_card_hover_detail_panel()
	_build_ui_sfx_player()
	_refresh_owned_skill_ui()
	_refresh_route_history_ui()
	_refresh_stage_options_ui()
	_refresh_enemy_deck_ui()
	call_deferred("_scroll_route_to_bottom")


func _build_ui_sfx_player() -> void:
	ui_sfx_player = AudioStreamPlayer.new()
	ui_sfx_player.name = "UISfxPlayer"
	add_child(ui_sfx_player)


func _play_ui_sound(kind: String) -> void:
	if ui_sfx_player == null:
		return
	var sound_path: String = UI_SOUND_SELECT_1
	match kind:
		"confirm":
			sound_path = UI_SOUND_CONFIRM_1
		"cursor":
			sound_path = UI_SOUND_CURSOR_1
		"error":
			sound_path = UI_SOUND_ERROR_1
		"cancel_alt":
			sound_path = UI_SOUND_CANCEL_2
		"cancel":
			sound_path = UI_SOUND_CANCEL_1
	var stream: AudioStream = load(sound_path)
	if stream == null:
		return
	ui_sfx_player.stream = stream
	ui_sfx_player.play()


func _refresh_owned_skill_ui() -> void:
	var equipped_skill_ids: Array[String] = RUN_STATE.get_equipped_skill_ids()
	var slots: Array = owned_skill_grid.get_children()

	for index in range(slots.size()):
		var slot: PanelContainer = slots[index]
		_clear_tile(slot)
		if index < equipped_skill_ids.size():
			_fill_owned_skill_slot(slot, equipped_skill_ids[index])


func _fill_owned_skill_slot(tile: PanelContainer, skill_id: String) -> void:
	var skill: Dictionary = SKILL_CATALOG.get_skill(skill_id)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12
	label.offset_top = 10
	label.offset_right = -10
	label.offset_bottom = -10
	label.text = String(skill.get("name", skill_id))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.86, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
	label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)


func _refresh_stage_options_ui() -> void:
	stage_map_title.text = RUN_STATE.current_stage_label

	var options: Array[String] = RUN_STATE.get_stage_options()
	if RUN_STATE.current_stage_index == 1:
		map_hint.text = "Choose the first enemy for the deck. Stage 1 begins with only one enemy type."
	elif RUN_STATE.get_stage_sub_index(RUN_STATE.current_stage_index) == RUN_STATE.STAGES_PER_ACT:
		map_hint.text = "Boss stage."
	else:
		map_hint.text = "Stage cleared. Choose the next enemy to add from the remaining pool."

	_apply_stage_option(stage1_card, stage1_card_panel, stage1_title, stage1_icon, stage1_desc_panel, stage1_desc, options, 0)
	_apply_stage_option(stage2_card, stage2_card_panel, stage2_title, stage2_icon, stage2_desc_panel, stage2_desc, options, 1)


func _refresh_route_history_ui() -> void:
	for child in route_history_list.get_children():
		child.queue_free()

	for entry in RUN_STATE.get_route_history():
		_add_route_history_entry(entry)


func _add_route_history_entry(entry: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 150)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", stage1_icon.get_theme_stylebox("panel"))
	route_history_list.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var stage_label := Label.new()
	stage_label.text = String(entry.get("stage_label", "Stage"))
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.9, 1.0))
	content.add_child(stage_label)

	var icon_tile := PanelContainer.new()
	icon_tile.custom_minimum_size = Vector2(0, 82)
	icon_tile.add_theme_stylebox_override("panel", stage1_icon.get_theme_stylebox("panel"))
	content.add_child(icon_tile)
	_fill_enemy_icon(icon_tile, String(entry.get("enemy_id", "")))

	var enemy_name := Label.new()
	enemy_name.text = String(entry.get("enemy_name", ""))
	enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	enemy_name.clip_text = true
	enemy_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	enemy_name.add_theme_color_override("font_color", Color(0.74, 0.78, 0.85, 1.0))
	content.add_child(enemy_name)


func _scroll_route_to_bottom() -> void:
	map_scroll.scroll_vertical = int(map_scroll.get_v_scroll_bar().max_value)


func _apply_stage_option(card: Button, card_panel: PanelContainer, title: Label, icon_tile: PanelContainer, desc_panel: PanelContainer, desc: Label, options: Array[String], index: int) -> void:
	if index >= options.size():
		card.visible = false
		card.disabled = true
		return

	card.visible = true
	card.disabled = false

	var option_data: Dictionary = _parse_stage_option(options[index])
	var enemy_id: String = String(option_data.get("id", ""))
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	var encounter_type: String = String(option_data.get("type", "enemy"))
	var totem_id: String = String(option_data.get("totem_id", ""))
	if encounter_type == "elite":
		title.text = "Elite: %s" % String(enemy["name"])
	elif encounter_type == "boss":
		title.text = "Boss: %s" % String(enemy["name"])
	else:
		title.text = String(enemy["name"])
	var special_text: String = String(enemy.get("special", ""))
	var lines: Array[String] = [
		"HP %d" % int(enemy["hp"]),
		"Move %d" % int(enemy["speed"]),
		"Damage %d" % int(enemy["attack"]),
	]
	if encounter_type != "boss":
		lines.append("Score %d" % int(enemy["danger_score"]))
	desc.text = "\n".join(lines)
	var tooltip_text := ""
	if not special_text.is_empty() and special_text.to_lower() != "x" and special_text.to_lower() != "none" and special_text.to_lower() != "no special ability.":
		tooltip_text = special_text
	card.tooltip_text = tooltip_text
	card_panel.tooltip_text = tooltip_text
	icon_tile.tooltip_text = tooltip_text
	desc.tooltip_text = tooltip_text
	_apply_enemy_card_tint(card_panel, icon_tile, enemy, desc_panel)
	_fill_enemy_icon(icon_tile, enemy_id)
	_add_totem_chip(icon_tile, totem_id)


func _build_enemy_hover_detail_panel() -> void:
	enemy_hover_detail_panel = PanelContainer.new()
	enemy_hover_detail_panel.visible = false
	enemy_hover_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_hover_detail_panel.custom_minimum_size = Vector2(280, 170)
	enemy_hover_detail_panel.z_index = 20
	enemy_hover_detail_panel.add_theme_stylebox_override("panel", stage1_desc_panel.get_theme_stylebox("panel"))
	add_child(enemy_hover_detail_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	enemy_hover_detail_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	enemy_hover_detail_title = Label.new()
	enemy_hover_detail_title.add_theme_font_size_override("font_size", 20)
	enemy_hover_detail_title.add_theme_color_override("font_color", Color(0.93, 0.94, 0.83, 1.0))
	content.add_child(enemy_hover_detail_title)

	enemy_hover_detail_body = Label.new()
	enemy_hover_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_hover_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_hover_detail_body.add_theme_font_size_override("font_size", 15)
	enemy_hover_detail_body.add_theme_color_override("font_color", Color(0.78, 0.84, 0.76, 1.0))
	content.add_child(enemy_hover_detail_body)


func _build_card_hover_detail_panel() -> void:
	card_hover_detail_panel = PanelContainer.new()
	card_hover_detail_panel.top_level = true
	card_hover_detail_panel.visible = false
	card_hover_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_hover_detail_panel.custom_minimum_size = Vector2(300, 190)
	card_hover_detail_panel.z_index = 20
	card_hover_detail_panel.add_theme_stylebox_override("panel", stage1_desc_panel.get_theme_stylebox("panel"))
	add_child(card_hover_detail_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card_hover_detail_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	card_hover_detail_title = Label.new()
	card_hover_detail_title.add_theme_font_size_override("font_size", 19)
	card_hover_detail_title.add_theme_color_override("font_color", Color(0.93, 0.94, 0.83, 1.0))
	content.add_child(card_hover_detail_title)

	card_hover_detail_body = Label.new()
	card_hover_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_hover_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_hover_detail_body.add_theme_font_size_override("font_size", 15)
	card_hover_detail_body.add_theme_color_override("font_color", Color(0.78, 0.84, 0.76, 1.0))
	content.add_child(card_hover_detail_body)
	_set_mouse_ignore_recursive(card_hover_detail_panel)


func _show_stage_card_detail(index: int) -> void:
	var options: Array[String] = RUN_STATE.get_stage_options()
	if index < 0 or index >= options.size():
		return
	var option_data: Dictionary = _parse_stage_option(String(options[index]))
	var enemy_id: String = String(option_data.get("id", ""))
	if enemy_id.is_empty():
		return
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	var encounter_type: String = String(option_data.get("type", "enemy"))
	var totem_id: String = String(option_data.get("totem_id", ""))
	var special_text: String = String(enemy.get("special", ""))
	if special_text.is_empty() or special_text.to_lower() == "x" or special_text.to_lower() == "none" or special_text.to_lower() == "no special ability.":
		special_text = "No special ability."
	if not totem_id.is_empty():
		var totem: Dictionary = TOTEM_CATALOG.get_totem(totem_id)
		var totem_name: String = String(totem.get("name", totem_id))
		var totem_detail: String = String(totem.get("detail_description", ""))
		if totem_detail.is_empty():
			totem_detail = String(totem.get("description", ""))
		if not totem_detail.is_empty():
			special_text += "\n\nTotem: %s\n%s" % [totem_name, totem_detail]
		else:
			special_text += "\n\nTotem: %s" % totem_name
	enemy_hover_detail_title.text = "%s%s" % [
		String(enemy.get("name", enemy_id)),
		" (Elite)" if encounter_type == "elite" else ""
	]
	enemy_hover_detail_body.text = special_text
	var target_card: Control = stage1_card if index == 0 else stage2_card
	var card_rect: Rect2 = target_card.get_global_rect()
	var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * Vector2(card_rect.position.x + card_rect.size.x + 14.0, card_rect.position.y + 18.0)
	enemy_hover_detail_panel.position = local_position
	enemy_hover_detail_panel.visible = true


func _hide_stage_card_detail() -> void:
	if enemy_hover_detail_panel != null:
		enemy_hover_detail_panel.visible = false


func _on_stage_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_play_ui_sound("cursor")
		var options: Array[String] = RUN_STATE.get_stage_options()
		if index < 0 or index >= options.size():
			return
		var option_data: Dictionary = _parse_stage_option(String(options[index]))
		var enemy_id: String = String(option_data.get("id", ""))
		if enemy_id.is_empty():
			return
		if enemy_hover_detail_panel != null and enemy_hover_detail_panel.visible:
			var current_title: String = enemy_hover_detail_title.text
			var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
			var expected_title := String(enemy.get("name", enemy_id))
			var encounter_type: String = String(option_data.get("type", "enemy"))
			if encounter_type == "elite":
				expected_title += " (Elite)"
			if current_title == expected_title:
				_hide_stage_card_detail()
				accept_event()
				return
		_show_stage_card_detail(index)
		accept_event()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_ui_sound("select")
		_hide_stage_card_detail()


func _show_card_hover_detail(target: Control, skill_id: String) -> void:
	var skill: Dictionary = SKILL_CATALOG.get_skill(skill_id)
	if skill.is_empty():
		return
	var detail_description: String = String(skill.get("detail_description", ""))
	if detail_description.is_empty():
		detail_description = String(skill.get("description", ""))
	card_hover_detail_title.text = "%s [%s]" % [
		String(skill.get("name", skill_id)),
		String(skill.get("rarity", "common")).capitalize()
	]
	card_hover_detail_body.text = "\n".join([
		"%s  |  CD %d" % [
			String(skill.get("category", "utility")).capitalize(),
			int(skill.get("cooldown", 0))
		],
		detail_description
	])
	var card_rect: Rect2 = target.get_global_rect()
	card_hover_detail_panel.global_position = Vector2(card_rect.position.x + card_rect.size.x + 14.0, card_rect.position.y + 12.0)
	card_hover_detail_panel.visible = true


func _hide_card_hover_detail() -> void:
	if card_hover_detail_panel != null:
		card_hover_detail_panel.visible = false


func _parse_stage_option(option_token: String) -> Dictionary:
	var parsed := {
		"type": "enemy",
		"id": option_token,
		"totem_id": "",
	}
	var segments: PackedStringArray = option_token.split("|", false)
	for segment in segments:
		var parts: PackedStringArray = String(segment).split(":", false, 1)
		if parts.size() != 2:
			continue
		var key: String = String(parts[0])
		var value: String = String(parts[1])
		match key:
			"enemy", "elite", "boss":
				parsed["type"] = key
				parsed["id"] = value
			"totem":
				parsed["totem_id"] = value
	return parsed


func _get_projected_score(enemy_id: String) -> int:
	var score := 0
	var counts: Dictionary = RUN_STATE.get_enemy_counts()
	for existing_enemy_id in counts.keys():
		var enemy: Dictionary = ENEMY_CATALOG.get_enemy(String(existing_enemy_id))
		score += int(enemy.get("danger_score", 1)) * int(counts[existing_enemy_id])
	var added_enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	score += int(added_enemy.get("danger_score", 1))
	return score


func _build_reward_preview(score: int) -> String:
	if score <= 1:
		return "Reward Common+"
	elif score <= 3:
		return "Reward Rare Up"
	return "Reward Epic Up"


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
			return Color(0.34, 0.16, 0.48, 0.97)
		_:
			return Color(0.16, 0.18, 0.2, 0.97)


func _apply_enemy_card_tint(card_panel: PanelContainer, icon_tile: PanelContainer, enemy: Dictionary, desc_panel: PanelContainer = null) -> void:
	var accent: Color = Color(enemy.get("color", Color(0.45, 0.3, 0.3, 1.0)))

	var card_style := card_panel.get_theme_stylebox("panel")
	if card_style is StyleBoxFlat:
		var card_box: StyleBoxFlat = (card_style as StyleBoxFlat).duplicate()
		card_box.border_color = accent.lerp(Color(0.96, 0.94, 0.88, 1.0), 0.35)
		card_box.bg_color = accent.darkened(0.78)
		card_box.shadow_color = accent.darkened(0.6)
		card_panel.add_theme_stylebox_override("panel", card_box)

	var icon_style := icon_tile.get_theme_stylebox("panel")
	if icon_style is StyleBoxFlat:
		var icon_box: StyleBoxFlat = (icon_style as StyleBoxFlat).duplicate()
		icon_box.border_color = accent.lightened(0.12)
		icon_box.bg_color = accent.darkened(0.62)
		icon_tile.add_theme_stylebox_override("panel", icon_box)

	if desc_panel != null:
		var desc_style := desc_panel.get_theme_stylebox("panel")
		if desc_style is StyleBoxFlat:
			var desc_box: StyleBoxFlat = (desc_style as StyleBoxFlat).duplicate()
			desc_box.border_color = accent.darkened(0.1).lerp(Color(0.88, 0.9, 0.82, 1.0), 0.12)
			desc_box.bg_color = accent.darkened(0.84)
			desc_panel.add_theme_stylebox_override("panel", desc_box)


func _refresh_enemy_deck_ui() -> void:
	var deck: Array[String] = RUN_STATE.get_enemy_deck()
	var deck_tiles: Array = deck_grid.get_children()
	var counts: Dictionary = RUN_STATE.get_enemy_counts()

	for index in range(deck_tiles.size()):
		var tile: PanelContainer = deck_tiles[index]
		_clear_tile(tile)
		if index < deck.size():
			_fill_deck_tile(tile, String(deck[index]))
		else:
			_fill_empty_tile(tile)

	var score := 0
	for enemy_id in counts.keys():
		var enemy: Dictionary = ENEMY_CATALOG.get_enemy(String(enemy_id))
		score += int(enemy.get("danger_score", 1)) * int(counts[enemy_id])

	deck_score_value.text = str(score)
	var rarity_chances: Dictionary = _build_card_rarity_chances_from_score(score)
	RUN_STATE.set_card_rarity_chances(rarity_chances)
	common_value.text = "%d%%" % int(rarity_chances.get("common", 0))
	rare_value.text = "%d%%" % int(rarity_chances.get("rare", 0))
	epic_value.text = "%d%%" % int(rarity_chances.get("epic", 0))
	legendary_value.text = "%d%%" % int(rarity_chances.get("elite", 0))


func _build_card_rarity_chances_from_score(score: int) -> Dictionary:
	if score <= 1:
		return {
			"common": 100,
			"rare": 0,
			"epic": 0,
			"elite": 0,
		}

	var steps: int = int(floor(float(score) / 2.0))
	var common_chance: int = max(100 - steps * 3, 0)
	var rare_chance: int = steps * 2
	var epic_chance: int = steps
	return {
		"common": common_chance,
		"rare": rare_chance,
		"epic": epic_chance,
		"elite": 0,
	}


func _fill_enemy_icon(tile: PanelContainer, enemy_id: String, icon_size: Vector2 = Vector2(104, 104)) -> void:
	_clear_tile(tile)
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	tile.clip_contents = true
	var preview_wrap := CenterContainer.new()
	preview_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(preview_wrap)

	var enemy_ui: Control = ENEMY_UI_SCENE.instantiate()
	enemy_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_ui.custom_minimum_size = icon_size
	enemy_ui.call(
		"set_enemy_data",
		String(enemy.get("name", enemy_id)),
		int(enemy.get("attack", 0)),
		int(enemy.get("hp", 0)),
		int(enemy.get("hp", 0)),
		String(enemy.get("rank", "normal"))
	)
	enemy_ui.call("set_icon_texture", enemy.get("icon", null))
	enemy_ui.call("set_visual_color", Color(enemy.get("color", Color(0.45, 0.3, 0.3, 1.0))))
	_set_mouse_ignore_recursive(enemy_ui)
	preview_wrap.add_child(enemy_ui)


func _add_totem_chip(tile: PanelContainer, totem_id: String) -> void:
	if totem_id.is_empty():
		return
	var totem: Dictionary = TOTEM_CATALOG.get_totem(totem_id)
	if totem.is_empty():
		return

	var overlay := Control.new()
	overlay.name = "TotemChipOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 3
	tile.add_child(overlay)

	var chip := PanelContainer.new()
	chip.name = "TotemChip"
	chip.custom_minimum_size = Vector2(18, 18)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	chip.offset_left = -24
	chip.offset_top = 6
	chip.offset_right = -6
	chip.offset_bottom = 24

	var style := StyleBoxFlat.new()
	style.bg_color = Color(totem.get("color", Color(0.8, 0.8, 0.8, 1.0)))
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = style.bg_color.lightened(0.2)
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	chip.add_theme_stylebox_override("panel", style)
	overlay.add_child(chip)


func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore_recursive(child)



func _fill_deck_tile(tile: PanelContainer, enemy_id: String) -> void:
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
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


func _fill_empty_tile(tile: PanelContainer) -> void:
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


func _clear_tile(tile: PanelContainer) -> void:
	for child in tile.get_children():
		child.queue_free()


func _on_stage_1_pressed() -> void:
	var options: Array[String] = RUN_STATE.get_stage_options()
	if not options.is_empty():
		_play_ui_sound("confirm")
		_begin_stage_choice(options[0])


func _on_stage_2_pressed() -> void:
	var options: Array[String] = RUN_STATE.get_stage_options()
	if options.size() > 1:
		_play_ui_sound("confirm")
		_begin_stage_choice(options[1])
 

func _begin_stage_choice(enemy_id: String) -> void:
	var option_data: Dictionary = _parse_stage_option(enemy_id)
	var encounter_type: String = String(option_data.get("type", "enemy"))
	var selected_enemy_id: String = String(option_data.get("id", ""))
	var selected_totem_id: String = String(option_data.get("totem_id", ""))
	if encounter_type == "elite":
		RUN_STATE.set_current_stage_encounter("elite", selected_enemy_id)
		RUN_STATE.set_current_stage_totem_id(selected_totem_id)
		RUN_STATE.commit_stage_choice(selected_enemy_id)
		get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")
		return
	if encounter_type == "boss":
		RUN_STATE.set_current_stage_encounter("boss", selected_enemy_id)
		RUN_STATE.set_current_stage_totem_id("")
		RUN_STATE.commit_stage_choice(selected_enemy_id)
		get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")
		return
	if RUN_STATE.is_enemy_deck_full():
		_open_enemy_replace_popup(selected_enemy_id, "stage", selected_totem_id)
		return
	RUN_STATE.set_current_stage_encounter("normal")
	RUN_STATE.set_current_stage_totem_id(selected_totem_id)
	RUN_STATE.commit_stage_choice(selected_enemy_id)
	RUN_STATE.add_enemy_to_deck(selected_enemy_id)
	get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")


func _on_back_pressed() -> void:
	_play_ui_sound("select")
	_open_test_mode_popup()


func _build_test_mode_popup() -> void:
	test_mode_overlay = ColorRect.new()
	test_mode_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	test_mode_overlay.color = Color(0.02, 0.02, 0.02, 0.7)
	test_mode_overlay.visible = false
	test_mode_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(test_mode_overlay)

	var popup_center := CenterContainer.new()
	popup_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	test_mode_overlay.add_child(popup_center)

	test_mode_panel = PanelContainer.new()
	test_mode_panel.custom_minimum_size = Vector2(420, 320)
	test_mode_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	test_mode_panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	popup_center.add_child(test_mode_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	test_mode_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Test Mode"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose a test action."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.76, 0.82, 0.72, 1))
	content.add_child(subtitle)

	var card_add_button := Button.new()
	card_add_button.text = "Card Add"
	card_add_button.custom_minimum_size = Vector2(0, 68)
	card_add_button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	card_add_button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	card_add_button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	card_add_button.pressed.connect(_on_test_mode_card_add_pressed)
	content.add_child(card_add_button)

	var enemy_add_button := Button.new()
	enemy_add_button.text = "Enemy Add"
	enemy_add_button.custom_minimum_size = Vector2(0, 68)
	enemy_add_button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	enemy_add_button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	enemy_add_button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	enemy_add_button.pressed.connect(_on_test_mode_enemy_add_pressed)
	content.add_child(enemy_add_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(160, 52)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	close_button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	close_button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	close_button.pressed.connect(_close_test_mode_popup)
	content.add_child(close_button)


func _open_test_mode_popup() -> void:
	test_mode_overlay.visible = true


func _close_test_mode_popup() -> void:
	test_mode_overlay.visible = false


func _on_test_mode_card_add_pressed() -> void:
	_play_ui_sound("confirm")
	_close_test_mode_popup()
	_open_card_add_popup()


func _on_test_mode_enemy_add_pressed() -> void:
	_play_ui_sound("confirm")
	_close_test_mode_popup()
	_open_enemy_add_popup()


func _build_enemy_add_popup() -> void:
	enemy_add_overlay = ColorRect.new()
	enemy_add_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enemy_add_overlay.color = Color(0.02, 0.02, 0.02, 0.74)
	enemy_add_overlay.visible = false
	enemy_add_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(enemy_add_overlay)

	var popup_center := CenterContainer.new()
	popup_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_add_overlay.add_child(popup_center)

	enemy_add_panel = PanelContainer.new()
	enemy_add_panel.custom_minimum_size = Vector2(940, 640)
	enemy_add_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_add_panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	popup_center.add_child(enemy_add_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	enemy_add_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Enemy Add"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	content.add_child(title)

	enemy_add_subtitle = Label.new()
	enemy_add_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_add_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_add_subtitle.add_theme_font_size_override("font_size", 16)
	enemy_add_subtitle.add_theme_color_override("font_color", Color(0.76, 0.82, 0.72, 1))
	content.add_child(enemy_add_subtitle)

	enemy_add_scroll = ScrollContainer.new()
	enemy_add_scroll.custom_minimum_size = Vector2(0, 470)
	enemy_add_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(enemy_add_scroll)

	enemy_add_grid = GridContainer.new()
	enemy_add_grid.columns = 5
	enemy_add_grid.add_theme_constant_override("h_separation", 12)
	enemy_add_grid.add_theme_constant_override("v_separation", 12)
	enemy_add_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_add_scroll.add_child(enemy_add_grid)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(160, 52)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	close_button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	close_button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	close_button.pressed.connect(_close_enemy_add_popup)
	content.add_child(close_button)


func _open_enemy_add_popup() -> void:
	enemy_add_subtitle.text = "Click an enemy to add it to the current deck. If the deck is full, you will choose one enemy to replace."
	for child in enemy_add_grid.get_children():
		child.queue_free()
	for enemy_id in ENEMY_CATALOG.all_enemy_ids():
		enemy_add_grid.add_child(_create_enemy_add_button(String(enemy_id)))
	enemy_add_overlay.visible = true


func _close_enemy_add_popup() -> void:
	enemy_add_overlay.visible = false


func _create_enemy_add_button(enemy_id: String) -> Button:
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	var button := Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(92, 108)
	button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	button.pressed.connect(_on_enemy_add_selected.bind(enemy_id))

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	button.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := CenterContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(content)

	var icon_tile := PanelContainer.new()
	icon_tile.custom_minimum_size = Vector2(68, 68)
	icon_tile.add_theme_stylebox_override("panel", stage1_icon.get_theme_stylebox("panel"))
	content.add_child(icon_tile)
	_apply_enemy_card_tint(panel, icon_tile, enemy)
	_fill_enemy_icon(icon_tile, enemy_id, Vector2(60, 60))

	var special_text := String(enemy.get("special", ""))
	var tooltip_lines: Array[String] = [
		String(enemy.get("name", enemy_id)),
		"HP %d" % int(enemy.get("hp", 0)),
		"Move %d" % int(enemy.get("speed", 1)),
		"Damage %d" % int(enemy.get("attack", 0)),
		"Score %d" % int(enemy.get("danger_score", 0)),
	]
	if not special_text.is_empty() and special_text.to_lower() != "x" and special_text.to_lower() != "none" and special_text.to_lower() != "no special ability.":
		tooltip_lines.append(special_text)
	var tooltip_text := "\n".join(tooltip_lines)
	button.tooltip_text = tooltip_text
	panel.tooltip_text = tooltip_text
	icon_tile.tooltip_text = tooltip_text

	if RUN_STATE.get_enemy_deck().has(enemy_id):
		button.disabled = true
		button.modulate = Color(0.62, 0.62, 0.62, 1.0)

	_set_mouse_ignore_recursive(panel)
	return button


func _on_enemy_add_selected(enemy_id: String) -> void:
	if RUN_STATE.get_enemy_deck().has(enemy_id):
		_play_ui_sound("error")
		return
	if RUN_STATE.is_enemy_deck_full():
		_play_ui_sound("select")
		enemy_add_overlay.visible = false
		_open_enemy_replace_popup(enemy_id, "test")
		return
	_play_ui_sound("confirm")
	RUN_STATE.add_enemy_to_deck(enemy_id)
	_refresh_enemy_deck_ui()
	_refresh_stage_options_ui()
	_open_enemy_add_popup()


func _build_card_add_popup() -> void:
	card_add_overlay = ColorRect.new()
	card_add_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_add_overlay.color = Color(0.02, 0.02, 0.02, 0.74)
	card_add_overlay.visible = false
	card_add_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card_add_overlay)

	var popup_center := CenterContainer.new()
	popup_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_add_overlay.add_child(popup_center)

	card_add_panel = PanelContainer.new()
	card_add_panel.custom_minimum_size = Vector2(940, 640)
	card_add_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	card_add_panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	popup_center.add_child(card_add_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card_add_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Card Add"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	content.add_child(title)

	card_add_subtitle = Label.new()
	card_add_subtitle.text = "Select a card to add. Popup size stays fixed and the list scrolls."
	card_add_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_add_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_add_subtitle.add_theme_font_size_override("font_size", 16)
	card_add_subtitle.add_theme_color_override("font_color", Color(0.76, 0.82, 0.72, 1))
	content.add_child(card_add_subtitle)

	card_add_scroll = ScrollContainer.new()
	card_add_scroll.custom_minimum_size = Vector2(0, 470)
	card_add_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_add_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(card_add_scroll)

	card_add_content = VBoxContainer.new()
	card_add_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_add_content.add_theme_constant_override("separation", 18)
	card_add_scroll.add_child(card_add_content)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(160, 52)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	close_button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	close_button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	close_button.pressed.connect(_close_card_add_popup)
	content.add_child(close_button)


func _build_card_replace_popup() -> void:
	card_replace_overlay = ColorRect.new()
	card_replace_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_replace_overlay.color = Color(0.02, 0.02, 0.02, 0.74)
	card_replace_overlay.visible = false
	card_replace_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card_replace_overlay)

	var popup_center := CenterContainer.new()
	popup_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_replace_overlay.add_child(popup_center)

	card_replace_panel = PanelContainer.new()
	card_replace_panel.custom_minimum_size = Vector2(760, 520)
	card_replace_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	card_replace_panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	popup_center.add_child(card_replace_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card_replace_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Replace One Card"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	content.add_child(title)

	card_replace_subtitle = Label.new()
	card_replace_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_replace_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_replace_subtitle.add_theme_font_size_override("font_size", 16)
	card_replace_subtitle.add_theme_color_override("font_color", Color(0.76, 0.82, 0.72, 1))
	content.add_child(card_replace_subtitle)

	card_replace_grid = GridContainer.new()
	card_replace_grid.columns = 3
	card_replace_grid.add_theme_constant_override("h_separation", 12)
	card_replace_grid.add_theme_constant_override("v_separation", 12)
	card_replace_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(card_replace_grid)

	var back_button_local := Button.new()
	back_button_local.text = "Back"
	back_button_local.custom_minimum_size = Vector2(160, 52)
	back_button_local.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button_local.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	back_button_local.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	back_button_local.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	back_button_local.pressed.connect(_back_to_card_add_from_replace)
	content.add_child(back_button_local)


func _open_card_add_popup() -> void:
	pending_card_choice_id = ""
	_refresh_card_add_popup()
	card_add_overlay.visible = true


func _close_card_add_popup() -> void:
	card_add_overlay.visible = false


func _refresh_card_add_popup() -> void:
	for child in card_add_content.get_children():
		child.queue_free()

	var by_group := {
		"Damage": [],
		"Control": [],
		"Utility": [],
		"Install": [],
	}

	for skill_id in SKILL_CATALOG.all_skill_ids():
		var skill: Dictionary = SKILL_CATALOG.get_skill(String(skill_id))
		var category: String = String(skill.get("category", "utility")).to_lower()
		var group_name := "Utility"
		if category == "attack" or category == "damage":
			group_name = "Damage"
		elif category == "control":
			group_name = "Control"
		elif category == "install":
			group_name = "Install"
		by_group[group_name].append(String(skill_id))

	for group_name in ["Damage", "Control", "Utility", "Install"]:
		_add_card_add_group(group_name, by_group[group_name])


func _add_card_add_group(group_name: String, skill_ids: Array) -> void:
	if skill_ids.is_empty():
		return

	var title := Label.new()
	title.text = group_name
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	card_add_content.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_add_content.add_child(grid)

	for skill_id in skill_ids:
		grid.add_child(_create_card_add_button(String(skill_id)))


func _create_card_add_button(skill_id: String) -> Button:
	var skill: Dictionary = SKILL_CATALOG.get_skill(skill_id)
	var button := Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(0, 138)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	button.pressed.connect(_on_card_add_selected.bind(skill_id))
	button.mouse_entered.connect(_show_card_hover_detail.bind(button, skill_id))
	button.mouse_exited.connect(_hide_card_hover_detail)
	var detail_description: String = String(skill.get("detail_description", ""))
	if detail_description.is_empty():
		detail_description = String(skill.get("description", ""))
	button.tooltip_text = "%s [%s]\n%s  |  CD %d\n%s" % [
		String(skill.get("name", skill_id)),
		String(skill.get("rarity", "common")).capitalize(),
		String(skill.get("category", "utility")).capitalize(),
		int(skill.get("cooldown", 0)),
		detail_description
	]

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := stage1_card_panel.get_theme_stylebox("panel").duplicate()
	if panel_style is StyleBoxFlat:
		var rarity_color: Color = _get_rarity_border_color(String(skill.get("rarity", "common")))
		var category_color: Color = _get_category_fill_color(String(skill.get("category", "utility")))
		(panel_style as StyleBoxFlat).border_color = rarity_color
		(panel_style as StyleBoxFlat).bg_color = category_color
	panel.add_theme_stylebox_override("panel", panel_style)
	button.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "%s [%s]" % [String(skill.get("name", skill_id)), String(skill.get("rarity", "common")).capitalize()]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.93, 0.94, 0.83, 1))
	content.add_child(title)

	var stat := Label.new()
	stat.text = "CD %d  |  %s" % [int(skill.get("cooldown", 0)), String(skill.get("category", "utility")).capitalize()]
	stat.add_theme_font_size_override("font_size", 14)
	stat.add_theme_color_override("font_color", Color(0.75, 0.82, 0.7, 1))
	content.add_child(stat)

	var desc := Label.new()
	desc.text = String(skill.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.78, 0.82, 0.78, 1))
	content.add_child(desc)

	var owned := RUN_STATE.get_owned_skill_ids().has(skill_id)
	if owned:
		button.disabled = true
		var owned_label := Label.new()
		owned_label.text = "Owned"
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		owned_label.add_theme_font_size_override("font_size", 13)
		owned_label.add_theme_color_override("font_color", Color(0.89, 0.85, 0.55, 1))
		content.add_child(owned_label)

	_set_mouse_ignore_recursive(panel)
	return button


func _on_card_add_selected(skill_id: String) -> void:
	if RUN_STATE.get_owned_skill_ids().has(skill_id):
		_play_ui_sound("error")
		return
	if RUN_STATE.is_skill_inventory_full():
		_play_ui_sound("select")
		pending_card_choice_id = skill_id
		_open_card_replace_popup(skill_id)
		return
	_play_ui_sound("confirm")
	RUN_STATE.add_owned_skill(skill_id)
	_refresh_owned_skill_ui()
	_refresh_card_add_popup()


func _open_card_replace_popup(skill_id: String) -> void:
	var skill: Dictionary = SKILL_CATALOG.get_skill(skill_id)
	card_replace_subtitle.text = "Your card deck is full (%d/%d). Pick one card to replace with %s." % [
		RUN_STATE.get_owned_skill_ids().size(),
		RUN_STATE.get_skill_limit(),
		String(skill.get("name", skill_id))
	]
	for child in card_replace_grid.get_children():
		child.queue_free()
	for owned_skill_id in RUN_STATE.get_owned_skill_ids():
		card_replace_grid.add_child(_create_card_replace_button(String(owned_skill_id)))
	card_add_overlay.visible = false
	card_replace_overlay.visible = true


func _create_card_replace_button(skill_id: String) -> Button:
	var skill: Dictionary = SKILL_CATALOG.get_skill(skill_id)
	var button := Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(0, 118)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	button.pressed.connect(_on_card_replace_selected.bind(skill_id))
	button.mouse_entered.connect(_show_card_hover_detail.bind(button, skill_id))
	button.mouse_exited.connect(_hide_card_hover_detail)
	var detail_description: String = String(skill.get("detail_description", ""))
	if detail_description.is_empty():
		detail_description = String(skill.get("description", ""))
	button.tooltip_text = "%s [%s]\n%s  |  CD %d\n%s" % [
		String(skill.get("name", skill_id)),
		String(skill.get("rarity", "common")).capitalize(),
		String(skill.get("category", "utility")).capitalize(),
		int(skill.get("cooldown", 0)),
		detail_description
	]

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := stage1_card_panel.get_theme_stylebox("panel").duplicate()
	if panel_style is StyleBoxFlat:
		var rarity_color: Color = _get_rarity_border_color(String(skill.get("rarity", "common")))
		var category_color: Color = _get_category_fill_color(String(skill.get("category", "utility")))
		(panel_style as StyleBoxFlat).border_color = rarity_color
		(panel_style as StyleBoxFlat).bg_color = category_color
	panel.add_theme_stylebox_override("panel", panel_style)
	button.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var title := Label.new()
	title.text = String(skill.get("name", skill_id))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.93, 0.94, 0.83, 1))
	content.add_child(title)

	var stat := Label.new()
	stat.text = "%s  |  CD %d" % [String(skill.get("category", "utility")).capitalize(), int(skill.get("cooldown", 0))]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_font_size_override("font_size", 13)
	stat.add_theme_color_override("font_color", Color(0.75, 0.82, 0.7, 1))
	content.add_child(stat)

	_set_mouse_ignore_recursive(panel)
	return button


func _on_card_replace_selected(removed_skill_id: String) -> void:
	if pending_card_choice_id.is_empty():
		_play_ui_sound("error")
		return
	_play_ui_sound("confirm")
	RUN_STATE.replace_owned_skill(removed_skill_id, pending_card_choice_id)
	pending_card_choice_id = ""
	card_replace_overlay.visible = false
	card_add_overlay.visible = true
	_refresh_owned_skill_ui()
	_refresh_card_add_popup()


func _back_to_card_add_from_replace() -> void:
	_play_ui_sound("cancel_alt")
	pending_card_choice_id = ""
	card_replace_overlay.visible = false
	card_add_overlay.visible = true


func _build_enemy_replace_popup() -> void:
	enemy_replace_overlay = ColorRect.new()
	enemy_replace_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enemy_replace_overlay.color = Color(0.02, 0.02, 0.02, 0.72)
	enemy_replace_overlay.visible = false
	enemy_replace_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(enemy_replace_overlay)

	var popup_center := CenterContainer.new()
	popup_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_replace_overlay.add_child(popup_center)

	enemy_replace_panel = PanelContainer.new()
	enemy_replace_panel.custom_minimum_size = Vector2(720, 540)
	enemy_replace_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_replace_panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	popup_center.add_child(enemy_replace_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	enemy_replace_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	enemy_replace_title = Label.new()
	enemy_replace_title.text = "Replace One Enemy"
	enemy_replace_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_replace_title.add_theme_font_size_override("font_size", 28)
	enemy_replace_title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	content.add_child(enemy_replace_title)

	enemy_replace_subtitle = Label.new()
	enemy_replace_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_replace_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_replace_subtitle.add_theme_font_size_override("font_size", 16)
	enemy_replace_subtitle.add_theme_color_override("font_color", Color(0.76, 0.82, 0.72, 1))
	content.add_child(enemy_replace_subtitle)

	enemy_replace_choice_icon = PanelContainer.new()
	enemy_replace_choice_icon.custom_minimum_size = Vector2(0, 150)
	enemy_replace_choice_icon.add_theme_stylebox_override("panel", stage1_icon.get_theme_stylebox("panel"))
	content.add_child(enemy_replace_choice_icon)

	var grid_title := Label.new()
	grid_title.text = "Choose an enemy in your deck to replace"
	grid_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid_title.add_theme_font_size_override("font_size", 18)
	grid_title.add_theme_color_override("font_color", Color(0.9, 0.92, 0.75, 1))
	content.add_child(grid_title)

	enemy_replace_grid = GridContainer.new()
	enemy_replace_grid.columns = 5
	enemy_replace_grid.add_theme_constant_override("h_separation", 12)
	enemy_replace_grid.add_theme_constant_override("v_separation", 12)
	enemy_replace_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(enemy_replace_grid)

	enemy_replace_back_button = Button.new()
	enemy_replace_back_button.text = "Back"
	enemy_replace_back_button.custom_minimum_size = Vector2(160, 52)
	enemy_replace_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enemy_replace_back_button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	enemy_replace_back_button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	enemy_replace_back_button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	enemy_replace_back_button.pressed.connect(_close_enemy_replace_popup)
	content.add_child(enemy_replace_back_button)


func _open_enemy_replace_popup(enemy_id: String, mode: String = "stage", totem_id: String = "") -> void:
	pending_enemy_choice_id = enemy_id
	pending_enemy_choice_totem_id = totem_id
	pending_enemy_choice_mode = mode
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	if mode == "test":
		enemy_replace_subtitle.text = "Enemy deck is full (%d/%d). Pick one enemy to replace with %s." % [
			RUN_STATE.get_enemy_deck().size(),
			RUN_STATE.get_enemy_deck_limit(),
			String(enemy.get("name", enemy_id))
		]
	else:
		enemy_replace_subtitle.text = "Your enemy deck is full (%d/%d). Pick one enemy to replace with %s." % [
			RUN_STATE.get_enemy_deck().size(),
			RUN_STATE.get_enemy_deck_limit(),
			String(enemy.get("name", enemy_id))
		]
	_apply_enemy_card_tint(enemy_replace_panel, enemy_replace_choice_icon, enemy)
	_fill_enemy_icon(enemy_replace_choice_icon, enemy_id)

	for child in enemy_replace_grid.get_children():
		child.queue_free()

	for existing_enemy_id in RUN_STATE.get_enemy_deck():
		enemy_replace_grid.add_child(_create_enemy_replace_button(String(existing_enemy_id)))

	enemy_replace_overlay.visible = true


func _close_enemy_replace_popup() -> void:
	pending_enemy_choice_id = ""
	pending_enemy_choice_totem_id = ""
	pending_enemy_choice_mode = "stage"
	enemy_replace_overlay.visible = false


func _create_enemy_replace_button(enemy_id: String) -> Button:
	var enemy: Dictionary = ENEMY_CATALOG.get_enemy(enemy_id)
	var button := Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(118, 150)
	button.add_theme_stylebox_override("normal", stage1_card.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover", stage1_card.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("pressed", stage1_card.get_theme_stylebox("pressed"))
	button.pressed.connect(_on_enemy_replace_selected.bind(enemy_id))

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", stage1_card_panel.get_theme_stylebox("panel"))
	button.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var name_label := Label.new()
	name_label.text = String(enemy.get("name", enemy_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.83, 1))
	content.add_child(name_label)

	var icon_tile := PanelContainer.new()
	icon_tile.custom_minimum_size = Vector2(0, 78)
	icon_tile.add_theme_stylebox_override("panel", stage1_icon.get_theme_stylebox("panel"))
	content.add_child(icon_tile)
	_apply_enemy_card_tint(panel, icon_tile, enemy)
	_fill_enemy_icon(icon_tile, enemy_id)

	var score_label := Label.new()
	score_label.text = "Score %d" % int(enemy.get("danger_score", 0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 13)
	score_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.7, 1))
	content.add_child(score_label)

	_set_mouse_ignore_recursive(panel)
	return button


func _on_enemy_replace_selected(removed_enemy_id: String) -> void:
	if pending_enemy_choice_id.is_empty():
		_play_ui_sound("error")
		return
	_play_ui_sound("confirm")
	var replace_mode := pending_enemy_choice_mode
	if replace_mode == "stage":
		RUN_STATE.set_current_stage_encounter("normal")
		RUN_STATE.set_current_stage_totem_id(pending_enemy_choice_totem_id)
		RUN_STATE.commit_stage_choice(pending_enemy_choice_id)
	RUN_STATE.replace_enemy_in_deck(removed_enemy_id, pending_enemy_choice_id)
	_close_enemy_replace_popup()
	if replace_mode == "test":
		_refresh_enemy_deck_ui()
		_refresh_stage_options_ui()
		_open_enemy_add_popup()
	else:
		get_tree().change_scene_to_file("res://scenes/battle_screen.tscn")
