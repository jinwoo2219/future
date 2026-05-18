extends Control
class_name EnemyUI

@export var enemy_name: String = "Enemy"
@export var attack: int = 1
@export var hp: int = 30
@export var max_hp: int = 30
@export var rank: String = "normal" # normal / elite / boss / totem
@export var is_targeted: bool = false
@export var status_icons: Array[String] = []
@export var accent_color: Color = Color(0.73, 0.42, 0.35, 1.0)
@export var plague_active: bool = false
@export var plague_damage: int = 0
@export var stealth_active: bool = false
@export var attached_active: bool = false
@export var shield_active: bool = false
@export var turn_counter: int = 0
@export var totem_active: bool = false
@export var totem_color: Color = Color.WHITE
@export var icon_texture: Texture2D

@onready var body_panel: Panel = $Body
@onready var icon_rect: TextureRect = $Body/Icon
@onready var attack_label: Label = $Body/AttackLabel
@onready var hp_label: Label = $Body/HpLabel
@onready var name_label: Label = $Body/NameLabel
@onready var rank_label: Label = $Body/RankLabel
@onready var target_ring: ColorRect = $TargetRing
@onready var target_frame: Panel = $TargetFrame
@onready var status_row: HBoxContainer = $StatusRow
var plague_label: Label
var stealth_label: Label
var attached_label: Label
var shield_label: Label
var turn_counter_label: Label
var boss_left_rect: ColorRect
var boss_right_rect: ColorRect
var totem_badge: Panel
var hp_bar_back: ColorRect
var hp_bar_fill: ColorRect
var hp_bar_label: Label
var idle_tween: Tween
var icon_base_position := Vector2.ZERO


func _ready() -> void:
	_ensure_boss_split_rects()
	_ensure_plague_label()
	_ensure_stealth_label()
	_ensure_attached_label()
	_ensure_shield_label()
	_ensure_turn_counter_label()
	_ensure_totem_badge()
	_ensure_hp_bar()
	update_ui()
	call_deferred("_start_idle_motion")


func update_ui() -> void:
	name_label.text = enemy_name
	attack_label.text = str(attack)
	hp_label.text = str(hp)
	rank_label.text = rank.to_upper()
	target_ring.visible = false
	target_frame.visible = is_targeted
	if icon_rect != null:
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
		icon_rect.rotation = 0.0

	var uses_sprite := icon_texture != null
	attack_label.visible = not uses_sprite
	hp_label.visible = not uses_sprite
	name_label.visible = not uses_sprite
	rank_label.visible = not uses_sprite
	if hp_bar_back != null:
		hp_bar_back.visible = uses_sprite
	if hp_bar_fill != null:
		hp_bar_fill.visible = uses_sprite
	if hp_bar_label != null:
		hp_bar_label.visible = uses_sprite

	body_panel.scale = Vector2.ONE

	_apply_body_style()
	_update_rank_style()
	_update_status_icons()
	_update_plague_label()
	_update_stealth_visuals()
	_update_attached_visuals()
	_update_shield_visuals()
	_update_turn_counter_visuals()
	_update_hp_bar()


func set_enemy_data(data_name: String, data_attack: int, data_hp: int, data_max_hp: int, data_rank: String) -> void:
	enemy_name = data_name
	attack = data_attack
	hp = data_hp
	max_hp = data_max_hp
	rank = data_rank
	if is_node_ready():
		update_ui()


func set_targeted(value: bool) -> void:
	if is_targeted == value:
		return
	is_targeted = value
	if is_node_ready():
		target_ring.visible = false
		target_frame.visible = is_targeted
		_update_rank_style()


func set_visual_color(value: Color) -> void:
	accent_color = value
	if is_node_ready():
		update_ui()


func set_icon_texture(value: Texture2D) -> void:
	icon_texture = value
	if is_node_ready():
		update_ui()
		call_deferred("_start_idle_motion")


