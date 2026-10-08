extends Control
## Procedurally painted Cold War spy office used behind the main menu: a grey
## steel desk covered in dossiers, a Walther PPK, a red hotline phone, a
## Frog Bureau mug, an evidence board, a map of the Iron Curtain and a rainy
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
	_draw_wall_map(Rect2(540, 96, 230, 165))
	_draw_lamp_glow()
	_draw_desk()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wall() -> void:
	# Institutional grey-green paint, darker wainscot panelling below.
	var top := Color("#3b4144")
	var bottom := Color("#262b2e")
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 520), Vector2(0, 520)]),
		PackedColorArray([top, top, bottom, bottom]))
	for x in range(0, int(W), 46):
		draw_rect(Rect2(x, 0, 18, 380), Color(1, 1, 1, 0.018))
	draw_rect(Rect2(0, 380, W, 120), Color("#23282b"))
	draw_rect(Rect2(0, 380, W, 4), Color("#4a5155"))
	var px := 20.0
	while px < W:
		draw_rect(Rect2(px, 396, 150, 90), Color(1, 1, 1, 0.03), false, 2)
		px += 170.0
	# Skirting board.
	draw_rect(Rect2(0, 500, W, 20), Color("#1b1f22"))


func _draw_window(r: Rect2) -> void:
	draw_rect(r.grow(14), Color("#474d52"))
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
		draw_rect(Rect2(r.position.x - 6, y2, r.size.x + 12, 9), Color("#b4b9bc"))
		draw_rect(Rect2(r.position.x - 6, y2 + 7, r.size.x + 12, 2), Color("#7c8286"))
		y2 += 15
	draw_line(Vector2(r.position.x + 40, r.position.y), Vector2(r.position.x + 40, y2 + 60), Color("#ddd"), 1.5)
	# Frame cross.
	draw_rect(Rect2(r.position.x + r.size.x * 0.5 - 4, r.position.y, 8, r.size.y), Color("#474d52"))
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.5 - 4, r.size.x, 8), Color("#474d52"))
	# Moonlight falling into the room.
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, r.size.y), r.end, Vector2(r.end.x - 120, 720), Vector2(r.position.x - 260, 720)]),
		Color(0.55, 0.65, 1.0, 0.05))


