extends RefCounted

const ENEMY_SCENE := preload("res://scenes/enemy_ui.tscn")

var owner: Control
var rendered_enemy_positions: Dictionary = {}


func setup(target_owner: Control) -> void:
	owner = target_owner


func build_board_references() -> void:
	owner.board_tiles.clear()
	for lane_index in range(owner.LANE_COUNT):
		var lane_tiles: Array = []
		var base_path := "Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/CenterColumn/BattleBoard/BoardMargin/BoardContent/LaneColumns/Lane%d/Lane%dMargin/Lane%dContent" % [lane_index + 1, lane_index + 1, lane_index + 1]
		var lane_node: Node = owner.get_node_or_null(base_path)
		if lane_node == null:
			var missing_lane: Array = []
			for _i in range(owner.LAST_BATTLE_ROW + 1):
				missing_lane.append(null)
			owner.board_tiles.append(missing_lane)
			continue

		var preview_tile: PanelContainer = lane_node.get_node_or_null("Lane%dPreview" % [lane_index + 1])
		lane_tiles.append(preview_tile)
		for row_index in range(owner.FIRST_BATTLE_ROW, owner.LAST_BATTLE_ROW + 1):
			var tile: PanelContainer = lane_node.get_node_or_null("Lane%dTile%d" % [lane_index + 1, row_index])
			lane_tiles.append(tile)
		owner.board_tiles.append(lane_tiles)


func build_board_state() -> void:
	owner.board_state.clear()
	for _lane_index in range(owner.LANE_COUNT):
		var lane_rows: Array = []
		for _row_index in range(owner.LAST_BATTLE_ROW + 1):
			lane_rows.append([])
		owner.board_state.append(lane_rows)


func clear_board() -> void:
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			owner.board_state[lane_index][row_index].clear()
			refresh_tile_ui(lane_index, row_index)


