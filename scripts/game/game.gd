extends Node
## One round of Sniper Frogs: builds the street, runs the clock, the bunny
## snipers' AI, the player's rifle, traffic, weather and the end-of-round
## sequences (victory, frog down, or the presidential limousine).

const L := preload("res://scripts/game/layout.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")
const Building := preload("res://scripts/game/building.gd")
const Bunny := preload("res://scripts/game/bunny.gd")
const Backdrop := preload("res://scripts/game/backdrop.gd")
const Street := preload("res://scripts/game/street.gd")
const Pedestrian := preload("res://scripts/game/pedestrian.gd")
const Car := preload("res://scripts/game/car.gd")
const Fx := preload("res://scripts/game/fx.gd")
const Weather := preload("res://scripts/game/weather.gd")
const Scope := preload("res://scripts/game/scope.gd")
const Hud := preload("res://scripts/game/hud.gd")
const Overlay := preload("res://scripts/game/overlay.gd")
const BlurShader := preload("res://shaders/snow_blur.gdshader")

enum State { INTRO, STARTING, PLAYING, WON, LIMO, DEAD, DONE }

const BUILDING_COUNT := 15
const EDGE_SCROLL_ZONE := 70.0
const EDGE_SCROLL_SPEED := 1100.0
const KEY_SCROLL_SPEED := 950.0
const INTRO_TIME := 4.5
const INTRO_FADE := 0.35          # intro card fade before play begins

var main: Node

# Public state read by the HUD.
var state := State.INTRO
var storm := false
var snow := false
var bullets := 15
var time_left := 90.0
var health := 100.0
var snipers_total := 0
var snipers_killed := 0
var cam_left := 0.0
var touch_mode := false
var fire_button_glow := 0.0
var bunnies: Array = []

var _cfg: Dictionary
var _rng := RandomNumberGenerator.new()
var _world: Node2D
var _cam: Camera2D
var _modulate: CanvasModulate
var _base_modulate := Color.WHITE
var _backdrops: Array = []
var _buildings: Array = []
var _bunny_root: Node2D
var _peds_root: Node2D
var _cars_root: Node2D
var _fx: Node2D
var _weather: Node2D
var _scope: Node2D
var _hud: Control
var _overlay: Control
var _blur: ColorRect

var _view_w := 1280.0
var _aim := Vector2(640, 300)
var _mouse_inside := true
var _aim_touch := -1
var _touch_last := Vector2.ZERO
var _shake := 0.0
var _car_timer := 2.0
var _bird_timer := 5.0
var _intro_t := INTRO_TIME
var _end_t := 0.0
var _civilians_hit := 0
var _penalty_total := 0
var _kill_points := 0

var _limo: Node2D
var _limo_phase := 0
var _limo_t := 0.0
var _limo_target := 0.0


