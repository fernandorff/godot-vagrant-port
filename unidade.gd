class_name Unidade
extends RefCounted
## Um boneco da sala-fechada.html: gestos em fila, peso (aceleração e giro), rota na grade, teclado e pulo.
## Porte de sala-fechada.html:1184-1205 (gestos), 1395-1403 e 1540-1555 (pulo), 1476-1537 (peso, teclado) e 1678-1690 (rota).

# shortcut: o Godot mistura animações em linha reta, a página em curva S (liso); trocar por pesos à mão se a diferença aparecer

const VEL := 3.0                 # tiles por segundo andando
const CORRIDA := 1.8             # multiplicador da corrida
const LAG90 := 3.89              # duas esperas chegam a 90% em 3,89 constantes de tempo
const ENCADEIA := 0.06           # mistura entre os clipes de um mesmo gesto
const LACO: Array[String] = ["parado", "andar", "correr"]
# PESOS da página (sala-fechada.html:107-111): giro em graus/s, partida e parada em s, freio na curva, agacha e pouso em
# quadros do jogo (parado, andando), recupera = parte da velocidade mantida no pouso. Tecla P troca; o padrão é o pesado.
const PESOS := {
	"leve": {"giro": 900.0, "partida": 0.08, "parada": 0.08, "freio": 0.0, "agacha": [6, 3], "pouso": 8, "recupera": 1.0},
	"medio": {"giro": 540.0, "partida": 0.15, "parada": 0.2, "freio": 0.5, "agacha": [8, 4], "pouso": 11, "recupera": 0.5},
	"pesado": {"giro": 270.0, "partida": 0.3, "parada": 0.35, "freio": 0.85, "agacha": [11, 6], "pouso": 16, "recupera": 0.25},
}
static var peso := "pesado"      # um peso para todos, como a página
static var pk: Dictionary = PESOS.pesado

static func troca_peso() -> String:  # tecla P: leve -> medio -> pesado -> leve
	var l := PESOS.keys()
	peso = l[(l.find(peso) + 1) % l.size()]
	pk = PESOS[peso]
	return peso
# pulo (pulo-vs.js): SALTO 1,3 tile, GRAV 21, misturas em quadros de 1/30 s
const SALTO := 1.3
const GRAV := 21.0
const QUADRO := 1.0 / 30.0
const LENTO_AGUA := 0.65        # andando no rio (sala-fechada.html:458)
const MISTURA := {"agacha": 4, "impulso": 8, "topo": 16, "queda": 8, "pouso": 8, "parado": 8}
const VOO_SAIDA := 30.0          # velocidade de saída na escala do jogo
const VOO_TOPO := 9.0            # "topo" enquanto |v| <= 9

var pulo0 := sqrt(2.0 * GRAV * SALTO)
var nome: String
var no: Node3D
var player: AnimationPlayer   # só guarda os clipes
var arvore: AnimationTree      # toca: Transição em curva S + ritmo
var grade: Grade
var alt: float
var c: Vector2i                  # casa onde está
var gestos: Dictionary           # gesto -> nomes dos clipes, tocados em fila
var poses: Dictionary            # modo -> fase -> clipe (ou null)
var mao: Dictionary              # osso da mão, do ombro, lado e escudo (exportar-bonecos.mjs)
var leva: Fonte                  # a tocha na mão
var rota: Array[Vector2i] = []
var v := 0.0
var v1 := 0.0
var w := 0.0
var atual := ""
var fila: Array = []
var dirigido := false
var rumo := 0.0
var alvo := 0.0
var corre := false
var corre_vs := false
var pulando := false
var pulo_vy := 0.0
var pulo_agacha := 0.0
var pulo_poses = null            # Dictionary de fases, ou null quando o SEQ não tem as poses
var pouso := 0.0
var fora := Vector2.ZERO        # foraU da página: sol e céu que chegam (suavizado)
var mats: Array[ShaderMaterial] = []  # os materiais do corpo, para o fora
var lento := 1.0                 # lentidao() da página: 0,65 com o pé no rio

func _init(d: Dictionary, n: Node3D, p: AnimationPlayer, a: AnimationTree, g: Grade) -> void:
	nome = d.nome
	no = n
	player = p
	arvore = a
	grade = g
	alt = float(d.alt)
	c = Vector2i(int(d.cx), int(d.cz))
	gestos = d.gestos
	poses = d.poses
	mao = d.mao
	arvore.animation_finished.connect(func(n: StringName) -> void: if n == clipe_atual(): _proximo())
	toca("parado")

# ---- gestos ----
static func troca_de(de: String, para: String) -> float:
	if para == "golpe" or para == "magia": return 0.1
	if de == "golpe" or de == "magia": return 0.25
	if de == "pose": return MISTURA.parado * QUADRO  # do pouso de volta ao gesto (pulo-vs.js)
	var menos := 0.2 if para == "correr" or de == "correr" else 0.1
	if para == "parado": return maxf(menos, pk.parada)
	if de == "parado" or de == "": return maxf(menos, pk.partida)
	return 0.2

