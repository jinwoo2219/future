extends Control

const PREVIEW_ROW := 0
const FIRST_BATTLE_ROW := 1
const LAST_BATTLE_ROW := 6
const LANE_COUNT := 3
const STARTING_LIFE := 10
const STARTING_ACTIONS := 2
const INSTALLABLE_MIN_ROW := 4

const ENEMY_SCENE := preload("res://scenes/enemy_ui.tscn")
const TURN_MANAGER_SCRIPT := preload("res://scripts/turn_manager.gd")
const BATTLE_UI_RENDERER_SCRIPT := preload("res://scripts/battle_ui_renderer.gd")
const BATTLE_REWARD_FLOW_SCRIPT := preload("res://scripts/battle_reward_flow.gd")
const BATTLE_BOARD_RENDERER_SCRIPT := preload("res://scripts/battle_board_renderer.gd")
const BATTLE_WAVE_FLOW_SCRIPT := preload("res://scripts/battle_wave_flow.gd")
const BATTLE_INPUT_HANDLER_SCRIPT := preload("res://scripts/battle_input_handler.gd")
const BATTLE_ENEMY_STATE_SCRIPT := preload("res://scripts/battle_enemy_state.gd")
const BATTLE_COMBAT_RESOLVER_SCRIPT := preload("res://scripts/battle_combat_resolver.gd")
const BATTLE_DRAG_OVERLAY_SCRIPT := preload("res://scripts/battle_drag_overlay.gd")
const BATTLE_VFX_PLAYER_SCRIPT := preload("res://scripts/battle_vfx_player.gd")
const RUN_STATE = preload("res://scripts/run_state.gd")
const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")
const TOTEM_CATALOG = preload("res://scripts/totem_catalog.gd")
const SKILL_CATALOG = preload("res://scripts/skill_catalog.gd")
const MODULE_CATALOG = preload("res://scripts/module_catalog.gd")
const SKILL_EFFECT_RESOLVER = preload("res://scripts/skill_effect_resolver.gd")
const ACTION_COUNT_READY_PATH := "res://asset/turn_action/useablecount.png"
const ACTION_COUNT_ZERO_PATH := "res://asset/turn_action/countzero.png"
const ENERGY_GAIN_ACTION_PATH := "res://asset/turn_action/gainaction.png"
const ENERGY_COOLDOWN_PATH := "res://asset/turn_action/cooldown.png"
const SKILL_LIST_PANEL_PATH := "res://asset/card_new/skill_list.png"
const DRAG_USE_CONTROL_PATH := "res://asset/card_new/usecontrol.png"
const DRAG_USE_DAMAGE_PATH := "res://asset/card_new/usedamage.png"
const DRAG_USE_STRUCTURE_PATH := "res://asset/card_new/usestructure.png"
const DRAG_USE_UTILITY_PATH := "res://asset/card_new/useutill.png"
const UI_SOUND_CANCEL_1 := "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Cancel - 1.wav"
const UI_SOUND_CANCEL_2 := "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Cancel - 2.wav"
const UI_SOUND_CONFIRM_1 := "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Confirm - 1.wav"
const UI_SOUND_CURSOR_1 := "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Cursor - 1.wav"
const UI_SOUND_ERROR_1 := "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Error - 1.wav"
const UI_SOUND_SELECT_1 := "res://sounds/ui/JDSherbert - Wooden UI SFX Pack - Select - 1.wav"
const SFX_HIT := "res://sounds/sfx/hit.wav"
const SFX_INSTALLATION := "res://sounds/sfx/installation.wav"
const SFX_KILL := "res://sounds/sfx/kill.wav"
const SFX_PUSH := "res://sounds/sfx/push.wav"

var board_tiles: Array = []
var board_state: Array = []
var board_structures: Array = []
var selected_lane := -1
var selected_row := -1
var enemy_info_hover_lane := -1
var enemy_info_hover_row := -1
var life := STARTING_LIFE
var max_life := STARTING_LIFE
var wave_index := 0
var next_enemy_id := 1
var wave_queue: Array = []
var wave_defs: Array = []
var wave_turn_limit := 0
var wave_turns_remaining := 0
var skills: Array = []
var skill_buttons: Dictionary = {}
var turn_manager: RefCounted
var selected_skill_id: String = ""
var pending_skill_id: String = ""
var pending_push_target_id: int = -1
var pending_push_destinations: Array = []
var pending_pull_target_id: int = -1
var pending_pull_destinations: Array = []
var pending_retreat_target_id: int = -1
var pending_retreat_destinations: Array = []
var pending_structure_move_source: Dictionary = {}
var pending_structure_move_destinations: Array = []
var battle_finished := false
var drag_skill_id: String = ""
var drag_active := false
var drag_hover_lane := -1
var drag_origin_global := Vector2.ZERO
var drag_mouse_global := Vector2.ZERO
var ui_renderer: RefCounted
var reward_flow: RefCounted
var board_renderer: RefCounted
var wave_flow: RefCounted
var input_handler: RefCounted
var enemy_state: RefCounted
var combat_resolver: RefCounted
var vfx_player: RefCounted
var result_overlay: ColorRect
var result_label: Label
var reward_overlay: ColorRect
var reward_card_buttons: Array = []
var pending_reward_skill_ids: Array[String] = []
var drag_overlay: Control
var effect_overlay: Control
var energy_overlay: ColorRect
var energy_panel: PanelContainer
var energy_cd_button: Button
var battle_skill_detail_panel: PanelContainer
var battle_skill_detail_title: Label
var battle_skill_detail_body: Label
var current_battle_skill_detail_id: String = ""
var ui_sfx_player: AudioStreamPlayer
var combat_sfx_player: AudioStreamPlayer
var pending_energy_mode: String = ""
var pending_energy_prepaid := false
var aoe_range_bonus_this_turn := 0
var turret_damage_multiplier_this_turn := 1
var pending_cooldown_swap_active := false
var pending_cooldown_swap_card_id: String = ""
var pending_cooldown_swap_selected_ids: Array[String] = []
var pending_delayed_strikes: Array = []
var skill_cycle_counts: Dictionary = {}
var pending_next_damage_card_bonus := 0
var last_used_skill_id: String = ""
var last_used_skill_category := ""
var same_card_damage_streak := 0
var pending_bonus_actions_next_turn := 0
var enemy_inspect_panel: PanelContainer
var enemy_inspect_content: VBoxContainer
var current_stage_totem: Dictionary = {}

@onready var basic_info_label: Label = get_node("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/LeftColumn/BasicInfo/BasicInfoLabel")
@onready var enemy_pool_grid: GridContainer = get_node("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/LeftColumn/EnemyPool/EnemyPoolMargin/EnemyPoolGrid")
@onready var player_life_label: Label = get_node("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/CenterColumn/PlayerCoreRow/PlayerCore/PlayerCoreMargin/PlayerCoreContent/PlayerTopRow/PlayerLifeLabel")
@onready var action_count_tile: PanelContainer = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/TurnControls/TurnControlsMargin/TurnControlsSplit/ActionCountTile")
@onready var action_count_art: TextureRect = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/TurnControls/TurnControlsMargin/TurnControlsSplit/ActionCountTile/ActionCountArt")
@onready var action_count_label: Label = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/TurnControls/TurnControlsMargin/TurnControlsSplit/ActionCountTile/ActionCount")
@onready var control_zone_panel: PanelContainer = get_node("Margin/RootSplit/ControlZone")
@onready var skill_list_content: VBoxContainer = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/SkillList/SkillListMargin/SkillListContent")
@onready var skill_list_body: Label = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/SkillList/SkillListMargin/SkillListContent/SkillListBody")
@onready var energy_button: Button = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/TurnControls/TurnControlsMargin/TurnControlsSplit/ActionButtons/EnergyButton")
@onready var end_turn_button: Button = get_node("Margin/RootSplit/ControlZone/ControlMargin/RightContent/TurnControls/TurnControlsMargin/TurnControlsSplit/ActionButtons/EndTurnButton")
@onready var player_core_panel: PanelContainer = get_node("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/CenterColumn/PlayerCoreRow/PlayerCore")
func _ready() -> void:
	turn_manager = TURN_MANAGER_SCRIPT.new()
	turn_manager.setup(STARTING_ACTIONS)
	ui_renderer = BATTLE_UI_RENDERER_SCRIPT.new()
	ui_renderer.setup(self)
	reward_flow = BATTLE_REWARD_FLOW_SCRIPT.new()
	reward_flow.setup(self)
	board_renderer = BATTLE_BOARD_RENDERER_SCRIPT.new()
	board_renderer.setup(self)
	wave_flow = BATTLE_WAVE_FLOW_SCRIPT.new()
	wave_flow.setup(self)
	input_handler = BATTLE_INPUT_HANDLER_SCRIPT.new()
	input_handler.setup(self)
	enemy_state = BATTLE_ENEMY_STATE_SCRIPT.new()
	enemy_state.setup(self)
	combat_resolver = BATTLE_COMBAT_RESOLVER_SCRIPT.new()
	combat_resolver.setup(self)
	vfx_player = BATTLE_VFX_PLAYER_SCRIPT.new()
	vfx_player.setup(self)
	_reorder_battle_panels()
	_build_board_references()
	_build_board_state()
	_build_skill_buttons()
	_build_result_overlay()
	_build_reward_overlay()
	_build_drag_overlay()
	_build_energy_overlay()
	_build_battle_skill_detail_panel()
	_build_enemy_inspect_panel()
	_build_ui_sfx_player()
	_build_combat_sfx_player()
	_connect_inputs()
	_reset_run()


