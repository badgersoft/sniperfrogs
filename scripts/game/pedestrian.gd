extends Node2D
## A civilian going about their day on the pavement. Origin = feet.

const L := preload("res://scripts/game/layout.gd")

const SKINS := [Color("#f1c27d"), Color("#e0ac69"), Color("#c68642"), Color("#8d5524"), Color("#ffdbac")]
const SHIRTS := [Color("#e53935"), Color("#1e88e5"), Color("#43a047"), Color("#fdd835"), Color("#8e24aa"),
	Color("#fb8c00"), Color("#00acc1"), Color("#6d4c41"), Color("#eeeeee"), Color("#37474f")]
const PANTS := [Color("#263238"), Color("#3e2723"), Color("#1a237e"), Color("#455a64"), Color("#5d4037")]
const HAIR := [Color("#212121"), Color("#4e342e"), Color("#a1887f"), Color("#ffca28"), Color("#d84315"), Color("#9e9e9e")]
const UMBRELLAS := [Color("#d32f2f"), Color("#1976d2"), Color("#fbc02d"), Color("#212121"), Color("#7b1fa2")]

enum Extra { NONE, BRIEFCASE, BAG, HAT, UMBRELLA }

var dir := 1.0
var speed := 35.0
var alive := true
var skin := Color.WHITE
var shirt := Color.WHITE
var pants := Color.BLACK
var hair := Color.BLACK
var extra := Extra.NONE
var extra_color := Color.RED
var dress := false
var has_scarf := false
var scarf := Color.RED
var tall := 1.0
var flee_time := 0.0
var _t := 0.0
var _death_t := 0.0
var _pause := 0.0
var _rng: RandomNumberGenerator


func setup(x: float, rng: RandomNumberGenerator, storm: bool, snow := false) -> void:
	_rng = rng
	position = Vector2(x, rng.randf_range(L.SIDEWALK_TOP + 14, L.SIDEWALK_BOTTOM - 7))
	dir = -1.0 if rng.randf() < 0.5 else 1.0
	speed = rng.randf_range(24, 46)
	skin = SKINS[rng.randi() % SKINS.size()]
	shirt = SHIRTS[rng.randi() % SHIRTS.size()]
	pants = PANTS[rng.randi() % PANTS.size()]
	hair = HAIR[rng.randi() % HAIR.size()]
	dress = rng.randf() < 0.25
	tall = rng.randf_range(0.9, 1.1)
	_t = rng.randf() * 10.0
	if snow:
		# Wrapped up for winter: woolly hats and scarves.
		scarf = SHIRTS[rng.randi() % SHIRTS.size()]
		has_scarf = true
		extra = [Extra.HAT, Extra.HAT, Extra.BAG, Extra.BRIEFCASE][rng.randi() % 4]
		extra_color = SHIRTS[rng.randi() % SHIRTS.size()]
	elif storm and rng.randf() < 0.75:
		extra = Extra.UMBRELLA
		extra_color = UMBRELLAS[rng.randi() % UMBRELLAS.size()]
	else:
		extra = [Extra.NONE, Extra.NONE, Extra.BRIEFCASE, Extra.BAG, Extra.HAT][rng.randi() % 5]
		extra_color = SHIRTS[rng.randi() % SHIRTS.size()]


func hit_rect() -> Rect2:
	if not alive:
		return Rect2()
	var h := 40.0 * tall
	return Rect2(position.x - 7, position.y - h, 14, h)


func scare(from_x: float) -> void:
	if not alive:
		return
	flee_time = _rng.randf_range(3.0, 5.0)
	dir = 1.0 if position.x >= from_x else -1.0
	_pause = 0.0


func kill() -> void:
	alive = false
	_death_t = 0.0


func _process(delta: float) -> void:
	if not alive:
		_death_t += delta
		if _death_t < 2.5:
			queue_redraw()
		return
	_t += delta
	var v := speed
	if flee_time > 0.0:
		flee_time -= delta
		v = speed * 3.4
	elif _pause > 0.0:
		_pause -= delta
		v = 0.0
	elif _rng.randf() < delta * 0.04:
		_pause = _rng.randf_range(1.0, 3.5)   # stop to check their phone
	position.x += dir * v * delta
	if position.x < -40.0:
		position.x = L.WORLD_W + 30.0
	elif position.x > L.WORLD_W + 40.0:
		position.x = -30.0
	queue_redraw()


