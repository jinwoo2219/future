extends RefCounted

const ENEMY_SCENE := preload("res://scenes/enemy_ui.tscn")
const ENEMY_CATALOG = preload("res://scripts/enemy_catalog.gd")
const COMBAT_CENTER_PATH := "Margin/RootSplit/CombatZone/CombatMargin/CombatSplit/CenterColumn"

var owner: Control
var effect_overlay: Control


func setup(target_owner: Control) -> void:
	owner = target_owner


func build_effect_overlay() -> void:
	effect_overlay = Control.new()
	effect_overlay.name = "EffectOverlay"
	effect_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.z_index = 900
	owner.add_child(effect_overlay)


func play_projectile_from_enemy(enemy: Dictionary) -> void:
	if effect_overlay == null:
		return
	var lane_index: int = int(enemy.get("lane", -1))
	var row_index: int = int(enemy.get("row", -1))
	if lane_index < 0 or row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return
	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = tile.get_global_rect().position + tile.size * 0.5
	var end_global: Vector2 = owner.player_core_panel.get_global_rect().position + owner.player_core_panel.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(0.98, 0.82, 0.42, 0.95)
	line.antialiased = true
	line.points = PackedVector2Array([start_local, start_local])
	effect_overlay.add_child(line)

	var tween := owner.create_tween()
	tween.tween_property(line, "points", PackedVector2Array([start_local, end_local]), 0.12)
	tween.tween_property(line, "modulate:a", 0.0, 0.08)
	tween.finished.connect(line.queue_free)


func play_boss_attack(enemy: Dictionary) -> void:
	if effect_overlay == null:
		return
	var lane_index: int = int(enemy.get("lane", -1))
	var row_index: int = int(enemy.get("row", -1))
	if lane_index < 0 or row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return
	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = tile.get_global_rect().position + tile.size * 0.5
	var end_global: Vector2 = owner.player_core_panel.get_global_rect().position + owner.player_core_panel.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global
	var mid_local: Vector2 = start_local.lerp(end_local, 0.5) + Vector2(0, -36.0)

	var glow := Line2D.new()
	glow.width = 18.0
	glow.default_color = Color(0.92, 0.92, 0.96, 0.22)
	glow.antialiased = true
	glow.points = PackedVector2Array([start_local, mid_local, end_local])
	effect_overlay.add_child(glow)

	var line := Line2D.new()
	line.width = 8.0
	line.default_color = Color(0.98, 0.98, 1.0, 0.98)
	line.antialiased = true
	line.points = PackedVector2Array([start_local, start_local, start_local])
	effect_overlay.add_child(line)

	var impact := ColorRect.new()
	impact.color = Color(1.0, 1.0, 1.0, 0.0)
	impact.size = Vector2(42.0, 42.0)
	impact.position = end_local - impact.size * 0.5
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.add_child(impact)

	var tween := owner.create_tween()
	tween.tween_property(line, "points", PackedVector2Array([start_local, mid_local, end_local]), 0.16)
	tween.parallel().tween_property(glow, "modulate:a", 0.8, 0.08)
	tween.tween_property(impact, "color:a", 0.55, 0.04)
	tween.parallel().tween_property(line, "modulate:a", 0.0, 0.08)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.1)
	tween.parallel().tween_property(impact, "color:a", 0.0, 0.1)
	tween.finished.connect(line.queue_free)
	tween.finished.connect(glow.queue_free)
	tween.finished.connect(impact.queue_free)