func _build_board_references() -> void:
	board_renderer.build_board_references()


func _build_board_state() -> void:
	board_renderer.build_board_state()
	board_structures.clear()
	for _lane_index in range(LANE_COUNT):
		var lane_rows: Array = []
		for _row_index in range(LAST_BATTLE_ROW + 1):
			lane_rows.append(null)
		board_structures.append(lane_rows)


func _build_skill_buttons() -> void:
	ui_renderer.build_skill_buttons()


func _build_result_overlay() -> void:
	reward_flow.build_result_overlay()


func _build_reward_overlay() -> void:
	reward_flow.build_reward_overlay()


func _build_drag_overlay() -> void:
	drag_overlay = BATTLE_DRAG_OVERLAY_SCRIPT.new()
	drag_overlay.name = "DragOverlay"
	drag_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_overlay.z_index = 1000
	add_child(drag_overlay)
	_refresh_drag_overlay()
	_build_effect_overlay()


func _build_effect_overlay() -> void:
	vfx_player.build_effect_overlay()
	effect_overlay = vfx_player.effect_overlay


func _build_energy_overlay() -> void:
	energy_overlay = ColorRect.new()
	energy_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	energy_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	energy_overlay.visible = false
	energy_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(energy_overlay)

	energy_panel = PanelContainer.new()
	energy_panel.custom_minimum_size = Vector2(320, 150)
	energy_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var energy_panel_style := _build_texture_stylebox(SKILL_LIST_PANEL_PATH)
	if energy_panel_style != null:
		energy_panel.add_theme_stylebox_override("panel", energy_panel_style)
	else:
		energy_panel.add_theme_stylebox_override("panel", player_core_panel.get_theme_stylebox("panel"))
	energy_overlay.add_child(energy_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	energy_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var actions_row := HBoxContainer.new()
	actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_row.add_theme_constant_override("separation", 12)
	actions_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(actions_row)

	var action_button := Button.new()
	action_button.text = ""
	action_button.custom_minimum_size = Vector2(136, 78)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var gain_action_style := _build_texture_stylebox(ENERGY_GAIN_ACTION_PATH)
	if gain_action_style != null:
		action_button.add_theme_stylebox_override("normal", gain_action_style)
		action_button.add_theme_stylebox_override("hover", gain_action_style)
		action_button.add_theme_stylebox_override("pressed", gain_action_style)
		action_button.add_theme_stylebox_override("focus", gain_action_style)
		action_button.add_theme_stylebox_override("disabled", gain_action_style)
	else:
		action_button.text = "Gain +1 Action"
		action_button.add_theme_stylebox_override("normal", energy_button.get_theme_stylebox("normal"))
		action_button.add_theme_stylebox_override("hover", energy_button.get_theme_stylebox("hover"))
		action_button.add_theme_stylebox_override("pressed", energy_button.get_theme_stylebox("pressed"))
	action_button.pressed.connect(_on_energy_gain_action_pressed)
	actions_row.add_child(action_button)

	energy_cd_button = Button.new()
	energy_cd_button.text = ""
	energy_cd_button.custom_minimum_size = Vector2(136, 78)
	energy_cd_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_cd_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cooldown_style := _build_texture_stylebox(ENERGY_COOLDOWN_PATH)
	if cooldown_style != null:
		energy_cd_button.add_theme_stylebox_override("normal", cooldown_style)
		energy_cd_button.add_theme_stylebox_override("hover", cooldown_style)
		energy_cd_button.add_theme_stylebox_override("pressed", cooldown_style)
		energy_cd_button.add_theme_stylebox_override("focus", cooldown_style)
		energy_cd_button.add_theme_stylebox_override("disabled", cooldown_style)
	else:
		energy_cd_button.text = "Choose Card for CD -1"
		energy_cd_button.add_theme_stylebox_override("normal", energy_button.get_theme_stylebox("normal"))
		energy_cd_button.add_theme_stylebox_override("hover", energy_button.get_theme_stylebox("hover"))
		energy_cd_button.add_theme_stylebox_override("pressed", energy_button.get_theme_stylebox("pressed"))
	energy_cd_button.pressed.connect(_on_energy_reduce_cd_pressed)
	actions_row.add_child(energy_cd_button)


func _build_battle_skill_detail_panel() -> void:
	battle_skill_detail_panel = PanelContainer.new()
	battle_skill_detail_panel.top_level = true
	battle_skill_detail_panel.visible = false
	battle_skill_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_skill_detail_panel.custom_minimum_size = Vector2(320, 190)
	battle_skill_detail_panel.z_index = 1100
	battle_skill_detail_panel.add_theme_stylebox_override("panel", player_core_panel.get_theme_stylebox("panel"))
	add_child(battle_skill_detail_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	battle_skill_detail_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	battle_skill_detail_title = Label.new()
	battle_skill_detail_title.add_theme_font_size_override("font_size", 19)
	battle_skill_detail_title.add_theme_color_override("font_color", Color(0.93, 0.94, 0.83, 1.0))
	content.add_child(battle_skill_detail_title)

	battle_skill_detail_body = Label.new()
	battle_skill_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_skill_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_skill_detail_body.add_theme_font_size_override("font_size", 15)
	battle_skill_detail_body.add_theme_color_override("font_color", Color(0.78, 0.84, 0.76, 1.0))
	content.add_child(battle_skill_detail_body)


func _build_ui_sfx_player() -> void:
	ui_sfx_player = AudioStreamPlayer.new()
	ui_sfx_player.name = "UISfxPlayer"
	add_child(ui_sfx_player)


func _build_combat_sfx_player() -> void:
	combat_sfx_player = AudioStreamPlayer.new()
	combat_sfx_player.name = "CombatSfxPlayer"
	add_child(combat_sfx_player)


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


func _play_combat_sfx(kind: String) -> void:
	if combat_sfx_player == null:
		return
	var sound_path: String = ""
	match kind:
		"hit":
			sound_path = SFX_HIT
		"install":
			sound_path = SFX_INSTALLATION
		"kill":
			sound_path = SFX_KILL
		"push":
			sound_path = SFX_PUSH
		_:
			return
	var stream: AudioStream = load(sound_path)
	if stream == null:
		return
	combat_sfx_player.stream = stream
	combat_sfx_player.play()


func _toggle_battle_skill_detail(skill_id: String) -> void:
	if battle_skill_detail_panel != null and battle_skill_detail_panel.visible and current_battle_skill_detail_id == skill_id:
		_hide_battle_skill_detail()
		return
	_show_battle_skill_detail(skill_id)


func _show_battle_skill_detail(skill_id: String) -> void:
	var skill: Dictionary = _get_skill(skill_id)
	if skill.is_empty():
		return
	current_battle_skill_detail_id = skill_id
	var detail_description: String = String(skill.get("detail_description", ""))
	if detail_description.is_empty():
		detail_description = String(skill.get("description", ""))
	battle_skill_detail_title.text = "%s [%s]" % [
		String(skill.get("name", skill_id)),
		String(skill.get("rarity", "common")).capitalize()
	]
	battle_skill_detail_body.text = "%s  |  CD %d\n%s" % [
		String(skill.get("category", "utility")).capitalize(),
		int(_get_skill_effective_cooldown(skill)),
		detail_description
	]
	var button: Button = skill_buttons.get(skill_id, null)
	if button == null:
		return
	var button_rect: Rect2 = button.get_global_rect()
	battle_skill_detail_panel.global_position = Vector2(button_rect.position.x - battle_skill_detail_panel.custom_minimum_size.x - 14.0, button_rect.position.y)
	battle_skill_detail_panel.visible = true


func _hide_battle_skill_detail() -> void:
	if battle_skill_detail_panel != null:
		battle_skill_detail_panel.visible = false
	current_battle_skill_detail_id = ""


func _build_enemy_inspect_panel() -> void:
	enemy_inspect_panel = PanelContainer.new()
	enemy_inspect_panel.name = "EnemyInspectPanel"
	enemy_inspect_panel.custom_minimum_size = Vector2(250, 220)
	enemy_inspect_panel.visible = false
	enemy_inspect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_inspect_panel.z_index = 850
	enemy_inspect_panel.add_theme_stylebox_override("panel", player_core_panel.get_theme_stylebox("panel"))
	add_child(enemy_inspect_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_inspect_panel.add_child(margin)

	enemy_inspect_content = VBoxContainer.new()
	enemy_inspect_content.add_theme_constant_override("separation", 8)
	enemy_inspect_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(enemy_inspect_content)


func _clear_all_structures() -> void:
	for lane_index in range(LANE_COUNT):
		for row_index in range(LAST_BATTLE_ROW + 1):
			board_structures[lane_index][row_index] = null


func _connect_inputs() -> void:
	energy_button.focus_mode = Control.FOCUS_NONE
	end_turn_button.focus_mode = Control.FOCUS_NONE
	energy_button.pressed.connect(_on_energy_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	for lane_index in range(LANE_COUNT):
		for row_index in range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW + 1):
			var tile: Control = board_tiles[lane_index][row_index]
			if tile == null:
				continue
			tile.mouse_filter = Control.MOUSE_FILTER_STOP
			tile.gui_input.connect(_on_tile_gui_input.bind(lane_index, row_index))
			tile.mouse_entered.connect(_on_tile_mouse_entered.bind(lane_index, row_index))
			tile.mouse_exited.connect(_on_tile_mouse_exited.bind(lane_index, row_index))
			tile.resized.connect(_on_tile_resized.bind(lane_index, row_index))
		var preview_tile: Control = board_tiles[lane_index][PREVIEW_ROW]
		if preview_tile == null:
			continue
		preview_tile.resized.connect(_on_tile_resized.bind(lane_index, PREVIEW_ROW))


func _update_action_count_visual(current_actions: int) -> void:
	if action_count_art == null:
		return
	var texture_path := ACTION_COUNT_ZERO_PATH if current_actions <= 0 else ACTION_COUNT_READY_PATH
	if ResourceLoader.exists(texture_path):
		action_count_art.texture = load(texture_path)
		action_count_art.visible = true
	else:
		action_count_art.texture = null
		action_count_art.visible = false


func _build_texture_stylebox(texture_path: String) -> StyleBoxTexture:
	if not ResourceLoader.exists(texture_path):
		return null
	var texture: Texture2D = load(texture_path)
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


func _get_drag_use_texture(skill: Dictionary) -> Texture2D:
	var category := String(skill.get("category", "")).to_lower()
	var texture_path := ""
	if category.contains("control"):
		texture_path = DRAG_USE_CONTROL_PATH
	elif category.contains("attack") or category.contains("damage"):
		texture_path = DRAG_USE_DAMAGE_PATH
	elif category.contains("utility"):
		texture_path = DRAG_USE_UTILITY_PATH
	elif category.contains("install"):
		texture_path = DRAG_USE_STRUCTURE_PATH
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path)


func _reset_run() -> void:
	selected_lane = -1
	selected_row = -1
	selected_skill_id = ""
	life = RUN_STATE.get_current_life()
	max_life = RUN_STATE.get_current_max_life()
	wave_index = 0
	next_enemy_id = 1
	battle_finished = false
	turn_manager.base_actions_per_turn = STARTING_ACTIONS + RUN_STATE.get_bonus_actions_per_turn()
	if RUN_STATE.has_relic("compressed_time"):
		turn_manager.base_actions_per_turn = max(turn_manager.base_actions_per_turn - 1, 1)
	turn_manager.reset_battle()
	pending_skill_id = ""
	pending_push_target_id = -1
	pending_push_destinations.clear()
	pending_pull_target_id = -1
	pending_pull_destinations.clear()
	pending_retreat_target_id = -1
	pending_retreat_destinations.clear()
	pending_structure_move_source.clear()
	pending_structure_move_destinations.clear()
	pending_energy_mode = ""
	pending_energy_prepaid = false
	aoe_range_bonus_this_turn = 0
	turret_damage_multiplier_this_turn = 1
	pending_cooldown_swap_active = false
	pending_cooldown_swap_card_id = ""
	pending_cooldown_swap_selected_ids.clear()
	pending_delayed_strikes.clear()
	skill_cycle_counts.clear()
	pending_next_damage_card_bonus = 0
	last_used_skill_id = ""
	last_used_skill_category = ""
	same_card_damage_streak = 0
	pending_bonus_actions_next_turn = 0
	pending_reward_skill_ids.clear()
	_hide_enemy_tile_info()
	_cancel_drag_skill(false)
	_build_wave_defs_from_current_deck()
	if result_overlay != null:
		result_overlay.visible = false
	if reward_overlay != null:
		reward_overlay.visible = false

	for skill in skills:
		skill["current_cd"] = 0
		skill["current_stack"] = 0
		skill["module_used_this_battle"] = false

	_clear_board()
	_clear_all_structures()
	_clear_stage_totem()
	_spawn_stage_totem_if_needed()
	_refresh_enemy_deck_panel()
	_start_wave(0)
	_refresh_ui()


func _reorder_battle_panels() -> void:
	var left_column: VBoxContainer = get_node("Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/LeftColumn")
	var basic_info: Control = left_column.get_node("BasicInfo")
	var enemy_pool: Control = left_column.get_node("EnemyPool")
	left_column.move_child(basic_info, 0)
	left_column.move_child(enemy_pool, 1)


func _clear_board() -> void:
	board_renderer.clear_board()
	_clear_all_structures()
	_clear_stage_totem()


func _start_wave(index: int) -> void:
	wave_flow.start_wave(index)


func _build_wave_defs_from_current_deck() -> void:
	wave_flow.build_wave_defs_from_current_deck()


func _roll_wave_row_size(rng: RandomNumberGenerator) -> int:
	return wave_flow.roll_wave_row_size(rng)


func _spawn_wave_row(row_entries: Array, target_row: int) -> void:
	var lane_front_assigned := {}
	for entry in row_entries:
		var lane_index: int = int(entry["lane"])
		var insert_mode := "front"
		if lane_front_assigned.get(lane_index, false):
			insert_mode = "back"
		lane_front_assigned[lane_index] = true
		_spawn_enemy_entry(entry, lane_index, target_row, insert_mode)


func _fill_preview_tiles() -> void:
	wave_flow.fill_preview_tiles()


func _preview_row_has_enemies() -> bool:
	return wave_flow.preview_row_has_enemies()


func _make_enemy_instance(enemy_type: String) -> Dictionary:
	return enemy_state.make_enemy_instance(enemy_type)


func _spawn_enemy_entry(entry: Dictionary, lane_index: int, row_index: int, insert_mode: String = "front") -> void:
	var enemy_type: String = String(entry.get("type", ""))
	if enemy_type == "twin":
		var first_twin: Dictionary = _make_enemy_instance(enemy_type)
		var second_twin: Dictionary = _make_enemy_instance(enemy_type)
		first_twin["linked_twin_id"] = int(second_twin.get("instance_id", -1))
		second_twin["linked_twin_id"] = int(first_twin.get("instance_id", -1))
		_add_enemy_to_tile(first_twin, lane_index, row_index, insert_mode)
		_add_enemy_to_tile(second_twin, lane_index, row_index, "back")
		return
	_add_enemy_to_tile(_make_enemy_instance(enemy_type), lane_index, row_index, insert_mode)


func _add_enemy_to_tile(enemy: Dictionary, lane_index: int, row_index: int, insert_mode: String) -> void:
	enemy_state.add_enemy_to_tile(enemy, lane_index, row_index, insert_mode)


func _remove_enemy_from_tile(enemy: Dictionary, lane_index: int, row_index: int) -> void:
	enemy_state.remove_enemy_from_tile(enemy, lane_index, row_index)


func _refresh_tile_ui(lane_index: int, row_index: int, animate_enemy_motion: bool = true) -> void:
	board_renderer.refresh_tile_ui(lane_index, row_index, animate_enemy_motion)
	var is_hovered_info_tile := lane_index == enemy_info_hover_lane and row_index == enemy_info_hover_row
	if is_hovered_info_tile and enemy_inspect_panel != null and enemy_inspect_panel.visible:
		_show_enemy_tile_info(lane_index, row_index)


func _refresh_all_tiles(animate_enemy_motion: bool = false) -> void:
	board_renderer.refresh_all_tiles(animate_enemy_motion)


func _refresh_tile_selection_visuals() -> void:
	board_renderer.refresh_tile_selection_visuals()


func _update_tile_selection_visual(lane_index: int, row_index: int) -> void:
	board_renderer.update_tile_selection_visual(lane_index, row_index)


func _refresh_ui() -> void:
	ui_renderer.refresh_ui()


func _refresh_enemy_deck_panel() -> void:
	ui_renderer.refresh_enemy_deck_panel()


func _fill_enemy_pool_tile(tile: PanelContainer, enemy_id: String) -> void:
	ui_renderer.fill_enemy_pool_tile(tile, enemy_id)


func _fill_empty_enemy_pool_tile(tile: PanelContainer) -> void:
	ui_renderer.fill_empty_enemy_pool_tile(tile)


func _clear_enemy_pool_tile(tile: PanelContainer) -> void:
	ui_renderer.clear_enemy_pool_tile(tile)


func _update_skill_buttons() -> void:
	ui_renderer.update_skill_buttons()


func _create_skill_card(skill: Dictionary) -> Button:
	return ui_renderer.create_skill_card(skill)


func _create_empty_skill_slot(index: int) -> Button:
	return ui_renderer.create_empty_skill_slot(index)


func _apply_skill_card_state(button: Button, skill: Dictionary, usable: bool, current_actions: int) -> void:
	ui_renderer.apply_skill_card_state(button, skill, usable, current_actions)


func _on_tile_gui_input(event: InputEvent, lane_index: int, row_index: int) -> void:
	input_handler.on_tile_gui_input(event, lane_index, row_index)


func _on_tile_mouse_entered(lane_index: int, row_index: int) -> void:
	input_handler.on_tile_mouse_entered(lane_index, row_index)


func _on_tile_mouse_exited(lane_index: int, row_index: int) -> void:
	input_handler.on_tile_mouse_exited(lane_index, row_index)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if energy_overlay != null and energy_overlay.visible and energy_panel != null:
			if not energy_panel.get_global_rect().has_point(event.position):
				close_energy_popup()
				get_viewport().set_input_as_handled()
				return
		_hide_battle_skill_detail()
	input_handler.raw_input(event)


func _on_tile_resized(lane_index: int, row_index: int) -> void:
	_refresh_tile_ui(lane_index, row_index)


func _on_skill_pressed(skill_id: String) -> void:
	if battle_finished:
		return
	if pending_energy_mode == "reduce_cd":
		combat_resolver.apply_pending_energy_reduce_cd(skill_id)
		return

	if not selected_skill_id.is_empty() and selected_skill_id != skill_id:
		_clear_lane_selection()
	selected_skill_id = skill_id
	var skill: Dictionary = _get_skill(skill_id)
	if skill.is_empty():
		return
	if _is_same_category_restricted(skill):
		_play_ui_sound("error")
		_refresh_ui()
		return
	if int(skill.get("current_cd", 0)) > 0:
		_play_ui_sound("error")
		_refresh_ui()
		return
	var consumes_action: bool = bool(skill.get("consumes_action", true))
	var action_cost: int = max(int(skill.get("action_cost", 1)), 0)
	if consumes_action and not turn_manager.can_act(action_cost):
		_play_ui_sound("error")
		return

	var module_control_target_id: int = _get_module_control_target_id(skill)
	var used: bool = SKILL_EFFECT_RESOLVER.resolve_skill(self, skill)

	if not used:
		_refresh_ui()
		return

	if RUN_STATE.has_relic("controller") and String(skill.get("category", "")) == "control":
		_queue_next_damage_card_bonus(5)
	_update_last_used_skill_category(skill)
	_update_same_card_damage_streak(skill)
	_process_skill_counters_on_use(skill)
	_process_card_use_relics()
	_set_skill_current_cooldown(skill_id, _get_skill_effective_cooldown(skill))
	_apply_control_module_damage_to_instance(skill, module_control_target_id)
	_apply_after_card_use_module_effects(skill_id)
	if consumes_action:
		turn_manager.spend_action(action_cost)
	_post_action_cleanup()


func _unhandled_input(event: InputEvent) -> void:
	input_handler.unhandled_input(event)


func _select_skill_by_index(index: int) -> void:
	input_handler.select_skill_by_index(index)


func _select_skill(skill_id: String) -> void:
	input_handler.select_skill(skill_id)


func _select_lane(lane_index: int, row_index: int = -1) -> void:
	input_handler.select_lane(lane_index, row_index)


func _use_selected_input_state() -> void:
	input_handler.use_selected_input_state()


func _clear_current_selection() -> void:
	input_handler.clear_current_selection()


func _clear_lane_selection() -> void:
	input_handler.clear_lane_selection()


func _on_skill_card_gui_input(event: InputEvent, skill_id: String) -> void:
	input_handler.on_skill_card_gui_input(event, skill_id)


func _start_drag_skill(skill_id: String, mouse_position: Vector2) -> void:
	if battle_finished:
		return
	if pending_energy_mode == "reduce_cd":
		combat_resolver.apply_pending_energy_reduce_cd(skill_id)
		return
	var skill: Dictionary = _get_skill(skill_id)
	if skill.is_empty():
		return
	if _is_same_category_restricted(skill):
		_play_ui_sound("error")
		return
	if int(skill.get("current_cd", 0)) > 0:
		_play_ui_sound("error")
		return
	var consumes_action: bool = bool(skill.get("consumes_action", true))
	var action_cost: int = max(int(skill.get("action_cost", 1)), 0)
	if consumes_action and not turn_manager.can_act(action_cost):
		_play_ui_sound("error")
		return

	drag_skill_id = skill_id
	drag_active = true
	drag_hover_lane = -1
	drag_mouse_global = mouse_position
	selected_skill_id = skill_id
	var button: Control = skill_buttons.get(skill_id, null)
	if button != null:
		var rect := button.get_global_rect()
		drag_origin_global = rect.position + rect.size * 0.5
	else:
		drag_origin_global = mouse_position
	_refresh_drag_overlay()
	_refresh_ui()


func _update_drag_state(mouse_position: Vector2) -> void:
	if not drag_active:
		return
	drag_mouse_global = mouse_position
	var skill: Dictionary = _get_skill(drag_skill_id)
	var targeting_type := String(skill.get("targeting_type", ""))
	var is_self_state := targeting_type == "self_state"
	var lane_index := -1
	var row_index := -1
	if not is_self_state:
		if targeting_type == "tile_install" or targeting_type == "tile_structure" or targeting_type == "tile_any":
			var tile_coords: Dictionary = _get_tile_coords_from_global_position(mouse_position)
			lane_index = int(tile_coords.get("lane", -1))
			row_index = int(tile_coords.get("row", -1))
		else:
			lane_index = _get_lane_from_global_position(mouse_position)
	if lane_index != drag_hover_lane or ((targeting_type == "tile_install" or targeting_type == "tile_structure" or targeting_type == "tile_any") and row_index != selected_row):
		drag_hover_lane = lane_index
		if is_self_state or lane_index == -1:
			_clear_lane_selection()
		else:
			_select_lane(lane_index, row_index)
		_refresh_ui()
	_refresh_drag_overlay()


func _finish_drag_skill(mouse_position: Vector2) -> void:
	if not drag_active:
		return
	var skill_id := drag_skill_id
	var skill: Dictionary = _get_skill(skill_id)
	var targeting_type := String(skill.get("targeting_type", ""))
	var is_self_state := targeting_type == "self_state"
	var lane_index := -1
	var row_index := -1
	if not is_self_state:
		if targeting_type == "tile_install" or targeting_type == "tile_structure" or targeting_type == "tile_any":
			var tile_coords: Dictionary = _get_tile_coords_from_global_position(mouse_position)
			lane_index = int(tile_coords.get("lane", -1))
			row_index = int(tile_coords.get("row", -1))
		else:
			lane_index = _get_lane_from_global_position(mouse_position)
	var dropped_outside_skill_list := not skill_list_content.get_global_rect().has_point(mouse_position)
	_cancel_drag_skill(false)
	if is_self_state:
		if dropped_outside_skill_list:
			selected_skill_id = skill_id
			_refresh_ui()
			_on_skill_pressed(skill_id)
			return
		_refresh_ui()
		return
	if lane_index == -1:
		_refresh_ui()
		return
	_select_lane(lane_index, row_index)
	_refresh_ui()
	_on_skill_pressed(skill_id)


func _cancel_drag_skill(clear_selection: bool = true) -> void:
	drag_active = false
	drag_hover_lane = -1
	drag_skill_id = ""
	_refresh_drag_overlay()
	if clear_selection:
		_clear_current_selection()
	else:
		_refresh_ui()


func _get_lane_from_global_position(mouse_position: Vector2) -> int:
	for lane_index in range(LANE_COUNT):
		for row_index in range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW + 1):
			var tile: Control = board_tiles[lane_index][row_index]
			if tile == null:
				continue
			if tile.get_global_rect().has_point(mouse_position):
				return lane_index
	return -1


func _get_tile_coords_from_global_position(mouse_position: Vector2) -> Dictionary:
	for lane_index in range(LANE_COUNT):
		for row_index in range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW + 1):
			var tile: Control = board_tiles[lane_index][row_index]
			if tile == null:
				continue
			if tile.get_global_rect().has_point(mouse_position):
				return {"lane": lane_index, "row": row_index}
	return {}


