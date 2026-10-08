extends Node
## Root of the application: owns the current screen and handles fades between
## screens. Every screen is a plain script instanced in code.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const SCREENS := {
	"menu": preload("res://scripts/screens/main_menu.gd"),
	"instructions": preload("res://scripts/screens/instructions.gd"),
	"briefing": preload("res://scripts/screens/briefing.gd"),
	"game": preload("res://scripts/game/game.gd"),
	"round_end": preload("res://scripts/screens/round_end.gd"),
	"game_over": preload("res://scripts/screens/game_over.gd"),
}

var current: Node
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	get_tree().root.theme = UIKit.theme()
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_fade)
	_fade_layer.add_child(_fade)
	_swap("menu")
	_fade_in(0.6)


func goto(screen: String, fade_time := 0.35) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, fade_time)
	await tw.finished
	_swap(screen)
	_fade_in(fade_time)


func _swap(screen: String) -> void:
	get_tree().paused = false
	if current:
		current.queue_free()
		current = null
	current = SCREENS[screen].new()
	current.set("main", self)
	# Plain Nodes and CanvasLayers break theme inheritance, so hand the theme
	# to each top-level Control explicitly.
	if current is Control:
		current.theme = UIKit.theme()
	add_child(current)


func _fade_in(t: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, t)
	await tw.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