func play_player_attack(target: Dictionary, color: Color = Color(1.0, 0.86, 0.42, 0.95)) -> void:
	if effect_overlay == null:
		return
	var lane_index: int = int(target.get("lane", -1))
	var row_index: int = int(target.get("row", -1))
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return
	var end_global: Vector2 = owner.board_renderer.get_enemy_visual_center_from_snapshot({
		"lane": lane_index,
		"row": row_index,
		"stack_index": owner._get_enemy_stack_index(target),
	})
	if end_global == Vector2.ZERO:
		return
	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = owner.player_core_panel.get_global_rect().position + owner.player_core_panel.size * 0.5 + Vector2(0, -18.0)
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var glow := Line2D.new()
	glow.width = 10.0
	glow.default_color = Color(color.r, color.g, color.b, 0.2)
	glow.antialiased = true
	glow.points = PackedVector2Array([start_local, start_local])
	effect_overlay.add_child(glow)

	var line := Line2D.new()
	line.width = 4.0
	line.default_color = color
	line.antialiased = true
	line.points = PackedVector2Array([start_local, start_local])
	effect_overlay.add_child(line)

	var impact := ColorRect.new()
	impact.color = Color(color.r, color.g, color.b, 0.0)
	impact.size = Vector2(18.0, 18.0)
	impact.position = end_local - impact.size * 0.5
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.add_child(impact)

	var tween := owner.create_tween()
	tween.tween_property(glow, "points", PackedVector2Array([start_local, end_local]), 0.06)
	tween.parallel().tween_property(line, "points", PackedVector2Array([start_local, end_local]), 0.07)
	tween.parallel().tween_property(impact, "color:a", 0.45, 0.04)
	tween.tween_property(line, "modulate:a", 0.0, 0.07)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.08)
	tween.parallel().tween_property(impact, "color:a", 0.0, 0.08)
	tween.finished.connect(line.queue_free)
	tween.finished.connect(glow.queue_free)
	tween.finished.connect(impact.queue_free)


func play_enemy_move_effect(enemy_snapshot: Dictionary, from_lane: int, from_row: int, to_lane: int, to_row: int) -> void:
	if effect_overlay == null:
		return
	if from_lane < 0 or from_lane >= owner.LANE_COUNT or to_lane < 0 or to_lane >= owner.LANE_COUNT:
		return
	if from_row < owner.PREVIEW_ROW or from_row > owner.LAST_BATTLE_ROW:
		return
	if to_row < owner.PREVIEW_ROW or to_row > owner.LAST_BATTLE_ROW:
		return
	var from_tile: Control = owner.board_tiles[from_lane][from_row]
	var to_tile: Control = owner.board_tiles[to_lane][to_row]
	if from_tile == null or to_tile == null:
		return

	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = from_tile.get_global_rect().position + from_tile.size * 0.5
	var end_global: Vector2 = to_tile.get_global_rect().position + to_tile.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var ghost: Control = ENEMY_SCENE.instantiate()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 950
	effect_overlay.add_child(ghost)
	ghost.call("set_enemy_data",
		String(enemy_snapshot.get("name", "Enemy")),
		int(enemy_snapshot.get("attack", 0)),
		int(enemy_snapshot.get("hp", 0)),
		int(enemy_snapshot.get("max_hp", enemy_snapshot.get("hp", 0))),
		String(enemy_snapshot.get("rank", "normal"))
	)
	if enemy_snapshot.has("color"):
		ghost.call("set_visual_color", Color(enemy_snapshot["color"]))
	ghost.call("set_icon_texture", enemy_snapshot.get("icon", null))
	ghost.call("set_plague_state", bool(enemy_snapshot.get("plague_active", false)), int(enemy_snapshot.get("plague_damage", 0)))
	ghost.call("set_stealth_state", bool(enemy_snapshot.get("stealth_active", false)))
	ghost.call("set_attached_state", bool(enemy_snapshot.get("attached_active", false)))
	ghost.call("set_shield_state", bool(enemy_snapshot.get("shield_active", false)))
	ghost.call("set_turn_counter", int(enemy_snapshot.get("turn_counter", 0)))

	var size := Vector2(82.0, 82.0)
	ghost.position = start_local - size * 0.5

	var style: Dictionary = _get_enemy_move_style(enemy_snapshot)
	var target_position: Vector2 = end_local - size * 0.5
	var duration: float = float(style.get("duration", 0.14))
	var tween := owner.create_tween()
	tween.set_parallel(true)
	if bool(style.get("jump", false)):
		var midpoint_position: Vector2 = start_local.lerp(end_local, 0.5) - size * 0.5 + Vector2(0, -float(style.get("jump_height", 28.0)))
		tween.tween_property(ghost, "position", midpoint_position, duration * 0.48).set_trans(int(style.get("trans", Tween.TRANS_BACK))).set_ease(int(style.get("ease", Tween.EASE_OUT)))
		tween.chain().tween_property(ghost, "position", target_position, duration * 0.52).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(ghost, "position", target_position, duration).set_trans(int(style.get("trans", Tween.TRANS_SINE))).set_ease(int(style.get("ease", Tween.EASE_OUT)))
	tween.tween_property(ghost, "scale", Vector2(float(style.get("scale", 1.0)), float(style.get("scale", 1.0))), duration * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var trail := Line2D.new()
	trail.width = float(style.get("trail_width", 4.0))
	trail.default_color = Color(style.get("trail_color", Color(1, 1, 1, 0.4)))
	trail.antialiased = true
	if bool(style.get("jump", false)):
		var jump_mid: Vector2 = start_local.lerp(end_local, 0.5) + Vector2(0, -float(style.get("jump_height", 28.0)))
		trail.points = PackedVector2Array([start_local, jump_mid, end_local])
	else:
		trail.points = PackedVector2Array([start_local, end_local])
	effect_overlay.add_child(trail)
	tween.tween_property(trail, "modulate:a", 0.0, duration + 0.06)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.08).set_delay(duration - 0.03)

	if bool(style.get("blink", false)):
		ghost.modulate.a = 0.78
		var blink_tween := owner.create_tween()
		blink_tween.tween_property(ghost, "modulate:a", 0.18, 0.04)
		blink_tween.tween_property(ghost, "modulate:a", 0.82, 0.04)

	tween.finished.connect(ghost.queue_free)
	tween.finished.connect(trail.queue_free)