func _play_projectile_from_enemy(enemy: Dictionary) -> void:
	vfx_player.play_projectile_from_enemy(enemy)


func _play_boss_attack(enemy: Dictionary) -> void:
	vfx_player.play_boss_attack(enemy)


func _play_player_attack(target: Dictionary) -> void:
	var skill: Dictionary = _get_skill(selected_skill_id)
	var category_text: String = String(skill.get("category", "damage")).to_lower()
	var attack_color := Color(1.0, 0.86, 0.42, 0.95)
	if category_text.contains("control"):
		attack_color = Color(0.5, 0.95, 0.62, 0.95)
	elif category_text.contains("utility"):
		attack_color = Color(0.48, 0.8, 1.0, 0.95)
	elif category_text.contains("install"):
		attack_color = Color(0.86, 0.56, 0.98, 0.95)
	vfx_player.play_player_attack(target, attack_color)


func _play_projectile_from_structure(lane_index: int, row_index: int, target: Dictionary, color: Color) -> void:
	vfx_player.play_projectile_from_structure(lane_index, row_index, target, color)


func _play_enemy_move_effect(enemy_snapshot: Dictionary, from_lane: int, from_row: int, to_lane: int, to_row: int) -> void:
	vfx_player.play_enemy_move_effect(enemy_snapshot, from_lane, from_row, to_lane, to_row)