func set_hp(value: int) -> void:
	hp = clamp(value, 0, max_hp)
	if is_node_ready():
		hp_label.text = str(hp)
		_update_hp_bar()


func set_statuses(new_statuses: Array[String]) -> void:
	status_icons = new_statuses
	if is_node_ready():
		_update_status_icons()


func set_plague_state(active: bool, damage_value: int) -> void:
	plague_active = active
	plague_damage = damage_value
	if is_node_ready():
		update_ui()


func set_stealth_state(active: bool) -> void:
	stealth_active = active
	if is_node_ready():
		update_ui()


func set_attached_state(active: bool) -> void:
	attached_active = active
	if is_node_ready():
		update_ui()


func set_shield_state(active: bool) -> void:
	shield_active = active
	if is_node_ready():
		update_ui()


func set_turn_counter(value: int) -> void:
	turn_counter = max(value, 0)
	if is_node_ready():
		update_ui()


func set_totem_state(active: bool, color: Color) -> void:
	totem_active = active
	totem_color = color
	if is_node_ready():
		update_ui()


func _update_rank_style() -> void:
	if icon_texture != null:
		body_panel.modulate = Color(1, 1, 1, 1)
		return
	match rank:
		"normal":
			body_panel.modulate = Color(1, 1, 1, 1)
		"elite":
			body_panel.modulate = Color(1.0, 0.93, 0.72, 1.0)
		"boss":
			body_panel.modulate = Color(1.0, 0.76, 0.72, 1.0)
		"totem":
			body_panel.modulate = Color(0.82, 1.0, 0.82, 1.0)
		_:
			body_panel.modulate = Color(1, 1, 1, 1)

	if is_targeted:
		body_panel.modulate = body_panel.modulate * Color(1.04, 1.04, 0.99, 1.0)


func _apply_body_style() -> void:
	var panel_style := body_panel.get_theme_stylebox("panel")
	if panel_style is StyleBoxFlat:
		var body_box: StyleBoxFlat = (panel_style as StyleBoxFlat).duplicate()
		if icon_texture != null:
			body_box.bg_color = Color(0, 0, 0, 0)
			body_box.border_width_left = 0
			body_box.border_width_top = 0
			body_box.border_width_right = 0
			body_box.border_width_bottom = 0
			body_box.shadow_size = 0
			_set_boss_split_visible(false)
			body_panel.add_theme_stylebox_override("panel", body_box)
			return
		if rank == "boss":
			body_box.bg_color = Color(0, 0, 0, 0)
			body_box.border_color = Color(0.58, 0.88, 1.0, 1.0) if stealth_active else (Color(0.75, 0.36, 0.96, 1.0) if plague_active else (totem_color.lightened(0.18) if totem_active else Color(0.94, 0.94, 0.94, 1.0)))
			if totem_active:
				body_box.shadow_color = Color(totem_color.r, totem_color.g, totem_color.b, 0.55)
				body_box.shadow_size = 6
			_set_boss_split_visible(true)
		else:
			body_box.bg_color = accent_color.darkened(0.28).lerp(Color(0.2, 0.26, 0.32, 1.0), 0.35) if stealth_active else (accent_color.lerp(totem_color, 0.16) if totem_active else accent_color)
			body_box.border_color = Color(0.58, 0.88, 1.0, 1.0) if stealth_active else (Color(0.75, 0.36, 0.96, 1.0) if plague_active else (totem_color.lightened(0.04) if totem_active else accent_color.lerp(Color(0.96, 0.94, 0.88, 1.0), 0.45)))
			if totem_active:
				body_box.shadow_color = Color(totem_color.r, totem_color.g, totem_color.b, 0.45)
				body_box.shadow_size = 5
			_set_boss_split_visible(false)
		body_panel.add_theme_stylebox_override("panel", body_box)


func _update_status_icons() -> void:
	for child in status_row.get_children():
		child.queue_free()

	for status_name in status_icons:
		var label := Label.new()
		label.text = status_name.substr(0, 1).to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(14, 14)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.88, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
		label.add_theme_constant_override("outline_size", 1)
		status_row.add_child(label)