# ================================================================ setup ===
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	_cfg = GameState.current_round()
	storm = _cfg.weather == GameState.Weather.STORM
	snow = _cfg.weather == GameState.Weather.SNOW
	bullets = GameState.BULLETS_PER_ROUND
	time_left = GameState.ROUND_TIME
	health = GameState.health
	snipers_total = _cfg.snipers
	GameState.round_start_score = GameState.score
	touch_mode = GameState.is_touch()

	# Hidden snipers live on a layer the main view does not render.
	get_viewport().canvas_cull_mask = L.LAYER_WORLD
	_view_w = get_viewport().get_visible_rect().size.x

	_build_world()
	_cam = Camera2D.new()
	_cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_cam)
	_cam.make_current()
	cam_left = (L.WORLD_W - _view_w) * 0.5
	_aim = Vector2(_view_w * 0.5, L.PLAY_H * 0.45)

	var wl := CanvasLayer.new()
	wl.layer = 5
	add_child(wl)
	_weather = Weather.new()
	_weather.setup(storm, snow)
	_weather.lightning_flashed.connect(func(): _shake = maxf(_shake, 0.15))
	wl.add_child(_weather)

	var sl := CanvasLayer.new()
	sl.layer = 10
	add_child(sl)
	_scope = Scope.new()
	sl.add_child(_scope)
	var dia: float = _view_w * GameState.SCOPE_DIAMETER_FRACTION
	if touch_mode:
		dia *= GameState.SCOPE_TOUCH_MULTIPLIER
	_scope.setup(get_viewport().world_2d, dia, GameState.SCOPE_MAGNIFICATION)
	# No scope until the level card has faded away.
	_scope.visible = false

	if snow:
		# Snow flurries blur the view (scope included) every so often.
		var bl := CanvasLayer.new()
		bl.layer = 15
		add_child(bl)
		_blur = ColorRect.new()
		_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = BlurShader
		_blur.material = mat
		_blur.visible = false
		bl.add_child(_blur)

	var hl := CanvasLayer.new()
	hl.layer = 20
	add_child(hl)
	_hud = Hud.new()
	_hud.game = self
	hl.add_child(_hud)

	var ol := CanvasLayer.new()
	ol.layer = 30
	add_child(ol)
	_overlay = Overlay.new()
	_overlay.theme = UIKit.theme()
	_overlay.game = self
	ol.add_child(_overlay)
	_overlay.show_intro(_cfg)
	_overlay.resume_pressed.connect(_set_paused.bind(false))
	_overlay.quit_pressed.connect(_abort_to_menu)

	if storm:
		Sfx.start_rain(-8.0)
	elif snow:
		Sfx.start_wind(-10.0)
	# Snow deadens every gunshot.
	Sfx.set_muffled(snow)
	_update_camera(0.0)


func _exit_tree() -> void:
	get_viewport().canvas_cull_mask = 0xFFFFFFFF
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_rain()
	Sfx.set_muffled(false)


func _build_world() -> void:
	_world = Node2D.new()
	_world.visibility_layer = L.LAYER_WORLD | L.LAYER_SCOPE_ONLY
	add_child(_world)

	_modulate = CanvasModulate.new()
	_base_modulate = Color(0.74, 0.77, 0.86) if storm else (Color(0.9, 0.93, 1.0) if snow else Color.WHITE)
	_modulate.color = _base_modulate
	_world.add_child(_modulate)

	var seed_base := _rng.randi()
	for k in [Backdrop.Kind.SKY, Backdrop.Kind.CLOUDS, Backdrop.Kind.SKYLINE, Backdrop.Kind.TREES]:
		var b := Backdrop.new()
		b.setup(k, storm, seed_base + k, snow)
		_world.add_child(b)
		_backdrops.append(b)

	var broot := Node2D.new()
	_world.add_child(broot)
	_generate_buildings(broot)

	_bunny_root = Node2D.new()
	_bunny_root.visibility_layer = L.LAYER_WORLD | L.LAYER_SCOPE_ONLY
	_world.add_child(_bunny_root)
	_place_bunnies()

	var street := Street.new()
	street.setup(storm, seed_base + 99, snow)
	_world.add_child(street)

	_peds_root = Node2D.new()
	_peds_root.y_sort_enabled = true
	_world.add_child(_peds_root)
	for i in (10 if storm else (12 if snow else 15)):
		var p := Pedestrian.new()
		p.setup(_rng.randf_range(0, L.WORLD_W), _rng, storm, snow)
		_peds_root.add_child(p)

	_cars_root = Node2D.new()
	_cars_root.y_sort_enabled = true
	_world.add_child(_cars_root)

	_fx = Fx.new()
	_world.add_child(_fx)


func _generate_buildings(root: Node2D) -> void:
	var cols: Array = []
	for i in BUILDING_COUNT:
		cols.append([2, 4, 6][i % 3])     # 5 small, 5 medium, 5 large
	_shuffle(cols)
	var widths: Array = []
	var total := 0.0
	for c in cols:
		var w: float = 2.0 * L.SIDE_MARGIN + c * L.WIN_W + (c - 1) * L.WIN_GAP
		widths.append(w)
		total += w
	var weights: Array = []
	var wsum := 0.0
	for i in BUILDING_COUNT + 1:
		var wt := _rng.randf_range(0.6, 1.4)
		weights.append(wt)
		wsum += wt
	var free := L.WORLD_W - total
	var signs: Array = Building.SIGNS.duplicate()
	_shuffle(signs)
	var x := 0.0
	for i in BUILDING_COUNT:
		x += free * weights[i] / wsum
		var b := Building.new()
		var sign_name := ""
		if cols[i] >= 4 and _rng.randf() < 0.75:
			sign_name = signs.pop_back()
		b.setup(x, cols[i], _rng.randi_range(4, 10), _rng, sign_name, storm or snow, snow)
		root.add_child(b)
		_buildings.append(b)
		x += widths[i]


