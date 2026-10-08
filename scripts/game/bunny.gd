extends Node2D
## A Bunny sniper hiding behind a window. This node lives on the scope-only
## visibility layer, so it is invisible in the main view and appears only
## through the magnifying scope. Origin = top-left of the window.

const L := preload("res://scripts/game/layout.gd")
const Building := preload("res://scripts/game/building.gd")

const FURS := [Color("#9e9488"), Color("#b08d6e"), Color("#d9d4cc"), Color("#7a6f66")]

var building: Node2D
var window_index := -1
var alive := true
var training := 0
var shot_timer := 10.0
var aiming := false
var flash := 0.0
var fur := Color.GRAY
var _t := 0.0


func setup(b: Node2D, idx: int, train: int, rng: RandomNumberGenerator) -> void:
	building = b
	window_index = idx
	training = train
	visibility_layer = L.LAYER_SCOPE_ONLY
	position = b.window_world_rect(idx).position
	fur = FURS[rng.randi() % FURS.size()]
	_t = rng.randf() * 10.0


func world_rect() -> Rect2:
	return Rect2(position, Vector2(L.WIN_W, L.WIN_H))


func _process(delta: float) -> void:
	_t += delta
	flash = maxf(0.0, flash - delta * 6.0)
	queue_redraw()


func _draw() -> void:
	var w := L.WIN_W
	var h := L.WIN_H
	var r := Rect2(0, 0, w, h)
	# Dark room interior.
	var top := Color("#2d2638")
	var bot := Color("#120f17")
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bot, bot]))
	draw_rect(Rect2(3, 4, 7, 9), Color(0.35, 0.3, 0.4, 0.5))   # picture on back wall
	var bob := sin(_t * 2.2) * 0.6
	var hc := Vector2(14, 18 + bob)
	var inner := Color("#f2a7b4")
	var dark := fur.darkened(0.35)
	# Shoulders / body.
	var clip := PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
	for poly in Geometry2D.intersect_polygons(_ellipse(Vector2(14, 33 + bob), Vector2(12, 8)), clip):
		draw_colored_polygon(poly, dark)
	for poly in Geometry2D.intersect_polygons(_ellipse(Vector2(14, 32 + bob), Vector2(11, 7)), clip):
		draw_colored_polygon(poly, fur)
	# Ears (one bent - McWhurter's crew are a scruffy lot).
	draw_colored_polygon(_ellipse(hc + Vector2(-4, -10), Vector2(2.8, 8.5), 0.18), dark)
	draw_colored_polygon(_ellipse(hc + Vector2(-4, -10), Vector2(1.3, 6.5), 0.18), inner)
	draw_colored_polygon(_ellipse(hc + Vector2(5, -9), Vector2(2.8, 8.0), -0.5), dark)
	draw_colored_polygon(_ellipse(hc + Vector2(5, -9), Vector2(1.3, 6.0), -0.5), inner)
	# Head.
	draw_circle(hc, 7.2, dark)
	draw_circle(hc + Vector2(0, -0.3), 6.6, fur)
	draw_circle(hc + Vector2(0, 3), 3.6, fur.lightened(0.35))
	if training == 2:
		# Elite: black beret.
		draw_colored_polygon(_ellipse(hc + Vector2(-1, -6), Vector2(6.5, 2.4)), Color("#1a1a1a"))
	# Shades.
	draw_rect(Rect2(hc + Vector2(-6.2, -2.6), Vector2(12.4, 1.2)), Color("#101010"))
	draw_circle(hc + Vector2(-3, -1), 2.4, Color("#101010"))
	draw_circle(hc + Vector2(3, -1), 2.4, Color("#101010"))
	draw_line(hc + Vector2(-4, -2), hc + Vector2(-3, -2.6), Color(1, 1, 1, 0.7), 0.8)
	# Nose, teeth, whiskers.
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-1.2, 1.6), hc + Vector2(1.2, 1.6), hc + Vector2(0, 3)]), Color("#e86a85"))
	draw_rect(Rect2(hc + Vector2(-1.2, 4.0), Vector2(2.4, 2.0)), Color.WHITE)
	for s in [-1.0, 1.0]:
		draw_line(hc + Vector2(s * 2, 3), hc + Vector2(s * 8, 2), Color(1, 1, 1, 0.6), 0.6)
		draw_line(hc + Vector2(s * 2, 3.5), hc + Vector2(s * 8, 4.5), Color(1, 1, 1, 0.6), 0.6)
	_draw_rifle(hc)
	if flash > 0.0:
		var fp := Vector2(25, 21 + bob)
		draw_circle(fp, 7.0 * flash, Color(1.0, 0.85, 0.3, flash))
		draw_circle(fp, 3.5 * flash, Color(1, 1, 1, flash))
	Building.draw_window_frame(self, r)


func _draw_rifle(hc: Vector2) -> void:
	var wood := Color("#7b4a26")
	var steel := Color("#2a2d33")
	if aiming:
		# Shouldered and levelled - the scope is up at the eye.
		draw_line(hc + Vector2(-9, 9), hc + Vector2(4, 4), wood, 4.0)
		draw_line(hc + Vector2(2, 4), hc + Vector2(14, 3), steel, 2.0)
		draw_rect(Rect2(hc + Vector2(-1, 0), Vector2(8, 2.6)), steel)
		draw_circle(hc + Vector2(-1, 1.3), 1.6, Color("#5fc8ff"))
		draw_circle(hc + Vector2(4, 9), 2.4, fur)      # paw on the stock
	else:
		# Held at port arms.
		draw_line(hc + Vector2(-9, 15), hc + Vector2(2, 10), wood, 4.0)
		draw_line(hc + Vector2(1, 10.5), hc + Vector2(13, 3), steel, 2.0)
		draw_rect(Rect2(hc + Vector2(-2, 8.5), Vector2(7, 2.4)), steel)
		draw_circle(hc + Vector2(-5, 14), 2.4, fur)
		draw_circle(hc + Vector2(6, 9), 2.2, fur)


func _ellipse(c: Vector2, rad: Vector2, rot := 0.0, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := cos(rot)
	var sn := sin(rot)
	for i in n:
		var a := TAU * float(i) / n
		var p := Vector2(cos(a) * rad.x, sin(a) * rad.y)
		pts.append(c + Vector2(p.x * cs - p.y * sn, p.x * sn + p.y * cs))
	return pts
