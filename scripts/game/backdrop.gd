extends Node2D
## Background layers: sky (screen-locked), drifting clouds, a distant skyline
## and a tree line. `kind` picks which layer this node paints. The game moves
## each layer horizontally according to its parallax factor.

const L := preload("res://scripts/game/layout.gd")

enum Kind { SKY, CLOUDS, SKYLINE, TREES }

var kind := Kind.SKY
var storm := false
var view_w := 1280.0
var parallax := 0.0
var _clouds: Array = []
var _rng := RandomNumberGenerator.new()
var _seed := 0


func setup(k: int, is_storm: bool, seed_value: int) -> void:
	kind = k
	storm = is_storm
	_seed = seed_value
	_rng.seed = seed_value
	match kind:
		Kind.SKY: parallax = 0.0
		Kind.CLOUDS: parallax = L.PARALLAX_CLOUDS
		Kind.SKYLINE: parallax = L.PARALLAX_SKYLINE
		Kind.TREES: parallax = L.PARALLAX_TREES
	if kind == Kind.CLOUDS:
		var n := 16 if storm else 6
		for i in n:
			_clouds.append(_make_cloud(_rng.randf_range(-300, 2600)))


func follow(cam_left: float, w: float) -> void:
	if w != view_w:
		view_w = w
		queue_redraw()
	position.x = cam_left * (1.0 - parallax)


func _process(delta: float) -> void:
	if kind != Kind.CLOUDS:
		set_process(false)
		return
	for c in _clouds:
		c.pos.x += c.speed * delta
		if c.pos.x > 2600 + view_w:
			c.merge(_make_cloud(-400), true)
	queue_redraw()


func _make_cloud(x: float) -> Dictionary:
	var puffs := []
	var n := _rng.randi_range(5, 8)
	var w := _rng.randf_range(90, 190) * (1.4 if storm else 1.0)
	for i in n:
		var t := float(i) / (n - 1)
		var r := _rng.randf_range(0.22, 0.34) * w * (1.0 - absf(t - 0.5) * 0.9)
		puffs.append(Vector3(t * w - w * 0.5, -r * _rng.randf_range(0.3, 0.8), r))
	var y := _rng.randf_range(40, 230) if not storm else _rng.randf_range(10, 200)
	return {"pos": Vector2(x, y), "puffs": puffs, "speed": _rng.randf_range(4, 14) * (2.2 if storm else 1.0),
		"shade": _rng.randf_range(0.0, 0.25)}


func _draw() -> void:
	if kind != Kind.CLOUDS:
		_rng.seed = _seed   # static layers must repaint identically
	match kind:
		Kind.SKY: _draw_sky()
		Kind.CLOUDS: _draw_clouds()
		Kind.SKYLINE: _draw_skyline()
		Kind.TREES: _draw_trees()


func _draw_sky() -> void:
	var top := Color("#2f7fe8") if not storm else Color("#3e4652")
	var mid := Color("#79b8ff") if not storm else Color("#5d6672")
	var hor := Color("#d6f0ff") if not storm else Color("#8a929c")
	var w := view_w + 4
	draw_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(w, 0), Vector2(w, 260), Vector2(-2, 260)]),
		PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(-2, 260), Vector2(w, 260), Vector2(w, L.PLAY_H), Vector2(-2, L.PLAY_H)]),
		PackedColorArray([mid, mid, hor, hor]))
	if not storm:
		var sun := Vector2(view_w * 0.84, 92)
		for k in 6:
			draw_circle(sun, 120.0 - k * 16.0, Color(1.0, 0.97, 0.75, 0.05))
		draw_circle(sun, 34, Color("#fff6c9"))
		draw_circle(sun, 28, Color("#fffbe6"))


func _draw_clouds() -> void:
	for c in _clouds:
		var base := Color(1, 1, 1) if not storm else Color(0.48, 0.5, 0.55)
		var shade := base.darkened(0.18 + c.shade)
		var p: Vector2 = c.pos
		for pf in c.puffs:
			draw_circle(p + Vector2(pf.x, pf.y + 6), pf.z, Color(shade, 0.95))
		for pf in c.puffs:
			draw_circle(p + Vector2(pf.x, pf.y), pf.z * 0.94, base)
		for pf in c.puffs:
			draw_circle(p + Vector2(pf.x - pf.z * 0.2, pf.y - pf.z * 0.25), pf.z * 0.45, Color(1, 1, 1, 0.25 if not storm else 0.06))


func _draw_skyline() -> void:
	var col := Color("#a7c7e3") if not storm else Color("#6f7782")
	var win := Color(1, 1, 1, 0.25) if not storm else Color(1.0, 0.9, 0.6, 0.25)
	var x := -50.0
	var limit := L.WORLD_W * parallax + 2600.0
	while x < limit:
		var w := _rng.randf_range(50, 120)
		var h := _rng.randf_range(120, 300)
		var r := Rect2(x, L.BASE_Y - h, w, h)
		draw_rect(r, col)
		if _rng.randf() < 0.3:
			draw_line(Vector2(x + w * 0.5, r.position.y), Vector2(x + w * 0.5, r.position.y - 30), col, 3)
		var wy := r.position.y + 10
		while wy < L.BASE_Y - 20:
			var wx := x + 8
			while wx < x + w - 10:
				if _rng.randf() < 0.5:
					draw_rect(Rect2(wx, wy, 5, 6), win)
				wx += 12
			wy += 16
		x += w + _rng.randf_range(-10, 30)


func _draw_trees() -> void:
	var limit := L.WORLD_W + 200.0
	# Grass bank at the base.
	draw_rect(Rect2(-100, L.BASE_Y - 30, limit + 200, 32), Color("#4f8f3a") if not storm else Color("#3d6a32"))
	var x := -80.0
	var greens := [Color("#2f7d32"), Color("#3f9a3c"), Color("#4caf50"), Color("#2a6b2c")]
	while x < limit:
		var h := _rng.randf_range(70, 125)
		var r := _rng.randf_range(24, 40)
		var base := Vector2(x, L.BASE_Y - 4)
		draw_rect(Rect2(base.x - 4, base.y - h * 0.55, 8, h * 0.55), Color("#5d4037"))
		var g: Color = greens[_rng.randi() % greens.size()]
		var top := base + Vector2(0, -h)
		draw_circle(top + Vector2(-r * 0.6, r * 0.55), r * 0.75, g.darkened(0.2))
		draw_circle(top + Vector2(r * 0.6, r * 0.55), r * 0.75, g.darkened(0.2))
		draw_circle(top + Vector2(0, r * 0.2), r, g)
		draw_circle(top + Vector2(-r * 0.3, -r * 0.1), r * 0.55, g.lightened(0.15))
		draw_circle(top + Vector2(r * 0.25, r * 0.6), r * 0.6, g.darkened(0.08))
		x += _rng.randf_range(34, 70)
