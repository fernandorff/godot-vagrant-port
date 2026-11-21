extends Node
# GodotSSRWater (marcelb, MIT): shader de água com reflexo em espaço de tela, transparência, refração e ondas 3D,
# aplicado ao rio (n184) e à poça de demonstração. Sem interação com boneco (o shader não tem entrada para isso).

const NOME := "GodotSSRWater (reflexo em tela, marcelb)"
const EXCLUSIVO := true
const VISTA := "rio"
const C := preload("../comum/agua_comum.gd")

var rio: MeshInstance3D
var mat: ShaderMaterial
var camadas_antes := 0

func _ruido(tipo: int, freq: float, fractal: int, normal: bool) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = tipo
	n.frequency = freq
	n.fractal_type = fractal
	var t := NoiseTexture2D.new()
	t.noise = n
	t.seamless = true
	t.seamless_blend_skirt = 0.5
	t.as_normal_map = normal
	t.generate_mipmaps = false
	return t

func ligar(cena: Node3D) -> void:
	mat = ShaderMaterial.new()
	mat.shader = load("res://efeitos/agua/ssr-water/water.gdshader")
	mat.render_priority = -128
	# texturas de ruído iguais às da demo (World.tscn do repositório)
	mat.set_shader_parameter("wave_a", _ruido(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0005, FastNoiseLite.FRACTAL_PING_PONG, false))
	mat.set_shader_parameter("wave_b", _ruido(FastNoiseLite.TYPE_CELLULAR, 0.0225, FastNoiseLite.FRACTAL_NONE, false))
	mat.set_shader_parameter("surface_normals_a", _ruido(FastNoiseLite.TYPE_SIMPLEX, 0.007, FastNoiseLite.FRACTAL_FBM, true))
	mat.set_shader_parameter("surface_normals_b", _ruido(FastNoiseLite.TYPE_SIMPLEX, 0.02, FastNoiseLite.FRACTAL_NONE, true))
	# escala: a demo é um mar de 320 x 320; aqui o rio tem 6 tiles de largura e 0,84 de fundo, a poça 5 cm
	mat.set_shader_parameter("wave_height_scale", 0.05)
	mat.set_shader_parameter("max_visible_depth", 1.5)
	mat.set_shader_parameter("border_scale", 0.12)
	mat.set_shader_parameter("ssr_max_travel", 30.0)
	rio = C.rio(cena)
	if rio == null:
		push_error("agua/ssr-water: nó n184 (rio) não encontrado")
	else:
		camadas_antes = rio.layers
		rio.layers = camadas_antes | 2  # o rio passa a receber sol e céu (camada FORA), como o resto ao ar livre
		rio.material_override = mat
	C.criar_poca(self, 48).material_override = mat

func desligar() -> void:
	if rio != null and rio.material_override == mat:
		rio.material_override = null
		rio.layers = camadas_antes