func play_control_shift_effect(from_lane: int, from_row: int, to_lane: int, to_row: int) -> void:
	if effect_overlay == null:
		return
	if from_lane < 0 or from_lane >= owner.LANE_COUNT or to_lane < 0 or to_lane >= owner.LANE_COUNT:
		return
	if from_row < owner.PREVIEW_ROW or from_row > owner.LAST_BATTLE_ROW:
		return
	if to_row < owner.PREVIEW_ROW or to_row > owner.LAST_BATTLE_ROW:
		return
	var from_tile: Control = owner.board_tiles[from_lane][from_row]
	var to_tile: Control = owner.board_tiles[to_lane][to_row]
	if from_tile == null or to_tile == null:
		return

	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = from_tile.get_global_rect().position + from_tile.size * 0.5
	var end_global: Vector2 = to_tile.get_global_rect().position + to_tile.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var glow := Line2D.new()
	glow.width = 16.0
	glow.default_color = Color(0.86, 1.0, 0.58, 0.18)
	glow.antialiased = true
	glow.points = PackedVector2Array([start_local, start_local])
	effect_overlay.add_child(glow)

	var line := Line2D.new()
	line.width = 6.0
	line.default_color = Color(0.96, 1.0, 0.72, 0.95)
	line.antialiased = true
	line.points = PackedVector2Array([start_local, start_local])
	effect_overlay.add_child(line)

	var impact := ColorRect.new()
	impact.color = Color(0.92, 1.0, 0.72, 0.0)
	impact.size = Vector2(28.0, 28.0)
	impact.position = end_local - impact.size * 0.5
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.add_child(impact)

	var flash := ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.size = Vector2(40.0, 40.0)
	flash.position = end_local - flash.size * 0.5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.add_child(flash)

	var tween := owner.create_tween()
	tween.tween_property(glow, "points", PackedVector2Array([start_local, end_local]), 0.05)
	tween.parallel().tween_property(line, "points", PackedVector2Array([start_local, end_local]), 0.06)
	tween.parallel().tween_property(impact, "color:a", 0.4, 0.04)
	tween.parallel().tween_property(flash, "color:a", 0.22, 0.04)
	tween.tween_property(line, "modulate:a", 0.0, 0.06)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.08)
	tween.parallel().tween_property(impact, "color:a", 0.0, 0.09)
	tween.parallel().tween_property(flash, "color:a", 0.0, 0.08)
	tween.finished.connect(line.queue_free)
	tween.finished.connect(glow.queue_free)
	tween.finished.connect(impact.queue_free)
	tween.finished.connect(flash.queue_free)


