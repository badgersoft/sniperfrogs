extends Control
## Spy-movie terminal briefing shown before every round.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const CRT := preload("res://shaders/crt.gdshader")

const CHAR_TIME := 0.032
const FONT_SIZE := 26

var main: Node
var _lines: Array[String] = []
var _typing := ""
var _cursor_on := true
var _waiting_answer := false
var _answered := false
var _hint := "[ click or press FIRE to skip ]"
var _skipped := false
var _aborted := false
var _rng := RandomNumberGenerator.new()
var _t := 0.0


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var crt := ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = CRT
	crt.material = mat
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UIKit.full_rect(crt))
	_run()


func _process(delta: float) -> void:
	_t += delta
	_cursor_on = fmod(_t, 0.9) < 0.5
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.025, 0.015))
	var font := UIKit.mono_font()
	var line_h := FONT_SIZE * 1.45
	var x := 60.0
	var top := 70.0
	# Header bar.
	var r := GameState.round_index + 1
	draw_string(font, Vector2(x, 38), "frog@hq:~$ secure_link --round %d/%d" % [r, GameState.ROUNDS.size()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(UIKit.TERMINAL, 0.45))
	draw_line(Vector2(x, 50), Vector2(size.x - x, 50), Color(UIKit.TERMINAL, 0.2), 1)

	var max_lines := int((size.y - top - 80) / line_h)
	var all: Array[String] = _lines.duplicate()
	all.append(_typing)
	var start := maxi(0, all.size() - max_lines)
	var y := top + FONT_SIZE
	for i in range(start, all.size()):
		var txt: String = all[i]
		var pos := Vector2(x, y)
		# Phosphor glow.
		draw_string(font, pos + Vector2(0, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(UIKit.TERMINAL, 0.25))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, UIKit.TERMINAL)
		if i == all.size() - 1 and _cursor_on:
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
			draw_rect(Rect2(pos + Vector2(w + 4, -FONT_SIZE * 0.8), Vector2(FONT_SIZE * 0.55, FONT_SIZE)), UIKit.TERMINAL)
		y += line_h
	if _hint != "" and fmod(_t, 1.2) < 0.8:
		var hs := font.get_string_size(_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, Vector2((size.x - hs.x) * 0.5, size.y - 40), _hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UIKit.TERMINAL, 0.6))


func _gui_input(event: InputEvent) -> void:
	# Click / tap / FIRE at any point (including the Y/N prompt) deploys
	# straight into the round.
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		accept_event()
		_skip()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		_skip()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _waiting_answer and (event.keycode == KEY_N or event.keycode == KEY_ESCAPE):
			_answer(false)
		elif event.keycode in [KEY_Y, KEY_ENTER, KEY_KP_ENTER]:
			_skip()


## Deploy immediately, whatever point the briefing has reached.
func _skip() -> void:
	if _skipped or _aborted:
		return
	_skipped = true
	_hint = ""
	if _waiting_answer:
		_typing += "Y"
	_commit()
	_typing = "...connection terminated."
	Sfx.play("accept", -4.0)
	main.goto("game", 0.4)


func _answer(yes: bool) -> void:
	if _answered:
		return
	_answered = true
	_aborted = not yes
	_waiting_answer = false
	_hint = ""
	_typing += "Y" if yes else "N"
	Sfx.play("accept" if yes else "beep", -4.0)


## Awaits `t` seconds; returns false if this screen was freed meanwhile.
func _wait(t: float) -> bool:
	await get_tree().create_timer(t).timeout
	return is_inside_tree() and not _skipped


func _type_line(text: String) -> bool:
	_typing = ""
	for i in text.length():
		_typing += text[i]
		if text[i] != " " and i % 2 == 0:
			Sfx.play_varied("type", -10.0, 0.15)
		if not await _wait(CHAR_TIME * _rng.randf_range(0.6, 1.5)):
			return false
	return true


func _commit() -> void:
	_lines.append(_typing)
	_typing = ""


func _run() -> void:
	var cfg := GameState.current_round()
	var n: int = cfg.snipers
	var trained: String = {
		GameState.Training.LOW: "low-level trained",
		GameState.Training.MEDIUM: "medium trained",
		GameState.Training.HIGH: "highly trained",
	}[cfg.training]
	var weather := "good. Clear skies." if cfg.weather == GameState.Weather.CLEAR else "bad. Storms and lightning."

	# Idle blinking cursor before the link wakes up.
	if not await _wait(2.4):
		return
	var script_lines := [
		"...Operation initiated.",
		"...Protect the president.",
		"...%d %s believed to be in location." % [n, "Sniper" if n == 1 else "Snipers"],
		"...They are %s." % trained,
		"...The weather is %s" % weather,
	]
	for l in script_lines:
		if not await _type_line(l):
			return
		_commit()
		if not await _wait(0.45):
			return
	if not await _type_line("...Deploy frog asset Y/N? "):
		return
	_hint = "[ click or press FIRE to deploy  -  N to abort ]"
	_waiting_answer = true
	while not _answered:
		if not await _wait(0.05):
			return
	# Only "N" gets here - accepting goes through _skip().
	_commit()
	if not await _wait(0.4):
		return
	if not await _type_line("...Mission aborted. Returning to HQ."):
		return
	_commit()
	if await _wait(1.0):
		main.goto("menu")