func _place_bunnies() -> void:
	var order: Array = _buildings.duplicate()
	_shuffle(order)
	var used := {}
	for i in snipers_total:
		var b: Node2D = order[i % order.size()]
		var idx: int = _rng.randi() % b.window_count()
		while used.has([b.get_instance_id(), idx]):
			idx = _rng.randi() % b.window_count()
		used[[b.get_instance_id(), idx]] = true
		var bunny := Bunny.new()
		bunny.setup(b, idx, _cfg.training, _rng)
		bunny.snow = snow
		var iv := GameState.shot_interval()
		bunny.shot_timer = _rng.randf_range(iv.x * 0.6, iv.y * 0.75) + i * 1.8
		_bunny_root.add_child(bunny)
		bunnies.append(bunny)


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


# ================================================================= loop ===
func _process(delta: float) -> void:
	_view_w = get_viewport().get_visible_rect().size.x
	fire_button_glow = maxf(0.0, fire_button_glow - delta * 4.0)
	_handle_scrolling(delta)
	_update_camera(delta)
	_modulate.color = _base_modulate.lerp(Color(1.25, 1.25, 1.35), _weather.flash * 0.6)
	if _blur:
		var amt: float = _weather.blur
		_blur.visible = amt > 0.01
		if _blur.visible:
			_blur.size = Vector2(_view_w, L.PLAY_H)
			(_blur.material as ShaderMaterial).set_shader_parameter("amount", amt)

	match state:
		State.INTRO:
			_intro_t -= delta
			if _intro_t <= 0.0:
				_begin_play()
		State.PLAYING:
			time_left -= delta
			_update_bunnies(delta)
			if time_left <= 0.0:
				time_left = 0.0
				_start_limo()
		State.LIMO:
			_update_limo(delta)
		State.WON:
			_end_t -= delta
			if _end_t <= 0.0:
				_finish_round_won()
		State.DEAD:
			_end_t -= delta
			if _end_t <= 0.0:
				_game_over("frog")
	_update_traffic(delta)
	_update_ambience(delta)


func _handle_scrolling(delta: float) -> void:
	if state == State.LIMO or state == State.DEAD or state == State.DONE:
		return
	var v := Input.get_axis("scroll_left", "scroll_right") * KEY_SCROLL_SPEED
	var pointer_active := _mouse_inside if not touch_mode else _aim_touch >= 0
	if pointer_active:
		if _aim.x < EDGE_SCROLL_ZONE:
			v -= EDGE_SCROLL_SPEED * (1.0 - _aim.x / EDGE_SCROLL_ZONE)
		elif _aim.x > _view_w - EDGE_SCROLL_ZONE:
			v += EDGE_SCROLL_SPEED * (1.0 - (_view_w - _aim.x) / EDGE_SCROLL_ZONE)
	cam_left += v * delta


func _update_camera(delta: float) -> void:
	cam_left = clampf(cam_left, 0.0, maxf(0.0, L.WORLD_W - _view_w))
	_shake = maxf(0.0, _shake - delta * 2.0)
	var amp := _shake * _shake * 14.0
	var off := Vector2(_rng.randf_range(-amp, amp), _rng.randf_range(-amp, amp))
	_cam.position = Vector2(cam_left, 0)
	_cam.offset = off
	for b in _backdrops:
		b.follow(cam_left + off.x, _view_w)
	_aim.x = clampf(_aim.x, 0.0, _view_w)
	_aim.y = clampf(_aim.y, 0.0, L.PLAY_H - 4.0)
	_scope.aim = _aim
	_scope.update_scope(_aim_world(), delta)


func _aim_world() -> Vector2:
	return Vector2(cam_left, 0) + _cam.offset + _aim


