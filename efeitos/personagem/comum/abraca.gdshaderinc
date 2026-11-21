// Porte do shader dos bonecos da sala-fechada.html (BONECO_VARIA/BONECO_PARS/BONECO_LUZ, linhas 1030-1105, modo ABRACA):
// cada luz de ponto dá ABRACO (0,2) de si em qualquer ângulo e o resto por meia luz de Lambert (half-Lambert), com a queda
// j²·D0²/(d²+D0²), j = 1-(d/alcance)²; o pixel some quando a luz direta fica abaixo de um limiar de ruído fino por pixel.
// Diferença do original: sem mapa de sombra das tochas no cálculo do sumiço (o Three usa as 2 luzes com sombra, com folga).

uniform sampler2D tex : filter_nearest, repeat_enable;  // sem source_color: valores crus, como o Three r117 (saída sem gama)
uniform float corte = 0.5;          // alpha scissor do material original
uniform int n_luzes = 0;
uniform vec3 luz_pos[16];
uniform vec3 luz_cor[16];           // cor x intensidade do Three
uniform float luz_alc[16];
uniform vec3 luz = vec3(0.0);       // luz igual no corpo todo (o "luz" do Three); 1 na luz clara de diagnóstico

const float D0 = 4.0;
const float ABRACO = 0.2;
const float SOME_LIM = 0.05;

varying vec3 p_mundo;
varying vec3 n_mundo;

// ruído de gradiente intercalado ("fino" no Three): sem período visível
float fino(vec2 a) { return fract(52.9829189 * fract(dot(a, vec2(0.06711056, 0.00583715)))); }

vec3 para_linear(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c)); }

// soma da luz direta das tochas num ponto, normal ns já virada para a câmera
vec3 luz_direta(vec3 p, vec3 ns) {
	vec3 s = luz;
	for (int i = 0; i < n_luzes; i++) {
		vec3 l = luz_pos[i] - p;
		float d = length(l);
		float x = d / luz_alc[i];
		float j = clamp(1.0 - x * x, 0.0, 1.0);
		float nl = ABRACO + (1.0 - ABRACO) * 0.5 * (dot(ns, l / d) + 1.0);
		s += luz_cor[i] * (j * j * D0 * D0 / (d * d + D0 * D0) * nl);
	}
	return s;
}

bool some(vec3 luzes, vec2 frag) {
	return smoothstep(0.0, SOME_LIM, max(luzes.r, max(luzes.g, luzes.b))) <= fino(frag);
}
