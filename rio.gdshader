// Rio da planta "mundo": porte direto do shader do Three (planta-mundo.js linhas 338-374), mesmas contas.
// Diferenças: "borda" (atributo que o glTF não trouxe) é recalculada pela distância ao centro do rio;
// a cor final passa por srgb->linear porque o Three r117 escreve sem conversão e o Godot converte na saída;
// o hash fract(sin(...)*43758) do Three virou um hash sem seno: no Vulkan da RTX o seno de argumento grande saiu em
// degraus e o rio ficou cheio de quadrados (print comparado em 20/11); o desenho do ruído muda, a estatística não.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

#define ANEIS 8
uniform float tempo;
uniform bool cru = true;
uniform float ceuI = 0.5;
uniform vec3 zen;
uniform vec3 hor;
uniform vec3 solCor;
uniform vec3 solDir = vec3(0.0, 1.0, 0.0);
uniform vec4 aneis[ANEIS];
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
float h(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f); return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + 1.0), f.x), f.y); }
float onda(vec2 p) { return n(p * vec2(0.9, 0.45) - vec2(0.0, tempo * 1.2)) + 0.5 * n(p * vec2(2.1, 1.2) - vec2(tempo * 0.15, tempo * 2.0)) + 0.25 * n(p * 4.3 - vec2(0.0, tempo * 2.6)); }
float rio_x(float z) { return (35.0 + 1.6 * sin(z / 2.0 * 0.17 + 0.6)) * 2.0; }
vec3 lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }

void vertex() {
	vM = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vM.xz, a0 = anel(p); float e = 0.08, o = onda(p) + a0.x;
	float vB = abs(vM.x - rio_x(vM.z)) / 1.8;
	vec3 nrm = normalize(vec3(-(onda(p + vec2(e, 0.0)) + anel(p + vec2(e, 0.0)).x - o) / e * 0.25, 1.0, -(onda(p + vec2(0.0, e)) + anel(p + vec2(0.0, e)).x - o) / e * 0.25));
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 V = normalize(cam - vM), R = reflect(-V, nrm);
	float fres = 0.05 + 0.95 * pow(1.0 - max(dot(nrm, V), 0.0), 4.0);
	vec3 ceu = mix(hor, zen, clamp(R.y * 1.5, 0.0, 1.0));
	vec3 c = mix(vec3(0.02, 0.05, 0.06) * (0.3 + ceuI) + hor * 0.08, ceu, fres);
	c += solCor * pow(max(dot(R, solDir), 0.0), 180.0) * 2.5 + solCor * pow(max(dot(R, solDir), 0.0), 12.0) * 0.08;
	float esp = smoothstep(0.7, 1.0, vB) * smoothstep(0.45, 0.85, n(p * 3.0 - vec2(0.0, tempo * 1.8)));
	c = mix(c, (hor * 0.6 + zen * 0.4) * (0.4 + ceuI), esp * 0.5);
	c = mix(c, (hor * 0.5 + vec3(0.5)) * (0.3 + ceuI), clamp(a0.y * 0.7, 0.0, 0.7));
	ALBEDO = cru ? c : lin(c);  // cru: a cena já entrega o valor bruto do Three na tela (cor_three do vagrant.gd)
	ALPHA = mix(0.88, 0.6, smoothstep(0.75, 1.0, vB));
}
