extends Node
# Ultimate Retro Shader Collection 1.5 (Zorochase, MIT): shader standard dele na sala + pontilhado de tela. Ver ORIGEM.md.

const NOME := "PS1: Ultimate Retro Shader Collection 1.5"
const EXCLUSIVO := true
const VISTA := "padrao"
const T := preload("../comum/troca.gd")
const AQUI := "res://efeitos/visual-ps1/ursc/"

var feitos := []
var criados: Array[StringName] = []
var tela: CanvasLayer

func ligar(c: Node3D) -> void:
	# valores de setup.gd do pacote (névoa desligada: início e fim 0), menos cull_distance 0 (o padrão 64 corta a sala ao longe)
	criados = T.globais([[&"affine_texture_mapping", RenderingServer.GLOBAL_VAR_TYPE_BOOL, true], [&"texture_filtering", RenderingServer.GLOBAL_VAR_TYPE_BOOL, false],
		[&"texture_lod_halve_distance", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0], [&"vertex_snap_intensity", RenderingServer.GLOBAL_VAR_TYPE_INT, 2],
		[&"fog_color", RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(0, 0, 0, 1)], [&"fog_start_distance", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0],
		[&"fog_end_distance", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0], [&"cull_distance", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0]])
	var sh := {T.OPACO: load(AQUI + "standard_opaque_repeating.gdshader"), T.OPACO_DUPLO: load(AQUI + "lab_opaco_duplo.gdshader"),
		T.TRANSP: load(AQUI + "standard_transparent_repeating.gdshader"), T.TRANSP_DUPLO: load(AQUI + "lab_transp_duplo.gdshader")}
	feitos = T.aplicar(c.sala, func(tipo: int, o: BaseMaterial3D, tem_cor: bool) -> Material:
		var m := ShaderMaterial.new()
		m.shader = sh[tipo]
		m.set_shader_parameter("albedo_texture", o.albedo_texture)
		var cor := o.albedo_color
		m.set_shader_parameter("albedo_color", cor if tipo >= T.TRANSP else Color(cor.r, cor.g, cor.b))
		m.set_shader_parameter("mix_factor", 1.0 if tem_cor else 0.0)  # 1 = textura x cor de vértice (a página Three usa vertexColors)
		return m)
	var pp := ShaderMaterial.new()
	pp.shader = load(AQUI + "dithering.gdshader")
	pp.set_shader_parameter("dithering_pattern_texture", T.bayer4())  # o pacote não traz o padrão: Bayer 4x4 gerada aqui
	tela = T.camada_de_tela(self, pp)

func desligar() -> void:
	T.devolver(feitos)
	feitos = []
	if tela: tela.free()
	T.tirar_globais(criados)
	criados = []