func _ensure_plague_label() -> void:
	if plague_label != null:
		return
	plague_label = Label.new()
	plague_label.name = "PlagueLabel"
	plague_label.layout_mode = 1
	plague_label.offset_left = 3.0
	plague_label.offset_top = 12.0
	plague_label.offset_right = 24.0
	plague_label.offset_bottom = 24.0
	plague_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plague_label.add_theme_font_size_override("font_size", 11)
	plague_label.add_theme_color_override("font_color", Color(0.8, 0.42, 1.0, 1.0))
	plague_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
	plague_label.add_theme_constant_override("outline_size", 1)
	plague_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	plague_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_panel.add_child(plague_label)


func _ensure_stealth_label() -> void:
	if stealth_label != null:
		return
	stealth_label = Label.new()
	stealth_label.name = "StealthLabel"
	stealth_label.layout_mode = 1
	stealth_label.anchor_left = 0.0
	stealth_label.anchor_right = 1.0
	stealth_label.offset_left = 4.0
	stealth_label.offset_top = 2.0
	stealth_label.offset_right = -4.0
	stealth_label.offset_bottom = 14.0
	stealth_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stealth_label.text = "STEALTH"
	stealth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stealth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stealth_label.add_theme_font_size_override("font_size", 8)
	stealth_label.add_theme_color_override("font_color", Color(0.74, 0.94, 1.0, 1.0))
	stealth_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.08, 1.0))
	stealth_label.add_theme_constant_override("outline_size", 1)
	body_panel.add_child(stealth_label)


func _ensure_attached_label() -> void:
	if attached_label != null:
		return
	attached_label = Label.new()
	attached_label.name = "AttachedLabel"
	attached_label.layout_mode = 1
	attached_label.anchor_left = 0.0
	attached_label.anchor_right = 1.0
	attached_label.offset_left = 4.0
	attached_label.offset_top = 14.0
	attached_label.offset_right = -4.0
	attached_label.offset_bottom = 26.0
	attached_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attached_label.text = "LINK"
	attached_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attached_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	attached_label.add_theme_font_size_override("font_size", 8)
	attached_label.add_theme_color_override("font_color", Color(0.98, 0.9, 0.58, 1.0))
	attached_label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.08, 1.0))
	attached_label.add_theme_constant_override("outline_size", 1)
	body_panel.add_child(attached_label)


func _ensure_shield_label() -> void:
	if shield_label != null:
		return
	shield_label = Label.new()
	shield_label.name = "ShieldLabel"
	shield_label.layout_mode = 1
	shield_label.anchor_left = 0.0
	shield_label.anchor_right = 1.0
	shield_label.offset_left = 4.0
	shield_label.offset_top = 26.0
	shield_label.offset_right = -4.0
	shield_label.offset_bottom = 38.0
	shield_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_label.text = "SHIELD"
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shield_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shield_label.add_theme_font_size_override("font_size", 8)
	shield_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.62, 1.0))
	shield_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
	shield_label.add_theme_constant_override("outline_size", 1)
	body_panel.add_child(shield_label)


func _ensure_turn_counter_label() -> void:
	if turn_counter_label != null:
		return
	turn_counter_label = Label.new()
	turn_counter_label.name = "TurnCounterLabel"
	turn_counter_label.layout_mode = 1
	turn_counter_label.offset_left = 4.0
	turn_counter_label.offset_top = 14.0
	turn_counter_label.offset_right = 24.0
	turn_counter_label.offset_bottom = 30.0
	turn_counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turn_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	turn_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_counter_label.add_theme_font_size_override("font_size", 15)
	turn_counter_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48, 1.0))
	turn_counter_label.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.1, 1.0))
	turn_counter_label.add_theme_constant_override("outline_size", 1)
	body_panel.add_child(turn_counter_label)


