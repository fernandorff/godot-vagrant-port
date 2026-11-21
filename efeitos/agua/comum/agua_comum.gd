extends RefCounted
# Comum aos candidatos de água: onde fica a água e os anéis que os pés dos bonecos fazem.
# A planta "mundo" exportada não tem poça nem fosso (planta-mundo.js linha 153: agua: { poca: [], fosso: [] });
# a única água é o rio (nó n184). A poça aqui é de DEMONSTRAÇÃO, sob os 4 bonecos, para ver boneco dentro d'água.

const POCA_CENTRO := Vector3(22.0, 0.05, 7.0)  # bonecos em x 19 a 25, z 7, y 0 (cena.json)
const POCA_TAM := Vector2(12.0, 5.0)           # x 16 a 28, z 4,5 a 9,5
const RIO_Y := 0.04                            # AGUA_Y de planta-mundo.js
const ANEIS := 8

# centro do rio em x para um z do mundo (planta-mundo.js linhas 34 e 330: RIO em células de 2 tiles)
static func rio_x(z: float) -> float:
	return (35.0 + 1.6 * sin(z / 2.0 * 0.17 + 0.6)) * 2.0

# "molha" do rio: até 1,75 tile do centro o leito fica abaixo da água (planta-mundo.js linhas 95-96)
static func no_rio(p: Vector3) -> bool:
	return absf(p.x - rio_x(p.z)) < 1.75 and p.y <= RIO_Y + 0.1

static func na_poca(p: Vector3) -> bool:
	return absf(p.x - POCA_CENTRO.x) <= POCA_TAM.x / 2.0 and absf(p.z - POCA_CENTRO.z) <= POCA_TAM.y / 2.0 and p.y <= POCA_CENTRO.y + 0.1

static func criar_poca(pai: Node, subdiv := 0) -> MeshInstance3D:
	var m := PlaneMesh.new()
	m.size = POCA_TAM
	m.subdivide_width = subdiv
	m.subdivide_depth = subdiv * int(POCA_TAM.y) / int(POCA_TAM.x)
	var mi := MeshInstance3D.new()
	mi.name = "Poca"
	mi.mesh = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = POCA_CENTRO
	pai.add_child(mi)
	return mi

# Anéis dos pés, como respingos() de planta-mundo.js (linhas 391-399): entrar = anel forte; parado = anel fraco a cada
# 1,3 s; andando = anel 0,6 a cada 0,3 s. Os bonecos desta cena estão parados (só o clipe "parado" foi exportado).
class Aneis:
	var tempo := 0.0
	var slots: Array[Vector4] = []
	var prox := 0
	var estado := {}  # índice do boneco -> {dentro, t, x, z}
	var dentro_agora := 0

	func _init() -> void:
		for i in ANEIS: slots.append(Vector4(0, 0, -99, 0))

	func anel(x: float, z: float, forca: float) -> void:
		slots[prox] = Vector4(x, z, tempo, forca)
		prox = (prox + 1) % ANEIS

	# pes: posições dos pés; dentro: Callable(Vector3) -> bool
	func atualizar(dt: float, pes: Array, dentro: Callable) -> void:
		tempo += dt
		dentro_agora = 0
		for i in pes.size():
			var p: Vector3 = pes[i]
			var s: Dictionary = estado.get(i, {"dentro": false, "t": 0.3 * i, "x": p.x, "z": p.z})  # defasados: não batem juntos
			var w: bool = dentro.call(p)
			var anda := dt > 0.0 and Vector2(p.x - s.x, p.z - s.z).length() / dt > 0.3
			s.t -= dt
			if w and not s.dentro and s.t <= 0.0:
				anel(p.x, p.z, 1.0)
				s.t = 0.3
				s.dentro = true
			elif w and s.dentro and s.t <= 0.0:
				anel(p.x, p.z, 0.6 if anda else 0.25)
				s.t = 0.3 if anda else 1.3
			elif not w:
				s.dentro = false
			if w: dentro_agora += 1
			s.x = p.x
			s.z = p.z
			estado[i] = s

# pés dos bonecos: posição de cena.json (estão parados nesta cena)
static func pes(cena: Node) -> Array:
	var r := []
	for u in cena.unidades:
		r.append(Vector3(u.pos[0], u.pos[1], u.pos[2]))
	return r

static func rio(cena: Node) -> MeshInstance3D:
	return cena.nos.get("n184") as MeshInstance3D