func _shake_combat_center(direction: Vector2) -> void:
	var shake_target: Control = owner.get_node_or_null(COMBAT_CENTER_PATH)
	if shake_target == null:
		return
	var origin: Vector2 = shake_target.position
	var normalized_direction := direction
	if normalized_direction.length() <= 0.001:
		normalized_direction = Vector2(1.0, 0.0)
	else:
		normalized_direction = normalized_direction.normalized()
	var offset := Vector2(round(normalized_direction.x * 8.0), round(normalized_direction.y * 5.0))
	var tween := owner.create_tween()
	tween.tween_property(shake_target, "position", origin + offset, 0.035).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(shake_target, "position", origin, 0.07).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func play_projectile_from_structure(lane_index: int, row_index: int, target: Dictionary, color: Color) -> void:
	if effect_overlay == null:
		return
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return
	var start_global: Vector2 = tile.get_global_rect().position + tile.size * 0.5
	var end_global: Vector2 = owner.board_renderer.get_enemy_visual_center_from_snapshot({
		"lane": int(target.get("lane", -1)),
		"row": int(target.get("row", -1)),
		"stack_index": owner._get_enemy_stack_index(target),
	})
	if end_global == Vector2.ZERO:
		return
	var overlay_inverse := effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var line := Line2D.new()
	line.width = 4.0
	line.default_color = color
	line.antialiased = true
	line.points = PackedVector2Array([start_local, start_local])
	effect_overlay.add_child(line)

	var tween := owner.create_tween()
	tween.tween_property(line, "points", PackedVector2Array([start_local, end_local]), 0.1)
	tween.tween_property(line, "modulate:a", 0.0, 0.08)
	tween.finished.connect(line.queue_free)


func _get_enemy_move_style(enemy_snapshot: Dictionary) -> Dictionary:
	var move_pattern_id: String = String(enemy_snapshot.get("move_pattern_id", "straight_1"))
	var enemy_type: String = String(enemy_snapshot.get("type", ""))
	var traits: Array = enemy_snapshot.get("traits", [])
	if enemy_type == "ninja" or traits.has("stealth_cycle"):
		return {
			"duration": 0.08,
			"scale": 0.94,
			"trans": Tween.TRANS_QUINT,
			"ease": Tween.EASE_OUT,
			"trail_width": 3.0,
			"trail_color": Color(0.56, 0.9, 1.0, 0.44),
			"blink": true,
		}
	if move_pattern_id == "straight_2" or enemy_type == "speeder":
		return {
			"duration": 0.09,
			"scale": 0.98,
			"trans": Tween.TRANS_QUART,
			"ease": Tween.EASE_OUT,
			"trail_width": 4.0,
			"trail_color": Color(1.0, 0.8, 0.44, 0.42),
		}
	if move_pattern_id == "hold_then_move" or move_pattern_id == "king_kong_launch" or int(enemy_snapshot.get("hp", 0)) >= 70 or String(enemy_snapshot.get("rank", "")) == "elite":
		return {
			"duration": 0.2,
			"scale": 1.06,
			"trans": Tween.TRANS_BACK,
			"ease": Tween.EASE_OUT,
			"trail_width": 5.0,
			"trail_color": Color(0.9, 0.76, 0.56, 0.34),
			"jump": true,
			"jump_height": 26.0,
		}
	if move_pattern_id == "side_shift" or move_pattern_id == "seek_crowd_1":
		return {
			"duration": 0.15,
			"scale": 1.0,
			"trans": Tween.TRANS_SINE,
			"ease": Tween.EASE_OUT,
			"trail_width": 4.0,
			"trail_color": Color(0.72, 0.9, 1.0, 0.34),
		}
	return {
		"duration": 0.13,
		"scale": 1.0,
		"trans": Tween.TRANS_SINE,
		"ease": Tween.EASE_OUT,
		"trail_width": 3.5,
		"trail_color": Color(0.92, 0.92, 0.96, 0.3),
	}


