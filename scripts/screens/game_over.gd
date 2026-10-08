extends Control
## Losing screen (limo destroyed / agent down) and the final victory screen.
## Offers a place on the Honourable Roll Call when the score qualifies.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const SpyRoom := preload("res://scripts/screens/spy_room.gd")
const Hud := preload("res://scripts/game/hud.gd")
const MainMenu := preload("res://scripts/screens/main_menu.gd")

var main: Node
var _box: VBoxContainer
var _name_edit: LineEdit
var _entry_row: Control


func _ready() -> void:
	UIKit.full_rect(self)
	add_child(UIKit.full_rect(SpyRoom.new()))
	var reason := GameState.game_over_reason
	var won := reason == "victory"
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.05, 0.02, 0.84) if won else Color(0.12, 0.0, 0.0, 0.84)
	add_child(UIKit.full_rect(shade))

	var center := CenterContainer.new()
	add_child(UIKit.full_rect(center))
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 620
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	panel.add_child(_box)

	var title := ""
	var sub := ""
	match reason:
		"victory":
			title = "MISSION ACCOMPLISHED"
			sub = "Every Bunny sniper has been eliminated. The world's rightful leaders are safe... for now."
		"frog":
			title = "AGENT DOWN"
			sub = "Bunny McWhurter's snipers got to you first. The President is on their own."
		_:
			title = "MISSION FAILED"
			sub = "The presidential limousine has been destroyed. The Bunnies have won this level."
	var t := UIKit.label(title, 50, UIKit.GOLD if won else UIKit.RED, UIKit.title_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 10)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_box.add_child(t)
	var s := UIKit.label(sub, 19, UIKit.TEXT_DIM)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size.x = 560
	_box.add_child(s)

	var info := UIKit.label("Reached level %d of %d" % [GameState.round_index + 1, GameState.ROUNDS.size()], 20, UIKit.TEXT)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(info)
	var sc := UIKit.label("FINAL SCORE  " + Hud._fmt(GameState.score), 38, UIKit.GOLD, UIKit.title_font())
	sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sc)

	if GameState.qualifies_for_roll_call(GameState.score):
		_build_entry()
	else:
		_show_roll_call(-1)

	Sfx.play("fanfare" if won else "lose", -3.0)


func _build_entry() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_entry_row = v
	_box.add_child(v)
	var l := UIKit.label("You've earned a place on the Honourable Roll Call!", 20, UIKit.GREEN)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Agent codename"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(300, 56)
	_name_edit.text_submitted.connect(func(_t): _submit())
	h.add_child(_name_edit)
	var b := UIKit.button("ENLIST", 160)
	b.pressed.connect(_submit)
	h.add_child(b)
	_name_edit.grab_focus.call_deferred()


func _submit() -> void:
	var rank := GameState.submit_highscore(_name_edit.text, GameState.score)
	_entry_row.queue_free()
	_show_roll_call(rank)


func _show_roll_call(highlight: int) -> void:
	var head := UIKit.label("HONOURABLE ROLL CALL", 24, UIKit.GOLD, UIKit.title_font())
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(head)
	var cc := CenterContainer.new()
	var grid := MainMenu.build_roll_call(highlight, 20)
	grid.custom_minimum_size.x = 380
	cc.add_child(grid)
	_box.add_child(cc)
	var back := UIKit.button("RETURN TO HQ", 320)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): main.goto("menu"))
	_box.add_child(back)
	back.grab_focus.call_deferred()
