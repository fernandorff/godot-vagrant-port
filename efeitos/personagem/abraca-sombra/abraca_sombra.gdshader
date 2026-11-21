shader_type spatial;
// Variante: a cor vem das luzes do Godot (com sombra de verdade e a calibração da sala) por meia luz de Lambert com piso 0,2
// em light(); o sumiço com pontilhado continua decidido pela soma própria (Three), porque light() não pode descartar pixel.
render_mode fog_disabled, cull_back, specular_disabled;

#include "../comum/abraca.gdshaderinc"

void vertex() {
	p_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	n_mundo = dot(NORMAL, NORMAL) > 0.25 ? normalize(MODEL_NORMAL_MATRIX * NORMAL) : vec3(0.0);
}

void fragment() {
	vec4 d = texture(tex, UV) * COLOR;
	if (d.a < corte) discard;
	vec3 nf = normalize(cross(dFdx(p_mundo), dFdy(p_mundo)));
	if (dot(nf, CAMERA_POSITION_WORLD - p_mundo) < 0.0) nf = -nf;
	vec3 ns = dot(n_mundo, n_mundo) > 0.25 ? normalize(n_mundo) : nf;
	if (dot(ns, nf) < 0.0) ns = -ns;
	if (some(luz_direta(p_mundo, ns), FRAGCOORD.xy)) discard;
	ALBEDO = para_linear(d.rgb);
	NORMAL = (VIEW_MATRIX * vec4(ns, 0.0)).xyz;  // a normal suave virada para a câmera, como no Three
}

void light() {
	float nl = ABRACO + (1.0 - ABRACO) * 0.5 * (dot(NORMAL, LIGHT) + 1.0);
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR / PI * nl;  // LIGHT_COLOR já vem multiplicado por PI (documentação do light())
}