func play_enemy_dash_to_core(enemy_snapshot: Dictionary, lane_index: int, row_index: int) -> void:
	if effect_overlay == null:
		return
	if lane_index < 0 or lane_index >= owner.LANE_COUNT:
		return
	if row_index < owner.FIRST_BATTLE_ROW or row_index > owner.LAST_BATTLE_ROW:
		return
	var tile: Control = owner.board_tiles[lane_index][row_index]
	if tile == null:
		return

	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = tile.get_global_rect().position + tile.size * 0.5
	var end_global: Vector2 = owner.player_core_panel.get_global_rect().position + owner.player_core_panel.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var ghost: Control = ENEMY_SCENE.instantiate()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 960
	effect_overlay.add_child(ghost)
	ghost.call("set_enemy_data",
		String(enemy_snapshot.get("name", "Enemy")),
		int(enemy_snapshot.get("attack", 0)),
		int(enemy_snapshot.get("hp", 0)),
		int(enemy_snapshot.get("max_hp", enemy_snapshot.get("hp", 0))),
		String(enemy_snapshot.get("rank", "normal"))
	)
	if enemy_snapshot.has("color"):
		ghost.call("set_visual_color", Color(enemy_snapshot["color"]))
	ghost.call("set_icon_texture", enemy_snapshot.get("icon", null))

	var size := Vector2(82.0, 82.0)
	ghost.position = start_local - size * 0.5
	ghost.scale = Vector2(0.96, 0.96)

	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(1.0, 0.56, 0.72, 0.7)
	line.antialiased = true
	line.points = PackedVector2Array([start_local, end_local])
	effect_overlay.add_child(line)

	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "position", end_local - size * 0.5, 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost, "scale", Vector2(1.08, 1.08), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.06).set_delay(0.12)
	tween.finished.connect(ghost.queue_free)
	tween.finished.connect(line.queue_free)


func play_king_kong_throw(from_enemy: Dictionary, target_lane: int, target_row: int) -> void:
	if effect_overlay == null:
		return
	if target_lane < 0 or target_lane >= owner.LANE_COUNT:
		return
	if target_row < owner.FIRST_BATTLE_ROW or target_row > owner.LAST_BATTLE_ROW:
		return
	var source_lane: int = int(from_enemy.get("lane", -1))
	var source_row: int = int(from_enemy.get("row", -1))
	if source_lane < 0 or source_lane >= owner.LANE_COUNT:
		return
	if source_row < owner.FIRST_BATTLE_ROW or source_row > owner.LAST_BATTLE_ROW:
		return
	var from_tile: Control = owner.board_tiles[source_lane][source_row]
	var to_tile: Control = owner.board_tiles[target_lane][target_row]
	if from_tile == null or to_tile == null:
		return

	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_global: Vector2 = from_tile.get_global_rect().position + from_tile.size * 0.5
	var end_global: Vector2 = to_tile.get_global_rect().position + to_tile.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	var ghost: Control = ENEMY_SCENE.instantiate()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 960
	effect_overlay.add_child(ghost)
	ghost.call("set_enemy_data", "Kong Minion", 1, 10, 10, "special")
	ghost.call("set_visual_color", Color(0.78, 0.54, 0.32, 1.0))

	var size := Vector2(82.0, 82.0)
	ghost.position = start_local - size * 0.5
	ghost.scale = Vector2(0.72, 0.72)

	var arc := Line2D.new()
	arc.width = 4.0
	arc.default_color = Color(0.96, 0.74, 0.46, 0.42)
	arc.antialiased = true
	var arc_mid: Vector2 = start_local.lerp(end_local, 0.5) + Vector2(0, -42.0)
	arc.points = PackedVector2Array([start_local, arc_mid, end_local])
	effect_overlay.add_child(arc)

	var tween := owner.create_tween()
	tween.tween_property(ghost, "position", arc_mid - size * 0.5, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2(0.84, 0.84), 0.11)
	tween.tween_property(ghost, "position", end_local - size * 0.5, 0.11).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.76, 0.76), 0.11).set_delay(0.11)
	tween.tween_property(arc, "modulate:a", 0.0, 0.08)
	tween.parallel().tween_property(ghost, "modulate:a", 0.0, 0.06).set_delay(0.18)
	tween.finished.connect(ghost.queue_free)
	tween.finished.connect(arc.queue_free)