func _play_enemy_dash_to_core(enemy_snapshot: Dictionary, lane_index: int, row_index: int) -> void:
	vfx_player.play_enemy_dash_to_core(enemy_snapshot, lane_index, row_index)


func _play_king_kong_throw(from_enemy: Dictionary, target_lane: int, target_row: int) -> void:
	vfx_player.play_king_kong_throw(from_enemy, target_lane, target_row)


func _play_rocket_boss_launch(from_enemy: Dictionary, target_lane: int, target_row: int, spawned_enemy_type: String) -> void:
	vfx_player.play_rocket_boss_launch(from_enemy, target_lane, target_row, spawned_enemy_type)


func _play_tsunami_effect() -> void:
	vfx_player.play_tsunami_effect()


func _play_combo_sequence(chain_targets: Array, base_damage: int, bonus_per_link: int) -> void:
	vfx_player.play_combo_sequence(chain_targets, base_damage, bonus_per_link)


func _run_combo_sequence_via_vfx(chain_targets: Array, base_damage: int, bonus_per_link: int) -> void:
	vfx_player.run_combo_sequence_async(chain_targets, base_damage, bonus_per_link)


func _refresh_drag_overlay() -> void:
	if drag_overlay == null:
		return
	var transform := drag_overlay.get_global_transform_with_canvas().affine_inverse()
	var local_start: Vector2 = transform * drag_origin_global
	var local_end: Vector2 = transform * drag_mouse_global
	var skill: Dictionary = _get_skill(drag_skill_id)
	var is_self_state := String(skill.get("targeting_type", "")) == "self_state"
	var label_text := String(skill.get("name", ""))
	var is_valid_drop := false
	var rarity_border_color := Color(0.68, 0.86, 0.5, 0.9)
	match String(skill.get("rarity", "common")).to_lower():
		"rare":
			rarity_border_color = Color(0.52, 0.82, 0.98, 0.94)
		"epic":
			rarity_border_color = Color(0.78, 0.5, 0.96, 0.96)
	var category_fill_color := Color(0.18, 0.18, 0.18, 0.96)
	var category := String(skill.get("category", "utility")).to_lower()
	if category.contains("control"):
		category_fill_color = Color(0.15, 0.32, 0.17, 0.97)
	elif category.contains("attack") or category.contains("damage"):
		category_fill_color = Color(0.42, 0.14, 0.14, 0.97)
	elif category.contains("utility"):
		category_fill_color = Color(0.14, 0.22, 0.38, 0.97)
	var preview_texture: Texture2D = null
	if is_self_state:
		is_valid_drop = drag_active and not skill_list_content.get_global_rect().has_point(drag_mouse_global)
		preview_texture = _get_drag_use_texture(skill)
	else:
		is_valid_drop = drag_hover_lane != -1
	drag_overlay.call("set_drag_points", local_start, local_end, drag_active, is_valid_drop, is_self_state, label_text, category_fill_color, rarity_border_color, preview_texture)


