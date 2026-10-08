extends Control
## Procedurally painted spy apartment used behind the main menu: a messy desk
## covered in dossiers, a revolver, coffee, an evidence board and a rainy
## window with venetian blinds. Painted in a 1280x720 design space and scaled
## to cover whatever size the control ends up.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const W := 1280.0
const H := 720.0

var _rng := RandomNumberGenerator.new()
var _papers := []
var _city := []
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 1987
	for i in 16:
		_papers.append({
			"pos": Vector2(_rng.randf_range(80, 1200), _rng.randf_range(540, 690)),
			"rot": _rng.randf_range(-0.6, 0.6),
			"size": Vector2(_rng.randf_range(90, 140), _rng.randf_range(110, 160)),
			"tint": _rng.randf_range(0.82, 1.0),
		})
	for i in 40:
		_city.append(Vector4(_rng.randf_range(0, 1), _rng.randf_range(0.2, 1.0), _rng.randf_range(0.04, 0.12), _rng.randf()))
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := maxf(size.x / W, size.y / H)
	var off := (size - Vector2(W, H) * s) * 0.5
	draw_set_transform(off, 0.0, Vector2(s, s))
	_draw_wall()
	_draw_window(Rect2(820, 60, 340, 300))
	_draw_board(Rect2(70, 70, 420, 280))
	_draw_lamp_glow()
	_draw_desk()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wall() -> void:
	var top := Color("#2a2f2c")
	var bottom := Color("#16191a")
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 520), Vector2(0, 520)]),
		PackedColorArray([top, top, bottom, bottom]))
	for x in range(0, int(W), 46):
		draw_rect(Rect2(x, 0, 18, 520), Color(1, 1, 1, 0.025))
	# Skirting board.
	draw_rect(Rect2(0, 500, W, 20), Color("#1d1512"))


func _draw_window(r: Rect2) -> void:
	draw_rect(r.grow(14), Color("#3b2c22"))
	var sky_top := Color("#0b1630")
	var sky_bot := Color("#25315a")
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([sky_top, sky_top, sky_bot, sky_bot]))
	# Distant city skyline with lit windows.
	var bx := r.position.x
	var i := 0
	while bx < r.end.x:
		var c: Vector4 = _city[i % _city.size()]
		var bw := 26.0 + c.z * 300.0
		var bh := 60.0 + c.y * 150.0
		var br := Rect2(bx, r.end.y - bh, minf(bw, r.end.x - bx), bh)
		draw_rect(br, Color("#0d1020"))
		var wy := br.position.y + 8
		while wy < r.end.y - 6:
			var wx := br.position.x + 5
			while wx < br.end.x - 6:
				if fmod(wx * 7.3 + wy * 3.1 + c.w * 50.0, 5.0) < 1.6:
					draw_rect(Rect2(wx, wy, 4, 5), Color(1.0, 0.85, 0.45, 0.8))
				wx += 9
			wy += 11
		bx += bw + 4
		i += 1
	# Moon.
	draw_circle(r.position + Vector2(260, 60), 22, Color(0.95, 0.95, 0.85, 0.9))
	# Rain on the glass.
	for k in 26:
		var x := r.position.x + fmod(k * 53.7, r.size.x)
		var y := r.position.y + fmod(k * 91.3 + _t * (120 + k * 7), r.size.y)
		draw_line(Vector2(x, y), Vector2(x - 2, y + 10), Color(0.7, 0.8, 1.0, 0.35), 1.0)
	# Venetian blinds, partly open.
	var y2 := r.position.y
	while y2 < r.position.y + r.size.y * 0.62:
		draw_rect(Rect2(r.position.x - 6, y2, r.size.x + 12, 9), Color("#c9b99a"))
		draw_rect(Rect2(r.position.x - 6, y2 + 7, r.size.x + 12, 2), Color("#8a7a60"))
		y2 += 15
	draw_line(Vector2(r.position.x + 40, r.position.y), Vector2(r.position.x + 40, y2 + 60), Color("#ddd"), 1.5)
	# Frame cross.
	draw_rect(Rect2(r.position.x + r.size.x * 0.5 - 4, r.position.y, 8, r.size.y), Color("#3b2c22"))
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.5 - 4, r.size.x, 8), Color("#3b2c22"))
	# Moonlight falling into the room.
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, r.size.y), r.end, Vector2(r.end.x - 120, 720), Vector2(r.position.x - 260, 720)]),
		Color(0.55, 0.65, 1.0, 0.05))


