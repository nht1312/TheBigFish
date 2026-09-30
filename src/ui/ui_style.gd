class_name UiStyle
extends RefCounted
## Shared look for code-built UI: quiet, readable, not a dashboard (docs/18 §51–52).

const TEXT := Color(0.96, 0.95, 0.9)
const DIM := Color(0.75, 0.74, 0.7)
const THOUGHT := Color(1.0, 0.93, 0.72)
const NARRATION := Color(0.78, 0.84, 0.9)
const PANEL := Color(0.05, 0.06, 0.07, 0.72)
const SAFE := Color(0.45, 0.75, 0.45)
const NORMAL := Color(0.85, 0.8, 0.4)
const DANGER := Color(0.95, 0.55, 0.25)
const CRITICAL := Color(0.95, 0.25, 0.2)


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 5)
	t.set_stylebox("panel", "PanelContainer", panel_box())
	var normal := flat(Color(0.12, 0.13, 0.14, 0.9), 6)
	var hover := flat(Color(0.25, 0.26, 0.22, 0.95), 6)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), 6, Color(0.9, 0.85, 0.6)))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", THOUGHT)
	t.set_font_size("font_size", "Button", 20)
	return t


static func flat(color: Color, radius: int = 8, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(2)
	return s


static func panel_box() -> StyleBoxFlat:
	var s := flat(PANEL, 10)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s


static func label(text: String = "", size: int = 20, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func bar(fill: Color, width: float = 220.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, 12)
	b.show_percentage = false
	b.max_value = 100.0
	b.add_theme_stylebox_override("background", flat(Color(0, 0, 0, 0.55), 4))
	var f := flat(fill, 4)
	f.content_margin_top = 0
	f.content_margin_bottom = 0
	b.add_theme_stylebox_override("fill", f)
	return b


static func set_bar_color(b: ProgressBar, color: Color) -> void:
	var f: StyleBoxFlat = b.get_theme_stylebox("fill")
	f.bg_color = color