func play_rocket_boss_launch(from_enemy: Dictionary, target_lane: int, target_row: int, spawned_enemy_type: String) -> void:
	if effect_overlay == null:
		return
	if target_lane < 0 or target_lane >= owner.LANE_COUNT:
		return
	if target_row < owner.FIRST_BATTLE_ROW or target_row > owner.LAST_BATTLE_ROW:
		return
	var start_global: Vector2 = owner.board_renderer.get_enemy_visual_center_from_snapshot(from_enemy)
	if start_global == Vector2.ZERO:
		return
	var target_tile: Control = owner.board_tiles[target_lane][target_row]
	if target_tile == null:
		return
	var overlay_inverse: Transform2D = effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var end_global: Vector2 = target_tile.get_global_rect().position + target_tile.size * 0.5
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global
	var control_local: Vector2 = start_local.lerp(end_local, 0.45) + Vector2(0, -60.0)

	var enemy_def: Dictionary = ENEMY_CATALOG.get_enemy(spawned_enemy_type)
	var glow := Line2D.new()
	glow.width = 12.0
	glow.default_color = Color(1.0, 0.58, 0.24, 0.22)
	glow.antialiased = true
	glow.points = PackedVector2Array([start_local, control_local, end_local])
	effect_overlay.add_child(glow)

	var trail := Line2D.new()
	trail.width = 5.0
	trail.default_color = Color(1.0, 0.82, 0.38, 0.9)
	trail.antialiased = true
	trail.points = PackedVector2Array([start_local, control_local, end_local])
	effect_overlay.add_child(trail)

	var ghost: Control = ENEMY_SCENE.instantiate()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 962
	effect_overlay.add_child(ghost)
	ghost.call(
		"set_enemy_data",
		String(enemy_def.get("name", spawned_enemy_type)),
		int(enemy_def.get("attack", 0)),
		int(enemy_def.get("hp", 10)),
		int(enemy_def.get("hp", 10)),
		String(enemy_def.get("rank", "normal"))
	)
	ghost.call("set_visual_color", Color(enemy_def.get("color", Color(1.0, 0.82, 0.42, 1.0))))
	ghost.call("set_icon_texture", enemy_def.get("icon", null))
	var ghost_size := Vector2(82.0, 82.0)
	ghost.position = start_local - ghost_size * 0.5
	ghost.scale = Vector2(0.52, 0.52)

	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.96, 0.72, 0.0)
	flash.size = Vector2(36.0, 36.0)
	flash.position = start_local - flash.size * 0.5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_overlay.add_child(flash)

	var tween := owner.create_tween()
	tween.tween_property(flash, "color:a", 0.55, 0.04)
	tween.parallel().tween_property(ghost, "position", control_local - ghost_size * 0.5, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.64, 0.64), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "rotation", 0.3, 0.09)
	tween.tween_property(ghost, "position", end_local - ghost_size * 0.5, 0.11).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.8, 0.8), 0.11)
	tween.parallel().tween_property(ghost, "rotation", 0.0, 0.11)
	tween.parallel().tween_property(flash, "color:a", 0.0, 0.1)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.12)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.14)
	tween.parallel().tween_property(ghost, "modulate:a", 0.0, 0.06).set_delay(0.16)
	tween.finished.connect(ghost.queue_free)
	tween.finished.connect(trail.queue_free)
	tween.finished.connect(glow.queue_free)
	tween.finished.connect(flash.queue_free)


