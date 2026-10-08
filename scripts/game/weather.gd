extends Node2D
## Screen-space weather: rain streaks, lightning bolts and the white flash.
## Lives on its own CanvasLayer above the world and below the scope/HUD.

const L := preload("res://scripts/game/layout.gd")

signal lightning_flashed

var storm := false
var view_size := Vector2(1280, 720)
var flash := 0.0              # 0..1, read by the game to brighten the world
var _drops: Array[Vector3] = []
var _bolt: Array = []         # list of PackedVector2Array segments
var _bolt_life := 0.0
var _next_strike := 8.0
var _rng := RandomNumberGenerator.new()


func setup(is_storm: bool) -> void:
	storm = is_storm
	_rng.randomize()
	_next_strike = _rng.randf_range(4.0, 9.0)
	if storm:
		for i in 260:
			_drops.append(Vector3(_rng.randf() * 1600.0, _rng.randf() * L.PLAY_H, _rng.randf_range(0.6, 1.0)))


func _process(delta: float) -> void:
	if not storm:
		set_process(false)
		return
	view_size = get_viewport().get_visible_rect().size
	for i in _drops.size():
		var d := _drops[i]
		d.y += 900.0 * d.z * delta
		d.x -= 160.0 * d.z * delta
		if d.y > L.PLAY_H:
			d.y -= L.PLAY_H + 20.0
			d.x = _rng.randf() * (view_size.x + 200.0)
		if d.x < -20.0:
			d.x += view_size.x + 200.0
		_drops[i] = d
	flash = maxf(0.0, flash - delta * 2.4)
	_bolt_life -= delta
	_next_strike -= delta
	if _next_strike <= 0.0:
		strike()
	queue_redraw()


## Fire a lightning strike now. Returns nothing; thunder follows shortly.
func strike(thunder_delay := -1.0) -> void:
	_next_strike = _rng.randf_range(7.0, 15.0)
	flash = 1.0
	_bolt_life = 0.35
	_make_bolt()
	lightning_flashed.emit()
	if thunder_delay < 0.0:
		thunder_delay = _rng.randf_range(0.1, 0.9)
	get_tree().create_timer(thunder_delay, false).timeout.connect(func():
		Sfx.play_varied("thunder", -1.0, 0.1))
	# Second flicker.
	get_tree().create_timer(0.12, false).timeout.connect(func(): flash = maxf(flash, 0.8))


func _make_bolt() -> void:
	_bolt.clear()
	var p := Vector2(_rng.randf_range(0.1, 0.9) * view_size.x, 0)
	var main := PackedVector2Array([p])
	var end_y := _rng.randf_range(220, 380)
	while p.y < end_y:
		p += Vector2(_rng.randf_range(-26, 26), _rng.randf_range(14, 30))
		main.append(p)
		if _rng.randf() < 0.18:
			var b := PackedVector2Array([p])
			var q := p
			for k in _rng.randi_range(3, 6):
				q += Vector2(_rng.randf_range(-30, 30), _rng.randf_range(10, 24))
				b.append(q)
			_bolt.append(b)
	_bolt.push_front(main)


func _draw() -> void:
	if not storm:
		return
	# Rain.
	var pts := PackedVector2Array()
	for d in _drops:
		pts.append(Vector2(d.x, d.y))
		pts.append(Vector2(d.x + 4.0 * d.z, d.y - 18.0 * d.z))
	if not pts.is_empty():
		draw_multiline(pts, Color(0.8, 0.85, 0.95, 0.35), 1.2)
	if _bolt_life > 0.0:
		var a := clampf(_bolt_life / 0.35, 0.0, 1.0)
		for i in _bolt.size():
			var w := 3.0 if i == 0 else 1.5
			draw_polyline(_bolt[i], Color(0.7, 0.75, 1.0, 0.35 * a), w * 4.0)
			draw_polyline(_bolt[i], Color(1, 1, 1, a), w)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(view_size.x, L.PLAY_H)), Color(0.9, 0.92, 1.0, flash * 0.45))
