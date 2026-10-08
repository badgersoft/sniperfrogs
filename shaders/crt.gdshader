shader_type canvas_item;
// Cheap CRT overlay: scanlines, flicker and a vignette. Drawn on a ColorRect
// on top of the terminal, so it only darkens - no screen texture read needed.

uniform float scan_strength = 0.22;
uniform float vignette = 0.85;

void fragment() {
	vec2 uv = UV;
	float line = sin(FRAGCOORD.y * 3.14159 * 0.5) * 0.5 + 0.5;
	float flicker = 0.03 * sin(TIME * 60.0) + 0.02 * sin(TIME * 7.3);
	vec2 d = uv - 0.5;
	float v = smoothstep(0.35, 0.95, length(d) * vignette * 1.4);
	float a = line * scan_strength + v * 0.85 + flicker;
	COLOR = vec4(0.0, 0.02, 0.0, clamp(a, 0.0, 1.0));
}
