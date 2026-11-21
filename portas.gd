class_name Portas
extends Node
## As duas portas da casa (planta-mundo.js:466-483 e 575-620): E perto abre; aberta de todo, quem abriu sai do outro lado
## (a casa de fora e a de dentro são lugares separados, 72 tiles um do outro). Só um lugar aparece por vez.

const PERTO := 3.2               # tiles da porta para o E valer
const ABRE := 0.7                # s para abrir ou fechar
const GIRA := 1.65               # rad com a porta toda aberta
const DENTRO := Rect2i(82, 20, 8, 6)  # as casas de dentro da casa, letra 'h' (planta-mundo.js:78)

class Porta:
	var no: Node3D               # a dobradiça
	var x: float
	var z: float
	var t := 0.0
	var aberta := false
	var quem: Unidade

var fora: Porta
var dentro: Porta
var g_fora: Node3D               # n176: clareira e caminho
var g_casa: Node3D               # n201: o lado de dentro
var bonecos: Bonecos
var camera: CameraOrbita
var grade: Grade
var paredes_casa: Array[Dictionary] = []  # {no, eixo, c, sai, op}: somem quando a câmera fica do lado de fora delas

func montar(nos: Dictionary, b: Bonecos, cam: CameraOrbita, g: Grade) -> void:
	bonecos = b
	camera = cam
	grade = g
	fora = _porta(nos.get("n198"), 92.0)
	dentro = _porta(nos.get("n213"), 164.0)
	g_fora = nos.get("n176")
	g_casa = nos.get("n201")
	if g_casa: _classifica_casa()

# planta-mundo.js:450 e 463: lá dentro, telhado e oitões nunca aparecem, e cada parede (com a janela) some quando a câmera
# está do lado de fora dela. shortcut: as peças são reconhecidas pela caixa (parede = fina e comprida; telhado = acima de
# PISO_CASA + PE), não por nome; trocar se o export ganhar o nome das peças.
func _classifica_casa() -> void:
	for n in g_casa.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b: AABB = mi.global_transform * mi.get_aabb()
		var mt := mi.mesh.surface_get_material(0) as BaseMaterial3D
		if mt and mt.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and mi.mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR:
			# feixes de sol das janelas (planta-mundo.js:521): aditivos, cor por vértice; o export do glTF perde o "Additive"
			mt.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mt.vertex_color_use_as_albedo = true
			mt.albedo_color = Color.WHITE
			mt.disable_fog = true
			mt.cull_mode = BaseMaterial3D.CULL_DISABLED
			continue
		if b.position.y >= 5.4:  # beiral do telhado em 5,5; o alto das paredes em 6,0
			mi.visible = false
		elif b.size.x <= 0.7 and b.size.z >= 4.0:
			paredes_casa.append({"no": mi, "eixo": 0, "c": b.get_center().x, "sai": -1.0 if b.get_center().x < 172.0 else 1.0, "op": 1.0})
		elif b.size.z <= 0.7 and b.size.x >= 4.0:
			paredes_casa.append({"no": mi, "eixo": 2, "c": b.get_center().z, "sai": -1.0 if b.get_center().z < 46.0 else 1.0, "op": 1.0})

func _porta(no: Node3D, x: float) -> Porta:
	var p := Porta.new()
	p.no = no
	p.x = x
	p.z = 45.0                   # PORTA_Z
	return p

func perto() -> Porta:  # a porta ao lado do escolhido, ou null
	var u := bonecos.sel.no.position
	for d in [fora, dentro]:
		if d.no and Vector2(u.x - d.x, u.z - d.z).length() < PERTO: return d
	return null

func alterna() -> void:  # alternaPorta() da página: só abre; fecha sozinha depois de atravessar
	var d := perto()
	if d and not d.aberta:
		d.aberta = true
		d.quem = bonecos.sel

func _process(dt: float) -> void:
	for d: Porta in [fora, dentro]:
		if d.no == null: continue
		d.t = clampf(d.t + (1.0 if d.aberta else -1.0) * dt / ABRE, 0.0, 1.0)
		d.no.rotation.y = GIRA * d.t * d.t * (3.0 - 2.0 * d.t)
	if fora.aberta and fora.t >= 1.0: _atravessa(fora, dentro, 1)
	elif dentro.aberta and dentro.t >= 1.0: _atravessa(dentro, fora, -1)
	var la_dentro := DENTRO.has_point(Vector2i(floori(bonecos.sel.no.position.x / grade.CEL), floori(bonecos.sel.no.position.z / grade.CEL)))
	if g_casa and g_casa.visible != la_dentro:
		g_casa.visible = la_dentro
		g_fora.visible = not la_dentro
	for w in paredes_casa:
		var quer := 0.0 if la_dentro and (camera.position[w.eixo] - w.c) * w.sai > 0.0 else 1.0
		if quer == w.op: continue
		w.op = clampf(w.op + signf(quer - w.op) * dt / CameraOrbita.SOME_EM, 0.0, 1.0)
		w.no.visible = w.op > 0.0
		w.no.transparency = 1.0 - w.op

func _atravessa(de: Porta, para: Porta, s: int) -> void:  # sai a 1 tile da outra porta, de costas para ela
	de.aberta = false
	de.t = 0.0
	para.t = 1.0
	para.aberta = false
	var u := de.quem
	if u == null: return
	var x := para.x + s
	var z := para.z
	u.no.position = Vector3(x, grade.seco(x, z), z)
	u.c = Vector2i(floori(x / grade.CEL), floori(z / grade.CEL))
	u.rota.clear()
	u.v = 0.0
	u.v1 = 0.0
	u.pulando = false
	u.rumo = s * PI / 2.0
	u.no.rotation.y = u.rumo
	if u == bonecos.sel: camera.salta()  # sem deslizar pelo mapa: a câmera já está lá