func _show_enemy_tile_info(lane_index: int, row_index: int) -> void:
	if enemy_inspect_panel == null or enemy_inspect_content == null:
		return
	if lane_index < 0 or lane_index >= LANE_COUNT:
		_hide_enemy_tile_info()
		return
	if row_index < PREVIEW_ROW or row_index > LAST_BATTLE_ROW:
		_hide_enemy_tile_info()
		return
	var occupants: Array = board_state[lane_index][row_index]
	if occupants.is_empty():
		_hide_enemy_tile_info()
		return

	for child in enemy_inspect_content.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Tile Info"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.82, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
	title.add_theme_constant_override("outline_size", 1)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_inspect_content.add_child(title)

	for enemy in occupants:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 72)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(enemy.get("color", Color(0.2, 0.2, 0.2, 1.0))).darkened(0.55)
		style.border_color = Color(enemy.get("color", Color(0.7, 0.7, 0.7, 1.0))).lightened(0.25)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("panel", style)
		enemy_inspect_content.add_child(card)

		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)

		var icon := ENEMY_SCENE.instantiate()
		icon.custom_minimum_size = Vector2(54, 54)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		icon.call("set_enemy_data", enemy["name"], _get_enemy_effective_attack(enemy), enemy["hp"], enemy["max_hp"], enemy["rank"])
		icon.call("set_icon_texture", enemy.get("icon", null))
		if enemy.has("color"):
			icon.call("set_visual_color", Color(enemy["color"]))
		icon.call("set_plague_state", bool(enemy.get("plague_active", false)), int(enemy.get("plague_damage", 0)))
		icon.call("set_stealth_state", _is_enemy_hidden(enemy))
		icon.call("set_attached_state", int(enemy.get("attached_host_id", -1)) != -1)
		icon.call("set_shield_state", bool(enemy.get("shield_active", false)))
		icon.call("set_totem_state", _is_enemy_in_active_totem_range(enemy), _get_active_totem_color())
		icon.call("set_turn_counter", int(enemy.get("behavior_state", {}).get("turns_remaining", 0)))

		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 2)
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(info)

		var name_label := Label.new()
		name_label.text = String(enemy.get("name", "Enemy"))
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.88, 1.0))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(name_label)

		var stat_label := Label.new()
		stat_label.text = "HP %d  D %d  M %d  S %d" % [
			int(enemy.get("hp", 0)),
			_get_enemy_effective_attack(enemy),
			int(enemy.get("speed", 1)),
			int(enemy.get("danger_score", 0))
		]
		stat_label.add_theme_font_size_override("font_size", 12)
		stat_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.76, 1.0))
		stat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(stat_label)

		var special_label := Label.new()
		special_label.text = String(enemy.get("special", ""))
		special_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		special_label.add_theme_font_size_override("font_size", 11)
		special_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.82, 1.0))
		special_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(special_label)

	var tile: Control = board_tiles[lane_index][row_index]
	if tile == null:
		enemy_inspect_panel.visible = true
		return

	var tile_rect := tile.get_global_rect()
	var local_pos := get_global_transform_with_canvas().affine_inverse() * tile_rect.position
	var target_x := local_pos.x + tile_rect.size.x + 14.0
	var target_y := local_pos.y
	var viewport_size := get_viewport_rect().size
	if target_x + enemy_inspect_panel.custom_minimum_size.x > viewport_size.x - 16.0:
		target_x = local_pos.x - enemy_inspect_panel.custom_minimum_size.x - 14.0
	target_x = clamp(target_x, 12.0, viewport_size.x - enemy_inspect_panel.custom_minimum_size.x - 12.0)
	target_y = clamp(target_y, 12.0, viewport_size.y - enemy_inspect_panel.custom_minimum_size.y - 12.0)
	enemy_inspect_panel.position = Vector2(target_x, target_y)
	enemy_inspect_panel.visible = true


func _hide_enemy_tile_info() -> void:
	if enemy_inspect_panel != null:
		enemy_inspect_panel.visible = false


func _get_selected_skill_name() -> String:
	var skill := _get_skill(selected_skill_id)
	return String(skill.get("name", selected_skill_id))


func _has_enemy_trait_on_field(trait_id: String) -> bool:
	if trait_id.is_empty():
		return false
	for lane_index in range(LANE_COUNT):
		for row_index in range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW + 1):
			for enemy in board_state[lane_index][row_index]:
				if enemy.get("traits", []).has(trait_id):
					return true
	return false


func _get_skill_effective_cooldown(skill: Dictionary) -> int:
	var cooldown: int = int(skill.get("cooldown", 0))
	var module_data: Dictionary = _get_skill_module(skill)
	if String(module_data.get("effect_key", "")) == "cooldown_down":
		cooldown -= int(module_data.get("values", {}).get("cooldown_bonus", 1))
	if RUN_STATE.has_relic("compressed_time"):
		cooldown -= 2
	if RUN_STATE.has_relic("clockwork") and cooldown >= 3:
		cooldown -= 1
	if RUN_STATE.has_relic("tactician") and String(skill.get("category", "")).to_lower().contains("control"):
		cooldown -= 1
	if _has_enemy_trait_on_field("cooldown_aura"):
		cooldown += 1
	return max(cooldown, 0)


func _queue_next_damage_card_bonus(amount: int) -> void:
	if amount <= 0:
		return
	pending_next_damage_card_bonus += amount


func _peek_next_damage_card_bonus() -> int:
	return max(pending_next_damage_card_bonus, 0)


func _consume_next_damage_card_bonus() -> int:
	var amount: int = max(pending_next_damage_card_bonus, 0)
	pending_next_damage_card_bonus = 0
	return amount


func _get_same_card_damage_bonus(skill: Dictionary) -> int:
	if not RUN_STATE.has_relic("momentum"):
		return 0
	if String(skill.get("category", "")) != "damage":
		return 0
	if String(skill.get("id", "")) != last_used_skill_id:
		return 0
	return max(same_card_damage_streak, 0) * 5


func _get_skill_module(skill: Dictionary) -> Dictionary:
	return MODULE_CATALOG.get_module(String(skill.get("module_id", "")))


func _is_damage_module_skill(skill: Dictionary) -> bool:
	var category := String(skill.get("category", "")).to_lower()
	return category == "damage" or category == "attack"


func _get_module_adjusted_damage(skill: Dictionary, amount: int) -> int:
	var adjusted: int = amount
	var module_data: Dictionary = _get_skill_module(skill)
	var effect_key: String = String(module_data.get("effect_key", ""))
	if module_data.is_empty() or not _is_damage_module_skill(skill):
		return adjusted
	if effect_key == "damage_bonus":
		adjusted += int(module_data.get("values", {}).get("damage_bonus", 0))
	elif effect_key == "overheat":
		var multiplier: float = float(module_data.get("values", {}).get("damage_multiplier", 1.5))
		adjusted = int(ceil(float(adjusted) * multiplier))
	return max(adjusted, 0)


func _get_module_structure_hp_bonus(skill: Dictionary) -> int:
	var module_data: Dictionary = _get_skill_module(skill)
	if String(module_data.get("effect_key", "")) != "structure_hp_bonus":
		return 0
	return max(int(module_data.get("values", {}).get("hp_bonus", 0)), 0)


func _get_module_control_target_id(skill: Dictionary) -> int:
	if String(skill.get("category", "")).to_lower() != "control":
		return -1
	var module_data: Dictionary = _get_skill_module(skill)
	if String(module_data.get("effect_key", "")) != "control_chip_damage":
		return -1
	if selected_lane == -1:
		return -1
	var target: Dictionary = _get_front_enemy_in_lane(selected_lane)
	if target.is_empty():
		return -1
	return int(target.get("instance_id", -1))


func _apply_control_module_damage_to_instance(skill: Dictionary, instance_id: int) -> void:
	if instance_id == -1:
		return
	var module_data: Dictionary = _get_skill_module(skill)
	if String(module_data.get("effect_key", "")) != "control_chip_damage":
		return
	var target: Dictionary = _find_enemy_by_instance_id(instance_id)
	if target.is_empty():
		return
	_damage_enemy(target, int(module_data.get("values", {}).get("damage", 3)))


