extends RefCounted
## Shared look & feel: theme, fonts, colours and small widget factories.

const GREEN := Color("#7ddc5a")
const GREEN_DARK := Color("#2f6b2a")
const GOLD := Color("#ffcc4d")
const RED := Color("#ff4d4d")
const INK := Color("#0b1410")
const PANEL := Color(0.04, 0.08, 0.06, 0.82)
const TEXT := Color("#e9f2e4")
const TEXT_DIM := Color("#9fb39a")
const TERMINAL := Color("#39ff7a")

static var _theme: Theme
static var _title_font: Font
static var _mono_font: Font
static var _body_font: Font


static func title_font() -> Font:
	if _title_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Montserrat", "Arial Black", "Impact", "Helvetica Neue", "Roboto", "DejaVu Sans", "sans-serif"])
		f.font_weight = 900
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_title_font = f
	return _title_font


static func body_font() -> Font:
	if _body_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Inter", "Segoe UI", "Helvetica Neue", "Roboto", "Noto Sans", "DejaVu Sans", "sans-serif"])
		f.font_weight = 600
		_body_font = f
	return _body_font


static func mono_font() -> Font:
	if _mono_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["JetBrains Mono", "Consolas", "DejaVu Sans Mono", "Menlo", "Courier New", "Droid Sans Mono", "monospace"])
		f.font_weight = 500
		_mono_font = f
	return _mono_font


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 22

	var normal := _box(Color(0.07, 0.16, 0.10, 0.92), GREEN.darkened(0.25))
	var hover := _box(Color(0.12, 0.28, 0.15, 0.96), GREEN)
	var pressed := _box(Color(0.20, 0.42, 0.20, 1.0), GOLD)
	var disabled := _box(Color(0.1, 0.1, 0.1, 0.6), Color(0.3, 0.3, 0.3))
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD, 2))
	t.set_stylebox("disabled", "Button", disabled)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_font("font", "Button", title_font())
	t.set_font_size("font_size", "Button", 24)

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)

	var le := _box(Color(0.02, 0.05, 0.03, 0.95), GREEN, 2)
	le.content_margin_left = 14
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", _box(Color(0.02, 0.05, 0.03, 0.95), GOLD, 2))
	t.set_color("font_color", "LineEdit", Color.WHITE)
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_font_size("font_size", "LineEdit", 26)

	t.set_stylebox("panel", "PanelContainer", panel_box())
	_theme = t
	return t


static func _box(bg: Color, border: Color, bw := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(12)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 6
	s.anti_aliasing = true
	return s


static func panel_box(alpha := 0.82) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(PANEL.r, PANEL.g, PANEL.b, alpha)
	s.border_color = Color(GREEN.r, GREEN.g, GREEN.b, 0.45)
	s.set_border_width_all(2)
	s.set_corner_radius_all(18)
	s.set_content_margin_all(24)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 18
	return s


static func label(text: String, size := 22, color := TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	return l


static func button(text: String, min_width := 300) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 64)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_entered.connect(func(): Sfx.play("tick", -14.0))
	b.pressed.connect(func(): Sfx.play("beep", -8.0))
	return b


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Draws a cartoon frog head (used for the logo, lives and the HUD).
static func draw_frog_head(ci: CanvasItem, center: Vector2, r: float, beret := true) -> void:
	var skin := Color("#5cbf3c")
	var dark := Color("#2e7a22")
	ci.draw_circle(center + Vector2(0, r * 0.15), r, dark)
	ci.draw_circle(center + Vector2(0, r * 0.1), r * 0.94, skin)
	for sx in [-1.0, 1.0]:
		var e := center + Vector2(sx * r * 0.52, -r * 0.62)
		ci.draw_circle(e, r * 0.42, dark)
		ci.draw_circle(e, r * 0.38, skin)
		ci.draw_circle(e, r * 0.27, Color.WHITE)
		ci.draw_circle(e + Vector2(sx * r * 0.03, r * 0.04), r * 0.13, INK)
		ci.draw_circle(e + Vector2(sx * r * 0.0 - r * 0.05, -r * 0.05), r * 0.05, Color.WHITE)
	# Mask band across the eyes - every secret agent needs one.
	ci.draw_rect(Rect2(center + Vector2(-r * 1.0, -r * 0.7), Vector2(r * 2.0, r * 0.16)), Color(0.08, 0.08, 0.1, 0.9))
	ci.draw_arc(center + Vector2(0, r * 0.15), r * 0.55, 0.35, PI - 0.35, 18, dark, maxf(2.0, r * 0.08), true)
	ci.draw_circle(center + Vector2(-r * 0.6, r * 0.25), r * 0.13, Color(1.0, 0.5, 0.5, 0.35))
	ci.draw_circle(center + Vector2(r * 0.6, r * 0.25), r * 0.13, Color(1.0, 0.5, 0.5, 0.35))
	if beret:
		var bc := center + Vector2(-r * 0.15, -r * 1.02)
		var pts := PackedVector2Array()
		for i in 21:
			var a := PI + PI * float(i) / 20.0
			pts.append(bc + Vector2(cos(a) * r * 0.85, sin(a) * r * 0.38))
		ci.draw_colored_polygon(pts, Color("#2b2b33"))
		ci.draw_circle(bc + Vector2(0, -r * 0.38), r * 0.08, Color("#2b2b33"))
		ci.draw_line(bc + Vector2(-r * 0.85, 0), bc + Vector2(r * 0.85, 0), Color("#c62828"), maxf(2.0, r * 0.1))