func refresh_tile_ui(lane_index: int, row_index: int, animate_enemy_motion: bool = true) -> void:
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return
	_capture_existing_enemy_positions(tile)
	for child in tile.get_children():
		if child.has_method("set_enemy_data") or child.name == "EnemyStackLayer" or child.name == "StructureLayer" or child.name == "DelayedStrikeLabel" or child.name == "TotemLayer" or child.name == "TotemAuraLayer" or child.name == "WideBossLayer":
			tile.remove_child(child)
			child.free()

	var occupants: Array = owner.board_state[lane_index][row_index]
	var virtual_row_occupants: Array = occupants.duplicate()
	if virtual_row_occupants.is_empty():
		var virtual_front: Dictionary = owner._get_front_enemy_in_tile(lane_index, row_index)
		if not virtual_front.is_empty() and virtual_front.get("traits", []).has("wide_top_3") and int(virtual_front.get("row", -1)) == row_index:
			if lane_index == int(owner.LANE_COUNT / 2):
				virtual_row_occupants.append(virtual_front)
	var structure = owner._get_structure_in_tile(lane_index, row_index)
	var delayed_strike: Dictionary = owner._get_delayed_strike_in_tile(lane_index, row_index)
	var front_enemy: Dictionary = owner._get_front_enemy_in_lane(lane_index)
	if not delayed_strike.is_empty():
		var count_label := Label.new()
		count_label.name = "DelayedStrikeLabel"
		count_label.layout_mode = 1
		count_label.offset_left = 4.0
		count_label.offset_top = tile.size.y * 0.5 - 16.0
		count_label.offset_right = 28.0
		count_label.offset_bottom = tile.size.y * 0.5 + 12.0
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.text = str(int(delayed_strike.get("turns_remaining", 0)))
		count_label.add_theme_font_size_override("font_size", 24)
		count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
		count_label.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.04, 1.0))
		count_label.add_theme_constant_override("outline_size", 2)
		tile.add_child(count_label)
	if owner._is_totem_tile(lane_index, row_index):
		var totem_data: Dictionary = owner._get_active_totem()
		var totem_overlay := Control.new()
		totem_overlay.name = "TotemLayer"
		totem_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		totem_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		totem_overlay.z_index = 3
		tile.add_child(totem_overlay)

		var totem_color: Color = Color(totem_data.get("color", Color.WHITE))
		var totem_frame := PanelContainer.new()
		totem_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		totem_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(totem_color.r, totem_color.g, totem_color.b, 0.08)
		frame_style.border_color = totem_color.lightened(0.18)
		frame_style.border_width_left = 2
		frame_style.border_width_top = 2
		frame_style.border_width_right = 2
		frame_style.border_width_bottom = 2
		frame_style.corner_radius_top_left = 8
		frame_style.corner_radius_top_right = 8
		frame_style.corner_radius_bottom_left = 8
		frame_style.corner_radius_bottom_right = 8
		totem_frame.add_theme_stylebox_override("panel", frame_style)
		totem_overlay.add_child(totem_frame)

		var totem_panel := PanelContainer.new()
		totem_panel.custom_minimum_size = Vector2(22, 22)
		totem_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		totem_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		totem_panel.offset_left = -26
		totem_panel.offset_top = 4
		totem_panel.offset_right = -4
		totem_panel.offset_bottom = 26
		var totem_style := StyleBoxFlat.new()
		totem_style.bg_color = totem_color
		totem_style.border_color = Color(0.98, 0.98, 0.94, 0.98)
		totem_style.border_width_left = 3
		totem_style.border_width_top = 3
		totem_style.border_width_right = 3
		totem_style.border_width_bottom = 3
		totem_style.corner_radius_top_left = 999
		totem_style.corner_radius_top_right = 999
		totem_style.corner_radius_bottom_left = 999
		totem_style.corner_radius_bottom_right = 999
		totem_panel.add_theme_stylebox_override("panel", totem_style)
		totem_overlay.add_child(totem_panel)
	elif owner._is_totem_aura_tile(lane_index, row_index):
		var aura_overlay := Control.new()
		aura_overlay.name = "TotemAuraLayer"
		aura_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		aura_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aura_overlay.z_index = 2
		tile.add_child(aura_overlay)

		var aura_frame := PanelContainer.new()
		aura_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		aura_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var aura_style := StyleBoxFlat.new()
		var aura_color: Color = owner._get_active_totem_color()
		aura_style.bg_color = Color(aura_color.r, aura_color.g, aura_color.b, 0.04)
		aura_style.border_color = Color(aura_color.r, aura_color.g, aura_color.b, 0.55)
		aura_style.border_width_left = 1
		aura_style.border_width_top = 1
		aura_style.border_width_right = 1
		aura_style.border_width_bottom = 1
		aura_style.corner_radius_top_left = 8
		aura_style.corner_radius_top_right = 8
		aura_style.corner_radius_bottom_left = 8
		aura_style.corner_radius_bottom_right = 8
		aura_frame.add_theme_stylebox_override("panel", aura_style)
		aura_overlay.add_child(aura_frame)
	if structure != null:
		var structure_panel := PanelContainer.new()
		structure_panel.name = "StructureLayer"
		structure_panel.custom_minimum_size = Vector2(74, 74)
		structure_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		structure_panel.position = Vector2(tile.size.x * 0.5 - 37.0, tile.size.y * 0.5 - 37.0)
		var structure_style := StyleBoxFlat.new()
		structure_style.bg_color = Color(structure.get("color", Color(0.58, 0.38, 0.74, 1.0))).darkened(0.12)
		structure_style.border_color = Color(0.92, 0.88, 0.98, 0.95)
		structure_style.border_width_left = 2
		structure_style.border_width_top = 2
		structure_style.border_width_right = 2
		structure_style.border_width_bottom = 2
		structure_style.corner_radius_top_left = 8
		structure_style.corner_radius_top_right = 8
		structure_style.corner_radius_bottom_left = 8
		structure_style.corner_radius_bottom_right = 8
		structure_panel.add_theme_stylebox_override("panel", structure_style)
		tile.add_child(structure_panel)

		var structure_margin := MarginContainer.new()
		structure_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		structure_margin.add_theme_constant_override("margin_left", 6)
		structure_margin.add_theme_constant_override("margin_top", 6)
		structure_margin.add_theme_constant_override("margin_right", 6)
		structure_margin.add_theme_constant_override("margin_bottom", 6)
		structure_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		structure_panel.add_child(structure_margin)

		var structure_box := VBoxContainer.new()
		structure_box.alignment = BoxContainer.ALIGNMENT_CENTER
		structure_box.add_theme_constant_override("separation", 2)
		structure_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		structure_margin.add_child(structure_box)

		var hp_label := Label.new()
		var stacks: int = int(structure.get("stacks", 1))
		hp_label.text = str(int(structure.get("hp", 0))) if stacks <= 1 else "x%d" % stacks
		if int(structure.get("shield_hits", 0)) > 0:
			hp_label.text += " S"
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 16)
		hp_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))
		hp_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
		hp_label.add_theme_constant_override("outline_size", 1)
		hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		structure_box.add_child(hp_label)

		var name_label := Label.new()
		name_label.text = String(structure.get("name", "Wall"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))
		name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
		name_label.add_theme_constant_override("outline_size", 1)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		structure_box.add_child(name_label)

	if not virtual_row_occupants.is_empty():
		if virtual_row_occupants.size() == 1 and virtual_row_occupants[0].get("traits", []).has("wide_top_3"):
			_build_wide_boss_ui(tile, virtual_row_occupants[0], row_index)
			update_tile_selection_visual(lane_index, row_index)
			return
		var stack_layer := Control.new()
		stack_layer.name = "EnemyStackLayer"
		stack_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(stack_layer)

		var shown: int = min(virtual_row_occupants.size(), 3)
		var tile_center_x: float = tile.size.x * 0.5
		var tile_center_y: float = tile.size.y * 0.5
		var enemy_width := 82.0
		var enemy_height := 82.0
		for reverse_index in range(shown - 1, -1, -1):
			var enemy_data: Dictionary = virtual_row_occupants[reverse_index]
			var enemy_ui: Control = ENEMY_SCENE.instantiate()
			stack_layer.add_child(enemy_ui)
			var depth_from_front: int = reverse_index
			var offset_x: float = float(depth_from_front) * 10.0
			var offset_y: float = -float(depth_from_front) * 4.0
			var target_position := Vector2(tile_center_x - enemy_width * 0.5 + offset_x, tile_center_y - enemy_height * 0.5 + offset_y)
			enemy_ui.position = target_position
			enemy_ui.set_meta("instance_id", int(enemy_data.get("instance_id", -1)))
			enemy_ui.z_index = shown - reverse_index
			enemy_ui.call("set_enemy_data", enemy_data["name"], owner._get_enemy_effective_attack(enemy_data), enemy_data["hp"], enemy_data["max_hp"], enemy_data["rank"])
			enemy_ui.call("set_icon_texture", enemy_data.get("icon", null))
			if enemy_data.has("color"):
				enemy_ui.call("set_visual_color", Color(enemy_data["color"]))
			enemy_ui.call("set_plague_state", bool(enemy_data.get("plague_active", false)), int(enemy_data.get("plague_damage", 0)))
			enemy_ui.call("set_stealth_state", owner._is_enemy_hidden(enemy_data))
			enemy_ui.call("set_attached_state", int(enemy_data.get("attached_host_id", -1)) != -1)
			enemy_ui.call("set_shield_state", bool(enemy_data.get("shield_active", false)))
			enemy_ui.call("set_totem_state", owner._is_enemy_in_active_totem_range(enemy_data), owner._get_active_totem_color())
			enemy_ui.call("set_turn_counter", int(enemy_data.get("behavior_state", {}).get("turns_remaining", 0)))
			var is_front_target: bool = lane_index == owner.selected_lane and not front_enemy.is_empty() and int(enemy_data["instance_id"]) == int(front_enemy["instance_id"])
			enemy_ui.call("set_targeted", is_front_target)
			var body: Panel = enemy_ui.get_node("Body")
			if int(enemy_data.get("attached_host_id", -1)) != -1:
				body.self_modulate = Color(1.0, 1.0, 1.0, 0.42)
			elif enemy_data.get("icon", null) != null:
				body.self_modulate = Color(1.0, 1.0, 1.0, 0.64) if owner._is_enemy_hidden(enemy_data) else Color(1.0, 1.0, 1.0, 1.0)
			else:
				body.self_modulate = Color(1.0, 1.0, 1.0, 0.64) if owner._is_enemy_hidden(enemy_data) else enemy_data["color"]
			if animate_enemy_motion:
				_tween_enemy_from_previous_position(enemy_ui, stack_layer, enemy_data, target_position)

	update_tile_selection_visual(lane_index, row_index)
	_update_enemy_target_states(lane_index, row_index)


