extends Control
## Front page: faded spy apartment, the title, the Honourable Roll Call and the
## Start / Instructions buttons.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const SpyRoom := preload("res://scripts/screens/spy_room.gd")

var main: Node
var _logo: Control


func _ready() -> void:
	UIKit.full_rect(self)
	add_child(UIKit.full_rect(SpyRoom.new()))

	# Fade the apartment so the UI reads cleanly.
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.03, 0.02, 0.7)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UIKit.full_rect(shade))

	var margin := MarginContainer.new()
	UIKit.full_rect(margin)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 36)
	margin.add_child(row)

	# ---- left column: title + buttons
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 14)
	row.add_child(left)

	_logo = Control.new()
	_logo.custom_minimum_size = Vector2(140, 140)
	_logo.draw.connect(_draw_logo)
	left.add_child(_logo)

	# Scale the title so title + roll call always fit (16:9 down to 4:3).
	var vw := get_viewport().get_visible_rect().size.x
	var title_size := int(clampf((vw - 80.0 - 36.0 - 430.0) / 8.4, 40.0, 76.0))
	var title := UIKit.label("SNIPER FROGS", title_size, UIKit.GREEN, UIKit.title_font())
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.03))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	left.add_child(title)

	var sub := UIKit.label("2027  ·  THE BUNNIES ARE BACK", 24, UIKit.GOLD, UIKit.title_font())
	left.add_child(sub)
	var tag := UIKit.label("Eliminate Bunny McWhurter's snipers before they eliminate the President.", 18, UIKit.TEXT_DIM)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = minf(520.0, vw - 560.0)
	left.add_child(tag)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	left.add_child(spacer)

	var start := UIKit.button("START GAME", 340)
	start.pressed.connect(_on_start)
	left.add_child(start)
	var instr := UIKit.button("INSTRUCTIONS", 340)
	instr.pressed.connect(func(): main.goto("instructions"))
	left.add_child(instr)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var quit := UIKit.button("QUIT", 340)
		quit.pressed.connect(func(): get_tree().quit())
		left.add_child(quit)
	for b in left.get_children():
		if b is Button:
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	start.grab_focus.call_deferred()

	# ---- right column: Honourable Roll Call
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(430, 0)
	row.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var head := UIKit.label("HONOURABLE ROLL CALL", 26, UIKit.GOLD, UIKit.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(UIKit.GOLD, 0.5)
	col.add_child(rule)
	for i in GameState.highscores.size():
		var e: Array = GameState.highscores[i]
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		var c := UIKit.GOLD if i == 0 else (UIKit.TEXT if i < 3 else UIKit.TEXT_DIM)
		var rank := UIKit.label("%2d." % (i + 1), 20, c, UIKit.mono_font())
		rank.custom_minimum_size.x = 40
		var nm := UIKit.label(str(e[0]), 20, c)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		var sc := UIKit.label(_fmt(int(e[1])), 20, c, UIKit.mono_font())
		r.add_child(rank)
		r.add_child(nm)
		r.add_child(sc)
		col.add_child(r)

	var footer := UIKit.label("A Badger-soft production  ·  remake of the 2006 original", 15, Color(1, 1, 1, 0.45))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.position -= Vector2(24, 12)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(footer)


func _process(_delta: float) -> void:
	_logo.queue_redraw()


func _draw_logo() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var c := Vector2(70, 72)
	UIKit.draw_frog_head(_logo, c + Vector2(0, sin(t * 2.0) * 3.0), 44)
	# Rotating reticle around the agent.
	var rc := Color(UIKit.RED, 0.9)
	_logo.draw_arc(c, 64, t * 0.6, t * 0.6 + TAU, 64, rc, 3, true)
	for k in 4:
		var a := t * 0.6 + k * PI * 0.5
		_logo.draw_line(c + Vector2(cos(a), sin(a)) * 56, c + Vector2(cos(a), sin(a)) * 72, rc, 3, true)


func _on_start() -> void:
	GameState.new_game()
	main.goto("briefing")


static func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
