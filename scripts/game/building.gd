extends Node2D
## A single high-rise. Drawn once (Godot caches the draw list) and only redrawn
## when a window breaks or picks up a bullet hole.
## Local origin is the bottom-left corner at pavement level; y grows upward
## as negative values.

const L := preload("res://scripts/game/layout.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

enum Decor { PLAIN, CURTAINS, BLINDS, HALF_BLINDS, PLANT, LIT, CLOSED }

const PALETTES := [
	[Color("#8fc9c0"), Color("#5f9e95")],   # teal
	[Color("#f2e39a"), Color("#c9b75f")],   # butter
	[Color("#8a5a4a"), Color("#5e3a2e")],   # brick
	[Color("#e8b4a8"), Color("#bb857a")],   # salmon
	[Color("#a39a91"), Color("#766d65")],   # taupe
	[Color("#9cc3e6"), Color("#6b93b8")],   # sky
	[Color("#b7d99b"), Color("#84a96a")],   # mint
	[Color("#c3b3dd"), Color("#9182ae")],   # lavender
	[Color("#d98d5f"), Color("#a8613a")],   # terracotta
	[Color("#e6d3b3"), Color("#b8a27f")],   # sand
]
const CURTAIN_COLORS := [Color("#c0392b"), Color("#f1c40f"), Color("#27ae60"), Color("#8e44ad"),
	Color("#e67e22"), Color("#ecf0f1"), Color("#2c7fb8"), Color("#e84393")]
const SIGNS := ["HOTEL", "BANK", "CAFE", "NEWS", "PIZZA", "ACME", "LAW", "TECH", "GYM", "DINER",
	"POST", "LOANS", "PAWN", "CINEMA", "BOOKS", "TOYS"]

var cols := 2
var floors := 4
var width := 100.0
var height := 300.0
var body := Color.WHITE
var trim := Color.GRAY
var sign_text := ""
var roof_kind := 0
var awning := false
var awning_color := Color.RED
var windows: Array = []           # per-window decor dictionaries
var broken := {}                  # window index -> {"blood": bool, "seed": int}
var holes: Array[Vector2] = []    # local bullet holes
var snow := false


func setup(x: float, n_cols: int, n_floors: int, rng: RandomNumberGenerator, sign_name := "", storm := false, is_snow := false) -> void:
	snow = is_snow
	cols = n_cols
	floors = n_floors
	width = 2.0 * L.SIDE_MARGIN + cols * L.WIN_W + (cols - 1) * L.WIN_GAP
	height = L.GROUND_H + floors * L.FLOOR_H + L.ROOF_H
	position = Vector2(x, L.BASE_Y)
	var pal: Array = PALETTES[rng.randi() % PALETTES.size()]
	body = pal[0]
	trim = pal[1]
	sign_text = sign_name
	roof_kind = rng.randi() % 4
	awning = rng.randf() < 0.5
	awning_color = CURTAIN_COLORS[rng.randi() % CURTAIN_COLORS.size()]
	var house_curtain: Color = CURTAIN_COLORS[rng.randi() % CURTAIN_COLORS.size()]
	windows.clear()
	for i in cols * floors:
		var d := rng.randi() % 10
		var decor := Decor.PLAIN
		if d < 3:
			decor = Decor.PLAIN
		elif d < 5:
			decor = Decor.CURTAINS
		elif d == 5:
			decor = Decor.BLINDS
		elif d == 6:
			decor = Decor.HALF_BLINDS
		elif d == 7:
			decor = Decor.PLANT
		elif d == 8:
			# Lights are only on when the storm darkens the street.
			decor = Decor.LIT if storm else Decor.PLAIN
		else:
			decor = Decor.CLOSED
		if storm and decor == Decor.PLAIN and rng.randf() < 0.3:
			decor = Decor.LIT
		var cc: Color = house_curtain if rng.randf() < 0.7 else CURTAIN_COLORS[rng.randi() % CURTAIN_COLORS.size()]
		windows.append({"decor": decor, "curtain": cc, "open": rng.randf_range(0.25, 0.45)})


func window_count() -> int:
	return cols * floors


func window_local_rect(idx: int) -> Rect2:
	var c := idx % cols
	var f := idx / cols
	var x := L.SIDE_MARGIN + c * (L.WIN_W + L.WIN_GAP)
	var floor_top := -(L.GROUND_H + (f + 1) * L.FLOOR_H)
	return Rect2(x, floor_top + 5.0, L.WIN_W, L.WIN_H)


func window_world_rect(idx: int) -> Rect2:
	var r := window_local_rect(idx)
	r.position += position
	return r


func world_rect() -> Rect2:
	return Rect2(position + Vector2(0, -height), Vector2(width, height))


## Returns the window index under a world point (with a little slack), or -1.
func window_at(world_point: Vector2, slack := 2.0) -> int:
	var p := world_point - position
	for i in window_count():
		if window_local_rect(i).grow(slack).has_point(p):
			return i
	return -1


func break_window(idx: int, blood: bool) -> void:
	if broken.has(idx):
		broken[idx].blood = broken[idx].blood or blood
	else:
		broken[idx] = {"blood": blood, "seed": idx * 7919 + int(position.x)}
	queue_redraw()


func add_hole(world_point: Vector2) -> void:
	holes.append(world_point - position)
	if holes.size() > 30:
		holes.pop_front()
	queue_redraw()


# -------------------------------------------------------------- drawing ---
func _draw() -> void:
	var top := -height
	# Body with a soft vertical gradient and darker outline.
	draw_rect(Rect2(-2, top - 2, width + 4, height + 2), trim.darkened(0.35))
	var light := body.lightened(0.12)
	draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(width, top), Vector2(width, 0), Vector2(0, 0)]),
		PackedColorArray([light, light, body, body]))
	# Right-side shade for volume.
	draw_rect(Rect2(width - 8, top, 8, height), Color(0, 0, 0, 0.12))
	# Floor ledges.
	for f in floors + 1:
		var y := -(L.GROUND_H + f * L.FLOOR_H)
		draw_rect(Rect2(0, y - 2, width, 3), trim)
		draw_rect(Rect2(0, y - 2, width, 1), Color(1, 1, 1, 0.18))
	_draw_roof(top)
	_draw_ground_floor()
	for i in window_count():
		var r := window_local_rect(i)
		if broken.has(i):
			draw_broken_window(self, r, broken[i].blood, broken[i].seed)
		else:
			_draw_window(r, windows[i])
	if snow:
		_draw_snow()
	for h in holes:
		draw_circle(h, 2.6, Color(0.1, 0.08, 0.08))
		draw_circle(h + Vector2(-0.6, -0.6), 1.2, Color(0, 0, 0))
		for k in 4:
			var a := k * 1.7 + h.x
			draw_line(h, h + Vector2(cos(a), sin(a)) * 5.0, Color(0, 0, 0, 0.35), 1.0)