func _draw_board(r: Rect2) -> void:
	draw_rect(r.grow(10), Color("#3d4347"))
	draw_rect(r, Color("#8a8275"))
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
	# Grey steel government-issue desk in perspective.
	var top := PackedVector2Array([Vector2(-40, 520), Vector2(W + 40, 520), Vector2(W + 200, H), Vector2(-200, H)])
	var steel_a := Color("#575e62")
	var steel_b := Color("#33393c")
	draw_polygon(top, PackedColorArray([steel_a, steel_a, steel_b, steel_b]))
	draw_rect(Rect2(-40, 520, W + 80, 5), Color("#6d7478"))
	# Green linoleum blotter.
	draw_colored_polygon(PackedVector2Array([Vector2(180, 545), Vector2(1000, 545), Vector2(1060, 720), Vector2(120, 720)]), Color("#34463d"))
	# Papers and dossiers.
	for p in _papers:
		_draw_paper(p.pos, p.rot, p.size, p.tint)
	_draw_folder(Vector2(560, 600), -0.12)
	_draw_map(Vector2(260, 610), 0.18)
	_draw_phone(Vector2(760, 560))
	_draw_mug(Vector2(1150, 612))
	_draw_ppk(Vector2(850, 612), -0.12, 1.25)
	for k in 5:
		_draw_cartridge(Vector2(960 + k * 22, 690 + (k % 2) * 8), 0.4 + k * 0.5)
	# Desk lamp.
	var lb := Vector2(1010, 470)
	draw_line(lb + Vector2(80, 70), lb + Vector2(40, -10), Color("#24292c"), 6)
	draw_line(lb + Vector2(40, -10), lb, Color("#24292c"), 6)
	draw_colored_polygon(PackedVector2Array([lb + Vector2(-34, 12), lb + Vector2(-10, -22), lb + Vector2(22, -14), lb + Vector2(34, 12)]), Color("#2d4a3e"))
	draw_circle(lb + Vector2(0, 12), 10, Color(1.0, 0.92, 0.6))
	draw_colored_polygon(_ellipse(lb + Vector2(80, 74), Vector2(40, 10)), Color("#24292c"))


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
	# A shaded ceramic cylinder: per-strip lighting, elliptical rim, coffee.
	var r := 56.0
	var ry := 13.0
	var h := 104.0
	var top_y := pos.y - h * 0.5
	var bot_y := pos.y + h * 0.5
	var ceramic := Color("#ebe8e1")
	draw_colored_polygon(_ellipse(Vector2(pos.x + 10, bot_y + 4), Vector2(r + 16, ry + 4)), Color(0, 0, 0, 0.3))
	# Handle (drawn first so the body overlaps its roots).
	var hc := Vector2(pos.x + r - 4, pos.y - 4)
	draw_arc(hc, 30, -1.25, 1.25, 24, ceramic.darkened(0.35), 15, true)
	draw_arc(hc, 30, -1.25, 1.25, 24, ceramic.darkened(0.12), 11, true)
	draw_arc(hc, 33, -1.0, 0.2, 16, Color(1, 1, 1, 0.5), 2.5, true)
	# Body strips with cylinder lighting from the upper left.
	var n := 28
	for i in n:
		var x0 := pos.x - r + 2.0 * r * i / n
		var x1 := pos.x - r + 2.0 * r * (i + 1) / n
		var u0 := clampf((x0 - pos.x) / r, -1.0, 1.0)
		var u1 := clampf((x1 - pos.x) / r, -1.0, 1.0)
		var e0 := ry * sqrt(1.0 - u0 * u0)
		var e1 := ry * sqrt(1.0 - u1 * u1)
		var um := (u0 + u1) * 0.5
		var light := clampf(cos(asin(um) + 0.65), 0.0, 1.0)
		var shade := 0.58 + 0.42 * light + (0.12 if absf(um + 0.45) < 0.06 else 0.0)
		var c := Color(ceramic.r * shade, ceramic.g * shade, ceramic.b * shade)
		draw_colored_polygon(PackedVector2Array([Vector2(x0, top_y + e0), Vector2(x1, top_y + e1),
			Vector2(x1, bot_y + e1), Vector2(x0, bot_y + e0)]), c)
	# Rim, inner wall and coffee.
	draw_colored_polygon(_ellipse(Vector2(pos.x, top_y), Vector2(r, ry), 40), ceramic.lightened(0.3))
	draw_colored_polygon(_ellipse(Vector2(pos.x, top_y + 1), Vector2(r - 5, ry - 3), 40), ceramic.darkened(0.3))
	draw_colored_polygon(_ellipse(Vector2(pos.x, top_y + 4), Vector2(r - 6, ry - 4.5), 40), Color("#2a170c"))
	draw_colored_polygon(_ellipse(Vector2(pos.x - 14, top_y + 2.5), Vector2(14, 2.2), 16), Color(1, 1, 1, 0.18))
	# Printed logo: "Frog Bureau Int." with bold red initials, wrapped round
	# the cylinder: each glyph is placed at an angle around the mug, so it is
	# squeezed towards the edges and follows the curve of the rim.
	var parts := [["F", true], ["rog ", false], ["B", true], ["ureau ", false], ["I", true], ["nt.", false]]
	var fs := 13
	var glyphs := []   # [char, bold, advance]
	var total := 0.0
	for pt in parts:
		var f := _part_font(pt[1])
		for ch in pt[0]:
			var adv := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			glyphs.append([ch, pt[1], adv])
			total += adv
	var wrap_r := r * 1.05          # text sits just proud of the surface
	var sag := ry * 0.85            # how much the line dips at the front
	var base_y := pos.y + 8.0
	var arc := -total * 0.5
	for g in glyphs:
		var adv: float = g[2]
		var theta := (arc + adv * 0.5) / wrap_r
		var squeeze := cos(theta)
		var gx := pos.x + wrap_r * sin(theta)
		var gy := base_y - sag * (1.0 - cos(theta))
		var slope := atan2(-sag * sin(theta), wrap_r * cos(theta))
		var f := _part_font(g[1])
		var col := Color("#c4161c") if g[1] else Color("#1e2a48")
		# Fade slightly as the letters turn away from the light / viewer.
		col = col.lerp(Color(0.55, 0.55, 0.55), (1.0 - squeeze) * 0.5)
		draw_set_transform_matrix(_xf(Vector2(gx, gy), slope).scaled_local(Vector2(squeeze, 1.0)))
		draw_char(f, Vector2(-adv * 0.5, 0), g[0], fs, col)
		arc += adv
	_reset_xf()
	# Little frog-badge above the text, centred on the mug.
	var bc := Vector2(pos.x, pos.y - 17)
	draw_circle(bc, 10, Color("#1e2a48"))
	draw_circle(bc, 7.5, Color("#5cbf3c"))
	draw_circle(bc + Vector2(-3.5, -3), 2, Color.WHITE)
	draw_circle(bc + Vector2(3.5, -3), 2, Color.WHITE)
	# Steam.
	for k in 3:
		var pts := PackedVector2Array()
		for j in 12:
			var y := top_y - 6.0 - j * 8.0
			pts.append(Vector2(pos.x - 16 + k * 16 + sin(_t * 2.0 + j * 0.6 + k) * 5.0, y))
		draw_polyline(pts, Color(1, 1, 1, 0.1), 3, true)


