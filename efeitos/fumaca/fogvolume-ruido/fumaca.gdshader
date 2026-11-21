shader_type fog;
// Porte da função densidade() de fumaca.js (sala-fechada, Three.js) para um FogVolume do Godot 4.
// A luz das tochas o próprio motor soma (névoa volumétrica ilumina por luz, com anisotropia do Environment);
// aqui só a densidade animada: camada rasteira + uma pluma por fogo aceso + erosão por ruído.

uniform vec4 fontes[18];            // xyz = chama, w = força (1,3 tocha, 1,8 braseiro)
uniform int n_fontes = 0;
uniform vec3 caixa_min;
uniform vec3 caixa_max;
uniform float altura = 1.0;         // uAltura
uniform float cobertura = 0.8;      // uCob
uniform float densidade = 0.8;      // uDens
uniform vec3 cor : source_color = vec3(0.749, 0.820, 1.0);      // uCor 0xbfd1ff
uniform vec3 ambiente : source_color = vec3(0.161, 0.2, 0.322); // uAmb 0x293352
uniform float energia_ambiente = 0.3;

// ruído de valor 3D por hash (fumaca.js lê uma textura 256x256; aqui é procedural para não importar textura)
float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float ruido(vec3 x) {
	vec3 i = floor(x), f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	float n = ruido(p) * 0.5 + ruido(p * 2.03 + 7.1) * 0.25 + ruido(p * 4.07 + 13.7) * 0.125;
	return smoothstep(0.22, 0.78, n / 0.875);
}

void fog() {
	vec3 p = WORLD_POSITION;
	float T = TIME;
	float h = p.y - caixa_min.y;
	vec3 b = min(p - caixa_min, caixa_max - p);
	float borda = smoothstep(0.0, 2.5, min(b.x, b.z)) * smoothstep(0.0, 1.0, caixa_max.y - p.y);
	float cob = exp(-h / altura) * cobertura;
	float pluma = 0.0;
	for (int i = 0; i < 18; i++) {
		if (i >= n_fontes) break;
		vec3 r = p - fontes[i].xyz;
		float hy = r.y;
		r.xz += hy * 0.3 * vec2(sin(T * 0.7 + hy * 1.3 + fontes[i].x), cos(T * 0.5 + hy * 1.1 + fontes[i].z));
		float raio = 0.2 * fontes[i].w + max(hy, 0.0) * 0.3;
		pluma += 0.9 * exp(-dot(r.xz, r.xz) / (raio * raio)) * smoothstep(-0.2, 0.5, hy) * exp(-max(hy, 0.0) / (2.6 * fontes[i].w));
	}
	float total = (cob + pluma) * borda;
	float d = 0.0;
	if (total >= 0.02) {
		vec3 q = p * 0.55;
		q.xz += vec2(T * 0.035, T * 0.022);
		q.xz += 0.55 * vec2(sin(q.z * 1.4 + T * 0.13), cos(q.x * 1.4 + T * 0.11));
		q.y -= T * 0.012;
		float n = fbm(q);
		if (pluma > 0.02) n = mix(n, fbm(vec3(p.x, p.y - T * 0.6, p.z) * 1.7), min(pluma * 1.5, 1.0));
		d = max(0.0, n + total - 1.0) * 2.0;
	}
	DENSITY = d * densidade;
	ALBEDO = cor;
	EMISSION = ambiente * cor * energia_ambiente;
}