const SNOW := Color("#f4f7fa")


func _draw_snow() -> void:
	var top := -height
	# Thick cap along the cornice with a lumpy top edge.
	draw_rect(Rect2(-6, top - 9, width + 12, 6), SNOW)
	var x := -4.0
	while x < width + 4:
		draw_circle(Vector2(x, top - 9), 3.5, SNOW)
		x += 9.0
	# A dusting on every floor ledge and window sill.
	for f in floors + 1:
		var y := -(L.GROUND_H + f * L.FLOOR_H)
		draw_rect(Rect2(0, y - 4, width, 2), Color(SNOW, 0.85))
	for i in window_count():
		draw_window_snow(self, window_local_rect(i))
	if awning:
		draw_rect(Rect2(width * 0.5 - 30, -54 - 3, 60, 3), SNOW)


static func draw_window_snow(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position.x - 4, r.end.y - 1.5, r.size.x + 8, 2.5), SNOW)
	ci.draw_circle(Vector2(r.position.x + 4, r.end.y - 1.2), 1.8, SNOW)
	ci.draw_circle(Vector2(r.end.x - 6, r.end.y - 1.0), 1.5, SNOW)


func _draw_roof(top: float) -> void:
	# Cornice.
	draw_rect(Rect2(-5, top - 4, width + 10, 8), trim.darkened(0.15))
	draw_rect(Rect2(-5, top - 4, width + 10, 2), Color(1, 1, 1, 0.25))
	var dark := Color("#3d3f45")
	match roof_kind:
		0:
			# Water tower.
			if width > 150:
				var wx := width * 0.7
				draw_line(Vector2(wx - 12, top - 4), Vector2(wx - 10, top - 18), dark, 2)
				draw_line(Vector2(wx + 12, top - 4), Vector2(wx + 10, top - 18), dark, 2)
				draw_rect(Rect2(wx - 15, top - 40, 30, 24), Color("#8b5e3c"))
				for k in 3:
					draw_line(Vector2(wx - 15, top - 34 + k * 7), Vector2(wx + 15, top - 34 + k * 7), Color("#5b3b22"), 1)
				draw_colored_polygon(PackedVector2Array([Vector2(wx - 17, top - 40), Vector2(wx, top - 52), Vector2(wx + 17, top - 40)]), Color("#5b3b22"))
		1:
			# Antenna with a blinking-red tip look.
			draw_line(Vector2(width * 0.3, top - 4), Vector2(width * 0.3, top - 36), dark, 2)
			draw_line(Vector2(width * 0.3 - 7, top - 24), Vector2(width * 0.3 + 7, top - 24), dark, 2)
			draw_circle(Vector2(width * 0.3, top - 37), 2.5, Color("#ff4040"))
		2:
			# AC units.
			for k in mini(3, cols / 2 + 1):
				draw_rect(Rect2(10 + k * 34, top - 16, 26, 12), Color("#c7cbd1"))
				draw_circle(Vector2(23 + k * 34, top - 10), 4, Color("#8c9199"))
		_:
			# Railing.
			draw_line(Vector2(0, top - 14), Vector2(width, top - 14), dark, 1.5)
			var x := 0.0
			while x <= width:
				draw_line(Vector2(x, top - 4), Vector2(x, top - 14), dark, 1.5)
				x += 12.0


