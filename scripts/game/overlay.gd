extends Control
## Top-most in-game layer: round intro card, banners, damage effects, the
## "agent down" / "president down" moments and the pause menu.

const L := preload("res://scripts/game/layout.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

const CRACK_LIFE := 6.0

signal resume_pressed
signal quit_pressed

var game: Node
var _dmg := 0.0
var _cracks: Array = []           # [lines, age] screen cracks from hits
var _edge := [0.0, 0.0]           # left / right shot-direction glows
var _down := 0.0                  # agent-down fade
var _t := 0.0
var _rng := RandomNumberGenerator.new()

var _intro: PanelContainer
var _banner: Label
var _banner_tw: Tween
var _pause: Control
var _caption: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)
	_rng.randomize()

	_banner = UIKit.label("", 64, UIKit.GOLD, UIKit.title_font())
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.anchor_top = 0.3
	_banner.anchor_bottom = 0.3
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)

	_caption = UIKit.label("", 30, Color.WHITE, UIKit.title_font())
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.anchor_left = 0.1
	_caption.anchor_right = 0.9
	_caption.anchor_top = 0.42
	_caption.anchor_bottom = 0.42
	_caption.add_theme_constant_override("outline_size", 10)
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_caption.modulate.a = 0.0
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)

	_build_pause()


func _process(delta: float) -> void:
	_t += delta
	_dmg = maxf(0.0, _dmg - delta * 1.4)
	_edge[0] = maxf(0.0, _edge[0] - delta * 1.2)
	_edge[1] = maxf(0.0, _edge[1] - delta * 1.2)
	for c in _cracks:
		c[1] += delta
	_cracks = _cracks.filter(func(c): return c[1] < CRACK_LIFE)
	queue_redraw()


# ------------------------------------------------------------- effects ---
func damage(amount: int) -> void:
	_dmg = 1.0
	# A spiderweb crack across the scope glass for each hit.
	var c := Vector2(_rng.randf_range(0.15, 0.85) * size.x, _rng.randf_range(0.15, 0.75) * L.PLAY_H)
	var lines := PackedVector2Array()
	for k in 9 + amount / 5:
		var a := _rng.randf() * TAU
		var p := c
		for s in 4:
			var q := p + Vector2(cos(a), sin(a)) * _rng.randf_range(18, 46)
			lines.append(p)
			lines.append(q)
			p = q
			a += _rng.randf_range(-0.5, 0.5)
	for ring in 2:
		var rr := 14.0 + ring * 22.0
		var prev := c + Vector2(rr, 0)
		for k in range(1, 13):
			var a := k * TAU / 12.0
			var nxt := c + Vector2(cos(a), sin(a)) * rr * _rng.randf_range(0.8, 1.2)
			lines.append(prev)
			lines.append(nxt)
			prev = nxt
	_cracks.append([lines, 0.0])
	banner("HIT!  -%d%%" % amount, UIKit.RED, 0.9, 44)


func edge_flash(side: int) -> void:
	_edge[0 if side < 0 else 1] = 1.0


func agent_down() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_down", 1.0, 2.0)
	_show_caption("AGENT DOWN\nThe Bunnies got you, Frog.", UIKit.RED)


func president_down() -> void:
	get_tree().create_timer(1.2).timeout.connect(func():
		if is_inside_tree():
			_show_caption("THE PRESIDENT HAS BEEN ASSASSINATED", UIKit.RED))


func _show_caption(text: String, col: Color) -> void:
	_caption.text = text
	_caption.add_theme_color_override("font_color", col)
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.6)


func banner(text: String, col: Color, hold := 1.2, font_size := 64) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", col)
	_banner.add_theme_font_size_override("font_size", font_size)
	_banner.pivot_offset = _banner.size * 0.5
	if _banner_tw:
		_banner_tw.kill()
	_banner.scale = Vector2(1.4, 1.4)
	_banner.modulate.a = 1.0
	_banner_tw = create_tween()
	_banner_tw.tween_property(_banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tw.tween_interval(hold)
	_banner_tw.tween_property(_banner, "modulate:a", 0.0, 0.4)


func _draw() -> void:
	var w := size.x
	var h := L.PLAY_H
	# Red damage vignette, plus a slow pulse when health is low.
	var low := 0.0
	if game and game.health <= 25.0 and game.health > 0.0:
		low = 0.25 + 0.15 * sin(_t * 5.0)
	var a := clampf(_dmg * 0.55 + low, 0.0, 0.8)
	if a > 0.01:
		_vignette(Rect2(0, 0, w, h), Color(0.8, 0.0, 0.0, a), 120.0)
	for k in 2:
		if _edge[k] > 0.0:
			var x := 0.0 if k == 0 else w - 90.0
			var cin := Color(1.0, 0.5, 0.1, 0.0)
			var cout := Color(1.0, 0.5, 0.1, 0.55 * _edge[k])
			var c0 := cout if k == 0 else cin
			var c1 := cin if k == 0 else cout
			draw_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 90, 0), Vector2(x + 90, h), Vector2(x, h)]),
				PackedColorArray([c0, c1, c1, c0]))
	for c in _cracks:
		var fade := clampf((CRACK_LIFE - c[1]) / 2.0, 0.0, 1.0)
		draw_multiline(c[0], Color(0, 0, 0, 0.18 * fade), 3.0)
		draw_multiline(c[0], Color(1, 1, 1, 0.55 * fade), 1.4)
	if _down > 0.0:
		draw_rect(Rect2(0, 0, w, size.y), Color(0.35, 0.0, 0.0, _down * 0.75))


