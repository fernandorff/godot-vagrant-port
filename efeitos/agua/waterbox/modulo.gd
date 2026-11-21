extends Node
# godot-waterbox (Adisoreq, MIT): só o shader de água do addon (onda em seno + cor chapada, alfa 0,7) no rio e na poça.
# O resto do addon é empuxo de RigidBody3D; os bonecos não são corpos rígidos, então não há interação (ver RESULTADO.md).

const NOME := "godot-waterbox (shader do addon)"
const EXCLUSIVO := true
const VISTA := "rio"
const C := preload("../comum/agua_comum.gd")

var rio: MeshInstance3D
var mat: ShaderMaterial
var camadas_antes := 0

func ligar(cena: Node3D) -> void:
	mat = ShaderMaterial.new()
	mat.shader = load("res://efeitos/agua/waterbox/water.gdshader")
	var n := FastNoiseLite.new()
	var t := NoiseTexture2D.new()  # o addon usa uma noise_texture (water.tres); a mesma ideia, gerada aqui
	t.noise = n
	t.seamless = true
	mat.set_shader_parameter("noise_texture", t)
	mat.set_shader_parameter("wave_strength", 0.03)  # padrão 0,2 levanta a superfície acima da margem do rio
	rio = C.rio(cena)
	if rio == null:
		push_error("agua/waterbox: nó n184 (rio) não encontrado")
	else:
		camadas_antes = rio.layers
		rio.layers = camadas_antes | 2
		rio.material_override = mat
	C.criar_poca(self, 48).material_override = mat

func desligar() -> void:
	if rio != null and rio.material_override == mat:
		rio.material_override = null
		rio.layers = camadas_antes
