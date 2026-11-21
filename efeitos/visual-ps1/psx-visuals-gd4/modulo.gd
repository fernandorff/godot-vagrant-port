extends Node
# PS1 / PSX Visuals GD4 Port (scolastico, MIT, v2.1.3): shader dele nos materiais da sala + pontilhado de tela. Ver ORIGEM.md.

const NOME := "PS1: PSX Visuals GD4 (scolastico)"
const EXCLUSIVO := true
const VISTA := "padrao"
const T := preload("../comum/troca.gd")
const AQUI := "res://efeitos/visual-ps1/psx-visuals-gd4/"

var feitos := []
var criados: Array[StringName] = []
var tela: CanvasLayer

func ligar(c: Node3D) -> void:
	# valores padrão do pacote (Psx.gd, touch_shader_globals); a névoa dele vem desligada (alfa 0) e o shader tem fog_disabled
	criados = T.globais([[&"psx_affine_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0], [&"psx_bit_depth", RenderingServer.GLOBAL_VAR_TYPE_INT, 5],
		[&"psx_fog_color", RenderingServer.GLOBAL_VAR_TYPE_COLOR, Color(0.5, 0.5, 0.5, 0.0)], [&"psx_fog_near", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 10.0],
		[&"psx_fog_far", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 20.0], [&"psx_snap_distance", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.025]])
	var sh := {T.OPACO: load(AQUI + "psx_opaque.gdshader"), T.OPACO_DUPLO: load(AQUI + "psx_opaque_double.gdshader"),
		T.TRANSP: load(AQUI + "psx_transparent.gdshader"), T.TRANSP_DUPLO: load(AQUI + "psx_transparent_double.gdshader")}
	feitos = T.aplicar(c.sala, func(tipo: int, o: BaseMaterial3D, tem_cor: bool) -> Material:
		var m := ShaderMaterial.new()  # o mesmo que AutoApply.gd faz: textura e cor do StandardMaterial3D
		m.shader = sh[tipo]
		m.set_shader_parameter("albedo", o.albedo_texture)
		m.set_shader_parameter("albedo_tint", o.albedo_color)
		m.set_shader_parameter("use_vertex_colors_in_albedo", tem_cor)  # a página Three usa vertexColors na sala
		return m)
	var pp := ShaderMaterial.new()
	pp.shader = load(AQUI + "psx_postprocess.gdshader")
	tela = T.camada_de_tela(self, pp)

func desligar() -> void:
	T.devolver(feitos)
	feitos = []
	if tela: tela.free()  # antes de tirar os globais que o shader da tela lê
	T.tirar_globais(criados)
	criados = []
