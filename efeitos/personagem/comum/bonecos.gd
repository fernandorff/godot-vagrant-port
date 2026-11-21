extends RefCounted
# Funções comuns dos candidatos de personagem (pasta sem modulo.gd: o menu não lista).

const MAX_LUZES := 16  # mesmo tamanho dos vetores nos shaders

# Luzes de ponto como o shader do Three as vê (sala-fechada.html, BONECO_LUZ): cor x intensidade do Three (r117 sem
# luz física), alcance = distance. Mesma escolha de intensidade do vagrant.gd (forcaBase, senão intensidadeAgora),
# sem a escala 0,35 da calibração da sala.
static func luzes_three(meta: Dictionary) -> Dictionary:
	var pos := PackedVector3Array()
	var cor := PackedVector3Array()
	var alc := PackedFloat32Array()
	for l in meta.luzes:
		if l.intensidadeAgora <= 0.0 or pos.size() >= MAX_LUZES: continue
		var i: float = l.forcaBase if l.forcaBase != null else l.intensidadeAgora
		var c := Color(l.cor)
		pos.append(Vector3(l.pos[0], l.pos[1], l.pos[2]))
		cor.append(Vector3(c.r, c.g, c.b) * i)
		alc.append(float(l.distancia))
	return {"pos": pos, "cor": cor, "alc": alc, "n": pos.size()}

static func poe_luzes(m: ShaderMaterial, L: Dictionary) -> void:
	var pos: PackedVector3Array = L.pos.duplicate()
	var cor: PackedVector3Array = L.cor.duplicate()
	var alc: PackedFloat32Array = L.alc.duplicate()
	pos.resize(MAX_LUZES)
	cor.resize(MAX_LUZES)
	alc.resize(MAX_LUZES)
	m.set_shader_parameter("luz_pos", pos)
	m.set_shader_parameter("luz_cor", cor)
	m.set_shader_parameter("luz_alc", alc)
	m.set_shader_parameter("n_luzes", L.n)

# Superfícies dos bonecos que o Three troca (os materiais VSTools: corpo, arma e escudo, todos com textura).
# fabrica: Callable(orig: BaseMaterial3D, mi: MeshInstance3D) -> Material. Devolve [mi, superfície, material] para devolver().
static func aplicar(bonecos: Node, fabrica: Callable) -> Array:
	var feitos := []
	for n in bonecos.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			if mi.get_surface_override_material(i) != null: continue
			var o := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if o == null or o.albedo_texture == null: continue
			var novo: Material = fabrica.call(o, mi)
			mi.set_surface_override_material(i, novo)
			feitos.append([mi, i, novo])
	return feitos

static func devolver(feitos: Array) -> void:
	for f in feitos:
		var mi: MeshInstance3D = f[0]
		if is_instance_valid(mi) and mi.get_surface_override_material(f[1]) == f[2]:
			mi.set_surface_override_material(f[1], null)
