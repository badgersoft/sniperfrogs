extends Control
## Instructions splash: the synopsis, how to play and the controls.

const UIKit := preload("res://scripts/ui/ui_kit.gd")
const SpyRoom := preload("res://scripts/screens/spy_room.gd")

var main: Node

const SYNOPSIS := "The year is 2027 and the Bunnies are back.\n\nThe Sniper Frogs are a secret underground organisation whose sole purpose is to protect the world's rightful leaders from assassination. Rumour has it that Bunny McWhurter, the notorious underground gangster from 2006, has come out of hiding - bought by some of the world's most nefarious bad guys to take out the last few good people left in positions of power.\n\nThe Sniper Frogs have one task: eliminate the Bunny snipers before they eliminate the President and his allies."

const HOW_TO := [
	["Find them", "Bunny snipers hide behind ordinary-looking windows. They only show up through your scope - sweep it across the buildings to spot them."],
	["Watch for flashes", "When a bunny takes a shot there's a muzzle flash at their window. In storms, thunder and lightning can hide it."],
	["Take the shot", "15 bullets, 90 seconds. Each bunny is worth 10,000 points. Hitting a civilian costs you 1,000 - 5,000."],
	["Stay alive", "Bunnies shoot back. Each hit costs around 25% health, and your health carries over from level to level. Every 3 levels a field medic restores 25% of what you have left. Better-trained bunnies miss less often."],
	["Save the President", "If time runs out, the presidential limousine arrives... and you've failed. Clear the level early for 500 points per second left. Survive all 13 levels to win."],
]


func _ready() -> void:
	UIKit.full_rect(self)
	add_child(UIKit.full_rect(SpyRoom.new()))
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.03, 0.02, 0.8)
	add_child(UIKit.full_rect(shade))

	var margin := MarginContainer.new()
	UIKit.full_rect(margin)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)
	var title := UIKit.label("MISSION DOSSIER", 52, UIKit.GREEN, UIKit.title_font())
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.03))
	outer.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 28)
	scroll.add_child(cols)

	var left := PanelContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	cols.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	left.add_child(lv)
	lv.add_child(UIKit.label("CLASSIFIED BRIEFING", 24, UIKit.GOLD, UIKit.title_font()))
	var syn := UIKit.label(SYNOPSIS, 19, UIKit.TEXT)
	syn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	syn.custom_minimum_size.x = 380
	lv.add_child(syn)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.3
	cols.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 10)
	right.add_child(rv)
	rv.add_child(UIKit.label("HOW TO PLAY", 24, UIKit.GOLD, UIKit.title_font()))
	for item in HOW_TO:
		var h := UIKit.label("▸ " + item[0], 20, UIKit.GREEN, UIKit.title_font())
		rv.add_child(h)
		var body := UIKit.label(item[1], 17, UIKit.TEXT_DIM)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = 420
		rv.add_child(body)
	rv.add_child(UIKit.label("CONTROLS", 22, UIKit.GOLD, UIKit.title_font()))
	var ctl := UIKit.label(
		"PC: move the mouse to aim, left-click (or Space) to fire. Push the scope to the screen edge, use A/D, arrow keys or the mouse wheel to scroll. Esc / P pauses.\n" +
		"Mobile: drag a finger anywhere to steer the scope like a trackpad (so your finger never hides the target) and tap the FIRE button. Steer the scope to the screen edge to scroll.", 17, UIKit.TEXT_DIM)
	ctl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ctl.custom_minimum_size.x = 420
	rv.add_child(ctl)

	var back := UIKit.button("BACK TO HQ", 300)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): main.goto("menu"))
	outer.add_child(back)
	back.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		main.goto("menu")