func play_tsunami_effect() -> void:
	if effect_overlay == null:
		return
	var overlay_rect := effect_overlay.get_global_rect()
	var start_x: float = 24.0
	var end_x: float = overlay_rect.size.x - 24.0
	var center_y: float = overlay_rect.size.y * 0.44

	var line := Line2D.new()
	line.width = 8.0
	line.default_color = Color(0.42, 0.82, 0.98, 0.95)
	line.antialiased = true
	effect_overlay.add_child(line)

	var glow := Line2D.new()
	glow.width = 16.0
	glow.default_color = Color(0.22, 0.5, 0.82, 0.28)
	glow.antialiased = true
	effect_overlay.add_child(glow)

	var points := PackedVector2Array()
	for step in range(16):
		var t: float = float(step) / 15.0
		var x: float = lerpf(start_x, end_x, t)
		var y: float = center_y + sin(t * TAU * 2.0) * 18.0
		points.append(Vector2(x, y))

	line.points = points
	glow.points = points
	line.modulate.a = 0.0
	glow.modulate.a = 0.0

	var tween := owner.create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(glow, "modulate:a", 1.0, 0.06)
	tween.tween_property(line, "position:x", 42.0, 0.12)
	tween.parallel().tween_property(glow, "position:x", 42.0, 0.12)
	tween.tween_property(line, "modulate:a", 0.0, 0.08)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.08)
	tween.finished.connect(line.queue_free)
	tween.finished.connect(glow.queue_free)


func play_combo_sequence(chain_targets: Array, base_damage: int, bonus_per_link: int) -> void:
	owner.call_deferred("_run_combo_sequence_via_vfx", chain_targets, base_damage, bonus_per_link)


func run_combo_sequence_async(chain_targets: Array, base_damage: int, bonus_per_link: int) -> void:
	for index in range(chain_targets.size()):
		var target_snapshot: Dictionary = chain_targets[index]
		if index > 0:
			var source_snapshot: Dictionary = chain_targets[index - 1]
			await play_combo_link_effect(source_snapshot, target_snapshot)
		else:
			await owner.get_tree().create_timer(0.04).timeout

		var live_target: Dictionary = owner._find_enemy_by_instance_id(int(target_snapshot.get("instance_id", -1)))
		if live_target.is_empty():
			continue
		owner._damage_enemy_from_card(live_target, base_damage + (bonus_per_link * index))


func play_combo_link_effect(source_snapshot: Dictionary, target_snapshot: Dictionary) -> Signal:
	if effect_overlay == null:
		return owner.get_tree().create_timer(0.01).timeout

	var start_global: Vector2 = owner.board_renderer.get_enemy_visual_center_from_snapshot(source_snapshot)
	var end_global: Vector2 = owner.board_renderer.get_enemy_visual_center_from_snapshot(target_snapshot)
	var overlay_inverse := effect_overlay.get_global_transform_with_canvas().affine_inverse()
	var start_local: Vector2 = overlay_inverse * start_global
	var end_local: Vector2 = overlay_inverse * end_global

	if start_local.distance_to(end_local) < 8.0:
		end_local += Vector2(18, -12)

	var midpoint: Vector2 = start_local.lerp(end_local, 0.5)
	var curve_offset: Vector2 = Vector2(0, -clampf(start_local.distance_to(end_local) * 0.12, 14.0, 36.0))
	var control: Vector2 = midpoint + curve_offset
	var points: PackedVector2Array = build_quadratic_points(start_local, control, end_local, 16)

	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(0.8, 0.48, 0.98, 0.98)
	line.antialiased = true
	line.points = PackedVector2Array([points[0], points[0]])
	effect_overlay.add_child(line)

	var glow := Line2D.new()
	glow.width = 9.0
	glow.default_color = Color(0.48, 0.18, 0.78, 0.35)
	glow.antialiased = true
	glow.points = PackedVector2Array([points[0], points[0]])
	effect_overlay.add_child(glow)

	var tween := owner.create_tween()
	for point in points:
		tween.tween_property(line, "points", PackedVector2Array([points[0], point]), 0.008)
		tween.parallel().tween_property(glow, "points", PackedVector2Array([points[0], point]), 0.008)
	tween.tween_property(line, "modulate:a", 0.0, 0.06)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.08)
	tween.finished.connect(line.queue_free)
	tween.finished.connect(glow.queue_free)
	return tween.finished


func build_quadratic_points(from: Vector2, control: Vector2, to: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var a: Vector2 = from.lerp(control, t)
		var b: Vector2 = control.lerp(to, t)
		points.append(a.lerp(b, t))
	return points