func _ensure_totem_badge() -> void:
	if totem_badge != null:
		return
	totem_badge = Panel.new()
	totem_badge.name = "TotemBadge"
	totem_badge.visible = false
	totem_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	totem_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	totem_badge.offset_left = -16
	totem_badge.offset_top = 3
	totem_badge.offset_right = -4
	totem_badge.offset_bottom = 15
	body_panel.add_child(totem_badge)


func _ensure_hp_bar() -> void:
	if hp_bar_back != null and hp_bar_fill != null and hp_bar_label != null:
		return
	hp_bar_back = ColorRect.new()
	hp_bar_back.name = "HpBarBack"
	hp_bar_back.visible = false
	hp_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_back.anchor_left = 0.5
	hp_bar_back.anchor_top = 1.0
	hp_bar_back.anchor_right = 0.5
	hp_bar_back.anchor_bottom = 1.0
	hp_bar_back.offset_left = -28.0
	hp_bar_back.offset_top = -16.0
	hp_bar_back.offset_right = 28.0
	hp_bar_back.offset_bottom = -8.0
	hp_bar_back.color = Color(0.06, 0.07, 0.08, 0.9)
	add_child(hp_bar_back)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.name = "HpBarFill"
	hp_bar_fill.visible = false
	hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_fill.anchor_left = 0.5
	hp_bar_fill.anchor_top = 1.0
	hp_bar_fill.anchor_right = 0.5
	hp_bar_fill.anchor_bottom = 1.0
	hp_bar_fill.offset_left = -25.0
	hp_bar_fill.offset_top = -13.0
	hp_bar_fill.offset_right = 25.0
	hp_bar_fill.offset_bottom = -11.0
	hp_bar_fill.color = Color(0.28, 0.92, 0.42, 1.0)
	add_child(hp_bar_fill)

	hp_bar_label = Label.new()
	hp_bar_label.name = "HpBarLabel"
	hp_bar_label.visible = false
	hp_bar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_label.anchor_left = 0.5
	hp_bar_label.anchor_top = 1.0
	hp_bar_label.anchor_right = 0.5
	hp_bar_label.anchor_bottom = 1.0
	hp_bar_label.offset_left = -34.0
	hp_bar_label.offset_top = -28.0
	hp_bar_label.offset_right = 34.0
	hp_bar_label.offset_bottom = -13.0
	hp_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_bar_label.add_theme_font_size_override("font_size", 10)
	hp_bar_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	hp_bar_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.05, 1.0))
	hp_bar_label.add_theme_constant_override("outline_size", 2)
	add_child(hp_bar_label)


func _update_hp_bar() -> void:
	if hp_bar_fill == null:
		return
	var ratio := 0.0
	if max_hp > 0:
		ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	hp_bar_fill.offset_right = -25.0 + 50.0 * ratio
	if hp_bar_label != null:
		hp_bar_label.text = "%d/%d" % [hp, max_hp]
	if ratio <= 0.25:
		hp_bar_fill.color = Color(0.96, 0.22, 0.2, 1.0)
	elif ratio <= 0.55:
		hp_bar_fill.color = Color(0.95, 0.74, 0.24, 1.0)
	else:
		hp_bar_fill.color = Color(0.28, 0.92, 0.42, 1.0)


