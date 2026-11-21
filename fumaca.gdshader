// Porte do fumaca.js (fumaça volumétrica da sala-fechada): raio marchado dentro de uma caixa, por ruído 3D animado,
// iluminado pelas 6 primeiras tochas, parando na geometria (textura de profundidade). Quadro de tela inteira, alfa
// pré-multiplicado. Diferenças: sem a meia resolução e o borrão 3x3 da página (aqui é resolução cheia, 32 passos).
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
uniform sampler2D prof : hint_depth_texture, filter_nearest;
uniform sampler2D ruido_tex : filter_linear, repeat_enable;
uniform vec3 cmin; uniform vec3 cmax; uniform vec3 cor; uniform vec3 amb;
uniform float tempo; uniform float dens = 1.2; uniform float altura = 1.0; uniform float cob = 0.8;
uniform vec3 luz_pos[6]; uniform vec3 luz_cor[6]; uniform float luz_alc[6]; uniform int n_luz = 0;
uniform vec4 fonte[6]; uniform int n_fonte = 0;
const int PASSOS = 32;

void vertex() { POSITION = vec4(VERTEX.xy * 2.0, 0.5, 1.0); }

float ruido(vec3 x) {
	vec3 p = floor(x), f = fract(x); f = f * f * (3.0 - 2.0 * f);
	vec2 rg = textureLod(ruido_tex, (p.xy + vec2(37.0, 17.0) * p.z + f.xy + 0.5) / 256.0, 0.0).yx;
	return mix(rg.x, rg.y, f.z);
}
float fbm(vec3 p) {
	float n = ruido(p) * 0.5 + ruido(p * 2.03 + 7.1) * 0.25;
	n = (n + ruido(p * 4.07 + 13.7) * 0.125) / 0.875;
	return smoothstep(0.22, 0.78, n);
}
float densidade(vec3 p) {
	float h = p.y - cmin.y, T = tempo;
	vec3 b = min(p - cmin, cmax - p);
	float borda = smoothstep(0.0, 2.5, min(b.x, b.z)) * smoothstep(0.0, 1.0, cmax.y - p.y);
	float cobre = exp(-h / altura) * cob;
	float pluma = 0.0;
	for (int i = 0; i < n_fonte; i++) {
		vec3 r = p - fonte[i].xyz; float hy = r.y;
		r.xz += hy * 0.3 * vec2(sin(T * 0.7 + hy * 1.3 + fonte[i].x), cos(T * 0.5 + hy * 1.1 + fonte[i].z));
		float raio = 0.2 * fonte[i].w + max(hy, 0.0) * 0.3;
		pluma += 0.9 * exp(-dot(r.xz, r.xz) / (raio * raio)) * smoothstep(-0.2, 0.5, hy) * exp(-max(hy, 0.0) / (2.6 * fonte[i].w));
	}
	float total = (cobre + pluma) * borda;
	if (total < 0.02) return 0.0;
	vec3 q = p * 0.55; q.xz += vec2(T * 0.035, T * 0.022);
	q.xz += 0.55 * vec2(sin(q.z * 1.4 + T * 0.13), cos(q.x * 1.4 + T * 0.11)); q.y -= T * 0.012;
	float n = fbm(q);
	if (pluma > 0.02) n = mix(n, fbm(vec3(p.x, p.y - T * 0.6, p.z) * 1.7), min(pluma * 1.5, 1.0));
	return max(0.0, n + total - 1.0) * 2.0;
}
vec3 mundo(vec2 uv, float z, mat4 inv_p, mat4 inv_v) {
	vec4 v = inv_p * vec4(uv * 2.0 - 1.0, z, 1.0);
	return (inv_v * vec4(v.xyz / v.w, 1.0)).xyz;
}
void fragment() {
	vec3 cam = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(mundo(SCREEN_UV, 0.5, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) - cam);
	vec3 t0 = (cmin - cam) / rd, t1 = (cmax - cam) / rd, ta = min(t0, t1), tb = max(t0, t1);
	float tA = max(max(ta.x, ta.y), max(ta.z, 0.0)), tB = min(tb.x, min(tb.y, tb.z));
	tB = min(tB, dot(mundo(SCREEN_UV, texture(prof, SCREEN_UV).x, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) - cam, rd));
	vec3 c = vec3(0.0); float tr = 1.0;
	if (tB > tA) {
		float ds = (tB - tA) / float(PASSOS);
		float t = tA + ds * fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		for (int s = 0; s < PASSOS; s++) {
			vec3 p = cam + rd * t; t += ds;
			float d = densidade(p);
			if (d < 0.003) continue;
			vec3 L = amb;
			for (int i = 0; i < n_luz; i++) {
				vec3 l = luz_pos[i] - p; float dist = length(l), a = max(0.0, 1.0 - dist / luz_alc[i]);
				float cc = dot(rd, l / dist), hg = 0.8775 / pow(1.1225 - 0.7 * cc, 1.5);
				L += luz_cor[i] * (a * a / (1.0 + dist * dist * 0.12)) * hg;
			}
			L *= mix(1.0, 0.6, min(d * 1.5, 1.0));
			float a = 1.0 - exp(-d * dens * ds);
			c += tr * a * L * cor; tr *= 1.0 - a;
			if (tr < 0.03) break;
		}
	}
	ALBEDO = c;
	ALPHA = 1.0 - tr;
}
