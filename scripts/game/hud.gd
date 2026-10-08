extends Control
## The static status board along the bottom 10% of the screen, plus the small
## on-screen widgets (round pill, mini-map, pause and touch FIRE buttons).

const L := preload("res://scripts/game/layout.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

var game: Node                # the game controller (read-only access)
var hit_flash := 0.0
var _t := 0.0
var _pill: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func _process(delta: float) -> void:
	_t += delta
	hit_flash = maxf(0.0, hit_flash - delta * 1.5)
	queue_redraw()


func fire_center() -> Vector2:
	return Vector2(size.x - 92, L.PLAY_H - 92)


func fire_radius() -> float:
	return 60.0


func pause_rect() -> Rect2:
	return Rect2(size.x - 64, 12, 50, 50)


func _draw() -> void:
	if game == null:
		return
	var w := size.x
	var y0 := L.PLAY_H
	var title := UIKit.title_font()
	var mono := UIKit.mono_font()
	# Board.
	var top := Color("#13221a")
	var bot := Color("#060b08")
	draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, L.VIEW_H + 4), Vector2(0, L.VIEW_H + 4)]),
		PackedColorArray([top, top, bot, bot]))
	draw_rect(Rect2(0, y0, w, 2), Color(UIKit.GREEN, 0.7))
	draw_rect(Rect2(0, y0 + 2, w, 3), Color(UIKit.GREEN, 0.12))
	if hit_flash > 0.0:
		draw_rect(Rect2(0, y0, w, L.HUD_H), Color(1, 0, 0, hit_flash * 0.35))

	var label_c := Color(UIKit.TEXT_DIM, 0.9)
	# --- Ammo
	draw_string(title, Vector2(16, y0 + 22), "AMMO  %d/%d" % [game.bullets, GameState.BULLETS_PER_ROUND],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, label_c)
	for i in GameState.BULLETS_PER_ROUND:
		_draw_cartridge(Vector2(18 + i * 13, y0 + 30), i < game.bullets)

	# --- Health
	var hx := maxf(232.0, w * 0.21)
	draw_string(title, Vector2(hx + 40, y0 + 22), "HEALTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, label_c)
	UIKit.draw_frog_head(self, Vector2(hx + 16, y0 + 44), 14, false)
	var bar := Rect2(hx + 40, y0 + 30, minf(190.0, w * 0.15), 22)
	draw_rect(bar.grow(2), Color(0, 0, 0, 0.6))
	var hp := clampf(game.health / 100.0, 0.0, 1.0)
	var hc := Color("#e53935").lerp(Color("#fdd835"), clampf(hp * 2.0, 0, 1)).lerp(Color("#66bb6a"), clampf(hp * 2.0 - 1.0, 0, 1))
	if hp <= 0.25 and fmod(_t, 0.6) < 0.3:
		hc = hc.lightened(0.4)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp, bar.size.y)), hc)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp, 6)), Color(1, 1, 1, 0.25))
	for k in range(1, 4):
		draw_line(bar.position + Vector2(bar.size.x * k / 4.0, 0), bar.position + Vector2(bar.size.x * k / 4.0, bar.size.y), Color(0, 0, 0, 0.4), 1)
	var hs := "%d%%" % int(game.health)
	draw_string_outline(title, bar.position + Vector2(8, 17), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.8))
	draw_string(title, bar.position + Vector2(8, 17), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# --- Time
	var secs := int(ceil(maxf(game.time_left, 0.0)))
	var ts := "%d:%02d" % [secs / 60, secs % 60]
	var tc := UIKit.TEXT
	var tsize := 38
	if secs <= 10 and game.time_left > 0.0:
		tc = UIKit.RED
		tsize = 38 + int(4.0 * maxf(0.0, sin(_t * TAU)))
	var tw := title.get_string_size(ts, HORIZONTAL_ALIGNMENT_LEFT, -1, tsize).x
	draw_string(title, Vector2(w * 0.5 - 22, y0 + 22), "TIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, label_c)
	draw_string(title, Vector2(w * 0.5 - tw * 0.5, y0 + 62), ts, HORIZONTAL_ALIGNMENT_LEFT, -1, tsize, tc)

	# --- Snipers
	var sx := w * 0.62
	draw_string(title, Vector2(sx, y0 + 22), "SNIPERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, label_c)
	for i in game.snipers_total:
		var c := Vector2(sx + 14 + i * 34, y0 + 46)
		_draw_bunny_icon(c, i < game.snipers_killed)

	# --- Score
	var sc := _fmt(GameState.score)
	var sw := title.get_string_size(sc, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
	var lw := title.get_string_size("SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(title, Vector2(w - 18 - lw, y0 + 22), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, label_c)
	draw_string(title, Vector2(w - 18 - sw, y0 + 60), sc, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UIKit.GOLD)

	# --- Round pill + weather (top-left)
	var stormy: bool = game.storm
	var pill := "LEVEL %d/%d   %s" % [GameState.round_index + 1, GameState.ROUNDS.size(), "STORM" if stormy else "CLEAR"]
	var pw := title.get_string_size(pill, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 50
	var pr := Rect2(12, 12, pw, 30)
	draw_style_box(_pill_box(), pr)
	_draw_weather_icon(Vector2(pr.end.x - 20, pr.position.y + 15), stormy)
	draw_string(title, Vector2(24, 33), pill, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UIKit.TEXT)

	# --- Mini-map of the 3-screen street.
	var mm := Rect2(w * 0.5 - 90, 16, 180, 10)
	draw_rect(mm, Color(0, 0, 0, 0.35))
	var view_frac: float = w / L.WORLD_W
	var left_frac: float = game.cam_left / L.WORLD_W
	draw_rect(Rect2(mm.position.x + mm.size.x * left_frac, mm.position.y - 2, mm.size.x * view_frac, mm.size.y + 4), Color(1, 1, 1, 0.55), false, 2)
	for b in game.bunnies:
		if not b.alive:
			draw_circle(Vector2(mm.position.x + mm.size.x * (b.position.x / L.WORLD_W), mm.get_center().y), 2.5, UIKit.RED)

	# --- Edge scroll hints.
	var pulse := 0.35 + 0.25 * sin(_t * 4.0)
	if game.cam_left > 4.0:
		_chevron(Vector2(14, L.PLAY_H * 0.5), -1.0, pulse)
	if game.cam_left < L.WORLD_W - w - 4.0:
		_chevron(Vector2(w - 14, L.PLAY_H * 0.5), 1.0, pulse)

	# --- Pause button.
	var p := pause_rect()
	draw_style_box(_pill_box(), p)
	draw_rect(Rect2(p.position + Vector2(17, 14), Vector2(5, 22)), UIKit.TEXT)
	draw_rect(Rect2(p.position + Vector2(28, 14), Vector2(5, 22)), UIKit.TEXT)

	# --- Touch FIRE button.
	if game.touch_mode:
		var fc := fire_center()
		var fr := fire_radius()
		var pressed: bool = game.fire_button_glow > 0.0
		draw_circle(fc, fr + 4, Color(0, 0, 0, 0.35))
		draw_circle(fc, fr, Color(0.75, 0.1, 0.1, 0.55 if not pressed else 0.85))
		draw_arc(fc, fr, 0, TAU, 48, Color(1, 1, 1, 0.6), 3, true)
		draw_arc(fc, fr * 0.45, 0, TAU, 32, Color(1, 1, 1, 0.8), 2, true)
		for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_line(fc + d * fr * 0.2, fc + d * fr * 0.7, Color(1, 1, 1, 0.8), 2)
		var fw := title.get_string_size("FIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(title, fc + Vector2(-fw * 0.5, fr + 22), "FIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8))


func _pill_box() -> StyleBoxFlat:
	if _pill == null:
		_pill = StyleBoxFlat.new()
		_pill.bg_color = Color(0.02, 0.05, 0.03, 0.6)
		_pill.border_color = Color(UIKit.GREEN, 0.5)
		_pill.set_border_width_all(1)
		_pill.set_corner_radius_all(15)
	return _pill


func _draw_cartridge(p: Vector2, live: bool) -> void:
	if live:
		draw_rect(Rect2(p + Vector2(0, 10), Vector2(9, 20)), Color("#c9a24a"))
		draw_rect(Rect2(p + Vector2(0, 10), Vector2(3, 20)), Color("#f2d27a"))
		draw_rect(Rect2(p + Vector2(1.5, 5), Vector2(6, 6)), Color("#b87333"))
		draw_circle(p + Vector2(4.5, 5), 3, Color("#b87333"))
		draw_rect(Rect2(p + Vector2(-0.5, 28), Vector2(10, 2)), Color("#8d6e2a"))
	else:
		draw_rect(Rect2(p + Vector2(0, 10), Vector2(9, 20)), Color(1, 1, 1, 0.12), false, 1)


func _draw_bunny_icon(c: Vector2, dead: bool) -> void:
	var fur := Color("#b0a597") if not dead else Color("#5a5550")
	draw_colored_polygon(_ellipse(c + Vector2(-4, -12), Vector2(3, 8)), fur)
	draw_colored_polygon(_ellipse(c + Vector2(4, -12), Vector2(3, 8)), fur)
	draw_circle(c, 9, fur)
	draw_rect(Rect2(c + Vector2(-7, -3), Vector2(14, 3)), Color("#111"))
	if dead:
		draw_line(c + Vector2(-12, -14), c + Vector2(12, 10), UIKit.RED, 3)
		draw_line(c + Vector2(12, -14), c + Vector2(-12, 10), UIKit.RED, 3)


func _draw_weather_icon(c: Vector2, stormy: bool) -> void:
	if not stormy:
		draw_circle(c, 6, Color("#ffd54f"))
		for k in 8:
			var a := k * TAU / 8.0 + _t
			draw_line(c + Vector2(cos(a), sin(a)) * 8, c + Vector2(cos(a), sin(a)) * 11, Color("#ffd54f"), 1.5)
	else:
		draw_circle(c + Vector2(-4, 0), 5, Color("#b0bec5"))
		draw_circle(c + Vector2(3, -2), 6, Color("#b0bec5"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, 2), c + Vector2(-3, 9), c + Vector2(0, 8), c + Vector2(-2, 14), c + Vector2(4, 6), c + Vector2(1, 6), c + Vector2(3, 2)]), Color("#ffeb3b"))


func _chevron(p: Vector2, d: float, a: float) -> void:
	var pts := PackedVector2Array([p + Vector2(-6 * d, -16), p + Vector2(6 * d, 0), p + Vector2(-6 * d, 16)])
	draw_polyline(pts, Color(1, 1, 1, a), 4, true)


func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
