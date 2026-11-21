extends RefCounted
# Luz assada da sala (sala-fechada.html:812-889, "poeLm"): luz indireta por vértice, só das tochas e braseiros.
# Por ponto da sala: quanto ele é aberto (13 raios no hemisfério, 3 tiles) e, por fogo a menos de 16 tiles, uma parte de
# luz rebatida, maior quando a chama está à vista (4 raios para pontos em volta dela). No Three a luz soma ao indireto do
# Lambert; aqui vira EMISSION = ALBEDO * lm num shader que imita o material (mesmo efeito: albedo vezes luz).
# Diferença: o Three anda numa grade da planta (rocha, colunas, teto) e os arcos não tapam nada; aqui os raios batem na
# malha de verdade (colisão triangular da própria sala), então arcos e beiradas tapam.
const ALC_LM := 16.0
const K_LM := 0.16
const COR_FOGO := Color(1, 0.62, 0.3)
const SHADER := """
shader_type spatial;
render_mode specular_disabled%s;
uniform sampler2D tex : source_color, filter_nearest_mipmap, repeat_enable;
varying vec3 lm;
void vertex() { lm = CUSTOM0.rgb; }
void fragment() {
	vec4 t = texture(tex, UV);
	ALBEDO = t.rgb * COLOR.rgb;
	EMISSION = ALBEDO * lm;
}
"""
var malhas := []   # {mi, mat_orig, mat_lm, de: PackedInt32Array (vértice -> ponto)}
var pares := []    # por ponto: [i_fogo, w, i_fogo, w, ...]
var ms := 0.0

static func _queda(d: float, a: float) -> float:
	return pow(maxf(0.0, 1.0 - d / a), 2.0)

func assar(raiz: Node3D, meta: Dictionary, salas: Array) -> void:
	var t0 := Time.get_ticks_usec()
	var espaco := raiz.get_world_3d().direct_space_state
	var corpos := []
	for mi in salas:  # colisão temporária com a própria malha
		var c := StaticBody3D.new()
		var f := CollisionShape3D.new()
		f.shape = mi.mesh.create_trimesh_shape()
		c.add_child(f)
		mi.add_child(c)
		corpos.append(c)
	await raiz.get_tree().physics_frame
	await raiz.get_tree().physics_frame
	var q := PhysicsRayQueryParameters3D.new()
	q.hit_back_faces = true
	var anda := func(p: Vector3, dir: Vector3, ate: float) -> float:  # distância até bater, como o anda() do Three (começa em 0,2)
		q.from = p + dir * 0.2
		q.to = p + dir * ate
		var r := espaco.intersect_ray(q)
		return ate if r.is_empty() else p.distance_to(r.position)
	var raios := [[1.0, 0.0, 0.0]]
	for j in 2:
		var g: float = deg_to_rad([50.0, 78.0][j])
		for i in 6: raios.append([cos(g), sin(g), (i + j / 2.0) * PI / 3.0])
	var em_volta := [Vector3(0.4, 0, 0), Vector3(-0.4, 0, 0), Vector3(0, 0, 0.4), Vector3(0, 0, -0.4)]
	var fogos := []
	for f in meta.fogos: fogos.append({"p": Vector3(f.chama[0], f.chama[1], f.chama[2]), "forca": float(f.forca)})
	var chave := {}
	var pts := []
	for mi in salas:
		var xf: Transform3D = mi.global_transform
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var de := PackedInt32Array()
		de.resize(vs.size())
		for i in vs.size():
			var v: Vector3 = xf * vs[i]
			var n: Vector3 = (xf.basis * ns[i]).normalized()
			var kk := str(Vector3i((v * 50.0).round()), Vector3i((n * 50.0).round()))  # posição e normal arredondadas (como o Three)
			if not chave.has(kk):
				chave[kk] = pts.size()
				pts.append([v + n * 0.05, n])
			de[i] = chave[kk]
		malhas.append({"mi": mi, "de": de})
	pares.resize(pts.size())
	for i in pts.size():
		var p: Vector3 = pts[i][0]
		var n: Vector3 = pts[i][1]
		var l := Vector2(n.z, n.x).length()
		var tg := Vector3(n.z / l, 0, -n.x / l) if l > 0.1 else Vector3(1, 0, 0)
		var bt := n.cross(tg)
		var tapado := 0.0
		var total := 0.0
		for r in raios:
			var dir: Vector3 = n * r[0] + tg * (cos(r[2]) * r[1]) + bt * (sin(r[2]) * r[1])
			var d: float = anda.call(p, dir.normalized(), 3.0)
			tapado += r[0] * (1.0 - d / 3.0)
			total += r[0]
		var aberto := 1.0 - tapado / total
		var lista := []
		for j in fogos.size():
			var fo: Dictionary = fogos[j]
			var d := p.distance_to(fo.p)
			if d >= ALC_LM: continue
			var vista := 0.0
			for e in em_volta:
				var alvo: Vector3 = fo.p + e
				var qd := p.distance_to(alvo)
				if anda.call(p, (alvo - p) / qd, qd - 0.1) >= qd - 0.1: vista += 0.25
			var w: float = fo.forca * _queda(d, ALC_LM) * aberto * (0.3 + 0.7 * vista) * K_LM
			if w > 0.002: lista.append_array([j, w])
		pares[i] = lista
	for c in corpos: c.queue_free()
	ms = (Time.get_ticks_usec() - t0) / 1000.0

func compor(meta: Dictionary) -> void:  # soma as partes das tochas acesas (lmCompoe do Three; escuridão total = sem azul ambiente)
	for m in malhas:
		var mi: MeshInstance3D = m.mi
		var de: PackedInt32Array = m.de
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var cus := PackedFloat32Array()
		cus.resize(de.size() * 4)
		for i in de.size():
			var s := 0.0
			var ps: Array = pares[de[i]]
			for k in range(0, ps.size(), 2):
				if not meta.fogos[ps[k]].apagada: s += ps[k + 1]
			cus[i * 4] = COR_FOGO.r * s
			cus[i * 4 + 1] = COR_FOGO.g * s
			cus[i * 4 + 2] = COR_FOGO.b * s
		arr[Mesh.ARRAY_CUSTOM0] = cus
		var orig: BaseMaterial3D = mi.mesh.surface_get_material(0)
		if not m.has("mat_lm"):
			var sh := Shader.new()
			sh.code = SHADER % (", cull_disabled" if orig.cull_mode == BaseMaterial3D.CULL_DISABLED else "")
			var sm := ShaderMaterial.new()
			sm.shader = sh
			sm.set_shader_parameter("tex", orig.albedo_texture)
			m.mat_lm = sm
			m.mat_orig = orig
		var nova := ArrayMesh.new()
		nova.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		nova.surface_set_material(0, m.mat_orig)
		m.malha_lm = nova
		if not m.has("malha_orig"): m.malha_orig = mi.mesh

func ligar(on: bool) -> void:
	for m in malhas:
		var mi: MeshInstance3D = m.mi
		mi.mesh = m.malha_lm if on else m.malha_orig
		mi.material_override = m.mat_lm if on else null
