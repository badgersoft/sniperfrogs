extends Node2D
## Lightweight particle + floating-text system for the world: blood, glass,
## sparks, dust, smoke, fire, explosions, muzzle flashes and score pop-ups.
## One node draws everything so the cost is a single canvas item.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

enum P { BLOOD, GLASS, SPARK, DUST, SMOKE, FIRE, DEBRIS, FLASH }

const MAX_PARTICLES := 900

var _parts: Array = []
var _texts: Array = []
var _fires: Array = []     # continuous emitters: {pos, time, size}
var _rng := RandomNumberGenerator.new()
var _redraw_once := true   # one last clear after the final particle dies


func _ready() -> void:
	_rng.randomize()


func _spawn(kind: int, pos: Vector2, vel: Vector2, life: float, size_px: float, col: Color, gravity := 0.0) -> void:
	if _parts.size() >= MAX_PARTICLES:
		return
	_parts.append({"k": kind, "p": pos, "v": vel, "life": life, "max": life, "s": size_px, "c": col,
		"g": gravity, "rot": _rng.randf() * TAU, "spin": _rng.randf_range(-12, 12)})


func blood(pos: Vector2, amount := 26) -> void:
	for i in amount:
		var a := _rng.randf_range(-PI, 0.2)
		var sp := _rng.randf_range(30, 170)
		_spawn(P.BLOOD, pos, Vector2(cos(a), sin(a)) * sp, _rng.randf_range(0.5, 1.1), _rng.randf_range(1.2, 3.2),
			Color("#c0001f").lerp(Color("#7a0010"), _rng.randf()), 420.0)


func glass(pos: Vector2, amount := 22) -> void:
	for i in amount:
		var a := _rng.randf_range(-PI * 0.9, -PI * 0.1) + PI * (0.5 if _rng.randf() < 0.5 else 0.0)
		_spawn(P.GLASS, pos + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-12, 12)),
			Vector2(cos(a) * _rng.randf_range(20, 110), _rng.randf_range(-60, 40)), _rng.randf_range(0.8, 1.6),
			_rng.randf_range(1.5, 3.5), Color(0.8, 0.9, 1.0, 0.9), 520.0)


func sparks(pos: Vector2, amount := 10) -> void:
	for i in amount:
		var a := _rng.randf() * TAU
		_spawn(P.SPARK, pos, Vector2(cos(a), sin(a)) * _rng.randf_range(60, 200), _rng.randf_range(0.15, 0.35),
			1.5, Color("#ffe082"), 300.0)
	dust(pos, 5)


func dust(pos: Vector2, amount := 8) -> void:
	for i in amount:
		_spawn(P.DUST, pos, Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-40, -5)), _rng.randf_range(0.4, 0.9),
			_rng.randf_range(2, 5), Color(0.75, 0.7, 0.62, 0.8), -10.0)


func muzzle_flash(pos: Vector2, strength := 1.0) -> void:
	_spawn(P.FLASH, pos, Vector2.ZERO, 0.16, 16.0 * strength, Color(1.0, 0.9, 0.5, strength))


func explosion(pos: Vector2) -> void:
	_spawn(P.FLASH, pos + Vector2(0, -20), Vector2.ZERO, 0.45, 180.0, Color(1, 0.95, 0.7, 1))
	for i in 70:
		var a := _rng.randf_range(-PI, 0)
		var sp := _rng.randf_range(40, 260)
		_spawn(P.FIRE, pos + Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-30, 0)), Vector2(cos(a), sin(a)) * sp,
			_rng.randf_range(0.5, 1.3), _rng.randf_range(8, 22), Color("#ffb300"), -60.0)
	for i in 40:
		var a := _rng.randf_range(-PI, 0)
		_spawn(P.DEBRIS, pos + Vector2(0, -20), Vector2(cos(a), sin(a)) * _rng.randf_range(120, 420),
			_rng.randf_range(1.0, 2.2), _rng.randf_range(3, 7), Color("#222"), 600.0)
	for i in 40:
		_spawn(P.SMOKE, pos + Vector2(_rng.randf_range(-80, 80), _rng.randf_range(-40, 0)),
			Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-90, -30)), _rng.randf_range(1.5, 3.0),
			_rng.randf_range(14, 30), Color(0.15, 0.15, 0.15, 0.8), -20.0)
	_fires.append({"pos": pos, "time": 30.0, "size": 110.0})


func popup(pos: Vector2, text: String, col: Color, size_px := 22) -> void:
	_texts.append({"p": pos, "t": text, "c": col, "life": 1.6, "s": size_px})