func _begin_play() -> void:
	# Let the level card fade completely before the scope and clock appear.
	state = State.STARTING
	_overlay.hide_intro(INTRO_FADE)
	get_tree().create_timer(INTRO_FADE, false).timeout.connect(_go)


func _go() -> void:
	if state != State.STARTING:
		return
	state = State.PLAYING
	_scope.visible = true
	_apply_cursor()
	_overlay.banner("GO!", UIKit.GREEN, 0.9)
	Sfx.play("accept", -6.0)


## The OS cursor is hidden while the scope is the pointer.
func _apply_cursor() -> void:
	var hidden := not touch_mode and state != State.INTRO and state != State.STARTING
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE


# ============================================================ shooting ===
func _fire() -> void:
	if state == State.INTRO:
		_intro_t = 0.0
		return
	if state != State.PLAYING:
		return
	if bullets <= 0:
		Sfx.play("dry_fire", -2.0)
		_overlay.banner("OUT OF AMMO", UIKit.RED, 0.8, 34)
		return
	bullets -= 1
	Sfx.play_varied("rifle", 0.0, 0.03)
	_scope.recoil = 1.0
	_shake = maxf(_shake, 0.35)
	fire_button_glow = 1.0
	var wp := _aim_world()

	for p in _peds_root.get_children():
		if absf(p.position.x - wp.x) < 420.0:
			p.scare(wp.x)

	for b in bunnies:
		if b.alive and b.world_rect().grow(3.0).has_point(wp):
			_kill_bunny(b)
			return
	# Front-most pedestrians (largest y) first.
	var peds := _peds_root.get_children()
	peds.sort_custom(func(a, b): return a.position.y > b.position.y)
	for p in peds:
		if p.alive and p.hit_rect().grow(2.0).has_point(wp):
			_kill_pedestrian(p)
			return
	for c in _cars_root.get_children():
		if c.hit_rect().has_point(wp):
			_fx.sparks(wp, 14)
			Sfx.play_varied("ping", -6.0, 0.1)
			return
	for b in _buildings:
		if b.world_rect().has_point(wp):
			var wi: int = b.window_at(wp, 0.0)
			if wi >= 0:
				b.break_window(wi, false)
				_fx.glass(wp, 12)
				Sfx.play_varied("glass", -7.0)
			else:
				b.add_hole(wp)
				_fx.sparks(wp, 6)
			return
	_fx.dust(wp, 10)


func _kill_bunny(b: Node2D) -> void:
	b.alive = false
	b.visible = false
	b.building.break_window(b.window_index, true)
	var c: Vector2 = b.world_rect().get_center()
	_fx.blood(c, 34)
	_fx.glass(c, 20)
	_fx.popup(c - Vector2(0, 26), "+" + Hud._fmt(GameState.POINTS_PER_BUNNY), UIKit.GOLD, 26)
	Sfx.play("glass", -3.0)
	Sfx.play("splat", -2.0)
	snipers_killed += 1
	_kill_points += GameState.POINTS_PER_BUNNY
	GameState.add_score(GameState.POINTS_PER_BUNNY)
	if snipers_killed >= snipers_total:
		state = State.WON
		_end_t = 2.6
		_overlay.banner("ALL SNIPERS ELIMINATED!", UIKit.GOLD, 2.2, 52)
		get_tree().create_timer(0.5, false).timeout.connect(func(): Sfx.play("fanfare", -3.0))
	else:
		var left := snipers_total - snipers_killed
		_overlay.banner("SNIPER DOWN  ·  %d LEFT" % left, UIKit.GREEN, 1.2, 34)


func _kill_pedestrian(p: Node2D) -> void:
	p.kill()
	var penalty := _rng.randi_range(GameState.CIVILIAN_PENALTY_MIN, GameState.CIVILIAN_PENALTY_MAX)
	_civilians_hit += 1
	_penalty_total += penalty
	GameState.add_score(-penalty)
	_fx.blood(p.position + Vector2(0, -22), 24)
	_fx.popup(p.position + Vector2(0, -52), "-" + Hud._fmt(penalty), UIKit.RED, 22)
	Sfx.play("splat", -2.0)
	Sfx.play_varied("scream", -6.0, 0.15)
	_overlay.banner("CIVILIAN HIT!", UIKit.RED, 1.0, 34)