func _draw_board(r: Rect2) -> void:
	draw_rect(r.grow(10), Color("#4a3322"))
	draw_rect(r, Color("#a87c4f"))
	for k in 260:
		var p := r.position + Vector2(fmod(k * 37.1, r.size.x), fmod(k * 19.7, r.size.y))
		draw_rect(Rect2(p, Vector2(2, 2)), Color(0.4, 0.25, 0.1, 0.3))
	var pins := [Vector2(60, 50), Vector2(200, 40), Vector2(330, 70), Vector2(110, 180), Vector2(280, 200)]
	# Red string linking the suspects.
	for k in pins.size():
		var a: Vector2 = r.position + pins[k]
		var b: Vector2 = r.position + pins[(k + 2) % pins.size()]
		draw_line(a, b, Color(0.85, 0.1, 0.1, 0.85), 2.0, true)
	for k in pins.size():
		var p: Vector2 = r.position + pins[k]
		var card := Rect2(p - Vector2(38, 30), Vector2(76, 86))
		draw_rect(card, Color("#f2efe6"))
		draw_rect(Rect2(card.position + Vector2(6, 6), Vector2(64, 52)), Color("#3c4148"))
		if k == 0:
			_draw_bunny_mugshot(card.position + Vector2(38, 36))
		else:
			draw_circle(card.position + Vector2(38, 26), 11, Color("#6c727a"))
			draw_rect(Rect2(card.position + Vector2(20, 38), Vector2(36, 20)), Color("#6c727a"))
		for ln in 2:
			draw_line(card.position + Vector2(8, 66 + ln * 7), card.position + Vector2(66 - ln * 14, 66 + ln * 7), Color(0.3, 0.3, 0.3, 0.7), 2)
		draw_circle(p - Vector2(0, 26), 5, Color("#d32f2f"))
	# "WANTED" note.
	var note := Rect2(r.position + Vector2(300, 120), Vector2(100, 60))
	draw_rect(note, Color("#ffe76a"))
	draw_string(UIKit.title_font(), note.position + Vector2(8, 26), "McWHURTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b71c1c"))
	draw_string(UIKit.body_font(), note.position + Vector2(8, 46), "back in town?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#333"))


func _draw_bunny_mugshot(c: Vector2) -> void:
	var fur := Color("#b9a99a")
	draw_colored_polygon(_ellipse(c + Vector2(-8, -22), Vector2(5, 14)), fur)
	draw_colored_polygon(_ellipse(c + Vector2(8, -22), Vector2(5, 14)), fur)
	draw_circle(c, 13, fur)
	draw_rect(Rect2(c + Vector2(-11, -5), Vector2(22, 6)), Color(0.05, 0.05, 0.05))
	draw_line(c + Vector2(-26, -30), c + Vector2(26, 22), Color(0.85, 0.1, 0.1), 4)
	draw_line(c + Vector2(26, -30), c + Vector2(-26, 22), Color(0.85, 0.1, 0.1), 4)


func _draw_lamp_glow() -> void:
	var lamp := Vector2(1010, 470)
	draw_colored_polygon(PackedVector2Array([lamp + Vector2(-30, 10), lamp + Vector2(30, 10), lamp + Vector2(240, 250), lamp + Vector2(-340, 250)]),
		Color(1.0, 0.8, 0.45, 0.08))
	for k in 6:
		draw_circle(lamp + Vector2(-40, 160), 260 - k * 36, Color(1.0, 0.75, 0.4, 0.025))