func _apply_after_card_use_module_effects(skill_id: String) -> void:
	var index := _get_skill_index(skill_id)
	if index == -1:
		return
	var skill: Dictionary = skills[index]
	var module_data: Dictionary = _get_skill_module(skill)
	if module_data.is_empty():
		return
	var effect_key: String = String(module_data.get("effect_key", ""))
	var values: Dictionary = module_data.get("values", {})
	if effect_key == "reduce_right_cd":
		_reduce_slot_cooldown(index + 1, int(values.get("cooldown_reduction", 1)))
	elif effect_key == "reduce_left_cd":
		_reduce_slot_cooldown(index - 1, int(values.get("cooldown_reduction", 1)))
	elif effect_key == "overheat":
		skills[index]["current_cd"] = max(int(skills[index].get("current_cd", 0)) + int(values.get("cooldown_penalty", 1)), 0)
	elif effect_key == "first_use_cd_zero" and not bool(skills[index].get("module_used_this_battle", false)):
		skills[index]["current_cd"] = 0
		skills[index]["module_used_this_battle"] = true


func _reduce_slot_cooldown(slot_index: int, amount: int) -> void:
	if amount <= 0:
		return
	if slot_index < 0 or slot_index >= skills.size():
		return
	var current_cd: int = int(skills[slot_index].get("current_cd", 0))
	if current_cd <= 0:
		return
	skills[slot_index]["current_cd"] = max(current_cd - amount, 0)


func _get_skill_counter(skill_id: String) -> int:
	var index := _get_skill_index(skill_id)
	if index == -1:
		return 0
	return int(skills[index].get("current_stack", 0))


func _consume_skill_counter(skill_id: String) -> void:
	var index := _get_skill_index(skill_id)
	if index == -1:
		return
	skills[index]["current_stack"] = 0


func _increment_skill_counter(skill_id: String, amount: int = 1) -> int:
	var index := _get_skill_index(skill_id)
	if index == -1:
		return 0
	var next_value: int = int(skills[index].get("current_stack", 0)) + amount
	skills[index]["current_stack"] = max(next_value, 0)
	return int(skills[index].get("current_stack", 0))


func _update_same_card_damage_streak(skill: Dictionary) -> void:
	var skill_id: String = String(skill.get("id", ""))
	if String(skill.get("category", "")) != "damage":
		last_used_skill_id = ""
		same_card_damage_streak = 0
		return
	if skill_id == last_used_skill_id:
		same_card_damage_streak += 1
	else:
		last_used_skill_id = skill_id
		same_card_damage_streak = 1


func _process_skill_counters_on_use(skill: Dictionary) -> void:
	var used_skill_id: String = String(skill.get("id", ""))
	var combo_skill_id := "combo_stack"
	if _get_skill_index(combo_skill_id) == -1:
		return
	if used_skill_id == combo_skill_id:
		_consume_skill_counter(combo_skill_id)
		return
	_increment_skill_counter(combo_skill_id, 1)


func _get_runtime_skill_description(skill: Dictionary) -> String:
	var skill_id: String = String(skill.get("id", ""))
	if skill_id == "combo_stack":
		var stack_count: int = _get_skill_counter(skill_id)
		return "Stack %d. %d damage." % [stack_count, stack_count * 3]
	return String(skill.get("description", ""))


func _process_card_use_relics() -> void:
	var use_count: int = RUN_STATE.increment_card_use_count()
	if not RUN_STATE.has_relic("decimator"):
		return
	if use_count <= 0 or use_count % 10 != 0:
		return
	for lane_index in range(LANE_COUNT):
		for row_index in range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW + 1):
			var enemies: Array = board_state[lane_index][row_index].duplicate()
			for enemy in enemies:
				if enemy.is_empty():
					continue
				if not _enemy_exists(enemy):
					continue
				_damage_enemy(enemy, 8)


func _advance_skill_cycle(skill_id: String, cycle_size: int) -> int:
	var next_count: int = int(skill_cycle_counts.get(skill_id, 0)) + 1
	if cycle_size > 0 and next_count > cycle_size:
		next_count = 1
	skill_cycle_counts[skill_id] = next_count
	return next_count


func _get_enemy_effective_attack(enemy: Dictionary) -> int:
	var base_attack: int = int(enemy.get("attack", 0))
	base_attack += enemy_state.get_attached_attack_bonus(enemy)
	base_attack += _get_totem_attack_bonus(enemy)
	if RUN_STATE.has_relic("war_drums"):
		base_attack += 2
	if int(enemy.get("attack_debuff_turns", 0)) <= 0:
		return base_attack
	return max(base_attack - int(enemy.get("attack_debuff_amount", 0)), 0)


func _get_enemy_effective_speed(enemy: Dictionary) -> int:
	return int(enemy.get("speed", 1)) + enemy_state.get_attached_speed_bonus(enemy) + _get_totem_speed_bonus(enemy)


func _is_enemy_hidden(enemy: Dictionary) -> bool:
	return bool(enemy.get("stealth_active", false)) or _has_totem_stealth(enemy)


func _apply_totem_turn_start_effects(enemy: Dictionary) -> void:
	if enemy.is_empty():
		return
	if not _is_enemy_in_active_totem_range(enemy):
		return
	if String(current_stage_totem.get("effect_key", "")) == "regen_5":
		combat_resolver.heal_enemy(enemy, int(current_stage_totem.get("values", {}).get("heal", 5)))


func _get_active_totem() -> Dictionary:
	return current_stage_totem.duplicate(true)


func _get_active_totem_color() -> Color:
	if current_stage_totem.is_empty():
		return Color(1, 1, 1, 1)
	return Color(current_stage_totem.get("color", Color.WHITE))


func _is_totem_aura_tile(lane_index: int, row_index: int) -> bool:
	if current_stage_totem.is_empty():
		return false
	return _is_tile_in_totem_range(lane_index, row_index)


func _is_totem_tile(lane_index: int, row_index: int) -> bool:
	if current_stage_totem.is_empty():
		return false
	return int(current_stage_totem.get("lane", -1)) == lane_index and int(current_stage_totem.get("row", -1)) == row_index


func _is_enemy_in_active_totem_range(enemy: Dictionary) -> bool:
	if current_stage_totem.is_empty():
		return false
	return _is_tile_in_totem_range(int(enemy.get("lane", -1)), int(enemy.get("row", -1)))


func _get_totem_attack_bonus(enemy: Dictionary) -> int:
	if not _is_enemy_in_active_totem_range(enemy):
		return 0
	if String(current_stage_totem.get("effect_key", "")) != "bonus_attack":
		return 0
	return int(current_stage_totem.get("values", {}).get("attack_bonus", 0))


func _get_totem_speed_bonus(enemy: Dictionary) -> int:
	if not _is_enemy_in_active_totem_range(enemy):
		return 0
	if String(current_stage_totem.get("effect_key", "")) != "bonus_speed":
		return 0
	return int(current_stage_totem.get("values", {}).get("speed_bonus", 0))


func _has_totem_stealth(enemy: Dictionary) -> bool:
	if not _is_enemy_in_active_totem_range(enemy):
		return false
	return String(current_stage_totem.get("effect_key", "")) == "grant_stealth"


func _is_tile_in_totem_range(lane_index: int, row_index: int) -> bool:
	if current_stage_totem.is_empty():
		return false
	var totem_lane: int = int(current_stage_totem.get("lane", -1))
	var totem_row: int = int(current_stage_totem.get("row", -1))
	if totem_lane < 0 or totem_row < FIRST_BATTLE_ROW:
		return false
	match String(current_stage_totem.get("range_type", "")):
		"row":
			return row_index == totem_row
		"column":
			return lane_index == totem_lane
		"cross":
			return abs(lane_index - totem_lane) + abs(row_index - totem_row) <= 1
		"square_3":
			return abs(lane_index - totem_lane) <= 1 and abs(row_index - totem_row) <= 1
		_:
			return false


func _clear_stage_totem() -> void:
	current_stage_totem.clear()


func _spawn_stage_totem_if_needed() -> void:
	if not RUN_STATE.TOTEMS_ENABLED:
		return
	var totem_id: String = RUN_STATE.get_current_stage_totem_id()
	if totem_id.is_empty():
		return
	var totem_data: Dictionary = TOTEM_CATALOG.get_totem(totem_id)
	if totem_data.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	current_stage_totem = totem_data.duplicate(true)
	current_stage_totem["lane"] = rng.randi_range(0, LANE_COUNT - 1)
	current_stage_totem["row"] = rng.randi_range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW)
	_refresh_all_tiles()


func _get_skill_category_key(skill: Dictionary) -> String:
	var category: String = String(skill.get("category", "")).to_lower()
	if category.contains("damage") or category.contains("attack"):
		return "damage"
	if category.contains("control"):
		return "control"
	if category.contains("install"):
		return "install"
	if category.contains("utility"):
		return "utility"
	return category


func _is_same_category_restricted(skill: Dictionary) -> bool:
	if not RUN_STATE.has_relic("discipline"):
		return false
	var category_key := _get_skill_category_key(skill)
	if category_key.is_empty():
		return false
	return category_key == last_used_skill_category


func _update_last_used_skill_category(skill: Dictionary) -> void:
	last_used_skill_category = _get_skill_category_key(skill)


func _reset_discipline_lock() -> void:
	last_used_skill_category = ""


func _get_lane_label(lane_index: int) -> String:
	match lane_index:
		0:
			return "Left"
		1:
			return "Center"
		2:
			return "Right"
	return "-"