func toca(g: String, de = null) -> void:
	if de == null: de = atual
	if atual == g or not gestos.has(g): return
	atual = g
	fila = gestos[g].duplicate()
	_proximo(troca_de(de, g))

func _proximo(dur := ENCADEIA) -> void:
	if fila.is_empty():
		if not atual in LACO:  # golpe ou magia acabou: volta ao que fazia
			var de := atual
			atual = ""
			toca(gesto(), de)
			return
		fila = gestos[atual].duplicate()
	mistura(fila.pop_front(), dur)

func mistura(clipe: String, dur: float) -> void:  # toca o clipe misturando a partir da pose atual, em curva S
	(arvore.tree_root.get_node(&"troca") as AnimationNodeTransition).xfade_time = dur
	arvore.set(&"parameters/troca/transition_request", clipe)

func clipe_atual() -> String:  # o pedido ainda não processado vale (a Transição só troca no próximo quadro)
	var pedido: String = arvore.get(&"parameters/troca/transition_request")
	return pedido if pedido != "" else arvore.get(&"parameters/troca/current_state")

func ritmo(r: float) -> void:  # o speed_scale do player antigo
	arvore.set(&"parameters/ritmo/scale", r)

func gesto() -> String:
	if dirigido: return "correr" if corre_vs else "andar"
	return "andar" if rota.size() else "parado"

func livre_de_pose() -> bool:
	return not pulando and pouso <= 0.0

func frente(d: float, h: float) -> Vector3:
	return no.position + Vector3(sin(no.rotation.y) * d, h, cos(no.rotation.y) * d)

# ---- peso: velocidade e rumo ----
func embala(meta_v: float, dt: float) -> void:
	var a := 1.0 - exp(-dt * LAG90 / (pk.partida if meta_v > v1 else pk.parada))
	v1 += (meta_v - v1) * a
	v += (v1 - v) * a
	if meta_v == 0.0 and v < 0.05:
		v = 0.0
		v1 = 0.0

func vira(para: float, dt: float) -> float:  # devolve o ângulo que falta virar
	var mx := deg_to_rad(pk.giro)
	var ry := no.rotation.y
	var d := atan2(sin(para - ry), cos(para - ry))
	if absf(d) > 3.1: d = absf(d) * (signf(w) if w != 0.0 else 1.0)
	if absf(d) < 1e-4:
		no.rotation.y = para
		w = 0.0
		return 0.0
	var alvo_w := signf(d) * minf(mx, sqrt(2.0 * (mx / (0.5 * pk.partida)) * absf(d)))
	w += (alvo_w - w) * (1.0 - exp(-dt / (0.15 * pk.partida)))
	var s := w * dt
	if signf(s) == signf(d) and absf(s) >= absf(d):
		no.rotation.y = para
		w = d / dt
	else:
		no.rotation.y = atan2(sin(ry + s), cos(ry + s))
	return d

# ---- pulo ----
func no_ar() -> bool:
	return pulando and not (pulo_agacha > 0.0)

func _poe_fase(fases: Dictionary, fase: String) -> void:
	if clipe_atual() != fases[fase]: mistura(fases[fase], MISTURA[fase] * QUADRO)

func _volta() -> void:
	atual = ""
	ritmo(1.0)
	toca(gesto(), "pose")

func pula(correndo: bool) -> void:
	if pulando or pouso > 0.0 or no.position.y < grade.seco(no.position.x, no.position.z) - 0.01: return
	var anda := dirigido or rota.size() > 0
	var modo := "parado" if not anda else ("correndo" if correndo else "andando")
	var fases = poses[modo] if poses[modo] != null else poses.parado
	pulando = true
	pulo_poses = fases
	if fases == null:
		pulo_vy = pulo0
		pulo_agacha = 0.0
		return
	pulo_vy = 0.0
	pulo_agacha = pk.agacha[1 if anda else 0] * QUADRO
	_poe_fase(fases, "agacha")

func voa(dt: float) -> void:
	var chao := grade.seco(no.position.x, no.position.z)
	if pouso > 0.0:
		pouso -= dt
		if pouso <= 0.0:
			pouso = 0.0
			_volta()
	if not pulando:
		if no.position.y > chao + 0.01 and rota.is_empty():  # saiu da borda: cai
			pulando = true
			pulo_vy = 0.0
			pulo_agacha = 0.0
			pulo_poses = poses.parado
		else: return
	if pulo_agacha > 0.0:
		pulo_agacha -= dt
		if pulo_agacha > 0.0: return
		pulo_vy = pulo0
	pulo_vy -= GRAV * dt
	no.position.y += pulo_vy * dt
	if no.position.y <= chao and pulo_vy < 0.0:
		no.position.y = chao
		pulando = false
		if pulo_poses != null:
			_poe_fase(pulo_poses, "pouso")
			pouso = pk.pouso * QUADRO / (2.0 if dirigido or rota.size() else 1.0)
		else: _volta()
	elif pulo_poses != null:
		var vy := pulo_vy / pulo0 * VOO_SAIDA  # faseDoVoo: velocidade na escala do jogo
		_poe_fase(pulo_poses, "topo" if absf(vy) <= VOO_TOPO else ("impulso" if vy > 0.0 else "queda"))

