extends Node2D
## Traffic and the presidential limousine. Origin = road contact point at the
## middle of the car; drawn facing +x and mirrored when driving left.

const L := preload("res://scripts/game/layout.gd")

enum Kind { SEDAN, HATCH, VAN, TAXI, LIMO }

const PAINTS := [Color("#e53935"), Color("#1e88e5"), Color("#fdd835"), Color("#43a047"), Color("#f5f5f5"),
	Color("#8e24aa"), Color("#fb8c00"), Color("#546e7a"), Color("#00897b")]

var kind := Kind.SEDAN
var dir := 1.0
var speed := 160.0
var length := 96.0
var paint := Color.RED
var wrecked := false
var snow := false
var stopped := false
var _wheel_rot := 0.0
var _t := 0.0


func setup(k: int, direction: float, rng: RandomNumberGenerator) -> void:
	kind = k
	dir = direction
	position.y = L.LANE_FAR_Y if dir > 0 else L.LANE_NEAR_Y
	match kind:
		Kind.SEDAN: length = 96.0
		Kind.HATCH: length = 78.0
		Kind.VAN: length = 104.0
		Kind.TAXI: length = 96.0
		Kind.LIMO: length = 250.0
	paint = PAINTS[rng.randi() % PAINTS.size()]
	if kind == Kind.TAXI:
		paint = Color("#ffc107")
	if kind == Kind.LIMO:
		paint = Color("#141518")
	speed = rng.randf_range(130, 220) if kind != Kind.LIMO else 190.0
	scale.x = dir


func hit_rect() -> Rect2:
	var h := 44.0 if kind == Kind.VAN else 36.0
	return Rect2(position.x - length * 0.5, position.y - h, length, h)


func _process(delta: float) -> void:
	_t += delta
	if not stopped and not wrecked:
		position.x += dir * speed * delta
		_wheel_rot += speed * delta / 8.0
	queue_redraw()


func _draw() -> void:
	var hl := length * 0.5
	var col := paint if not wrecked else Color("#1d1a18")
	# Shadow.
	draw_colored_polygon(_ellipse(Vector2(0, -1), Vector2(hl + 6, 5)), Color(0, 0, 0, 0.3))
	match kind:
		Kind.VAN:
			_body(PackedVector2Array([Vector2(-hl, -8), Vector2(-hl, -44), Vector2(hl * 0.55, -44), Vector2(hl - 2, -26),
				Vector2(hl, -20), Vector2(hl, -8)]), col)
			_glass(PackedVector2Array([Vector2(hl * 0.42, -40), Vector2(hl * 0.55, -40), Vector2(hl - 6, -26), Vector2(hl * 0.42, -26)]))
			_glass(PackedVector2Array([Vector2(-hl + 8, -40), Vector2(hl * 0.3, -40), Vector2(hl * 0.3, -28), Vector2(-hl + 8, -28)]))
			draw_rect(Rect2(-hl, -24, length, 3), col.darkened(0.25))
		Kind.LIMO:
			_body(PackedVector2Array([Vector2(-hl, -9), Vector2(-hl + 2, -24), Vector2(-hl * 0.7, -26), Vector2(-hl * 0.62, -40),
				Vector2(hl * 0.52, -40), Vector2(hl * 0.66, -27), Vector2(hl - 4, -24), Vector2(hl, -12), Vector2(hl, -9)]), col)
			if not wrecked:
				for k in 4:
					var x0 := -hl * 0.58 + k * hl * 0.29
					_glass(PackedVector2Array([Vector2(x0 + 4, -37), Vector2(x0 + hl * 0.27, -37), Vector2(x0 + hl * 0.27, -27), Vector2(x0 + 4, -27)]))
				_glass(PackedVector2Array([Vector2(hl * 0.6, -37), Vector2(hl * 0.62, -37), Vector2(hl * 0.66, -28), Vector2(hl * 0.55, -28)]))
				draw_line(Vector2(-hl + 2, -18), Vector2(hl - 2, -18), Color("#c0c6cc"), 1.5)
				_draw_flags(hl)
		_:
			var cab_front := hl * (0.3 if kind == Kind.HATCH else 0.22)
			var cab_back := -hl * (0.62 if kind == Kind.HATCH else 0.45)
			_body(PackedVector2Array([Vector2(-hl, -9), Vector2(-hl + 2, -24), Vector2(cab_back - 4, -25), Vector2(cab_back + 8, -39),
				Vector2(cab_front, -39), Vector2(cab_front + 14, -26), Vector2(hl - 3, -23), Vector2(hl, -12), Vector2(hl, -9)]), col)
			if not wrecked:
				var mid := (cab_back + cab_front) * 0.5
				_glass(PackedVector2Array([Vector2(cab_back + 9, -36), Vector2(mid - 2, -36), Vector2(mid - 2, -27), Vector2(cab_back + 3, -27)]))
				_glass(PackedVector2Array([Vector2(mid + 2, -36), Vector2(cab_front - 1, -36), Vector2(cab_front + 9, -27), Vector2(mid + 2, -27)]))
			if kind == Kind.TAXI:
				draw_rect(Rect2(mid_x(cab_back, cab_front) - 8, -45, 16, 6), Color("#212121"))
				draw_rect(Rect2(mid_x(cab_back, cab_front) - 6, -44, 12, 4), Color("#fff59d"))
				for k in 6:
					draw_rect(Rect2(-hl + 10 + k * 12, -18, 6, 3), Color("#212121"))
	if snow and not wrecked:
		_draw_roof_snow(hl)
	if not wrecked:
		draw_rect(Rect2(hl - 6, -21, 6, 5), Color("#fff9c4"))
		draw_rect(Rect2(-hl, -21, 4, 5), Color("#e53935"))
	draw_rect(Rect2(hl - 3, -12, 4, 4), Color("#9e9e9e"))
	draw_rect(Rect2(-hl - 1, -12, 4, 4), Color("#9e9e9e"))
	var wheel_x := hl * 0.62 if kind != Kind.LIMO else hl * 0.8
	for wx in [-wheel_x, wheel_x]:
		_wheel(Vector2(wx, -8))