func _draw_desk() -> void:
	# Desk top in perspective.
	var top := PackedVector2Array([Vector2(-40, 520), Vector2(W + 40, 520), Vector2(W + 200, H), Vector2(-200, H)])
	var wood_a := Color("#5a3a24")
	var wood_b := Color("#3a2416")
	draw_polygon(top, PackedColorArray([wood_a, wood_a, wood_b, wood_b]))
	for k in 12:
		var y := 528.0 + k * 16.0
		draw_line(Vector2(-40, y), Vector2(W + 40, y + 6), Color(0, 0, 0, 0.12), 2)
	# Papers and dossiers.
	for p in _papers:
		_draw_paper(p.pos, p.rot, p.size, p.tint)
	_draw_folder(Vector2(560, 600), -0.12)
	_draw_map(Vector2(260, 610), 0.18)
	_draw_mug(Vector2(1120, 600))
	_draw_revolver(Vector2(820, 640), -0.22, 1.25)
	for k in 5:
		_draw_cartridge(Vector2(960 + k * 22, 690 + (k % 2) * 8), 0.4 + k * 0.5)
	# Desk lamp.
	var lb := Vector2(1010, 470)
	draw_line(lb + Vector2(80, 70), lb + Vector2(40, -10), Color("#1f2a26"), 6)
	draw_line(lb + Vector2(40, -10), lb, Color("#1f2a26"), 6)
	draw_colored_polygon(PackedVector2Array([lb + Vector2(-34, 12), lb + Vector2(-10, -22), lb + Vector2(22, -14), lb + Vector2(34, 12)]), Color("#2d4a3e"))
	draw_circle(lb + Vector2(0, 12), 10, Color(1.0, 0.92, 0.6))
	draw_colored_polygon(_ellipse(lb + Vector2(80, 74), Vector2(40, 10)), Color("#1f2a26"))


func _draw_paper(pos: Vector2, rot: float, sz: Vector2, tint: float) -> void:
	draw_set_transform_matrix(_xf(pos, rot))
	draw_rect(Rect2(-sz * 0.5 + Vector2(4, 5), sz), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-sz * 0.5, sz), Color(tint, tint * 0.98, tint * 0.92))
	var y := -sz.y * 0.5 + 14
	while y < sz.y * 0.5 - 10:
		var w := sz.x - 24 - fmod(y * 13.0, 30.0)
		draw_line(Vector2(-sz.x * 0.5 + 10, y), Vector2(-sz.x * 0.5 + 10 + w, y), Color(0.25, 0.25, 0.3, 0.55), 2)
		y += 9
	_reset_xf()


func _draw_folder(pos: Vector2, rot: float) -> void:
	draw_set_transform_matrix(_xf(pos, rot))
	draw_rect(Rect2(-125, -78, 260, 170), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-130, -95, 80, 20), Color("#d9b26b"))
	draw_rect(Rect2(-130, -85, 260, 170), Color("#e3bf78"))
	draw_rect(Rect2(-120, -78, 248, 160), Color("#f6f2e6"))
	draw_rect(Rect2(-130, -40, 260, 125), Color("#e3bf78"))
	var f := UIKit.title_font()
	draw_string(f, Vector2(-96, 18), "TOP SECRET", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.75, 0.08, 0.08, 0.9))
	draw_rect(Rect2(-104, -12, 200, 42), Color(0.75, 0.08, 0.08, 0.9), false, 3)
	draw_string(UIKit.mono_font(), Vector2(-100, 60), "OPERATION: LILY PAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.2, 0.15, 0.1))
	_reset_xf()


func _draw_map(pos: Vector2, rot: float) -> void:
	draw_set_transform_matrix(_xf(pos, rot))
	draw_rect(Rect2(-150, -80, 300, 170), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-155, -88, 300, 170), Color("#dfe8d0"))
	for k in 7:
		draw_line(Vector2(-155 + k * 46, -88), Vector2(-150 + k * 44, 82), Color(0.5, 0.6, 0.5, 0.6), 2)
		draw_line(Vector2(-155, -88 + k * 26), Vector2(145, -84 + k * 25), Color(0.5, 0.6, 0.5, 0.6), 2)
	draw_arc(Vector2(20, -10), 30, 0, TAU, 32, Color(0.85, 0.1, 0.1), 3)
	draw_arc(Vector2(-80, 40), 18, 0, TAU, 24, Color(0.85, 0.1, 0.1), 3)
	_reset_xf()


