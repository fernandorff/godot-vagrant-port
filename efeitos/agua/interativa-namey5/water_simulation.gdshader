shader_type canvas_item;
render_mode unshaded;

uniform float velocity: hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float attenuation : hint_range(0.0, 1.0, 0.01) = 0.95;
uniform float scale : hint_range(0.25, 8.0, 0.25) = 1.0;
uniform float low_pass_filter : hint_range(0.0, 1.0, 0.001) = 0.01;

uniform float mouse_size : hint_range(0.0, 1024.0, 1.0) = 32.0;
// ALTERADO (godot-candidatos/agua): no lugar de um mouse_pos, até 8 pés (uv.xy, força 0 a 1, não usado); força 0 = nada
uniform vec4 pes[8];

void fragment() {
	vec3 duv = vec3(TEXTURE_PIXEL_SIZE, 0.0) * scale;
	vec2 prev = texture(TEXTURE, UV).xy * 2.0 - 1.0;
	vec4 spread = vec4(
		texture(TEXTURE, UV + duv.xz).x,
		texture(TEXTURE, UV - duv.xz).x,
		texture(TEXTURE, UV + duv.zy).x,
		texture(TEXTURE, UV - duv.zy).x
	) * 2.0 - 1.0;
	float vel = velocity * (dot(vec4(1.0), spread) - 4.0 * prev.x);
	float height = (2.0 * prev.x - prev.y + vel) * attenuation;
	
	// displace water at mouse position:
	// todo: have this not be hardcoded to test scene
	for (int i = 0; i < 8; i++) {
		vec2 circle = pes[i].xy - UV;
		height = mix(height, -1.0, pes[i].z * smoothstep(mouse_size, 0.0, length(circle / TEXTURE_PIXEL_SIZE)));
	}
	
	if (low_pass_filter > 0.0) {
		// low-pass filter to reduce shimmering:
		height *= 1.0 - exp(-abs(height) / low_pass_filter);
	}
	
	COLOR = vec4(height * 0.5 + 0.5, prev.x * 0.5 + 0.5, 0.0, 1.0);
}
