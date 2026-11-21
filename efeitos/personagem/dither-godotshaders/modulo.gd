extends Node
# Personagem: "Transparency Dither" do godotshaders.com (CC0) com o alfa do boneco inteiro pela luz em pés, peito e cabeça
# (função visto() da sala-fechada.html); cor pelas luzes do Godot. Ver ORIGEM.md.

const NOME := "Personagem: boneco inteiro some (Transparency Dither, godotshaders)"
const EXCLUSIVO := true
const VISTA := "bonecos"
const B := preload("../comum/bonecos.gd")
const D0 := 4.0
const SOME_LIM := 0.05

var cena: Node3D
var feitos := []
var vistos := {}  # MeshInstance3D -> visto calculado
var claro := false

func ligar(c: Node3D) -> void:
	cena = c
	var sh: Shader = load("res://efeitos/personagem/dither-godotshaders/dither_inteiro.gdshader")
	var L := B.luzes_three(c.meta)
	var cache := {}
	feitos = B.aplicar(c.bonecos, func(o: BaseMaterial3D, mi: MeshInstance3D) -> Material:
		if not vistos.has(mi): vistos[mi] = _visto(c.unidades, _unidade(mi), L)
		if not cache.has(o):
			var m := ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("tex", o.albedo_texture)
			m.set_shader_parameter("corte", o.alpha_scissor_threshold if o.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR else 0.0)
			cache[o] = m
		return cache[o])
	_poe_claro(c.claro)

# o nó do boneco se chama u<índice>_... (export da etapa 1); sobe na árvore até achar
func _unidade(n: Node) -> int:
	while n:
		var s := String(n.name)
		if s.begins_with("u") and s.contains("_") and s.substr(1, s.find("_") - 1).is_valid_int(): return int(s.substr(1, s.find("_") - 1))
		n = n.get_parent()
	return -1

# visto() da sala-fechada.html, linhas 1137-1145: maior soma de luz (sem ângulo) em 10%, 55% e 95% da altura, suavizada
func _visto(unidades: Array, k: int, L: Dictionary) -> float:
	if k < 0 or k >= unidades.size(): return 1.0
	var u: Dictionary = unidades[k]
	var m := 0.0
	for h in [0.1, 0.55, 0.95]:
		var p := Vector3(u.pos[0], u.pos[1] + u.alt * h, u.pos[2])
		var s := 0.0
		for i in L.n:
			var d: float = L.pos[i].distance_to(p)
			var j := maxf(0.0, 1.0 - pow(d / L.alc[i], 2.0))
			var c: Vector3 = L.cor[i]
			s += maxf(c.x, maxf(c.y, c.z)) * j * j * D0 * D0 / (d * d + D0 * D0)
		m = maxf(m, s)
	var x := minf(1.0, m / SOME_LIM)
	return x * x * (3.0 - 2.0 * x)

func _poe_claro(on: bool) -> void:
	claro = on
	for mi in vistos:
		if is_instance_valid(mi): mi.set_instance_shader_parameter("visto", 1.0 if on else vistos[mi])

func _process(_dt: float) -> void:
	if cena and cena.claro != claro: _poe_claro(cena.claro)

func desligar() -> void:
	B.devolver(feitos)
	feitos = []
	for mi in vistos:
		if is_instance_valid(mi): mi.set_instance_shader_parameter("visto", 1.0)
	vistos = {}