func _ensure_boss_split_rects() -> void:
	if boss_left_rect != null and boss_right_rect != null:
		return
	boss_left_rect = ColorRect.new()
	boss_left_rect.name = "BossLeftRect"
	boss_left_rect.layout_mode = 1
	boss_left_rect.anchor_right = 0.5
	boss_left_rect.anchor_bottom = 1.0
	boss_left_rect.offset_left = 2.0
	boss_left_rect.offset_top = 2.0
	boss_left_rect.offset_right = -1.0
	boss_left_rect.offset_bottom = -2.0
	boss_left_rect.color = Color(0.96, 0.96, 0.96, 1.0)
	boss_left_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_panel.add_child(boss_left_rect)
	body_panel.move_child(boss_left_rect, 0)

	boss_right_rect = ColorRect.new()
	boss_right_rect.name = "BossRightRect"
	boss_right_rect.layout_mode = 1
	boss_right_rect.anchor_left = 0.5
	boss_right_rect.anchor_right = 1.0
	boss_right_rect.anchor_bottom = 1.0
	boss_right_rect.offset_left = 1.0
	boss_right_rect.offset_top = 2.0
	boss_right_rect.offset_right = -2.0
	boss_right_rect.offset_bottom = -2.0
	boss_right_rect.color = Color(0.08, 0.08, 0.08, 1.0)
	boss_right_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_panel.add_child(boss_right_rect)
	body_panel.move_child(boss_right_rect, 1)

	_set_boss_split_visible(false)


func _set_boss_split_visible(visible: bool) -> void:
	if boss_left_rect != null:
		boss_left_rect.visible = visible
	if boss_right_rect != null:
		boss_right_rect.visible = visible


func _update_plague_label() -> void:
	if plague_label == null:
		return
	plague_label.visible = plague_active and plague_damage > 0
	plague_label.text = str(plague_damage)


func _update_stealth_visuals() -> void:
	if stealth_label != null:
		stealth_label.visible = stealth_active
	var dim_color := Color(0.76, 0.8, 0.84, 0.92) if stealth_active else Color(1.0, 1.0, 1.0, 1.0)
	name_label.modulate = dim_color
	attack_label.modulate = dim_color
	hp_label.modulate = dim_color
	rank_label.modulate = dim_color


func _update_attached_visuals() -> void:
	if attached_label != null:
		attached_label.visible = attached_active


func _update_shield_visuals() -> void:
	if shield_label != null:
		shield_label.visible = shield_active
	if not shield_active:
		return
	var panel_style := body_panel.get_theme_stylebox("panel")
	if panel_style is StyleBoxFlat:
		var body_box: StyleBoxFlat = (panel_style as StyleBoxFlat).duplicate()
		body_box.border_color = Color(1.0, 0.9, 0.46, 1.0)
		body_panel.add_theme_stylebox_override("panel", body_box)


func _update_turn_counter_visuals() -> void:
	if turn_counter_label == null:
		return
	turn_counter_label.visible = turn_counter > 0
	turn_counter_label.text = str(turn_counter)
	if totem_badge != null:
		totem_badge.visible = totem_active
		if totem_active:
			var badge_style := StyleBoxFlat.new()
			badge_style.bg_color = totem_color
			badge_style.border_color = Color(0.98, 0.98, 0.94, 0.98)
			badge_style.border_width_left = 2
			badge_style.border_width_top = 2
			badge_style.border_width_right = 2
			badge_style.border_width_bottom = 2
			badge_style.corner_radius_top_left = 999
			badge_style.corner_radius_top_right = 999
			badge_style.corner_radius_bottom_left = 999
			badge_style.corner_radius_bottom_right = 999
			totem_badge.add_theme_stylebox_override("panel", badge_style)


func _start_idle_motion() -> void:
	if icon_rect == null:
		return
	if idle_tween != null:
		idle_tween.kill()
		idle_tween = null
	icon_rect.rotation = 0.0
	icon_rect.scale = Vector2.ONE
	if icon_texture == null:
		return

	icon_base_position = icon_rect.position
	icon_rect.pivot_offset = icon_rect.size * 0.5
	var seed_offset := float(get_instance_id() % 9) * 0.07
	icon_rect.position = icon_base_position
	idle_tween = create_tween()
	idle_tween.set_loops()
	idle_tween.tween_interval(seed_offset)
	idle_tween.tween_property(icon_rect, "position:y", icon_base_position.y - 2.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property(icon_rect, "scale", Vector2(1.03, 0.97), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(icon_rect, "position:y", icon_base_position.y, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property(icon_rect, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