func _part_font(bold: bool) -> Font:
	return UIKit.title_font() if bold else UIKit.body_font()


func _draw_ppk(pos: Vector2, rot: float, sc: float) -> void:
	# Walther PPK: compact blued slide, short barrel, big rounded trigger
	# guard and a swept-back grip with black checkered panels. Muzzle left.
	var m := _xf(pos, rot).scaled_local(Vector2(sc, sc))
	draw_set_transform_matrix(m)
	var blued := Color("#2a2e35")
	var blued_hi := Color("#6b7380")
	var frame := Color("#353a42")
	var grip := Color("#141518")
	# Shadow.
	draw_colored_polygon(PackedVector2Array([Vector2(-84, 10), Vector2(46, 8), Vector2(70, 78), Vector2(28, 84), Vector2(-84, 24)]), Color(0, 0, 0, 0.35))
	# Grip, swept back.
	draw_colored_polygon(PackedVector2Array([Vector2(6, 4), Vector2(46, 2), Vector2(62, 66), Vector2(58, 74), Vector2(24, 76), Vector2(16, 70)]), frame)
	draw_colored_polygon(PackedVector2Array([Vector2(14, 10), Vector2(42, 9), Vector2(55, 63), Vector2(26, 68)]), grip)
	for k in 7:
		var o := k * 8.0
		draw_line(Vector2(15 + o * 0.5, 14 + o), Vector2(42 + o * 0.25, 13 + o), Color(1, 1, 1, 0.07), 1)
		draw_line(Vector2(18 + k * 5, 11), Vector2(28 + k * 4.5, 66), Color(1, 1, 1, 0.05), 1)
	draw_circle(Vector2(34, 36), 5, Color("#3d434b"))
	draw_circle(Vector2(34, 36), 3, Color("#8a919b"))
	# Magazine base with finger rest.
	draw_colored_polygon(PackedVector2Array([Vector2(16, 70), Vector2(24, 76), Vector2(58, 74), Vector2(56, 80), Vector2(20, 82), Vector2(10, 78)]), blued)
	# Frame under the slide and the trigger guard.
	draw_rect(Rect2(-74, 0, 120, 9), frame)
	draw_arc(Vector2(-14, 7), 15, 0.0, PI, 24, frame, 5, true)
	draw_line(Vector2(-12, 7), Vector2(-15, 18), blued_hi.darkened(0.2), 3)
	# Barrel tip.
	draw_rect(Rect2(-90, -16, 8, 10), Color("#1a1c20"))
	draw_circle(Vector2(-90, -11), 3.2, Color("#050505"))
	# Slide.
	draw_colored_polygon(PackedVector2Array([Vector2(-84, -22), Vector2(42, -24), Vector2(48, -18), Vector2(48, 0), Vector2(-84, 0), Vector2(-87, -4), Vector2(-87, -18)]), blued)
	draw_rect(Rect2(-84, -22, 128, 3), blued_hi)
	draw_line(Vector2(-84, -9), Vector2(46, -9), Color(1, 1, 1, 0.08), 1)
	for k in 7:
		draw_line(Vector2(22 + k * 3.4, -20), Vector2(22 + k * 3.4, -3), Color(0, 0, 0, 0.55), 1.4)
	draw_rect(Rect2(-14, -20, 22, 8), Color("#121418"))
	draw_rect(Rect2(-80, -27, 5, 5), blued)
	draw_rect(Rect2(36, -28, 8, 5), blued)
	# Safety lever, hammer and slide stamping.
	draw_circle(Vector2(30, -12), 4, blued_hi.darkened(0.25))
	draw_line(Vector2(30, -12), Vector2(40, -8), blued_hi.darkened(0.25), 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(47, -14), Vector2(54, -19), Vector2(57, -16), Vector2(50, -9)]), blued)
	draw_string(UIKit.body_font(), Vector2(-62, -11), "WALTHER  PPK", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.35))
	_reset_xf()