func _draw_ground_floor() -> void:
	var gy := -L.GROUND_H
	draw_rect(Rect2(0, gy, width, L.GROUND_H), trim)
	draw_rect(Rect2(0, gy, width, 4), trim.darkened(0.25))
	# Rusticated stone lines.
	for k in 3:
		draw_line(Vector2(0, gy + 14 + k * 15), Vector2(width, gy + 14 + k * 15), Color(0, 0, 0, 0.08), 1)
	var cx := width * 0.5
	var dw := 34.0
	var dh := 44.0
	var door := Rect2(cx - dw * 0.5, -dh, dw, dh)
	draw_rect(door.grow(3), trim.darkened(0.45))
	var g1 := Color("#2b3a55")
	var g2 := Color("#4f6a94")
	draw_polygon(PackedVector2Array([door.position, Vector2(door.end.x, door.position.y), door.end, Vector2(door.position.x, door.end.y)]),
		PackedColorArray([g2, g2, g1, g1]))
	draw_line(Vector2(cx, -dh), Vector2(cx, 0), trim.darkened(0.45), 2)
	draw_line(Vector2(cx - 4, -dh * 0.5), Vector2(cx - 4, -dh * 0.5 + 8), Color("#d4af37"), 2)
	draw_line(Vector2(cx + 4, -dh * 0.5), Vector2(cx + 4, -dh * 0.5 + 8), Color("#d4af37"), 2)
	draw_line(door.position + Vector2(3, 4), door.position + Vector2(10, 16), Color(1, 1, 1, 0.25), 2)
	# Step.
	draw_rect(Rect2(cx - dw * 0.5 - 6, -3, dw + 12, 3), Color("#bdbdbd"))
	if awning:
		var aw := dw + 22
		var ay := -dh - 10
		for k in 6:
			var c := awning_color if k % 2 == 0 else Color("#f5f5f5")
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - aw * 0.5 + k * aw / 6.0, ay), Vector2(cx - aw * 0.5 + (k + 1) * aw / 6.0, ay),
				Vector2(cx - aw * 0.5 + (k + 1) * aw / 6.0 + 2, ay + 10), Vector2(cx - aw * 0.5 + k * aw / 6.0 + 2, ay + 10)]), c)
	if sign_text != "":
		var font := UIKit.title_font()
		var fs := 11
		var tw := font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var sw := maxf(tw + 14, 50)
		var sr := Rect2(cx - sw * 0.5, gy + 4, sw, 14)
		if awning:
			sr.position.x = 6
		draw_rect(sr.grow(1), Color("#1b1b1b"))
		draw_rect(sr, Color("#263238"))
		draw_string(font, Vector2(sr.position.x + (sw - tw) * 0.5, sr.position.y + 11.5), sign_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffd54f"))
	else:
		# Wall lamps either side of the door.
		for sx in [-1.0, 1.0]:
			var lp := Vector2(cx + sx * (dw * 0.5 + 9), -dh + 6)
			draw_rect(Rect2(lp - Vector2(3, 4), Vector2(6, 8)), Color("#2d2d2d"))
			draw_circle(lp, 2.2, Color("#ffe082"))


static func draw_window_frame(ci: CanvasItem, r: Rect2) -> void:
	var frame := Color("#f4f1ea")
	ci.draw_rect(r.grow(2), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(r.position.x - 2, r.position.y - 2, r.size.x + 4, 3), frame)
	ci.draw_rect(Rect2(r.position.x - 2, r.position.y - 2, 3, r.size.y + 4), frame)
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y - 2, 3, r.size.y + 4), frame)
	ci.draw_rect(Rect2(r.position.x - 2, r.position.y + r.size.y * 0.55, r.size.x + 4, 2), frame)
	ci.draw_rect(Rect2(r.position.x + r.size.x * 0.5 - 1, r.position.y, 2, r.size.y * 0.55), frame)
	# Sill.
	ci.draw_rect(Rect2(r.position.x - 4, r.end.y, r.size.x + 8, 4), Color("#e0dbd0"))
	ci.draw_rect(Rect2(r.position.x - 4, r.end.y + 3, r.size.x + 8, 1), Color(0, 0, 0, 0.3))