# ---- teclado (dirige e rola) ----
func solta() -> void:  # largou o comando: volta a ficar parado, freando pelo peso
	if dirigido:
		dirigido = false
		if atual in LACO and livre_de_pose(): toca("parado")

func dirige(x: float, y: float, correndo: bool, az: float) -> void:
	corre = correndo
	var mag := minf(1.0, sqrt(x * x + y * y))
	if mag < 0.15:
		solta()
		return
	var fx := -sin(az)
	var fz := -cos(az)
	var mx := fx * -y + -fz * x
	var mz := fz * -y + fx * x
	rota.clear()
	dirigido = true
	rumo = atan2(mx, mz)
	lento = LENTO_AGUA if Grade.molha(no.position) else 1.0
	alvo = VEL * (CORRIDA if correndo else 1.0) * lento * mag
	corre_vs = correndo and gestos.has("correr")
	if livre_de_pose() and (atual in LACO or atual == ""): toca("correr" if corre_vs else "andar")

func rola(dt: float) -> void:  # o passo vai para onde ele olha; curva fechada come a velocidade
	var p := no.position
	var d := vira(rumo, dt) if dirigido else 0.0
	embala(alvo * (1.0 - pk.freio * (1.0 - maxf(0.0, cos(d)))) * (pk.recupera if pouso > 0.0 else 1.0) if dirigido else 0.0, dt)
	if dirigido and livre_de_pose() and atual in LACO:
		ritmo((1.6 if corre and not corre_vs else 1.0) * lento * minf(1.0, maxf(0.5, v / (VEL * (CORRIDA if corre else 1.0) * lento))))  # ritmo() da página
	if v == 0.0: return
	var passo := v * dt
	var mx := sin(no.rotation.y)
	var mz := cos(no.rotation.y)
	var ar := no_ar()
	var chao := grade.seco(p.x, p.z)
	var ref := maxf(p.y, chao) if ar else chao
	var pisando := absf(p.y - chao) < 0.01
	for a: Vector2 in [Vector2(mx, mz), Vector2(mx, 0), Vector2(0, mz)]:
		var nx := p.x + a.x * passo
		var nz := p.z + a.y * passo
		if a == Vector2.ZERO or not grade.livre(nx, nz, ref, ar): continue
		p.x = nx
		p.z = nz
		if pisando and not ar:
			var ny := grade.seco(nx, nz)
			if absf(ny - p.y) < 0.6: p.y = ny
		break
	no.position = p
	c = Vector2i(floori(p.x / grade.CEL), floori(p.z / grade.CEL))

# ---- rota na grade ----
func vai_para(destino: Vector2i) -> bool:
	var r := grade.caminho(c, destino)
	if r.is_empty(): return false
	rota.assign(r)
	toca("andar")
	return true

func anda_rota(correndo: bool, dt: float) -> void:
	if rota.is_empty(): return
	lento = LENTO_AGUA if Grade.molha(no.position) else 1.0
	var topo := VEL * (CORRIDA if correndo else 1.0) * lento
	var casa := rota[0]
	var dx := casa.x * grade.CEL + 1.0 - no.position.x
	var dz := casa.y * grade.CEL + 1.0 - no.position.z
	var l := sqrt(dx * dx + dz * dz)
	embala((topo if rota.size() > 1 else maxf(0.6, minf(topo, l / (0.6 * pk.parada)))) * (pk.recupera if pouso > 0.0 else 1.0), dt)
	vira(atan2(dx, dz), dt)
	if livre_de_pose() and (atual == "andar" or atual == "correr"):
		var tem_corrida := gestos.has("correr")
		toca("correr" if correndo and tem_corrida else "andar")
		ritmo((1.6 if correndo and not tem_corrida else 1.0) * lento * minf(1.0, maxf(0.5, v / topo)))
	var passo := v * dt
	if l <= passo:
		no.position.x += dx
		no.position.z += dz
		c = casa
		rota.pop_front()
		if not rota.is_empty():  # a sobra do passo segue para a próxima casa (sem ela, a velocidade caía a cada troca: tranco medido 21/11)
			var prox := Vector2(rota[0].x * grade.CEL + 1.0 - no.position.x, rota[0].y * grade.CEL + 1.0 - no.position.z)
			var resto := minf(passo - l, prox.length())
			if prox.length() > 0.0001:
				no.position.x += prox.x / prox.length() * resto
				no.position.z += prox.y / prox.length() * resto
		if rota.is_empty():
			v = 0.0
			v1 = 0.0
			ritmo(1.0)
			if atual in LACO and livre_de_pose(): toca("parado")
	else:
		no.position.x += dx / l * passo
		no.position.z += dz / l * passo
	if not no_ar(): no.position.y = grade.seco(no.position.x, no.position.z)