# ========================================================== bunny AI ===
func _update_bunnies(delta: float) -> void:
	for b in bunnies:
		if not b.alive:
			continue
		b.shot_timer -= delta
		b.aiming = b.shot_timer < 1.3
		if b.shot_timer <= 0.0:
			var iv := GameState.shot_interval()
			b.shot_timer = _rng.randf_range(iv.x, iv.y)
			_bunny_fires(b)


func _bunny_fires(b: Node2D) -> void:
	# In a storm a smart bunny times the shot with the lightning, hiding
	# both the muzzle flash and the report.
	var masked := storm and _rng.randf() < 0.5
	var muzzle: Vector2 = b.position + Vector2(L.WIN_W * 0.85, L.WIN_H * 0.62)
	if masked:
		_weather.strike(0.03)
	_fx.muzzle_flash(muzzle, 0.35 if masked else 1.0)
	b.flash = 1.0
	Sfx.play_at("bunny_shot", muzzle, -16.0 if masked else 0.0, _rng.randf_range(0.95, 1.05))
	if not masked:
		var screen_x: float = muzzle.x - cam_left
		if screen_x < 0.0:
			_overlay.edge_flash(-1)
		elif screen_x > _view_w:
			_overlay.edge_flash(1)
	var hit := _rng.randf() >= float(GameState.MISS_CHANCE[b.training])
	get_tree().create_timer(0.14, false).timeout.connect(_resolve_incoming.bind(hit))


func _resolve_incoming(hit: bool) -> void:
	if state != State.PLAYING:
		return
	if not hit:
		Sfx.play_varied("whiz", -4.0, 0.15)
		return
	var dmg: int = GameState.HIT_DAMAGE[_rng.randi() % GameState.HIT_DAMAGE.size()]
	health = maxf(0.0, health - dmg)
	Sfx.play("player_hit", 0.0)
	_shake = 1.0
	_hud.hit_flash = 1.0
	_overlay.damage(dmg)
	if health <= 0.0:
		state = State.DEAD
		_end_t = 3.2
		_overlay.agent_down()
		Sfx.play("lose", -2.0)
		_scope.visible = false


# ============================================================== limo ===
func _start_limo() -> void:
	state = State.LIMO
	_limo_phase = 0
	_limo_t = 0.0
	_scope.visible = false
	_overlay.banner("TIME'S UP!", UIKit.RED, 2.0, 56)
	# Clear the far lane so the motorcade has the road to itself.
	for c in _cars_root.get_children():
		if c.dir > 0:
			c.queue_free()
	_limo = Car.new()
	_limo.setup(Car.Kind.LIMO, 1.0, _rng)
	_limo.position.x = cam_left - 180.0
	_limo.snow = snow
	_limo.speed = 280.0
	_cars_root.add_child(_limo)
	_limo_target = cam_left + _view_w * 0.5
	Sfx.play("engine", -4.0)


func _update_limo(delta: float) -> void:
	_limo_t += delta
	match _limo_phase:
		0:
			# Ease to a halt in the middle of the screen.
			var dist := _limo_target - _limo.position.x
			_limo.speed = clampf(dist * 2.2, 40.0, 280.0)
			if dist <= 4.0:
				_limo.stopped = true
				_limo_phase = 1
				_limo_t = 0.0
		1:
			if _limo_t > 0.7:
				# The fatal shot - from one of the surviving snipers.
				var shooter: Node2D = null
				for b in bunnies:
					if b.alive:
						shooter = b
						break
				if shooter:
					var mz: Vector2 = shooter.position + Vector2(L.WIN_W * 0.85, L.WIN_H * 0.62)
					_fx.muzzle_flash(mz, 1.4)
					shooter.flash = 1.0
				Sfx.play("rifle", 2.0, 0.82)
				_limo_phase = 2
				_limo_t = 0.0
		2:
			if _limo_t > 0.35:
				_fx.explosion(_limo.position + Vector2(0, -20))
				_limo.wrecked = true
				_shake = 1.6
				Sfx.play("explosion", 2.0)
				for p in _peds_root.get_children():
					p.scare(_limo.position.x)
				_overlay.president_down()
				_limo_phase = 3
				_limo_t = 0.0
		3:
			if _limo_t > 5.0:
				_game_over("limo")