func _draw_phone(pos: Vector2) -> void:
	# The red hotline: rotary dial telephone.
	var red := Color("#9b1c1c")
	draw_colored_polygon(_ellipse(pos + Vector2(6, 40), Vector2(70, 12)), Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-58, 38), pos + Vector2(58, 38), pos + Vector2(44, -8), pos + Vector2(-44, -8)]), red)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-44, -8), pos + Vector2(44, -8), pos + Vector2(34, -18), pos + Vector2(-34, -18)]), red.lightened(0.15))
	# Dial.
	var dc := pos + Vector2(0, 14)
	draw_colored_polygon(_ellipse(dc, Vector2(26, 18)), Color("#e8e2d2"))
	for k in 10:
		var a := -PI * 0.35 + k * PI * 1.45 / 9.0
		draw_colored_polygon(_ellipse(dc + Vector2(cos(a) * 18, sin(a) * 12.5), Vector2(4, 3), 10), Color("#3a1010"))
	draw_colored_polygon(_ellipse(dc, Vector2(9, 6)), red.lightened(0.25))
	# Handset resting on the cradle.
	draw_rect(Rect2(pos + Vector2(-52, -34), Vector2(104, 12)), red.darkened(0.1))
	draw_colored_polygon(_ellipse(pos + Vector2(-48, -26), Vector2(18, 11)), red.darkened(0.05))
	draw_colored_polygon(_ellipse(pos + Vector2(48, -26), Vector2(18, 11)), red.darkened(0.05))
	draw_rect(Rect2(pos + Vector2(-46, -34), Vector2(92, 3)), Color(1, 1, 1, 0.22))
	# Curly cord.
	var pts := PackedVector2Array()
	for j in 40:
		var t := float(j) / 39.0
		pts.append(pos + Vector2(58 + t * 50, 20 + t * 40) + Vector2(cos(t * 40.0), sin(t * 40.0)) * 4.0)
	draw_polyline(pts, red.darkened(0.3), 2, true)


func _draw_wall_map(r: Rect2) -> void:
	# Pinned map of Europe split by the Iron Curtain.
	draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, Color("#d8d4c4"))
	draw_rect(Rect2(r.position.x + r.size.x * 0.52, r.position.y, r.size.x * 0.48, r.size.y), Color(0.75, 0.2, 0.2, 0.18))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x * 0.52, r.size.y), Color(0.2, 0.35, 0.75, 0.12))
	var land := Color("#9fa98f")
	var o := r.position
	draw_colored_polygon(PackedVector2Array([o + Vector2(20, 40), o + Vector2(70, 22), o + Vector2(140, 30), o + Vector2(205, 26),
		o + Vector2(220, 80), o + Vector2(190, 140), o + Vector2(120, 150), o + Vector2(90, 120), o + Vector2(40, 140), o + Vector2(28, 95)]), land)
	draw_colored_polygon(PackedVector2Array([o + Vector2(14, 50), o + Vector2(30, 30), o + Vector2(36, 62), o + Vector2(20, 72)]), land)
	for k in 6:
		draw_line(o + Vector2(0, k * 30), o + Vector2(r.size.x, k * 30), Color(0.3, 0.3, 0.3, 0.15), 1)
		draw_line(o + Vector2(k * 46, 0), o + Vector2(k * 46, r.size.y), Color(0.3, 0.3, 0.3, 0.15), 1)
	# The Curtain.
	var pts := PackedVector2Array()
	for j in 12:
		pts.append(o + Vector2(r.size.x * 0.52 + sin(j * 1.3) * 6.0, 18 + j * 12.0))
	for j in range(0, pts.size() - 1, 2):
		draw_line(pts[j], pts[j + 1], Color("#1a1a1a"), 3)
	draw_circle(o + Vector2(150, 70), 5, Color("#c62828"))
	draw_circle(o + Vector2(70, 95), 5, Color("#1565c0"))
	draw_string(UIKit.title_font(), o + Vector2(8, r.size.y - 8), "EUROPA  1962", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#333"))
	draw_circle(o + Vector2(r.size.x * 0.5, 6), 4, Color("#888"))


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
