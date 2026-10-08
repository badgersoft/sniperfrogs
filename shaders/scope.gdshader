shader_type canvas_item;
// Circular lens mask for the sniper scope: crops the magnified SubViewport to a
// circle, adds lens vignetting and a faint cool tint.

uniform float edge_softness = 0.03;

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	vec4 c = texture(TEXTURE, UV);
	float vig = smoothstep(0.55, 1.0, r);
	c.rgb *= 1.0 - vig * 0.6;
	c.rgb = mix(c.rgb, c.rgb * vec3(0.94, 1.0, 1.02), 0.5);
	c.a *= 1.0 - smoothstep(1.0 - edge_softness, 1.0, r);
	COLOR = c;
}
