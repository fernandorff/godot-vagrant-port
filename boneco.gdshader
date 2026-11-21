// Bonecos como o modo padrão da página (sala-fechada.html:1030-1105, ?bonecos=some&some=abraca):
// luz direta que abraça o corpo (0,2 de piso + meia Lambert) e o boneco some, em ruído fino, onde a luz direta não chega.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_back;
uniform sampler2D tex : source_color, filter_nearest;
uniform float scissor = 0.5;
uniform bool usa_cor_vertice = false;
uniform bool some = true;
uniform bool antes = false;  // "Como antes" da página: luz plana no corpo (ambiente x2 + tochas no peito x0,5), nunca some
uniform vec3 cor_luz = vec3(1.0, 0.62, 0.3);
uniform int n_fogos = 0;
uniform vec4 fogos[24];  // xyz posição no mundo; w = intensidade do Three (força x tremor)
uniform vec4 fogos_cor[24];  // rgb = cor bruta da fonte; a = alcance (tocha 10, clarões 9 a 16)
uniform vec2 fora = vec2(0.0);        // x sol, y céu (foraU de planta-mundo.js)
uniform vec3 sol_cor = vec3(0.0);     // cor bruta x intensidade da hora
uniform vec3 sol_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 hemi_ceu = vec3(0.0);
uniform vec3 hemi_chao = vec3(0.0);
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float fino(vec2 a) { return fract(52.9829189 * fract(dot(a, vec2(0.06711056, 0.00583715)))); }
void fragment() {
	vec4 t = texture(tex, UV);
	if (t.a < scissor) discard;
	ALBEDO = usa_cor_vertice ? t.rgb * COLOR.rgb : t.rgb;
	if (some && !IN_SHADOW_PASS) {
		// mesma conta da página para decidir o que some (sem as sombras: a luz real, com sombra, vem do light())
		vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float s = 0.0;
		for (int i = 0; i < n_fogos; i++) {
			vec3 l = fogos[i].xyz - wpos;
			float d = length(l), x = d / fogos_cor[i].a, j = clamp(1.0 - x * x, 0.0, 1.0);
			vec3 c = fogos_cor[i].rgb;
			s += fogos[i].w * j * j * 16.0 / (d * d + 16.0) * (0.2 + 0.4 * (dot(n, l / d) + 1.0)) * max(c.r, max(c.g, c.b));
		}
		// ar livre (LUZ_FORA, planta-mundo.js:637): sol e céu também contam. shortcut: aqui sem a sombra do sol; trocar se boneco
		// na sombra de uma árvore aparecer inteiro onde a página o apaga
		s += fora.x * max(sol_cor.r, max(sol_cor.g, sol_cor.b)) * (0.2 + 0.4 * (dot(n, sol_dir) + 1.0));
		vec3 hm = mix(hemi_chao, hemi_ceu, 0.5 * n.y + 0.5);
		s += fora.y * max(hm.r, max(hm.g, hm.b));
		if (smoothstep(0.0, 0.05, s) <= fino(FRAGCOORD.xy)) discard;
	}
	if (antes && !IN_SHADOW_PASS) {  // sala-fechada.html:1650-1659
		// shortcut: queda medida em cada pixel (não no peito) e sem cortar as 2 primeiras tochas pela sombra; trocar se
		// o boneco ficar claro atrás de uma parede
		vec3 lp = vec3(0.08, 0.09, 0.14);  // AMBIENTE x2 (sala-fechada.html:82)
		for (int i = 0; i < n_fogos; i++) {
			float q = max(0.0, 1.0 - length(fogos[i].xyz - wpos) / fogos_cor[i].a);
			lp += fogos_cor[i].rgb * fogos[i].w * q * q * 0.5;
		}
		EMISSION = ALBEDO * min(lp, vec3(1.2));
	}
	vec3 nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (!antes) EMISSION = ALBEDO * mix(hemi_chao, hemi_ceu, 0.5 * nw.y + 0.5) * fora.y;  // luz do céu (hemisfério), sem sombra como no Three
}
uniform float atenuacao_godot = 0.9;  // omni_attenuation das tochas (vagrant.gd)
uniform bool ver_sombra = false;      // diagnóstico --ver-sombra: o corpo mostra só a sombra do sol (branco = sem sombra)
void light() {
	if (!antes) {  // no "Como antes" a luz plana já está no EMISSION
	if (LIGHT_IS_DIRECTIONAL) {  // o sol: a cor e a meia Lambert da página; do Godot só a sombra (ATTENUATION)
		// o Godot zera a sombra nas faces de costas para o sol mesmo sem nada projetando (medido 21/11 com o corpo sem
		// sombra); a página ali dá a meia luz. shortcut: de costas para o sol, sem a sombra das árvores; trocar se as costas
		// na sombra de uma árvore aparecerem claras demais
		float nl = dot(NORMAL, LIGHT);
		float sombra_sol = mix(1.0, ATTENUATION, smoothstep(-0.05, 0.2, nl));
		DIFFUSE_LIGHT += ver_sombra ? vec3(sombra_sol) : sol_cor * (0.2 + 0.4 * (nl + 1.0)) * sombra_sol * fora.x;
	} else {
	// queda da página (j^2 D0^2/(d^2+D0^2), D0 = 4) no lugar da do Godot; do Godot fica só a sombra: ATTENUATION dividida
	// pela queda que o Godot aplicaria nessa distância. A tocha é achada pela direção da luz (a mais alinhada)
	vec3 lw = normalize((INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).xyz);
	float melhor = -2.0, d = 1.0, w = 0.0, a = 10.0;
	vec3 cor = cor_luz;
	for (int i = 0; i < n_fogos; i++) {
		vec3 l = fogos[i].xyz - wpos;
		float dl = length(l), c = dot(l / dl, lw);
		if (c > melhor) { melhor = c; d = dl; w = fogos[i].w; a = fogos_cor[i].a; cor = fogos_cor[i].rgb; }
	}
	float x = d / a, j = clamp(1.0 - x * x, 0.0, 1.0);
	float q = pow(max(1.0 - pow(d / a, 4.0), 0.0), 2.0) * pow(max(d, 0.0001), -atenuacao_godot);
	float sombra = q > 0.0001 ? clamp(ATTENUATION / q, 0.0, 1.0) : 0.0;
	DIFFUSE_LIGHT += cor * w * j * j * 16.0 / (d * d + 16.0) * (0.2 + 0.4 * (dot(NORMAL, LIGHT) + 1.0)) * sombra;
}
}
}
