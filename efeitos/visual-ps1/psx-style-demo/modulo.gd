extends Node
# Godot PSX Style Demo (MenacingMecha, MIT): shader psx_lit dele na sala + pontilhado de faixas na tela. Ver ORIGEM.md.

const NOME := "PS1: Godot PSX Style Demo (MenacingMecha)"
const EXCLUSIVO := true
const VISTA := "padrao"
const T := preload("../comum/troca.gd")
const AQUI := "res://efeitos/visual-ps1/psx-style-demo/"

var feitos := []
var criados: Array[StringName] = []
var tela: CanvasLayer

func ligar(c: Node3D) -> void:
	criados = T.globais([[&"precision_multiplier", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0]])  # valor do project.godot do demo
	var sh := {T.OPACO: load(AQUI + "psx_lit.gdshader"), T.OPACO_DUPLO: load(AQUI + "lab_lit_duplo.gdshader"),
		T.TRANSP: load(AQUI + "psx_lit_transparent.gdshader"), T.TRANSP_DUPLO: load(AQUI + "lab_lit_transp_duplo.gdshader")}
	feitos = T.aplicar(c.sala, func(tipo: int, o: BaseMaterial3D, _tem_cor: bool) -> Material:
		var m := ShaderMaterial.new()  # o shader dele sempre multiplica pela cor de vértice (branca quando a malha não tem)
		m.shader = sh[tipo]
		m.set_shader_parameter("albedoTex", o.albedo_texture)
		m.set_shader_parameter("modulate_color", o.albedo_color)
		return m)
	# névoa: o shader dele usa a do Environment, então a da base vale sem mudança
	var pp := ShaderMaterial.new()
	pp.shader = load(AQUI + "pp_band-dither.gdshader")
	pp.set_shader_parameter("dither_tex", T.png(AQUI + "psxdither.png"))
	tela = T.camada_de_tela(self, pp)

func desligar() -> void:
	T.devolver(feitos)
	feitos = []
	if tela: tela.free()
	T.tirar_globais(criados)
	criados = []