func _capture_existing_enemy_positions(tile: Control) -> void:
	for child in tile.get_children():
		if child.name == "EnemyStackLayer":
			for enemy_ui in child.get_children():
				_remember_enemy_position(enemy_ui)
		elif child.has_method("set_enemy_data"):
			_remember_enemy_position(child)


func _remember_enemy_position(enemy_ui: Node) -> void:
	if not enemy_ui.has_meta("instance_id"):
		return
	var instance_id := int(enemy_ui.get_meta("instance_id"))
	if instance_id < 0:
		return
	if enemy_ui is Control:
		rendered_enemy_positions[instance_id] = (enemy_ui as Control).global_position


func _tween_enemy_from_previous_position(enemy_ui: Control, parent: Control, enemy_data: Dictionary, target_position: Vector2) -> void:
	var instance_id := int(enemy_data.get("instance_id", -1))
	if instance_id < 0 or not rendered_enemy_positions.has(instance_id):
		return
	var previous_global: Vector2 = rendered_enemy_positions[instance_id]
	var start_position: Vector2 = parent.get_global_transform_with_canvas().affine_inverse() * previous_global
	if start_position.distance_to(target_position) < 2.0:
		return
	enemy_ui.position = start_position
	var tween := enemy_ui.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy_ui, "position", target_position, 0.28)


