extends Node2D
## Blizzard squall for snow levels: a dense wall of driven snow that sweeps
## across the play area from right to left, briefly hiding the street (and
## the scope, as this sits on a layer above it). Timing comes from the
## weather node's `squall` progress.

const L := preload("res://scripts/game/layout.gd")

const PEAK_ALPHA := 0.9       # how opaque the heart of the squall gets
const STREAKS := 220

var weather: Node2D
var _streaks: Array[Vector3] = []   # x offset in band (0..1), y, speed factor
var _puffs: Array[Vector3] = []     # x offset in band, y, radius
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for i in STREAKS:
		_streaks.append(Vector3(_rng.randf(), _rng.randf() * L.PLAY_H, _rng.randf_range(0.6, 1.4)))
	for i in 26:
		_puffs.append(Vector3(_rng.randf(), _rng.randf() * L.PLAY_H, _rng.randf_range(50, 130)))


func _process(_delta: float) -> void:
	queue_redraw()


## Opacity of the squall at a position across its band (0 = leading edge,
## 1 = trailing edge): soft edges, dense middle.
func _profile(u: float) -> float:
	if u < 0.0 or u > 1.0:
		return 0.0
	return pow(sin(PI * u), 0.7)


func _draw() -> void:
	if weather == null or weather.squall < 0.0:
		return
	var w := get_viewport().get_visible_rect().size.x
	var band := w * 1.1
	# The band's leading edge enters on the right and leaves off the left.
	var left := lerpf(w, -band, weather.squall)
	var t := Time.get_ticks_msec() / 1000.0

	# Fog wall, built from vertical slices so it fades in and out softly.
	var n := 32
	var white := Color(0.94, 0.96, 1.0)
	for i in n:
		var u0 := float(i) / n
		var u1 := float(i + 1) / n
		var x0 := left + u0 * band
		var x1 := left + u1 * band
		if x1 < 0.0 or x0 > w:
			continue
		var a0 := _profile(u0) * PEAK_ALPHA
		var a1 := _profile(u1) * PEAK_ALPHA
		draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, L.PLAY_H), Vector2(x0, L.PLAY_H)]),
			PackedColorArray([Color(white, a0), Color(white, a1), Color(white, a1), Color(white, a0)]))

	# Billowing clumps inside the wall.
	for p in _puffs:
		var u := fposmod(p.x + t * 0.05, 1.0)
		var a := _profile(u) * 0.35
		if a > 0.01:
			var y := p.y + sin(t * 1.3 + p.z) * 12.0
			draw_circle(Vector2(left + u * band, y), p.z, Color(1, 1, 1, a))

	# Driven snow streaks racing through it.
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for s in _streaks:
		var u := fposmod(s.x - t * 0.35 * s.z, 1.0)
		var a := _profile(u)
		if a < 0.05:
			continue
		var x := left + u * band
		var y := fposmod(s.y + t * 60.0 * s.z, L.PLAY_H)
		pts.append(Vector2(x, y))
		pts.append(Vector2(x + 26.0 * s.z, y - 6.0 * s.z))
		cols.append(Color(1, 1, 1, a * 0.8))
	if not pts.is_empty():
		draw_multiline_colors(pts, cols, 1.6)
