extends Node
# PSX Look Free 1.0.1 (heyheythere, CC-BY-4.0): shader psx_lit dele na sala; a versão grátis não traz o efeito de tela. Ver ORIGEM.md.

const NOME := "PS1: PSX Look Free (heyheythere)"
const EXCLUSIVO := true
const VISTA := "padrao"
const T := preload("../comum/troca.gd")
const AQUI := "res://efeitos/visual-ps1/psx-look-free/"

var feitos := []

func ligar(c: Node3D) -> void:
	var sh := {T.OPACO: load(AQUI + "psx_lit.gdshader"), T.OPACO_DUPLO: load(AQUI + "lab_lit_duplo.gdshader"),
		T.TRANSP: load(AQUI + "lab_lit_transp.gdshader"), T.TRANSP_DUPLO: load(AQUI + "lab_lit_transp.gdshader")}
	feitos = T.aplicar(c.sala, func(tipo: int, o: BaseMaterial3D, tem_cor: bool) -> Material:
		var m := ShaderMaterial.new()  # o que PSX.from_material (psx.gd) faz, menos a cor de vértice
		m.shader = sh[tipo]
		m.set_shader_parameter("albedo", o.albedo_color)
		m.set_shader_parameter("albedo_texture", o.albedo_texture)
		m.set_shader_parameter("uv_scale", Vector2(o.uv1_scale.x, o.uv1_scale.y))
		m.set_shader_parameter("uv_offset", Vector2(o.uv1_offset.x, o.uv1_offset.y))
		m.set_shader_parameter("vertex_colors", tem_cor)  # psx.gd copiaria vertex_color_use_as_albedo (falso); a página Three usa vertexColors
		return m)
	# névoa: a do Environment (o README dele pede névoa de profundidade), a da base vale sem mudança

func desligar() -> void:
	T.devolver(feitos)
	feitos = []