static func draw_glass(ci: CanvasItem, r: Rect2, lit := false) -> void:
	var a := Color("#a9b8ff") if not lit else Color("#ffe6a3")
	var b := Color("#5b5fd6") if not lit else Color("#f0b35a")
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([a, a.lerp(b, 0.4), b, b.lerp(a, 0.2)]))


func _draw_window(r: Rect2, w: Dictionary) -> void:
	var decor: int = w.decor
	draw_glass(self, r, decor == Decor.LIT)
	var cc: Color = w.curtain
	match decor:
		Decor.CURTAINS, Decor.PLANT:
			var o: float = w.open
			var cw := r.size.x * o
			draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(cw, 0), r.position + Vector2(cw * 0.6, r.size.y), Vector2(r.position.x, r.end.y)]), cc)
			draw_colored_polygon(PackedVector2Array([Vector2(r.end.x - cw, r.position.y), Vector2(r.end.x, r.position.y), r.end, Vector2(r.end.x - cw * 0.6, r.end.y)]), cc)
			draw_line(r.position + Vector2(cw * 0.5, 2), r.position + Vector2(cw * 0.35, r.size.y - 2), cc.darkened(0.25), 1)
			draw_line(Vector2(r.end.x - cw * 0.5, r.position.y + 2), Vector2(r.end.x - cw * 0.35, r.end.y - 2), cc.darkened(0.25), 1)
			if decor == Decor.PLANT:
				var pc := Vector2(r.position.x + r.size.x * 0.5, r.end.y - 4)
				draw_rect(Rect2(pc - Vector2(4, 1), Vector2(8, 5)), Color("#b5651d"))
				draw_circle(pc + Vector2(-3, -4), 3.5, Color("#2e8b57"))
				draw_circle(pc + Vector2(3, -5), 3.5, Color("#3cb371"))
				draw_circle(pc + Vector2(0, -8), 3.5, Color("#2e8b57"))
		Decor.BLINDS, Decor.HALF_BLINDS:
			var depth := r.size.y if decor == Decor.BLINDS else r.size.y * 0.5
			draw_rect(Rect2(r.position, Vector2(r.size.x, depth)), Color("#ece6d6"))
			var y := r.position.y + 3
			while y < r.position.y + depth:
				draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("#b9b19c"), 1)
				y += 3.5
		Decor.CLOSED:
			draw_rect(r, cc)
			draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.end.y), cc.darkened(0.3), 1)
			for k in 3:
				var x := r.position.x + 4 + k * 4
				draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), cc.darkened(0.15), 1)
				draw_line(Vector2(r.end.x - 4 - k * 4, r.position.y), Vector2(r.end.x - 4 - k * 4, r.end.y), cc.darkened(0.15), 1)
		Decor.LIT:
			# A little lamp silhouette inside.
			var lc := Vector2(r.position.x + r.size.x * 0.7, r.end.y - 3)
			draw_line(lc, lc + Vector2(0, -10), Color(0.3, 0.2, 0.1), 1.5)
			draw_colored_polygon(PackedVector2Array([lc + Vector2(-5, -10), lc + Vector2(5, -10), lc + Vector2(3, -16), lc + Vector2(-3, -16)]), Color("#fff3c4"))
	if decor != Decor.CLOSED and decor != Decor.BLINDS:
		# Reflection streak.
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(3, r.size.y), r.position + Vector2(r.size.x * 0.45, 0),
			r.position + Vector2(r.size.x * 0.62, 0), r.position + Vector2(r.size.x * 0.2, r.size.y)]), Color(1, 1, 1, 0.13))
	draw_window_frame(self, r)