func _build_wide_boss_ui(tile: Control, enemy_data: Dictionary, row_index: int) -> void:
	var left_tile: Control = owner.board_tiles[0][row_index]
	var right_tile: Control = owner.board_tiles[owner.LANE_COUNT - 1][row_index]
	if left_tile == null or right_tile == null:
		return

	var left_global: Rect2 = left_tile.get_global_rect()
	var right_global: Rect2 = right_tile.get_global_rect()
	var top_left: Vector2 = left_global.position
	var bottom_right: Vector2 = right_global.position + right_global.size
	var wide_size: Vector2 = bottom_right - top_left

	var wide_layer := Control.new()
	wide_layer.name = "WideBossLayer"
	wide_layer.top_level = true
	wide_layer.global_position = top_left
	wide_layer.size = wide_size
	wide_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wide_layer.z_index = 5
	tile.add_child(wide_layer)

	var body := PanelContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = Color(0.08, 0.08, 0.08, 0.98)
	body_style.border_color = Color(0.96, 0.96, 0.96, 0.96)
	body_style.border_width_left = 3
	body_style.border_width_top = 3
	body_style.border_width_right = 3
	body_style.border_width_bottom = 3
	body_style.corner_radius_top_left = 10
	body_style.corner_radius_top_right = 10
	body_style.corner_radius_bottom_left = 10
	body_style.corner_radius_bottom_right = 10
	body.add_theme_stylebox_override("panel", body_style)
	wide_layer.add_child(body)

	var left_half := ColorRect.new()
	left_half.color = Color(0.96, 0.96, 0.96, 0.92)
	left_half.anchor_left = 0.0
	left_half.anchor_top = 0.0
	left_half.anchor_right = 0.5
	left_half.anchor_bottom = 1.0
	left_half.offset_left = 4.0
	left_half.offset_top = 4.0
	left_half.offset_right = -2.0
	left_half.offset_bottom = -4.0
	left_half.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(left_half)

	var right_half := ColorRect.new()
	right_half.color = Color(0.08, 0.08, 0.08, 0.98)
	right_half.anchor_left = 0.5
	right_half.anchor_top = 0.0
	right_half.anchor_right = 1.0
	right_half.anchor_bottom = 1.0
	right_half.offset_left = 2.0
	right_half.offset_top = 4.0
	right_half.offset_right = -4.0
	right_half.offset_bottom = -4.0
	right_half.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(right_half)

	var center_line := ColorRect.new()
	center_line.color = Color(0.25, 0.25, 0.25, 0.9)
	center_line.anchor_left = 0.5
	center_line.anchor_right = 0.5
	center_line.anchor_top = 0.0
	center_line.anchor_bottom = 1.0
	center_line.offset_left = -1.0
	center_line.offset_right = 1.0
	center_line.offset_top = 4.0
	center_line.offset_bottom = -4.0
	center_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(center_line)

	var attack_label := Label.new()
	attack_label.text = "D %d" % owner._get_enemy_effective_attack(enemy_data)
	attack_label.anchor_left = 0.0
	attack_label.anchor_right = 0.0
	attack_label.anchor_top = 0.0
	attack_label.anchor_bottom = 0.0
	attack_label.offset_left = 12.0
	attack_label.offset_top = 8.0
	attack_label.offset_right = 62.0
	attack_label.offset_bottom = 24.0
	attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	attack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	attack_label.add_theme_font_size_override("font_size", 16)
	attack_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.82, 1.0))
	attack_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08, 1.0))
	attack_label.add_theme_constant_override("outline_size", 1)
	attack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(attack_label)

	var hp_label := Label.new()
	hp_label.text = "HP %d" % int(enemy_data.get("hp", 0))
	hp_label.anchor_left = 1.0
	hp_label.anchor_right = 1.0
	hp_label.anchor_top = 0.0
	hp_label.anchor_bottom = 0.0
	hp_label.offset_left = -84.0
	hp_label.offset_top = 8.0
	hp_label.offset_right = -12.0
	hp_label.offset_bottom = 24.0
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.82, 1.0))
	hp_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08, 1.0))
	hp_label.add_theme_constant_override("outline_size", 1)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hp_label)

	var title := Label.new()
	title.text = String(enemy_data.get("name", "Boss"))
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 1.0
	title.offset_left = 8.0
	title.offset_top = 20.0
	title.offset_right = -8.0
	title.offset_bottom = -18.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.92, 0.84, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08, 1.0))
	title.add_theme_constant_override("outline_size", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(title)


func refresh_all_tiles(animate_enemy_motion: bool = false) -> void:
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			refresh_tile_ui(lane_index, row_index, animate_enemy_motion)


func refresh_tile_selection_visuals() -> void:
	for lane_index in range(owner.LANE_COUNT):
		for row_index in range(owner.LAST_BATTLE_ROW + 1):
			update_tile_selection_visual(lane_index, row_index)
			_update_enemy_target_states(lane_index, row_index)


func _update_enemy_target_states(lane_index: int, row_index: int) -> void:
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return
	var front_enemy: Dictionary = owner._get_front_enemy_in_lane(lane_index)
	var target_instance_id := int(front_enemy.get("instance_id", -1))
	var stack_layer: Node = tile.get_node_or_null("EnemyStackLayer")
	if stack_layer == null:
		return
	for enemy_ui in stack_layer.get_children():
		if not enemy_ui.has_method("set_targeted"):
			continue
		if not enemy_ui.has_meta("instance_id"):
			continue
		var instance_id := int(enemy_ui.get_meta("instance_id", -1))
		enemy_ui.call("set_targeted", lane_index == owner.selected_lane and instance_id == target_instance_id)


func update_tile_selection_visual(lane_index: int, row_index: int) -> void:
	var tile: Control = owner.board_tiles[lane_index][row_index]
	_clear_tile_highlight_overlay(tile)
	if row_index == owner.PREVIEW_ROW:
		if lane_index == owner.selected_lane:
			tile.modulate = Color(1.08, 1.15, 1.24, 1.0)
		else:
			tile.modulate = Color(1, 1, 1, 1)
		return

	if owner._is_pending_push_destination(lane_index, row_index):
		tile.modulate = Color(1.24, 1.14, 0.72, 1.0)
		return
	if owner._is_pending_push_lane(lane_index):
		tile.modulate = Color(1.1, 1.02, 0.8, 1.0)
		return
	if owner._is_pending_retreat_destination(lane_index, row_index):
		tile.modulate = Color(0.82, 1.0, 1.12, 1.0)
		return
	if owner._is_pending_pull_destination(lane_index, row_index):
		tile.modulate = Color(0.98, 1.0, 0.78, 1.0)
		return
	if owner._is_pending_structure_move_source(lane_index, row_index):
		tile.modulate = Color(1.08, 1.26, 0.9, 1.0)
		return
	if owner._is_pending_structure_move_destination(lane_index, row_index):
		tile.modulate = Color(0.82, 1.18, 0.94, 1.0)
		return
	if owner._is_structure_target_preview_tile(lane_index, row_index):
		tile.modulate = Color(0.98, 1.22, 1.36, 1.0)
		return
	if owner._is_structure_move_preview_tile(lane_index, row_index):
		tile.modulate = Color(1.14, 1.24, 0.94, 1.0)
		return
	if owner._is_install_preview_tile(lane_index, row_index):
		var is_selected_install_tile: bool = lane_index == owner.selected_lane and row_index == owner.selected_row
		_apply_tile_highlight_overlay(
			tile,
			Color(0.96, 0.54, 0.98, 0.16) if not is_selected_install_tile else Color(1.0, 0.66, 1.0, 0.24),
			Color(0.82, 1.0, 0.62, 0.98) if not is_selected_install_tile else Color(1.0, 1.0, 0.82, 1.0),
			2 if not is_selected_install_tile else 4
		)
		tile.modulate = Color(1.34, 1.12, 1.56, 1.0)
		return
	var bomb_preview_role: int = owner._get_bomb_preview_role(lane_index, row_index)
	if bomb_preview_role == 2:
		tile.modulate = Color(1.34, 1.16, 1.48, 1.0)
		return
	if bomb_preview_role == 1:
		tile.modulate = Color(1.18, 1.08, 1.3, 1.0)
		return
	var sweep_preview_role: int = owner._get_sweep_preview_role(lane_index, row_index)
	if sweep_preview_role == 2:
		tile.modulate = Color(1.16, 1.3, 1.46, 1.0)
		return
	if sweep_preview_role == 1:
		tile.modulate = Color(1.08, 1.18, 1.3, 1.0)
		return
	var cross_preview_role: int = owner._get_cross_preview_role(lane_index, row_index)
	if cross_preview_role == 2:
		tile.modulate = Color(1.42, 1.2, 1.18, 1.0)
		return
	if cross_preview_role == 1:
		tile.modulate = Color(1.24, 1.12, 1.08, 1.0)
		return
	if cross_preview_role == 3:
		tile.modulate = Color(1.08, 1.2, 1.42, 1.0)
		return
	if owner._is_totem_tile(lane_index, row_index):
		var totem_color: Color = owner._get_active_totem_color()
		tile.modulate = totem_color.lerp(Color.WHITE, 0.18)
		return
	if owner._is_totem_aura_tile(lane_index, row_index):
		var aura_color: Color = owner._get_active_totem_color()
		tile.modulate = aura_color.lerp(Color.WHITE, 0.5)
		return

	if lane_index == owner.selected_lane and row_index == owner.selected_row:
		tile.modulate = Color(1.2, 1.22, 1.1, 1)
	elif lane_index == owner.selected_lane:
		tile.modulate = Color(1.08, 1.12, 1.18, 1)
	else:
		tile.modulate = Color(1, 1, 1, 1)


func _clear_tile_highlight_overlay(tile: Control) -> void:
	if tile == null:
		return
	var overlay: PanelContainer = tile.get_node_or_null("TileHighlightOverlay")
	if overlay != null:
		tile.remove_child(overlay)
		overlay.queue_free()


func _apply_tile_highlight_overlay(tile: Control, fill_color: Color, border_color: Color, border_width: int) -> void:
	if tile == null:
		return
	var overlay := PanelContainer.new()
	overlay.name = "TileHighlightOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 1
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	overlay.add_theme_stylebox_override("panel", style)
	tile.add_child(overlay)


func get_enemy_visual_center_from_snapshot(snapshot: Dictionary) -> Vector2:
	var lane_index: int = int(snapshot.get("lane", -1))
	var row_index: int = int(snapshot.get("row", -1))
	var stack_index: int = int(snapshot.get("stack_index", 0))
	if snapshot.get("traits", []).has("wide_top_3") and row_index >= owner.PREVIEW_ROW and row_index <= owner.LAST_BATTLE_ROW:
		var left_tile: Control = owner.board_tiles[0][row_index]
		var right_tile: Control = owner.board_tiles[owner.LANE_COUNT - 1][row_index]
		if left_tile != null and right_tile != null:
			var left_rect: Rect2 = left_tile.get_global_rect()
			var right_rect: Rect2 = right_tile.get_global_rect()
			return (left_rect.position + (right_rect.position + right_rect.size)) * 0.5
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return Vector2.ZERO
	if row_index < owner.PREVIEW_ROW or row_index > owner.LAST_BATTLE_ROW:
		return Vector2.ZERO
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return Vector2.ZERO
	var tile_rect: Rect2 = tile.get_global_rect()
	var center: Vector2 = tile_rect.position + tile_rect.size * 0.5
	return center + Vector2(float(stack_index) * 10.0, -float(stack_index) * 4.0)