func _get_skill(skill_id: String) -> Dictionary:
	for skill in skills:
		if skill["id"] == skill_id:
			return skill
	return {}


func _get_skill_index(skill_id: String) -> int:
	for index in range(skills.size()):
		if String(skills[index].get("id", "")) == skill_id:
			return index
	return -1


func _set_skill_current_cooldown(skill_id: String, value: int) -> void:
	var index := _get_skill_index(skill_id)
	if index == -1:
		return
	skills[index]["current_cd"] = max(value, 0)


func _get_front_enemy_in_lane(lane_index: int) -> Dictionary:
	return combat_resolver.get_front_enemy_in_lane(lane_index)


func _get_back_enemy_in_lane(lane_index: int) -> Dictionary:
	return combat_resolver.get_back_enemy_in_lane(lane_index)


func _get_front_enemy_in_tile(lane_index: int, row_index: int) -> Dictionary:
	return combat_resolver.get_front_enemy_in_tile(lane_index, row_index)


func _get_enemy_stack_index(enemy: Dictionary) -> int:
	return combat_resolver.get_enemy_stack_index(enemy)


func _get_closest_enemy_behind(target: Dictionary) -> Dictionary:
	return combat_resolver.get_closest_enemy_behind(target)


func _get_next_combo_target(current_target: Dictionary, hit_ids: Dictionary) -> Dictionary:
	return combat_resolver.get_next_combo_target(current_target, hit_ids)


func _get_rows_behind_target(target: Dictionary) -> Array:
	return combat_resolver.get_rows_behind_target(target)


func _get_rows_in_front_of_target(target: Dictionary) -> Array:
	return combat_resolver.get_rows_in_front_of_target(target)


func _get_all_enemies_in_row(row_index: int) -> Array:
	return combat_resolver.get_all_enemies_in_row(row_index)


func _is_row_fully_occupied(row_index: int) -> bool:
	return combat_resolver.is_row_fully_occupied(row_index)


func _get_bomb_preview_role(lane_index: int, row_index: int) -> int:
	return combat_resolver.get_bomb_preview_role(lane_index, row_index)


func _get_sweep_preview_role(lane_index: int, row_index: int) -> int:
	return combat_resolver.get_sweep_preview_role(lane_index, row_index)


func _get_cross_preview_role(lane_index: int, row_index: int) -> int:
	return combat_resolver.get_cross_preview_role(lane_index, row_index)


func _damage_enemy(enemy: Dictionary, amount: int) -> void:
	combat_resolver.damage_enemy(enemy, amount)


func _damage_enemy_from_card(enemy: Dictionary, amount: int) -> void:
	_play_player_attack(enemy)
	var skill: Dictionary = _get_skill(selected_skill_id)
	combat_resolver.damage_enemy(enemy, _get_module_adjusted_damage(skill, amount), true)


func _apply_life_damage(amount: int) -> void:
	combat_resolver.apply_life_damage(amount)


func _get_effective_max_life() -> int:
	return max_life


func _move_enemy_to_row(enemy: Dictionary, new_row: int, insert_mode: String) -> bool:
	return enemy_state.move_enemy_to_row(enemy, new_row, insert_mode)


func _play_control_move_impact(from_lane: int, from_row: int, to_lane: int, to_row: int) -> void:
	vfx_player.play_control_shift_effect(from_lane, from_row, to_lane, to_row)


func _post_action_cleanup() -> void:
	combat_resolver.post_action_cleanup()


func _on_energy_pressed() -> void:
	_play_ui_sound("select")
	combat_resolver.on_energy_pressed()


func open_energy_popup() -> void:
	if battle_finished or not turn_manager.can_use_energy():
		return
	if energy_overlay == null:
		return
	pending_energy_mode = ""
	pending_energy_prepaid = false
	_refresh_energy_popup_state()
	_position_energy_popup()
	energy_overlay.visible = true


func close_energy_popup() -> void:
	if energy_overlay != null:
		energy_overlay.visible = false
	pending_energy_mode = ""
	pending_energy_prepaid = false


func _position_energy_popup() -> void:
	if energy_panel == null or energy_button == null or control_zone_panel == null:
		return
	var button_rect := energy_button.get_global_rect()
	var local_pos := get_global_transform_with_canvas().affine_inverse() * button_rect.position
	var control_rect := control_zone_panel.get_global_rect()
	var control_local_pos := get_global_transform_with_canvas().affine_inverse() * control_rect.position
	var popup_width := energy_panel.custom_minimum_size.x
	var popup_height := energy_panel.custom_minimum_size.y
	var target_x := local_pos.x + (button_rect.size.x - popup_width) * 0.5
	var target_y := local_pos.y - popup_height - 10.0
	var padding := 10.0
	target_x = clamp(target_x, control_local_pos.x + padding, control_local_pos.x + control_rect.size.x - popup_width - padding)
	target_y = clamp(target_y, control_local_pos.y + padding, control_local_pos.y + control_rect.size.y - popup_height - padding)
	energy_panel.position = Vector2(target_x, target_y)


func _refresh_energy_popup_state() -> void:
	if energy_cd_button == null:
		return
	energy_cd_button.disabled = battle_finished or not turn_manager.can_use_energy()
	var using_cooldown_art := ResourceLoader.exists(ENERGY_COOLDOWN_PATH)
	if using_cooldown_art:
		energy_cd_button.text = ""
		return
	if pending_energy_mode == "reduce_cd":
		energy_cd_button.text = "Choose a Card..."
	elif RUN_STATE.has_relic("overcharge"):
		energy_cd_button.text = "Gain +1 Action + CD -1"
	else:
		energy_cd_button.text = "Choose Card for CD -1"


func _on_energy_gain_action_pressed() -> void:
	_play_ui_sound("confirm")
	combat_resolver.use_energy_for_action()


func _on_energy_reduce_cd_pressed() -> void:
	if battle_finished or not turn_manager.can_use_energy():
		_play_ui_sound("error")
		return
	_play_ui_sound("select")
	if RUN_STATE.has_relic("overcharge"):
		combat_resolver.use_energy_with_overcharge()
		return
	pending_energy_mode = "reduce_cd"
	pending_energy_prepaid = false
	energy_overlay.visible = false
	_refresh_ui()


func _on_end_turn_pressed() -> void:
	_play_ui_sound("confirm")
	combat_resolver.on_end_turn_pressed()


func _process_structures_turn() -> void:
	combat_resolver.process_structures_turn()


func _run_enemy_movement() -> void:
	enemy_state.run_enemy_movement()


func _enemy_exists(enemy: Dictionary) -> bool:
	return enemy_state.enemy_exists(enemy)


func _reduce_cooldowns() -> void:
	combat_resolver.reduce_cooldowns()


func _reduce_damage_skill_cooldowns(amount: int) -> bool:
	return combat_resolver.reduce_damage_skill_cooldowns(amount)


func _gain_actions_this_turn(amount: int) -> bool:
	return combat_resolver.gain_actions_this_turn(amount)


func _gain_aoe_range_this_turn(amount: int) -> bool:
	return combat_resolver.gain_aoe_range_this_turn(amount)


func _gain_turret_damage_multiplier_this_turn(multiplier: int) -> bool:
	return combat_resolver.gain_turret_damage_multiplier_this_turn(multiplier)


func _double_all_mines() -> bool:
	var changed := false
	for lane_index in range(LANE_COUNT):
		for row_index in range(FIRST_BATTLE_ROW, LAST_BATTLE_ROW + 1):
			var structure = _get_structure_in_tile(lane_index, row_index)
			if structure == null:
				continue
			if String(structure.get("id", "")) != "mine":
				continue
			structure["stacks"] = max(int(structure.get("stacks", 1)) * 2, 1)
			board_structures[lane_index][row_index] = structure
			_refresh_tile_ui(lane_index, row_index)
			changed = true
	return changed


func _begin_pending_cooldown_swap(skill_id: String) -> void:
	combat_resolver.begin_pending_cooldown_swap(skill_id)


func _apply_pending_cooldown_swap_selection(skill_id: String) -> bool:
	return combat_resolver.apply_pending_cooldown_swap_selection(skill_id)


func _check_wave_clear() -> void:
	wave_flow.check_wave_clear()


func _handle_battle_result(message: String) -> void:
	if message == "Stage Clear":
		_clear_board()
	reward_flow.handle_battle_result(message)


func _return_to_stage_select_after_delay() -> void:
	await reward_flow.return_to_stage_select_after_delay()


func _show_card_reward_popup() -> void:
	reward_flow.show_card_reward_popup()


func _generate_reward_skill_choices() -> Array[String]:
	return reward_flow.generate_reward_skill_choices()


func _roll_reward_skill_id(rng: RandomNumberGenerator, owned_skill_ids: Array[String], offered: Array[String], rarity_chances: Dictionary) -> String:
	return reward_flow.roll_reward_skill_id(rng, owned_skill_ids, offered, rarity_chances)


func _get_available_reward_skill_ids(rarity: String, owned_skill_ids: Array[String], offered: Array[String]) -> Array[String]:
	return reward_flow.get_available_reward_skill_ids(rarity, owned_skill_ids, offered)


func _populate_reward_cards() -> void:
	reward_flow.populate_reward_cards()


func _build_reward_card_ui(button: Button, skill_id: String) -> void:
	reward_flow.build_reward_card_ui(button, skill_id)


func _build_empty_reward_card_ui(button: Button) -> void:
	reward_flow.build_empty_reward_card_ui(button)


func _on_reward_card_pressed(index: int) -> void:
	reward_flow.on_reward_card_pressed(index)


