// Poça rasa de demonstração (sala escura): água escura e transparente, iluminada pelas tochas do próprio Godot
// (brilho especular nas cristas), com os mesmos anéis dos pés do rio e ondinhas leves. Inspirado no visual de
// agua.js (modo 'rasa'), mas sem a grade de onda simulada: os anéis são analíticos, como no rio da planta mundo.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

#define ANEIS 8
uniform float tempo;
uniform vec4 aneis[ANEIS];
uniform sampler2D tela : hint_screen_texture, filter_linear_mipmap, repeat_disable;
varying vec3 vM;

vec2 anel(vec2 p) {
	vec2 s = vec2(0.0);
	for (int i = 0; i < ANEIS; i++) {
		vec4 a = aneis[i]; float t = tempo - a.z; if (t < 0.0 || t > 1.4) continue;
		float d = length(p - a.xy) - (0.25 + 1.5 * t), k = a.w * (1.0 - t / 1.4) * exp(-d * d * 30.0);
		s += vec2(k * sin(d * 14.0), k);
	}
	return s;
}
float h(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); } // sem seno (ver rio.gdshader)
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + 1.0), f.x), f.y); }
float onda(vec2 p) { return 0.15 * (n(p * 1.7 + vec2(tempo * 0.3, 0.0)) + 0.5 * n(p * 3.9 - vec2(0.0, tempo * 0.4))); }

void vertex() {
	vM = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vM.xz, a0 = anel(p); float e = 0.05, o = onda(p) + a0.x;
	vec3 nw = normalize(vec3(-(onda(p + vec2(e, 0.0)) + anel(p + vec2(e, 0.0)).x - o) / e * 0.25, 1.0, -(onda(p + vec2(0.0, e)) + anel(p + vec2(0.0, e)).x - o) / e * 0.25));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	// fundo entortado pela inclinação da onda (como agua.js entorta as lajes), escurecido pela água
	vec3 fundo = textureLod(tela, SCREEN_UV + nw.xz * 0.03, 0.0).rgb;
	float fres = 0.05 + 0.95 * pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 4.0);
	ALBEDO = vec3(0.02, 0.035, 0.05);
	EMISSION = fundo * vec3(0.55, 0.62, 0.7) * (1.0 - fres);
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
	ALPHA = 1.0;
	ALBEDO = mix(ALBEDO, vec3(0.35, 0.4, 0.45), clamp(a0.y * 0.5, 0.0, 0.5)); // crista do anel, clara como espuma
}
