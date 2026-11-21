extends Node
# Personagem: shader próprio, porte direto do Three (luz que abraça, half-Lambert com piso 0,2, some com pontilhado fino).

const NOME := "Personagem: luz que abraça + some (porte do Three)"
const EXCLUSIVO := true
const VISTA := "bonecos"
const B := preload("../comum/bonecos.gd")

var cena: Node3D
var feitos := []
var mats: Array[ShaderMaterial] = []
var claro := false

func ligar(c: Node3D) -> void:
	cena = c
	var L := B.luzes_three(c.meta)
	var sh: Shader = load("res://efeitos/personagem/abraca-proprio/abraca.gdshader")
	feitos = B.aplicar(c.bonecos, func(o: BaseMaterial3D, _mi: MeshInstance3D) -> Material:
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("tex", o.albedo_texture)
		m.set_shader_parameter("corte", o.alpha_scissor_threshold if o.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR else 0.0)
		B.poe_luzes(m, L)
		mats.append(m)
		return m)
	_poe_claro(c.claro)

func _poe_claro(on: bool) -> void:
	claro = on  # luz clara: luz igual 1 no corpo todo, o boneco aparece inteiro com a textura
	for m in mats: m.set_shader_parameter("luz", Vector3.ONE if on else Vector3.ZERO)

func _process(_dt: float) -> void:
	if cena and cena.claro != claro: _poe_claro(cena.claro)

func desligar() -> void:
	B.devolver(feitos)
	feitos = []
	mats = []