func clear_all() -> void:
	_parts.clear()
	_texts.clear()
	_fires.clear()


func _process(delta: float) -> void:
	for f in _fires:
		f.time -= delta
		for n in 3:
			_spawn(P.FIRE, f.pos + Vector2(_rng.randf_range(-f.size * 0.5, f.size * 0.5), _rng.randf_range(-24, -4)),
				Vector2(_rng.randf_range(-15, 15), _rng.randf_range(-110, -50)), _rng.randf_range(0.4, 0.9),
				_rng.randf_range(9, 20), Color("#ffb300"), -40.0)
		if _rng.randf() < 0.4:
			_spawn(P.SMOKE, f.pos + Vector2(_rng.randf_range(-f.size * 0.4, f.size * 0.4), -40),
				Vector2(_rng.randf_range(-10, 20), _rng.randf_range(-70, -40)), _rng.randf_range(2.0, 3.5),
				_rng.randf_range(12, 22), Color(0.12, 0.12, 0.12, 0.7), -8.0)
	_fires = _fires.filter(func(f): return f.time > 0.0)

	var alive: Array = []
	for p in _parts:
		p.life -= delta
		if p.life <= 0.0:
			continue
		p.v.y += p.g * delta
		p.p += p.v * delta
		p.rot += p.spin * delta
		if p.k == P.SMOKE:
			p.s += delta * 14.0
			p.v *= 0.98
		alive.append(p)
	_parts = alive
	for t in _texts:
		t.life -= delta
		t.p.y -= 34.0 * delta
	_texts = _texts.filter(func(t): return t.life > 0.0)
	if not _parts.is_empty() or not _texts.is_empty() or not _fires.is_empty():
		queue_redraw()
	elif _redraw_once:
		_redraw_once = false
		queue_redraw()


func _draw() -> void:
	_redraw_once = not (_parts.is_empty() and _texts.is_empty())
	# Smoke first so fire and sparks sit on top.
	for p in _parts:
		if p.k == P.SMOKE:
			var a: float = p.life / p.max
			draw_circle(p.p, p.s, Color(p.c.r, p.c.g, p.c.b, p.c.a * a))
	for p in _parts:
		var t: float = p.life / p.max
		match p.k:
			P.BLOOD:
				draw_circle(p.p, p.s, p.c)
			P.GLASS:
				var d: Vector2 = Vector2(cos(p.rot), sin(p.rot)) * p.s
				draw_colored_polygon(PackedVector2Array([p.p - d, p.p + d.orthogonal() * 0.6, p.p + d]), Color(p.c, p.c.a * minf(1.0, t * 3.0)))
			P.SPARK:
				draw_line(p.p, p.p - p.v * 0.04, Color(p.c, t), 1.5)
			P.DUST:
				draw_circle(p.p, p.s * (1.5 - t * 0.5), Color(p.c, p.c.a * t))
			P.FIRE:
				var c := Color("#ffe14d").lerp(Color("#ff5a00"), 1.0 - t).lerp(Color("#c4160c"), maxf(0.0, 0.6 - t))
				draw_circle(p.p, p.s * (0.4 + t * 0.6), Color(c, minf(1.0, t * 1.6)))
			P.DEBRIS:
				var d: Vector2 = Vector2(cos(p.rot), sin(p.rot)) * p.s
				draw_line(p.p - d, p.p + d, p.c, 3.0)
			P.FLASH:
				draw_circle(p.p, p.s * (1.2 - t * 0.2), Color(p.c, p.c.a * t * 0.35))
				draw_circle(p.p, p.s * 0.55, Color(1, 1, 1, p.c.a * t))
				for k in 6:
					var a: float = k * TAU / 6.0 + p.rot
					draw_line(p.p, p.p + Vector2(cos(a), sin(a)) * p.s * 1.4, Color(p.c, p.c.a * t), 2.0)
	var font := UIKit.title_font()
	for tx in _texts:
		var a: float = clampf(tx.life / 0.5, 0.0, 1.0)
		var sz := font.get_string_size(tx.t, HORIZONTAL_ALIGNMENT_LEFT, -1, tx.s)
		var pos: Vector2 = tx.p - Vector2(sz.x * 0.5, 0)
		draw_string_outline(font, pos, tx.t, HORIZONTAL_ALIGNMENT_LEFT, -1, tx.s, 6, Color(0, 0, 0, a * 0.8))
		draw_string(font, pos, tx.t, HORIZONTAL_ALIGNMENT_LEFT, -1, tx.s, Color(tx.c, a))