func _resolve_pending_skill_on_tile(lane_index: int, row_index: int) -> bool:
	return combat_resolver.resolve_pending_skill_on_tile(lane_index, row_index)


func _resolve_bomb_at(lane_index: int, row_index: int) -> bool:
	return combat_resolver.resolve_bomb_at(lane_index, row_index)


func _resolve_cross_at(lane_index: int, row_index: int) -> bool:
	return combat_resolver.resolve_cross_at(lane_index, row_index)


func _resolve_push_to(lane_index: int, row_index: int) -> bool:
	return combat_resolver.resolve_push_to(lane_index, row_index)


func _resolve_push_from_keyboard(lane_index: int) -> bool:
	return combat_resolver.resolve_push_from_keyboard(lane_index)


func _resolve_retreat_to(lane_index: int, row_index: int) -> bool:
	return combat_resolver.resolve_retreat_to(lane_index, row_index)


func _retreat_all_enemies_one_row() -> bool:
	return combat_resolver.retreat_all_enemies_one_row()


func _is_pending_push_destination(lane_index: int, row_index: int) -> bool:
	return combat_resolver.is_pending_push_destination(lane_index, row_index)


func _is_pending_retreat_destination(lane_index: int, row_index: int) -> bool:
	return combat_resolver.is_pending_retreat_destination(lane_index, row_index)


func _is_pending_pull_destination(lane_index: int, row_index: int) -> bool:
	return combat_resolver.is_pending_pull_destination(lane_index, row_index)


func _is_pending_structure_move_source(lane_index: int, row_index: int) -> bool:
	return combat_resolver.is_pending_structure_move_source(lane_index, row_index)


func _is_pending_structure_move_destination(lane_index: int, row_index: int) -> bool:
	return combat_resolver.is_pending_structure_move_destination(lane_index, row_index)


func _is_pending_push_lane(lane_index: int) -> bool:
	return combat_resolver.is_pending_push_lane(lane_index)


func _get_pending_push_destination_for_lane(lane_index: int) -> Dictionary:
	return combat_resolver.get_pending_push_destination_for_lane(lane_index)


func _get_pending_retreat_destination(lane_index: int, row_index: int) -> Dictionary:
	return combat_resolver.get_pending_retreat_destination(lane_index, row_index)


func _get_pending_pull_destination(lane_index: int, row_index: int) -> Dictionary:
	return combat_resolver.get_pending_pull_destination(lane_index, row_index)


func _find_enemy_by_instance_id(instance_id: int) -> Dictionary:
	return enemy_state.find_enemy_by_instance_id(instance_id)


func _move_enemy_to_position(enemy: Dictionary, new_lane: int, new_row: int, insert_mode: String) -> bool:
	return enemy_state.move_enemy_to_position(enemy, new_lane, new_row, insert_mode)


func _advance_enemy_one_row(enemy: Dictionary, insert_mode: String = "front") -> void:
	enemy_state.advance_enemy_one_row(enemy, insert_mode)


func _spawn_boss_minions(enemy: Dictionary, spawn_count: int) -> void:
	enemy_state.spawn_boss_minions(enemy, spawn_count)


func _spawn_rocket_boss_minion(enemy: Dictionary) -> void:
	enemy_state.spawn_rocket_boss_minion(enemy)


func _get_structure_in_tile(lane_index: int, row_index: int) -> Variant:
	if lane_index < 0 or lane_index >= LANE_COUNT:
		return null
	if row_index < PREVIEW_ROW or row_index > LAST_BATTLE_ROW:
		return null
	return board_structures[lane_index][row_index]


func _get_delayed_strike_in_tile(lane_index: int, row_index: int) -> Dictionary:
	for strike in pending_delayed_strikes:
		if int(strike.get("lane", -1)) == lane_index and int(strike.get("row", -1)) == row_index:
			return strike
	return {}


func _can_install_at(lane_index: int, row_index: int) -> bool:
	return _can_install_structure_at(lane_index, row_index, "")


func _can_install_structure_at(lane_index: int, row_index: int, structure_id: String) -> bool:
	if lane_index < 0 or lane_index >= LANE_COUNT:
		return false
	var min_row: int = INSTALLABLE_MIN_ROW
	if structure_id == "mine" or _is_defensive_structure_id(structure_id):
		min_row = FIRST_BATTLE_ROW
	if row_index < min_row or row_index > LAST_BATTLE_ROW:
		return false
	if not board_state[lane_index][row_index].is_empty():
		return false
	var existing_structure = _get_structure_in_tile(lane_index, row_index)
	if existing_structure == null:
		return true
	if structure_id == "boost_turret" and String(existing_structure.get("id", "")) == "boost_turret":
		return int(existing_structure.get("stacks", 1)) < int(existing_structure.get("max_stacks", 1))
	if structure_id == "mine" and String(existing_structure.get("id", "")) == "mine":
		return int(existing_structure.get("stacks", 1)) < int(existing_structure.get("max_stacks", 1))
	return false


func _is_defensive_structure_id(structure_id: String) -> bool:
	return structure_id == "wall"


func _install_structure(lane_index: int, row_index: int, structure_data: Dictionary) -> bool:
	var structure_id := String(structure_data.get("id", ""))
	if not _can_install_structure_at(lane_index, row_index, structure_id):
		return false
	var existing_structure = _get_structure_in_tile(lane_index, row_index)
	if existing_structure != null and (
		(structure_id == "boost_turret" and String(existing_structure.get("id", "")) == "boost_turret")
		or (structure_id == "mine" and String(existing_structure.get("id", "")) == "mine")
	):
		existing_structure["stacks"] = min(
			int(existing_structure.get("stacks", 1)) + 1,
			int(existing_structure.get("max_stacks", 1))
		)
		board_structures[lane_index][row_index] = existing_structure
	else:
		board_structures[lane_index][row_index] = structure_data.duplicate(true)
	_refresh_tile_ui(lane_index, row_index)
	return true


func _damage_structure(lane_index: int, row_index: int, amount: int) -> bool:
	var structure = _get_structure_in_tile(lane_index, row_index)
	if structure == null:
		return false
	if int(structure.get("shield_hits", 0)) > 0 and amount > 0:
		structure["shield_hits"] = max(int(structure.get("shield_hits", 0)) - 1, 0)
		board_structures[lane_index][row_index] = structure
		_refresh_tile_ui(lane_index, row_index)
		return true
	if amount > 0:
		structure["hp"] = max(int(structure.get("hp", 0)) - amount, 0)
	if int(structure.get("hp", 0)) <= 0:
		board_structures[lane_index][row_index] = null
	else:
		board_structures[lane_index][row_index] = structure
	_refresh_tile_ui(lane_index, row_index)
	return true


func _trigger_mine_at(lane_index: int, row_index: int) -> bool:
	var structure = _get_structure_in_tile(lane_index, row_index)
	if structure == null:
		return false
	if String(structure.get("id", "")) != "mine":
		return false
	var damage: int = int(structure.get("attack", 0)) * max(int(structure.get("stacks", 1)), 1)
	for enemy in board_state[lane_index][row_index].duplicate():
		_damage_enemy(enemy, damage)
	board_structures[lane_index][row_index] = null
	_refresh_tile_ui(lane_index, row_index)
	return true


func _can_move_structure_to(lane_index: int, row_index: int) -> bool:
	if lane_index < 0 or lane_index >= LANE_COUNT:
		return false
	if row_index < INSTALLABLE_MIN_ROW or row_index > LAST_BATTLE_ROW:
		return false
	if not board_state[lane_index][row_index].is_empty():
		return false
	return _get_structure_in_tile(lane_index, row_index) == null


func _get_structure_move_destinations(lane_index: int, row_index: int) -> Array:
	var destinations: Array = []
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next_lane: int = lane_index + offset.x
		var next_row: int = row_index + offset.y
		if not _can_move_structure_to(next_lane, next_row):
			continue
		destinations.append({"lane": next_lane, "row": next_row})
	return destinations


func _move_structure_to(source_lane: int, source_row: int, dest_lane: int, dest_row: int) -> bool:
	var structure = _get_structure_in_tile(source_lane, source_row)
	if structure == null:
		return false
	if not _can_move_structure_to(dest_lane, dest_row):
		return false
	board_structures[source_lane][source_row] = null
	board_structures[dest_lane][dest_row] = structure
	_refresh_tile_ui(source_lane, source_row)
	_refresh_tile_ui(dest_lane, dest_row)
	return true


func _is_install_preview_tile(lane_index: int, row_index: int) -> bool:
	var skill: Dictionary = _get_skill(selected_skill_id)
	if String(skill.get("targeting_type", "")) != "tile_install":
		return false
	if String(skill.get("effect_key", "")) == "move_structure":
		return false
	return _can_install_structure_at(lane_index, row_index, String(skill.get("id", "")))


func _is_structure_target_preview_tile(lane_index: int, row_index: int) -> bool:
	var skill: Dictionary = _get_skill(selected_skill_id)
	if String(skill.get("targeting_type", "")) != "tile_structure":
		return false
	var structure = _get_structure_in_tile(lane_index, row_index)
	if structure == null:
		return false
	return int(structure.get("shield_hits", 0)) <= 0


func _is_structure_move_preview_tile(lane_index: int, row_index: int) -> bool:
	var skill: Dictionary = _get_skill(selected_skill_id)
	if String(skill.get("effect_key", "")) != "move_structure":
		return false
	if pending_skill_id == "move_structure":
		return false
	return _get_structure_in_tile(lane_index, row_index) != null


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_select_screen.tscn")