func _draw_mug(pos: Vector2) -> void:
	draw_colored_polygon(_ellipse(pos + Vector2(4, 60), Vector2(46, 12)), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(pos + Vector2(-34, -10), Vector2(68, 70)), Color("#e8e2d4"))
	draw_arc(pos + Vector2(36, 24), 18, -PI * 0.5, PI * 0.5, 16, Color("#e8e2d4"), 8)
	draw_colored_polygon(_ellipse(pos + Vector2(0, -10), Vector2(34, 9)), Color("#3b2414"))
	draw_string(UIKit.title_font(), pos + Vector2(-24, 34), "FBI", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#284a8a"))
	for k in 3:
		var pts := PackedVector2Array()
		for j in 12:
			var y := -20.0 - j * 8.0
			pts.append(pos + Vector2(-12 + k * 12 + sin(_t * 2.0 + j * 0.6 + k) * 5.0, y))
		draw_polyline(pts, Color(1, 1, 1, 0.12), 3, true)


func _draw_revolver(pos: Vector2, rot: float, sc: float) -> void:
	var m := _xf(pos, rot).scaled_local(Vector2(sc, sc))
	draw_set_transform_matrix(m)
	var steel := Color("#3d434b")
	var steel_hi := Color("#7c8590")
	var wood := Color("#6b3b1f")
	# Shadow.
	draw_colored_polygon(PackedVector2Array([Vector2(-120, 18), Vector2(70, 14), Vector2(110, 60), Vector2(60, 70), Vector2(-120, 28)]), Color(0, 0, 0, 0.35))
	# Barrel.
	draw_rect(Rect2(-130, -12, 120, 15), steel)
	draw_rect(Rect2(-130, -12, 120, 4), steel_hi)
	draw_rect(Rect2(-130, 3, 105, 7), steel.darkened(0.2))
	draw_rect(Rect2(-128, -18, 7, 6), steel)
	# Frame and cylinder.
	draw_rect(Rect2(-14, -16, 64, 30), steel)
	draw_rect(Rect2(-6, -14, 46, 32), steel.darkened(0.1))
	for k in 4:
		draw_line(Vector2(-2 + k * 12, -12), Vector2(-2 + k * 12, 16), steel_hi.darkened(0.3), 2)
	draw_rect(Rect2(-6, -14, 46, 4), steel_hi)
	# Hammer.
	draw_colored_polygon(PackedVector2Array([Vector2(46, -16), Vector2(60, -26), Vector2(66, -22), Vector2(56, -10)]), steel)
	# Trigger guard and trigger.
	draw_arc(Vector2(26, 22), 14, 0.0, PI, 16, steel, 4)
	draw_line(Vector2(26, 14), Vector2(22, 28), steel_hi, 3)
	# Grip.
	draw_colored_polygon(PackedVector2Array([Vector2(40, 8), Vector2(62, 2), Vector2(96, 54), Vector2(90, 66), Vector2(64, 70), Vector2(40, 22)]), wood)
	draw_colored_polygon(PackedVector2Array([Vector2(48, 14), Vector2(60, 10), Vector2(86, 56), Vector2(68, 60)]), wood.lightened(0.15))
	draw_circle(Vector2(66, 36), 3, steel_hi)
	_reset_xf()


func _draw_cartridge(pos: Vector2, rot: float) -> void:
	draw_set_transform_matrix(_xf(pos, rot))
	draw_rect(Rect2(-12, -4, 18, 8), Color("#c9a24a"))
	draw_rect(Rect2(6, -3.5, 7, 7), Color("#9c6b3a"))
	draw_rect(Rect2(-12, -4, 18, 2), Color("#f0d27a"))
	_reset_xf()


# ----------------------------------------------------------------- helpers -
func _xf(pos: Vector2, rot: float) -> Transform2D:
	var s := maxf(size.x / W, size.y / H)
	var off := (size - Vector2(W, H) * s) * 0.5
	return Transform2D(0.0, Vector2(s, s), 0.0, off) * Transform2D(rot, pos)


func _reset_xf() -> void:
	var s := maxf(size.x / W, size.y / H)
	var off := (size - Vector2(W, H) * s) * 0.5
	draw_set_transform(off, 0.0, Vector2(s, s))


func _ellipse(c: Vector2, r: Vector2, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