func _vignette(r: Rect2, c: Color, depth: float) -> void:
	var clear := Color(c, 0.0)
	var o := r.position
	var e := r.end
	var i0 := o + Vector2(depth, depth)
	var i1 := e - Vector2(depth, depth)
	var quads := [
		[Vector2(o.x, o.y), Vector2(e.x, o.y), Vector2(i1.x, i0.y), Vector2(i0.x, i0.y)],
		[Vector2(e.x, o.y), Vector2(e.x, e.y), Vector2(i1.x, i1.y), Vector2(i1.x, i0.y)],
		[Vector2(e.x, e.y), Vector2(o.x, e.y), Vector2(i0.x, i1.y), Vector2(i1.x, i1.y)],
		[Vector2(o.x, e.y), Vector2(o.x, o.y), Vector2(i0.x, i0.y), Vector2(i0.x, i1.y)],
	]
	for q in quads:
		draw_polygon(PackedVector2Array(q), PackedColorArray([c, c, clear, clear]))


# ---------------------------------------------------------- intro card ---
func show_intro(cfg: Dictionary) -> void:
	_intro = PanelContainer.new()
	_intro.add_theme_stylebox_override("panel", UIKit.panel_box(0.88))
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_intro.add_child(v)
	var title_text := "FINAL LEVEL %d" if GameState.is_last_round() else "LEVEL %d"
	var title := UIKit.label(title_text % (GameState.round_index + 1), 48, UIKit.GREEN, UIKit.title_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 60)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	var stormy: bool = cfg.weather == GameState.Weather.STORM
	var rows := [
		["Snipers detected", str(cfg.snipers)],
		["Bullets", str(GameState.BULLETS_PER_ROUND)],
		["Time", "%d seconds" % int(GameState.ROUND_TIME)],
		["Health", "%d%%" % GameState.health],
		["Weather", "STORMY" if stormy else "SUNNY"],
		["Sniper training", GameState.training_name(cfg.training).to_upper()],
	]
	if cfg.has("shot_interval"):
		rows.append(["Warning", "RAPID FIRE"])
	for r in rows:
		grid.add_child(UIKit.label(r[0], 22, UIKit.TEXT_DIM))
		var val := UIKit.label(r[1], 22, UIKit.GOLD, UIKit.title_font())
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(val)
	var hint := UIKit.label("Click / tap to begin", 16, Color(1, 1, 1, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	_center_intro.call_deferred()


func _center_intro() -> void:
	if _intro:
		_intro.reset_size()
		_intro.position = Vector2((size.x - _intro.size.x) * 0.5, (L.PLAY_H - _intro.size.y) * 0.45)


func hide_intro() -> void:
	if _intro:
		var p := _intro
		_intro = null
		var tw := create_tween()
		tw.tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)


# --------------------------------------------------------------- pause ---
func _build_pause() -> void:
	_pause = ColorRect.new()
	(_pause as ColorRect).color = Color(0, 0, 0, 0.6)
	UIKit.full_rect(_pause)
	_pause.visible = false
	_pause.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause)
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	_pause.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var t := UIKit.label("PAUSED", 48, UIKit.GREEN, UIKit.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var resume := UIKit.button("RESUME MISSION", 320)
	resume.pressed.connect(func(): resume_pressed.emit())
	v.add_child(resume)
	var quit := UIKit.button("ABORT TO HQ", 320)
	quit.pressed.connect(func(): quit_pressed.emit())
	v.add_child(quit)


func show_pause(p: bool) -> void:
	_pause.visible = p
	if p:
		var b: Button = _pause.find_children("*", "Button", true, false)[0]
		b.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if _pause.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		resume_pressed.emit()