# ============================================================ traffic ===
func _update_traffic(delta: float) -> void:
	for c in _cars_root.get_children():
		if c == _limo:
			continue
		if c.position.x < -300.0 or c.position.x > L.WORLD_W + 300.0 \
				or absf(c.position.x - (cam_left + _view_w * 0.5)) > _view_w * 2.5:
			c.queue_free()
	if state != State.PLAYING and state != State.INTRO and state != State.STARTING:
		return
	_car_timer -= delta
	if _car_timer > 0.0:
		return
	_car_timer = _rng.randf_range(4.0, 10.0)
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := cam_left - 140.0 if dir > 0 else cam_left + _view_w + 140.0
	for c in _cars_root.get_children():
		if c.dir == dir and absf(c.position.x - x) < 260.0:
			return
	var car := Car.new()
	car.setup([Car.Kind.SEDAN, Car.Kind.HATCH, Car.Kind.VAN, Car.Kind.TAXI][_rng.randi() % 4], dir, _rng)
	car.position.x = x
	car.snow = snow
	_cars_root.add_child(car)


func _update_ambience(delta: float) -> void:
	if storm or snow or state == State.LIMO:
		return
	_bird_timer -= delta
	if _bird_timer <= 0.0:
		_bird_timer = _rng.randf_range(6.0, 15.0)
		Sfx.play_varied("chirp", -20.0, 0.2)


# ========================================================== round end ===
func _finish_round_won() -> void:
	GameState.health = int(health)
	var boost := GameState.apply_health_boost()
	GameState.last_round = {
		"round": GameState.round_index + 1,
		"snipers": snipers_total,
		"kills": snipers_killed,
		"kill_points": _kill_points,
		"civilians": _civilians_hit,
		"penalty": _penalty_total,
		"time_left": int(ceil(time_left)),
		"bullets_left": bullets,
		"health": int(health),
		"health_boost": boost,
	}
	state = State.DONE    # freeze while fading out
	main.goto("round_end", 0.6)


func _game_over(reason: String) -> void:
	state = State.DONE
	GameState.game_over_reason = reason
	GameState.last_round = {
		"round": GameState.round_index + 1,
		"snipers": snipers_total,
		"kills": snipers_killed,
		"civilians": _civilians_hit,
		"penalty": _penalty_total,
	}
	main.goto("game_over", 0.8)


func _abort_to_menu() -> void:
	_set_paused(false)
	main.goto("menu")


# ============================================================== input ===
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return
	if get_tree().paused:
		return

	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if touch_mode:
			touch_mode = false
			_apply_cursor()
		_mouse_inside = true
		_aim = event.position
	elif event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if _hud.pause_rect().has_point(event.position):
					_set_paused(true)
				else:
					_fire()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				cam_left -= 140.0
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				cam_left += 140.0
	elif event is InputEventScreenTouch:
		touch_mode = true
		if event.pressed:
			if _hud.pause_rect().grow(8.0).has_point(event.position):
				_set_paused(true)
			elif event.position.distance_to(_hud.fire_center()) < _hud.fire_radius() * 1.2:
				_fire()
			elif _aim_touch < 0:
				# Steer like a trackpad: the scope moves with the finger's
				# motion so the finger never hides the target.
				_aim_touch = event.index
				_touch_last = event.position
		elif event.index == _aim_touch:
			_aim_touch = -1
	elif event is InputEventScreenDrag and event.index == _aim_touch:
		_aim += (event.position - _touch_last) * 1.1
		_touch_last = event.position
	elif event.is_action_pressed("fire"):
		_fire()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			_mouse_inside = false
		NOTIFICATION_WM_MOUSE_ENTER:
			_mouse_inside = true
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if is_inside_tree() and state in [State.PLAYING, State.INTRO, State.STARTING]:
				_set_paused(true)


func _set_paused(p: bool) -> void:
	if p and not (state in [State.PLAYING, State.INTRO, State.STARTING]):
		return
	get_tree().paused = p
	_overlay.show_pause(p)
	if p:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_apply_cursor()
