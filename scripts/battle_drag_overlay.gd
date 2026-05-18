extends Control

const CARD_FONT_PATH := "res://fonts/Galmuri11.ttf"
const CARD_TEXT_COLOR := Color(0.239216, 0.145098, 0.231373, 1.0)
const CARD_TEXT_OUTLINE_COLOR := Color(0.12, 0.07, 0.11, 1.0)

var active := false
var valid := false
var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var text_mode := false
var display_text := ""
var drag_chip: PanelContainer
var drag_label: Label
var drag_preview: Control
var drag_preview_texture: TextureRect
var drag_preview_label: Label


func _ready() -> void:
	drag_chip = PanelContainer.new()
	drag_chip.visible = false
	drag_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_chip.custom_minimum_size = Vector2(116, 42)
	add_child(drag_chip)

	var chip_margin := MarginContainer.new()
	chip_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_margin.add_theme_constant_override("margin_left", 10)
	chip_margin.add_theme_constant_override("margin_top", 6)
	chip_margin.add_theme_constant_override("margin_right", 10)
	chip_margin.add_theme_constant_override("margin_bottom", 6)
	chip_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_chip.add_child(chip_margin)

	drag_label = Label.new()
	drag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_label.add_theme_font_size_override("font_size", 16)
	drag_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.88, 1.0))
	drag_label.add_theme_color_override("font_outline_color", Color(0.07, 0.08, 0.1, 1.0))
	drag_label.add_theme_constant_override("outline_size", 2)
	chip_margin.add_child(drag_label)

	drag_preview = Control.new()
	drag_preview.visible = false
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.custom_minimum_size = Vector2(148, 44)
	add_child(drag_preview)

	drag_preview_texture = TextureRect.new()
	drag_preview_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag_preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview_texture.stretch_mode = TextureRect.STRETCH_SCALE
	drag_preview_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	drag_preview.add_child(drag_preview_texture)

	drag_preview_label = Label.new()
	drag_preview_label.position = Vector2(12, 10)
	drag_preview_label.size = Vector2(110, 20)
	drag_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview_label.clip_text = true
	drag_preview_label.add_theme_font_override("font", load(CARD_FONT_PATH))
	drag_preview_label.add_theme_font_size_override("font_size", 16)
	drag_preview_label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	drag_preview_label.add_theme_color_override("font_outline_color", CARD_TEXT_OUTLINE_COLOR)
	drag_preview_label.add_theme_constant_override("outline_size", 2)
	drag_preview.add_child(drag_preview_label)


func set_drag_points(new_start: Vector2, new_end: Vector2, is_active: bool, is_valid: bool, use_text_mode: bool = false, new_text: String = "", fill_color: Color = Color(0.18, 0.18, 0.18, 0.96), border_color: Color = Color(0.68, 0.86, 0.5, 0.9), preview_texture: Texture2D = null) -> void:
	start_point = new_start
	end_point = new_end
	active = is_active
	valid = is_valid
	text_mode = use_text_mode
	display_text = new_text
	if drag_chip != null and drag_label != null:
		var use_preview := active and text_mode and preview_texture != null
		drag_chip.visible = active and text_mode and not use_preview
		drag_label.text = display_text
		var chip_width: float = clamp(42.0 + drag_label.get_theme_font("font").get_string_size(display_text, HORIZONTAL_ALIGNMENT_CENTER, -1, drag_label.get_theme_font_size("font_size")).x, 116.0, 220.0)
		drag_chip.custom_minimum_size = Vector2(chip_width, 42)
		drag_chip.position = end_point + Vector2(18, -18)
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = fill_color if valid else fill_color.darkened(0.45)
		chip_style.border_color = border_color if valid else border_color.darkened(0.35)
		chip_style.border_width_left = 2
		chip_style.border_width_top = 2
		chip_style.border_width_right = 2
		chip_style.border_width_bottom = 2
		chip_style.corner_radius_top_left = 8
		chip_style.corner_radius_top_right = 8
		chip_style.corner_radius_bottom_left = 8
		chip_style.corner_radius_bottom_right = 8
		drag_chip.add_theme_stylebox_override("panel", chip_style)
		if drag_preview != null and drag_preview_texture != null and drag_preview_label != null:
			drag_preview.visible = use_preview
			var preview_width: float = clamp(52.0 + drag_preview_label.get_theme_font("font").get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, drag_preview_label.get_theme_font_size("font_size")).x, 148.0, 260.0)
			drag_preview.custom_minimum_size = Vector2(preview_width, 44)
			drag_preview.position = end_point + Vector2(18, -18)
			drag_preview_texture.texture = preview_texture
			drag_preview_texture.modulate = Color(1, 1, 1, 0.96) if valid else Color(0.6, 0.6, 0.6, 0.96)
			drag_preview_label.text = display_text
			drag_preview_label.size = Vector2(preview_width - 24.0, 20)
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	if text_mode:
		return

	var color := Color(0.95, 0.86, 0.45, 0.95) if valid else Color(0.55, 0.58, 0.5, 0.7)
	var shadow := Color(0.05, 0.06, 0.05, 0.6)
	var delta := end_point - start_point
	if delta.length() < 0.01:
		return

	var midpoint := start_point.lerp(end_point, 0.5)
	var curve_offset := Vector2(0, -clamp(delta.length() * 0.12, 20.0, 52.0))
	var control := midpoint + curve_offset
	var points := _build_quadratic_points(start_point, control, end_point, 18)
	var shadow_points := PackedVector2Array()
	for point in points:
		shadow_points.append(point + Vector2(2, 2))

	draw_polyline(shadow_points, shadow, 7.0, true)
	draw_polyline(points, color, 5.5, true)
	draw_circle(start_point, 6.0, color)

	var direction := (end_point - points[points.size() - 2]).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var arrow_tip := end_point
	var arrow_left := end_point - direction * 22.0 + perpendicular * 11.0
	var arrow_right := end_point - direction * 22.0 - perpendicular * 11.0
	draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_left, arrow_right]), color)


func _build_quadratic_points(from: Vector2, control: Vector2, to: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := from.lerp(control, t)
		var b := control.lerp(to, t)
		points.append(a.lerp(b, t))
	return points
