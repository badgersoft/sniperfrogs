extends Node2D
## The sniper scope. A small SubViewport shares the game's World2D and renders
## the area under the reticle through its own zoomed Camera2D. Its canvas cull
## mask also includes the scope-only layer, which is what reveals the hidden
## Bunny snipers. The texture is cropped to a circle by a shader and the
## reticle is drawn on top.

const L := preload("res://scripts/game/layout.gd")
const ScopeShader := preload("res://shaders/scope.gdshader")

var diameter := 52.0
var magnification := 1.8
var aim := Vector2(640, 300)          # screen-space centre of the scope
var recoil := 0.0

var _sub: SubViewport
var _cam: Camera2D
var _lens: Sprite2D
var _reticle: Node2D
var _px_scale := 1.0


func setup(world: World2D, dia: float, mag: float) -> void:
	diameter = dia
	magnification = mag
	_sub = SubViewport.new()
	_sub.world_2d = world
	_sub.canvas_cull_mask = L.LAYER_WORLD | L.LAYER_SCOPE_ONLY
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub.disable_3d = true
	_sub.handle_input_locally = false
	_sub.gui_disable_input = true
	add_child(_sub)
	_cam = Camera2D.new()
	_cam.ignore_rotation = true
	_sub.add_child(_cam)
	_cam.make_current()

	_lens = Sprite2D.new()
	_lens.texture = _sub.get_texture()
	var mat := ShaderMaterial.new()
	mat.shader = ScopeShader
	_lens.material = mat
	add_child(_lens)

	_reticle = Node2D.new()
	_reticle.draw.connect(_draw_reticle)
	add_child(_reticle)
	_resize()


func _resize() -> void:
	# Render the lens at physical resolution so it stays crisp when stretched.
	var s := get_viewport().get_final_transform().get_scale()
	_px_scale = maxf(1.0, maxf(s.x, s.y))
	var n := int(ceil(diameter * _px_scale))
	_sub.size = Vector2i(n, n)
	_lens.scale = Vector2.ONE * (diameter / float(n))
	_cam.zoom = Vector2.ONE * (float(n) / (diameter / magnification))


## world_point: the world position under the reticle centre.
func update_scope(world_point: Vector2, delta: float) -> void:
	recoil = maxf(0.0, recoil - delta * 4.0)
	var s := get_viewport().get_final_transform().get_scale()
	if not is_equal_approx(maxf(1.0, maxf(s.x, s.y)), _px_scale):
		_resize()
	position = aim + Vector2(0, -recoil * 18.0)
	_cam.position = world_point + Vector2(0, -recoil * 18.0 / magnification)
	_reticle.queue_redraw()


func _draw_reticle() -> void:
	var r := diameter * 0.5
	var ink := Color(0.02, 0.02, 0.03, 0.95)
	var lw := maxf(1.0, diameter / 52.0)
	# Bezel.
	_reticle.draw_arc(Vector2.ZERO, r + 2.5 * lw, 0, TAU, 48, Color(0.05, 0.05, 0.07), 5.0 * lw, true)
	_reticle.draw_arc(Vector2.ZERO, r + 4.6 * lw, 0, TAU, 48, Color(0.25, 0.27, 0.3), 1.2 * lw, true)
	_reticle.draw_arc(Vector2.ZERO, r + 2.5 * lw, -2.4, -1.6, 12, Color(1, 1, 1, 0.35), 1.5 * lw, true)
	# Crosshair - thick posts from the edge, fine lines at the centre.
	var gap := r * 0.12
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		_reticle.draw_line(d * r, d * r * 0.55, ink, 2.4 * lw)
		_reticle.draw_line(d * r * 0.55, d * gap, ink, 0.9 * lw)
	# Mil-dots.
	for k in [-2, -1, 1, 2]:
		var o: float = k * r * 0.2
		_reticle.draw_circle(Vector2(o, 0), 0.9 * lw, ink)
		_reticle.draw_circle(Vector2(0, o), 0.9 * lw, ink)
	_reticle.draw_circle(Vector2.ZERO, 1.3 * lw, Color(1.0, 0.15, 0.1, 0.95))
	# Glass glint.
	_reticle.draw_arc(Vector2.ZERO, r * 0.8, -2.3, -1.7, 8, Color(1, 1, 1, 0.18), 2.0 * lw, true)
