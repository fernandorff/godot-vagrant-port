extends RefCounted
# Funções comuns dos candidatos de visual PS1: troca os materiais da sala por um shader PS1 e devolve depois
# (CONTRATO-MODULOS.md, seção 2: material da sala é compartilhado, então só surface_override, nunca o recurso importado).
# Pasta sem modulo.gd: o menu não lista.

# Tipo de superfície pedido à fábrica do módulo.
enum { OPACO, OPACO_DUPLO, TRANSP, TRANSP_DUPLO }

# fabrica: Callable(tipo: int, orig: BaseMaterial3D, tem_cor: bool) -> Material (null = deixa a superfície como está).
# Só superfícies com luz (as sem luz, como céu e chamas, ficam) e sem override de outro módulo (a água, por exemplo).
# Devolve a lista [MeshInstance3D, superfície, material] para devolver().
static func aplicar(sala: Node, fabrica: Callable) -> Array:
	var feitos := []
	var cache := {}
	for n in sala.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			if mi.get_surface_override_material(i) != null or mi.material_override != null: continue
			var o := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if o == null or o.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED: continue
			var duplo := o.cull_mode == BaseMaterial3D.CULL_DISABLED
			var tipo: int = (TRANSP_DUPLO if duplo else TRANSP) if o.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED else (OPACO_DUPLO if duplo else OPACO)
			var tem_cor: bool = (mi.mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_COLOR) != 0
			var chave := [o, tipo, tem_cor]
			if not cache.has(chave): cache[chave] = fabrica.call(tipo, o, tem_cor)
			var novo: Material = cache[chave]
			if novo == null: continue
			mi.set_surface_override_material(i, novo)
			feitos.append([mi, i, novo])
	return feitos

# Tira só os overrides que este módulo pôs e que ainda são dele.
static func devolver(feitos: Array) -> void:
	for f in feitos:
		var mi: MeshInstance3D = f[0]
		if is_instance_valid(mi) and mi.get_surface_override_material(f[1]) == f[2]:
			mi.set_surface_override_material(f[1], null)

# Pós-processo de tela inteira: ColorRect numa CanvasLayer 0 (o menu do integrador fica na camada 1, acima).
static func camada_de_tela(dono: Node, mat: ShaderMaterial) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = 0
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = mat
	cl.add_child(r)
	dono.add_child(cl)
	return cl

# Uniformes globais em tempo de execução (os pacotes pedem em Project Settings; o contrato proíbe mexer nele).
# Precisam existir antes de o shader ser carregado. Devolve os nomes criados aqui, para remover no desligar.
static func globais(lista: Array) -> Array[StringName]:
	var criados: Array[StringName] = []
	for g in lista:  # [nome, tipo RenderingServer.GLOBAL_VAR_TYPE_*, valor]
		# sem consultar a lista: global_shader_parameter_get_list() é só do editor (dá erro em jogo); ninguém mais cria estes nomes
		RenderingServer.global_shader_parameter_add(g[0], g[1], g[2])
		criados.append(g[0])
	return criados

static func tirar_globais(criados: Array[StringName]) -> void:
	for g in criados: RenderingServer.global_shader_parameter_remove(g)

# Matriz de Bayer 4x4 (0..15)/16 em textura cinza, para os pós-processos que pedem um padrão e o pacote não traz.
static func bayer4() -> ImageTexture:
	var m := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var img := Image.create(4, 4, false, Image.FORMAT_L8)
	for y in 4:
		for x in 4:
			var v: float = (m[y * 4 + x] + 0.5) / 16.0
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)

# Textura PNG da própria pasta sem passar pelo importador (o contrato não roda --import na pasta comum).
static func png(caminho: String) -> ImageTexture:
	var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	return ImageTexture.create_from_image(img) if img else null
