shader_type spatial;
// Boneco "luz que abraça" (half-Lambert com piso 0,2) e some fora da luz com pontilhado: porte direto do Three.
// Luz calculada aqui, sem as luzes do Godot (unshaded), como o Three soma pointLights no próprio shader.
// Sem névoa: o shader VSTools dos bonecos no Three não tem fog.
render_mode unshaded, fog_disabled, cull_back;

#include "../comum/abraca.gdshaderinc"

void vertex() {
	p_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// vértice sem normal (só em triângulos entre dois ossos no Three) fica com zero: o fragmento usa a da face
	n_mundo = dot(NORMAL, NORMAL) > 0.25 ? normalize(MODEL_NORMAL_MATRIX * NORMAL) : vec3(0.0);
}

void fragment() {
	vec4 d = texture(tex, UV) * COLOR;  // diffuseColor do VSTools: textura x cor de vértice (já dobrada no export)
	if (d.a < corte) discard;
	vec3 nf = normalize(cross(dFdx(p_mundo), dFdy(p_mundo)));
	if (dot(nf, CAMERA_POSITION_WORLD - p_mundo) < 0.0) nf = -nf;
	vec3 ns = dot(n_mundo, n_mundo) > 0.25 ? normalize(n_mundo) : nf;
	if (dot(ns, nf) < 0.0) ns = -ns;
	vec3 luzes = luz_direta(p_mundo, ns);
	if (some(luzes, FRAGCOORD.xy)) discard;
	ALBEDO = para_linear(d.rgb * luzes);  // o Three escreve o número direto na tela; aqui volta a ele depois da conversão de saída
}
