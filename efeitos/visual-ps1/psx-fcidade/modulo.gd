extends Node
# PSX - Godot Shader 1.0.0 (Francisco Cidade, CC0): shader psx dele na sala + psx_screen na tela. Ver ORIGEM.md.

const NOME := "PS1: PSX Godot Shader (fcidade)"
const EXCLUSIVO := true
const VISTA := "padrao"
const T := preload("../comum/troca.gd")
const AQUI := "res://efeitos/visual-ps1/psx-fcidade/"

var feitos := []

func ligar(c: Node3D) -> void:
	var sh := {T.OPACO: load(AQUI + "psx.gdshader"), T.OPACO_DUPLO: load(AQUI + "psx_double_sided.gdshader"),
		T.TRANSP: load(AQUI + "psx_transparent.gdshader"), T.TRANSP_DUPLO: load(AQUI + "psx_transparent.gdshader")}
	feitos = T.aplicar(c.sala, func(tipo: int, o: BaseMaterial3D, tem_cor: bool) -> Material:
		var m := ShaderMaterial.new()  # demais parâmetros nos padrões dele (pixel 3, 15 bits, pontilhado, afim 1, névoa 0)
		m.shader = sh[tipo]
		m.set_shader_parameter("albedo_tex", o.albedo_texture)
		m.set_shader_parameter("albedo_color", o.albedo_color)
		m.set_shader_parameter("vertex_color_mix", 1.0 if tem_cor else 0.0)  # a página Three usa vertexColors
		return m)
	var pp := ShaderMaterial.new()
	pp.shader = load(AQUI + "psx_screen.gdshader")
	T.camada_de_tela(self, pp)

func desligar() -> void:
	T.devolver(feitos)
	feitos = []
