shader_type canvas_item;
// Snow flurry: softly blurs whatever is already on screen (world and scope)
// and lifts it towards a cold white. `amount` 0..1 is driven by the game.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * (1.0 + amount * 2.5);
	vec4 acc = vec4(0.0);
	float wsum = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float w = 1.0 / (1.0 + float(x * x + y * y));
			acc += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px) * w;
			wsum += w;
		}
	}
	vec3 c = acc.rgb / wsum;
	c = mix(c, vec3(0.93, 0.95, 1.0), amount * 0.2);
	COLOR = vec4(c, clamp(amount, 0.0, 1.0));
}