func _draw() -> void:
	if not alive:
		_draw_dead()
		return
	var moving := _pause <= 0.0 or flee_time > 0.0
	var rate := 9.0 if flee_time <= 0.0 else 18.0
	var swing := sin(_t * rate) * (0.55 if moving else 0.0)
	var h := tall
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	_shadow()
	var hip := Vector2(0, -15 * h)
	var shoulder := Vector2(0, -28 * h)
	var head := Vector2(1, -34 * h)
	# Legs.
	var leg := 15.0 * h
	draw_line(hip, hip + Vector2(sin(swing), cos(swing)) * leg, pants.darkened(0.2), 3.2)
	draw_line(hip, hip + Vector2(sin(-swing), cos(-swing)) * leg, pants, 3.2)
	for s in [swing, -swing]:
		var f: Vector2 = hip + Vector2(sin(s), cos(s)) * leg
		draw_line(f, f + Vector2(3, 0), Color("#1b1b1b"), 2.5)
	# Back arm.
	var arm := 11.0 * h
	var arm_a := -swing * 0.9
	if flee_time > 0.0:
		arm_a = PI * 0.85 + sin(_t * 20.0) * 0.2
	draw_line(shoulder, shoulder + Vector2(sin(arm_a), cos(arm_a)) * arm, shirt.darkened(0.3), 3.0)
	# Torso.
	if dress:
		draw_colored_polygon(PackedVector2Array([shoulder + Vector2(-4, 0), shoulder + Vector2(4, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)]), shirt)
	else:
		draw_rect(Rect2(shoulder.x - 4.5, shoulder.y - 1, 9, hip.y - shoulder.y + 3), shirt)
		draw_rect(Rect2(hip.x - 4.5, hip.y - 1, 9, 2), pants.darkened(0.3))
	if has_scarf:
		draw_rect(Rect2(shoulder.x - 4.5, shoulder.y - 2.5, 9, 3), scarf)
		draw_line(shoulder + Vector2(-3, 0), shoulder + Vector2(-6, 7), scarf, 2.0)
	# Front arm + accessory.
	var arm_b := swing * 0.9
	if flee_time > 0.0:
		arm_b = PI * 0.9 + sin(_t * 20.0 + 1.5) * 0.2
	var hand := shoulder + Vector2(sin(arm_b), cos(arm_b)) * arm
	if extra == Extra.UMBRELLA and flee_time <= 0.0:
		hand = shoulder + Vector2(5, 2)
	draw_line(shoulder, hand, shirt.darkened(0.1), 3.0)
	draw_circle(hand, 1.7, skin)
	match extra:
		Extra.BRIEFCASE:
			draw_rect(Rect2(hand.x - 4, hand.y + 1, 8, 6), Color("#4e342e"))
		Extra.BAG:
			draw_rect(Rect2(hand.x - 3, hand.y + 1, 7, 8), extra_color)
	# Head.
	draw_rect(Rect2(head.x - 1.5, head.y + 3, 3, 3), skin.darkened(0.1))
	draw_circle(head, 5.0, skin)
	draw_circle(head + Vector2(2.6, -0.5), 0.8, Color("#222"))
	draw_colored_polygon(PackedVector2Array([head + Vector2(-5.2, 0), head + Vector2(-4.8, -3.6), head + Vector2(0, -5.6),
		head + Vector2(4.6, -3.6), head + Vector2(5, -1.5), head + Vector2(1, -2.8), head + Vector2(-2, -1.5)]), hair)
	if dress:
		draw_line(head + Vector2(-4.5, -1), head + Vector2(-6, 7), hair, 2.5)
	if extra == Extra.HAT:
		draw_rect(Rect2(head.x - 7, head.y - 4, 14, 2), Color("#3e2723"))
		draw_rect(Rect2(head.x - 4.5, head.y - 9, 9, 5.5), Color("#3e2723"))
	elif extra == Extra.UMBRELLA and flee_time <= 0.0:
		var top := head + Vector2(3, -14)
		draw_line(hand, top, Color("#333"), 1.2)
		var pts := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			pts.append(top + Vector2(cos(a) * 14, sin(a) * 7 + 2))
		draw_colored_polygon(pts, extra_color)
		for i in 4:
			draw_line(top, top + Vector2(-14 + i * 9.3, 2), extra_color.darkened(0.3), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _shadow() -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a) * 8, sin(a) * 2))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.22))


func _draw_dead() -> void:
	var grow := clampf(_death_t / 2.2, 0.0, 1.0)
	# Pool of cartoon blood.
	var pool := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		var wob := 1.0 + 0.15 * sin(a * 3.0 + position.x)
		pool.append(Vector2(-22.0 * dir + cos(a) * 22 * grow * wob, 1 + sin(a) * 5 * grow * wob))
	if grow > 0.05:
		draw_colored_polygon(pool, Color("#a5001a"))
		draw_circle(Vector2(-30.0 * dir, 0), 2 * grow, Color(1, 1, 1, 0.25))
	# The body lying flat.
	var fall := clampf(_death_t / 0.25, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, -PI * 0.5 * fall * dir, Vector2(dir, 1.0))
	var h := tall
	draw_line(Vector2(0, -15 * h), Vector2(3, 0), pants, 3.2)
	draw_line(Vector2(0, -15 * h), Vector2(-3, 0), pants.darkened(0.2), 3.2)
	draw_rect(Rect2(-4.5, -29 * h, 9, 15 * h), shirt)
	draw_line(Vector2(0, -28 * h), Vector2(8, -36 * h), shirt.darkened(0.1), 3.0)
	draw_circle(Vector2(1, -34 * h), 5.0, skin)
	# Cartoon X eyes.
	var e := Vector2(3, -35 * h)
	draw_line(e + Vector2(-1.2, -1.2), e + Vector2(1.2, 1.2), Color("#222"), 0.9)
	draw_line(e + Vector2(1.2, -1.2), e + Vector2(-1.2, 1.2), Color("#222"), 0.9)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