static func draw_broken_window(ci: CanvasItem, r: Rect2, blood: bool, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Dark room behind shattered glass.
	ci.draw_rect(r, Color("#14121a"))
	var c := r.get_center() + Vector2(rng.randf_range(-4, 4), rng.randf_range(-5, 3))
	# Remaining jagged glass around the edges.
	var glass := Color(0.65, 0.7, 1.0, 0.55)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		var mid := a.lerp(b, rng.randf_range(0.3, 0.7))
		var inward := a.lerp(c, rng.randf_range(0.35, 0.6))
		ci.draw_colored_polygon(PackedVector2Array([a, mid, inward]), glass)
		ci.draw_line(a, inward, Color(1, 1, 1, 0.6), 1.0)
	# Radiating cracks.
	for k in 7:
		var ang := rng.randf() * TAU
		var p := c
		for s in 3:
			var q := p + Vector2(cos(ang), sin(ang)) * rng.randf_range(4, 8)
			q.x = clampf(q.x, r.position.x, r.end.x)
			q.y = clampf(q.y, r.position.y, r.end.y)
			ci.draw_line(p, q, Color(0.9, 0.95, 1.0, 0.7), 1.0)
			p = q
			ang += rng.randf_range(-0.5, 0.5)
	if blood:
		var red := Color("#b3001b")
		for k in 9:
			var bp := c + Vector2(rng.randf_range(-11, 11), rng.randf_range(-12, 10))
			ci.draw_circle(bp, rng.randf_range(1.5, 4.5), red)
		for k in 4:
			var dx := r.position.x + rng.randf_range(3, r.size.x - 3)
			var drip := rng.randf_range(6, 14)
			ci.draw_line(Vector2(dx, c.y), Vector2(dx, minf(c.y + drip, r.end.y + 4)), red, 2.0)
			ci.draw_circle(Vector2(dx, minf(c.y + drip, r.end.y + 4)), 1.6, red)
	draw_window_frame(ci, r)
	if blood:
		# A limp bunny ear flopped over the sill.
		var ear := PackedVector2Array([Vector2(c.x - 3, r.end.y - 6), Vector2(c.x + 3, r.end.y - 6),
			Vector2(c.x + 5, r.end.y + 8), Vector2(c.x - 1, r.end.y + 9)])
		ci.draw_colored_polygon(ear, Color("#9e9488"))
		ci.draw_line(Vector2(c.x + 1, r.end.y - 4), Vector2(c.x + 2, r.end.y + 6), Color("#e8a0a8"), 2.0)
