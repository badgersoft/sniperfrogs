extends Control
## Victorious end-of-round screen. Collates the level's bounty and then
## drains the remaining seconds into the score at $500 each.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const SpyRoom := preload("res://scripts/screens/spy_room.gd")
const Hud := preload("res://scripts/game/hud.gd")

const TICK := 0.04

var main: Node
var _secs := 0
var _bonus := 0
var _time_val: Label
var _bonus_val: Label
var _score_val: Label
var _next: Button
var _acc := 0.0
var _tallying := false


func _ready() -> void:
	UIKit.full_rect(self)
	add_child(UIKit.full_rect(SpyRoom.new()))
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.04, 0.02, 0.82)
	add_child(UIKit.full_rect(shade))

	var r: Dictionary = GameState.last_round
	_secs = int(r.get("time_left", 0))

	var center := CenterContainer.new()
	add_child(UIKit.full_rect(center))
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 640
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var head := UIKit.label("LEVEL %d COMPLETE" % int(r.get("round", 1)), 46, UIKit.GREEN, UIKit.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var sub := UIKit.label("The President lives to govern another day.", 19, UIKit.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(_rule())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var kills := int(r.get("kills", 0))
	_row(grid, "Snipers eliminated  (%d x $10,000)" % kills, "+" + Hud._fmt(int(r.get("kill_points", 0))), UIKit.GREEN)
	var civ := int(r.get("civilians", 0))
	_row(grid, "Civilian casualties  (%d)" % civ, ("-" + Hud._fmt(int(r.get("penalty", 0)))) if civ > 0 else "0", UIKit.RED if civ > 0 else UIKit.TEXT)
	var boost := int(r.get("health_boost", 0))
	_row(grid, "Health carried forward", "%d%%" % int(r.get("health", 100)), UIKit.TEXT)
	if not GameState.is_last_round():
		_row(grid, "Field medic boost", "+%d%%  ->  %d%%" % [boost, GameState.health], UIKit.GREEN if boost > 0 else UIKit.TEXT)
	_row(grid, "Bullets remaining", str(int(r.get("bullets_left", 0))), UIKit.TEXT)
	_time_val = _row(grid, "Seconds left on the clock", "%ds" % _secs, UIKit.TEXT)
	_bonus_val = _row(grid, "Time bonus  ($500 / second)", "+0", UIKit.GOLD)
	v.add_child(_rule())
	var tot := HBoxContainer.new()
	var tl := UIKit.label("TOTAL SCORE", 30, UIKit.TEXT, UIKit.title_font())
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tot.add_child(tl)
	_score_val = UIKit.label(Hud._fmt(GameState.score), 36, UIKit.GOLD, UIKit.title_font())
	tot.add_child(_score_val)
	v.add_child(tot)

	_next = UIKit.button("FINAL DEBRIEF" if GameState.is_last_round() else "NEXT MISSION", 340)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.modulate.a = 0.0
	_next.disabled = true
	_next.pressed.connect(_on_next)
	v.add_child(_next)

	get_tree().create_timer(0.9).timeout.connect(func(): _tallying = true)


func _row(grid: GridContainer, text: String, value: String, col: Color) -> Label:
	grid.add_child(UIKit.label(text, 21, UIKit.TEXT_DIM))
	var l := UIKit.label(value, 22, col, UIKit.title_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(l)
	return l


func _rule() -> ColorRect:
	var c := ColorRect.new()
	c.custom_minimum_size.y = 2
	c.color = Color(UIKit.GREEN, 0.35)
	return c


func _process(delta: float) -> void:
	if not _tallying:
		return
	_acc += delta
	while _acc >= TICK and _secs > 0:
		_acc -= TICK
		_drain_one()
	if _secs <= 0:
		_finish_tally()


func _drain_one() -> void:
	_secs -= 1
	_bonus += GameState.TIME_BONUS_PER_SECOND
	GameState.add_score(GameState.TIME_BONUS_PER_SECOND)
	Sfx.play("tick", -12.0, 1.0 + (_bonus % 5000) / 20000.0)
	_refresh()


func _refresh() -> void:
	_time_val.text = "%ds" % _secs
	_bonus_val.text = "+" + Hud._fmt(_bonus)
	_score_val.text = Hud._fmt(GameState.score)


func _finish_tally() -> void:
	if not _tallying:
		return
	_tallying = false
	_refresh()
	Sfx.play("accept", -6.0)
	_next.disabled = false
	create_tween().tween_property(_next, "modulate:a", 1.0, 0.3)
	_next.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	# Click / tap anywhere to skip the count.
	if _tallying and ((event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)):
		while _secs > 0:
			_secs -= 1
			_bonus += GameState.TIME_BONUS_PER_SECOND
			GameState.add_score(GameState.TIME_BONUS_PER_SECOND)
		_finish_tally()


func _on_next() -> void:
	if GameState.is_last_round():
		GameState.game_over_reason = "victory"
		main.goto("game_over")
	else:
		GameState.round_index += 1
		main.goto("briefing")
