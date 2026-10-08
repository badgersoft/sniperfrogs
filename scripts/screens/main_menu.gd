extends Control
## Front page: faded spy apartment, the title, the Honourable Roll Call and the
## Start / Instructions buttons.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const SpyRoom := preload("res://scripts/screens/spy_room.gd")

const ROLL_CALL_WIDTH := 400.0

var main: Node


func _ready() -> void:
	UIKit.full_rect(self)
	add_child(UIKit.full_rect(SpyRoom.new()))

	# Fade the apartment so the UI reads cleanly.
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.03, 0.64)
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

	# Title block: the subtitle centres under the title because both share
	# a box that shrinks to the title's width.
	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title_block.add_theme_constant_override("separation", 4)
	left.add_child(title_block)

	# Scale the title to the space left beside the roll call (16:9 to 4:3).
	var vw := get_viewport().get_visible_rect().size.x
	var avail := vw - 80.0 - 36.0 - ROLL_CALL_WIDTH - 10.0
	var per_px := UIKit.title_font().get_string_size("SNIPER FROGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x / 100.0
	var title_size := int(clampf(avail / per_px, 44.0, 95.0))
	var title := UIKit.label("SNIPER FROGS", title_size, UIKit.GREEN, UIKit.title_font())
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.03))
	# Soft green glow instead of a hard drop shadow.
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 22)
	title.add_theme_color_override("font_shadow_color", Color(UIKit.GREEN, 0.38))
	title_block.add_child(title)

	var sub := UIKit.label("2027  ·  THE BUNNIES ARE BACK", 26, UIKit.GOLD, UIKit.title_font())
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_block.add_child(sub)

	var tag := UIKit.label("Eliminate Bunny McWhurter's snipers before they eliminate the President.", 18, UIKit.TEXT_DIM)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = minf(560.0, avail)
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

	# ---- right column: Honourable Roll Call (top 5, translucent)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(ROLL_CALL_WIDTH, 0)
	var box := UIKit.panel_box(0.38)
	box.border_color = Color(UIKit.GOLD, 0.35)
	box.shadow_size = 8
	box.shadow_color = Color(0, 0, 0, 0.25)
	panel.add_theme_stylebox_override("panel", box)
	row.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head := UIKit.label("HONOURABLE ROLL CALL", 26, UIKit.GOLD, UIKit.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(UIKit.GOLD, 0.45)
	col.add_child(rule)
	col.add_child(build_roll_call(-1, 22))

	var footer := UIKit.label("A Badger-soft production  ·  remake of the 2006 original", 15, Color(1, 1, 1, 0.45))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.position -= Vector2(24, 12)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(footer)

	var version := UIKit.label("Version " + GameState.VERSION, 15, Color(1, 1, 1, 0.45))
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	version.position += Vector2(24, -12)
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(version)


## Rank / name / score table. One font and a grid keep every row's baseline
## and columns aligned. Shared with the game-over screen.
static func build_roll_call(highlight: int, font_size: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 8)
	var font := UIKit.body_font()
	for i in GameState.highscores.size():
		var e: Array = GameState.highscores[i]
		var c := UIKit.GOLD if i == 0 or i == highlight else (UIKit.TEXT if i < 3 else UIKit.TEXT_DIM)
		var rank := UIKit.label("%d." % (i + 1), font_size, c, font)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rank.custom_minimum_size.x = font_size * 1.4
		var nm := UIKit.label(str(e[0]), font_size, c, font)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		var sc := UIKit.label(_fmt(int(e[1])), font_size, c, font)
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sc.custom_minimum_size.x = font_size * 5.0
		for l in [rank, nm, sc]:
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			grid.add_child(l)
	return grid


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