func _draw_roof_snow(hl: float) -> void:
	var x0 := 0.0
	var x1 := 0.0
	var y := 0.0
	match kind:
		Kind.VAN:
			x0 = -hl
			x1 = hl * 0.55
			y = -44.0
		Kind.LIMO:
			x0 = -hl * 0.62
			x1 = hl * 0.52
			y = -40.0
		_:
			x0 = -hl * (0.62 if kind == Kind.HATCH else 0.45) + 8.0
			x1 = hl * (0.3 if kind == Kind.HATCH else 0.22)
			y = -39.0
	var white := Color("#f4f7fa")
	draw_rect(Rect2(x0, y - 4, x1 - x0, 4), white)
	draw_circle(Vector2(x0 + 2, y - 2), 2, white)
	draw_circle(Vector2(x1 - 2, y - 2), 2, white)
	# A little on the bonnet and boot too.
	draw_rect(Rect2(hl * 0.35, -26, hl * 0.55, 2), Color(white, 0.9))
	draw_rect(Rect2(-hl + 3, -27, hl * 0.3, 2), Color(white, 0.9))


func mid_x(a: float, b: float) -> float:
	return (a + b) * 0.5


func _body(pts: PackedVector2Array, col: Color) -> void:
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_colored_polygon(pts, col)
	# Lower body shading and a glossy highlight line.
	var hl := length * 0.5
	draw_rect(Rect2(-hl, -14, length, 5), col.darkened(0.25))
	draw_polyline(outline, col.darkened(0.45), 1.5, true)
	if not wrecked:
		draw_line(Vector2(-hl + 6, -23), Vector2(hl - 8, -22), Color(1, 1, 1, 0.35), 1.5)


func _glass(pts: PackedVector2Array) -> void:
	draw_colored_polygon(pts, Color("#9fd3f5") if kind != Kind.LIMO else Color("#2d3a46"))
	draw_line(pts[0] + Vector2(3, 1), pts[3] + Vector2(6, -1), Color(1, 1, 1, 0.4), 1.5)


func _wheel(c: Vector2) -> void:
	draw_circle(c, 8.5, Color("#1a1a1a"))
	draw_circle(c, 4.6, Color("#b0bec5") if not wrecked else Color("#3a3a3a"))
	for k in 3:
		var a := _wheel_rot + k * TAU / 3.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * 4.2, Color("#607d8b"), 1.5)


func _draw_flags(hl: float) -> void:
	for k in 2:
		var base := Vector2(hl - 22 - k * 10, -25)
		var top := base + Vector2(0, -22)
		draw_line(base, top, Color("#d7d7d7"), 1.5)
		var wave := sin(_t * 14.0 + k) * 2.0
		var fl := PackedVector2Array([top, top + Vector2(-16, wave), top + Vector2(-16, 10 + wave), top + Vector2(0, 10)])
		draw_colored_polygon(fl, Color("#1565c0"))
		draw_colored_polygon(PackedVector2Array([top + Vector2(0, 3.3), top + Vector2(-16, 3.3 + wave), top + Vector2(-16, 6.6 + wave), top + Vector2(0, 6.6)]), Color.WHITE)
		draw_circle(top + Vector2(-5, 1.6 + wave * 0.3), 1.2, Color("#ffd54f"))


func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
