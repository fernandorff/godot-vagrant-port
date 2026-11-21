class_name Rio
extends Node
## O rio da planta mundo (planta-mundo.js:330-406): o shader do rio do Three (rio.gdshader, cópia do efeitos/agua/nativo)
## no nó n184, com os anéis dos pés de quem está na água (respingos(): entrar = anel forte; andando = 0,6 a cada 0,3 s;
## parado = 0,25 a cada 1,3 s) e as 160 gotas que saltam do pé (entrar 18, cada passo 4, sair 8).

const C := preload("res://efeitos/agua/comum/agua_comum.gd")
const GOTAS := 160
const GRAVIDADE := 12.0          # a do agua.js
const SOME := -1e6               # gota parada fora da vista

var bonecos: Bonecos
var no_rio: MeshInstance3D
var mat: ShaderMaterial
var aneis := C.Aneis.new()
var vivas := 0
var _gp := PackedVector3Array()  # posição de cada gota
var _gv := PackedVector3Array()  # velocidade
var _prox := 0
var _pes := {}                   # Unidade -> {dentro, t, x, z}
var _gotas: MultiMesh

func montar(nos: Dictionary, b: Bonecos, meta: Dictionary, cor_three: bool) -> void:
	bonecos = b
	no_rio = nos.get("n184") as MeshInstance3D
	if no_rio == null:
		push_error("rio: nó n184 não encontrado")
		return
	var h: Dictionary = meta.HORA
	var s: Dictionary = meta.sol
	mat = ShaderMaterial.new()
	mat.shader = load("res://rio.gdshader")  # cópia do efeitos/agua/nativo, com a saída bruta opcional
	mat.set_shader_parameter("cru", cor_three)
	mat.set_shader_parameter("zen", _rgb(Color(h.zen)))
	mat.set_shader_parameter("hor", _rgb(Color(h.hor)))
	mat.set_shader_parameter("solCor", Vector3(h.sol[0], h.sol[1], h.sol[2]) * float(h.si))
	mat.set_shader_parameter("solDir", (Vector3(s.pos[0], s.pos[1], s.pos[2]) - Vector3(s.alvo[0], s.alvo[1], s.alvo[2])).normalized())
	mat.set_shader_parameter("ceuI", float(h.ci))
	no_rio.material_override = mat
	_monta_gotas(Color(h.hor).lerp(Color.WHITE, 0.5) * (0.4 + float(h.ci)), no_rio.get_parent())

func _monta_gotas(cor: Color, pai: Node) -> void:  # planta-mundo.js:381 e 560: pontos de 0,16, opacidade 0,9, cor da hora
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.16)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(cor.r, cor.g, cor.b, 0.9)
	q.material = m
	_gotas = MultiMesh.new()
	_gotas.transform_format = MultiMesh.TRANSFORM_3D
	_gotas.mesh = q
	_gotas.instance_count = GOTAS
	var mi := MultiMeshInstance3D.new()
	mi.name = "Gotas"
	mi.multimesh = _gotas
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0  # frustumCulled = false na página
	pai.add_child(mi)  # no grupo de fora: some junto quando se entra na casa
	_gp.resize(GOTAS)
	_gv.resize(GOTAS)
	_gp.fill(Vector3(0, SOME, 0))

func respinga(x: float, z: float, quantas: int, forca: float) -> void:  # nascem fora da barra do manto
	for q in quantas:
		var a := randf() * TAU
		var rr := 0.5 + randf() * 0.3
		var f := 0.8 + randf() * 1.2
		_gp[_prox] = Vector3(x + cos(a) * rr, Grade.AGUA_Y + 0.02, z + sin(a) * rr)
		_gv[_prox] = Vector3(cos(a) * f, (2.0 + randf() * 2.4) * forca, sin(a) * f)
		_prox = (_prox + 1) % GOTAS

func _process(dt: float) -> void:
	if mat == null: return
	var pes := []
	for u in bonecos.unidades: pes.append(u.no.position)
	aneis.atualizar(dt, pes, Grade.molha)
	mat.set_shader_parameter("tempo", aneis.tempo)
	mat.set_shader_parameter("aneis", aneis.slots)
	_respingos(dt)

func _respingos(dt: float) -> void:  # planta-mundo.js:391-406, só as gotas (os anéis vêm do Aneis)
	for u in bonecos.unidades:
		var p := u.no.position
		var w := Grade.molha(p)
		var s: Dictionary = _pes.get(u, {"dentro": false, "t": 0.0, "x": p.x, "z": p.z})
		var anda := dt > 0.0 and Vector2(p.x - s.x, p.z - s.z).length() / dt > 0.3
		s.t -= dt
		if w and not s.dentro:
			respinga(p.x, p.z, 18, 1.0)
			s.t = 0.3
		elif w and s.t <= 0.0:
			if anda: respinga(p.x, p.z, 4, 0.6)
			s.t = 0.3 if anda else 1.3
		elif not w and s.dentro:
			respinga(s.x, s.z, 8, 0.7)  # o que as pernas levantam cai de volta
		s.dentro = w
		s.x = p.x
		s.z = p.z
		_pes[u] = s
	vivas = 0
	for i in GOTAS:
		if _gp[i].y < -1e5: continue
		_gv[i].y -= GRAVIDADE * dt
		_gp[i] += _gv[i] * dt
		if _gp[i].y < Grade.AGUA_Y and _gv[i].y < 0.0: _gp[i].y = SOME
		else: vivas += 1
		_gotas.set_instance_transform(i, Transform3D(Basis(), _gp[i]))
	if _gotas:
		for i in GOTAS:
			if _gp[i].y < -1e5: _gotas.set_instance_transform(i, Transform3D(Basis(), Vector3(0, SOME, 0)))

static func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
