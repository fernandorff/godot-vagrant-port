shader_type spatial;
// Base: "Transparency Dither" de jacob, https://godotshaders.com/shader/transparency-dither/ (CC0, ver ORIGEM.md).
// Linhas dele mantidas: a constante ign e o teste de descarte. Mudanças do lab: textura x cor de vértice no lugar da cor
// lisa, e o alfa vem de "visto" por boneco (modo "Boneco inteiro" do Three: quanta luz direta chega a pés, peito ou cabeça).
// Cor pelas luzes do Godot (Lambert, sem ambiente na sala escura), como o modo INTEIRO do Three, que pinta com a luz direta.
render_mode fog_disabled, cull_back, specular_disabled, diffuse_lambert;

const vec3 ign = vec3(0.06711056f, 0.00583715f, 52.9829189f);
uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform sampler2D tex : filter_nearest, repeat_enable;
uniform float corte = 0.5;
instance uniform float visto = 1.0;

vec3 para_linear(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c)); }

void fragment() {
	vec4 d = texture(tex, UV) * COLOR;
	if (d.a < corte) discard;
	ALBEDO.rgb = para_linear(d.rgb) * color.rgb;
	float a = visto;  // no original: color.a
	if (a < 0.001 || a < fract(ign.z * fract(dot(FRAGCOORD.xy, ign.xy)))) {
		discard;
	}
}
