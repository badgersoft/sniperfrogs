extends Node2D
## Pavement, kerb, road and street furniture. Static: drawn once.

const L := preload("res://scripts/game/layout.gd")

var storm := false
var _rng := RandomNumberGenerator.new()
var _seed := 0


func setup(is_storm: bool, seed_value: int) -> void:
	storm = is_storm
	_seed = seed_value


func _draw() -> void:
	_rng.seed = _seed
	var w := L.WORLD_W
	# Pavement.
	var pave := Color("#cfc8bb") if not storm else Color("#a9a49b")
	draw_rect(Rect2(-200, L.SIDEWALK_TOP, w + 400, L.SIDEWALK_BOTTOM - L.SIDEWALK_TOP), pave)
	draw_rect(Rect2(-200, L.SIDEWALK_TOP, w + 400, 4), pave.darkened(0.25))
	var x := -200.0
	while x < w + 200:
		draw_line(Vector2(x, L.SIDEWALK_TOP + 4), Vector2(x - 8, L.SIDEWALK_BOTTOM - 6), pave.darkened(0.12), 1.0)
		x += 44.0
	draw_line(Vector2(-200, L.SIDEWALK_TOP + 22), Vector2(w + 200, L.SIDEWALK_TOP + 22), pave.darkened(0.08), 1.0)
	# Kerb.
	draw_rect(Rect2(-200, L.SIDEWALK_BOTTOM - 6, w + 400, 6), Color("#e7e2d8") if not storm else Color("#b9b5ad"))
	draw_rect(Rect2(-200, L.SIDEWALK_BOTTOM - 1, w + 400, 2), Color(0, 0, 0, 0.25))
	# Road.
	var tar := Color("#44474d") if not storm else Color("#2f3236")
	draw_polygon(PackedVector2Array([Vector2(-200, L.ROAD_TOP), Vector2(w + 200, L.ROAD_TOP), Vector2(w + 200, L.ROAD_BOTTOM), Vector2(-200, L.ROAD_BOTTOM)]),
		PackedColorArray([tar.darkened(0.15), tar.darkened(0.15), tar, tar]))
	var mid := (L.LANE_FAR_Y + L.LANE_NEAR_Y) * 0.5 - 3.0
	x = -200.0
	while x < w + 200:
		draw_rect(Rect2(x, mid, 38, 4), Color("#f4f1e1"))
		x += 76.0
	# Drains and patches.
	for i in 30:
		var px := _rng.randf_range(0, w)
		draw_rect(Rect2(px, L.ROAD_TOP + 2, 22, 5), Color(0, 0, 0, 0.35))
	if storm:
		# Puddles reflecting the grey sky.
		for i in 26:
			var c := Vector2(_rng.randf_range(0, w), _rng.randf_range(L.ROAD_TOP + 8, L.ROAD_BOTTOM - 4))
			_ellipse(c, Vector2(_rng.randf_range(18, 40), _rng.randf_range(3, 5)), Color(0.6, 0.65, 0.75, 0.35))
	# Street furniture along the back of the pavement.
	x = 140.0
	while x < w:
		_draw_lamp(Vector2(x, L.SIDEWALK_TOP + 8))
		var extra := _rng.randi() % 4
		var ex := x + _rng.randf_range(90, 200)
		match extra:
			0: _draw_hydrant(Vector2(ex, L.SIDEWALK_TOP + 10))
			1: _draw_bin(Vector2(ex, L.SIDEWALK_TOP + 10))
			2: _draw_bench(Vector2(ex, L.SIDEWALK_TOP + 10))
		x += _rng.randf_range(380, 520)


func _draw_lamp(p: Vector2) -> void:
	var c := Color("#2f3a40")
	_ellipse(p + Vector2(0, 1), Vector2(7, 2), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p.x - 4, p.y - 6, 8, 6), c)
	draw_rect(Rect2(p.x - 1.5, p.y - 62, 3, 58), c)
	draw_line(p + Vector2(0, -60), p + Vector2(12, -64), c, 2.5)
	draw_rect(Rect2(p.x + 8, p.y - 66, 12, 5), c)
	draw_rect(Rect2(p.x + 9, p.y - 61, 10, 2), Color("#fff2b0") if storm else Color("#f7f3e0"))


func _draw_hydrant(p: Vector2) -> void:
	var c := Color("#d32f2f")
	draw_rect(Rect2(p.x - 4, p.y - 14, 8, 14), c)
	draw_rect(Rect2(p.x - 6, p.y - 10, 12, 3), c.darkened(0.2))
	draw_circle(p + Vector2(0, -14), 4, c)


func _draw_bin(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 6, p.y - 16, 12, 16), Color("#37474f"))
	draw_rect(Rect2(p.x - 7, p.y - 18, 14, 3), Color("#263238"))
	for k in 2:
		draw_line(Vector2(p.x - 3 + k * 6, p.y - 14), Vector2(p.x - 3 + k * 6, p.y - 2), Color(1, 1, 1, 0.15), 1)


func _draw_bench(p: Vector2) -> void:
	var wood := Color("#8d6e63")
	draw_rect(Rect2(p.x - 18, p.y - 10, 36, 3), wood)
	draw_rect(Rect2(p.x - 18, p.y - 18, 36, 3), wood)
	draw_rect(Rect2(p.x - 16, p.y - 10, 2, 10), Color("#333"))
	draw_rect(Rect2(p.x + 14, p.y - 10, 2, 10), Color("#333"))


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
