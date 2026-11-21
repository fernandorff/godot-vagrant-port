class_name CameraOrbita
extends Camera3D
## A câmera da sala-fechada.html (sala-fechada.html:1312-1333 e 1696): órbita em volta do escolhido, arrastar gira,
## roda aproxima, e a névoa se afasta com a distância. Também apaga as paredes que tapam o corpo (1564-1590).

const DIST0 := 11.7              # distância inicial; a névoa só se afasta acima dela
const POLAR_MIN := 0.6
const POLAR_MAX := 1.5
const DIST_MIN := 6.0
const DIST_MAX := 44.0
const GIRA_X := 0.008            # rad por pixel arrastado
const GIRA_Y := 0.006
const SEGUE := 6.0               # lerp do alvo por segundo
const SOME_EM := 0.25            # s para a parede sumir ou voltar

class Parede:
	var no: GeometryInstance3D
	var nome: String
	var a: Vector2
	var b: Vector2
	var n: Vector3
	var y0: float
	var y1: float
	var op: float

var az := 0.0
var polar := 1.3
var dist := DIST0
var fixa := false                # --olhar ou --cam: câmera de diagnóstico, sem órbita
var bonecos: Bonecos
var grade: Grade
var ambiente: Environment
var nevoa_perto := 0.0
var nevoa_longe := 0.0
var paredes: Array[Parede] = []
var _alvo := Vector3.ZERO
var _rs := Vector2.ZERO          # analógico direito
var _zoom := 0.0                 # direcional: baixo afasta, cima aproxima

func iniciar(c: Dictionary, b: Bonecos, g: Grade, e: Environment, nevoa: Dictionary) -> void:
	fov = c.fov
	near = c.near
	far = c.far
	global_transform = Transform3D(Basis(Quaternion(c.quat[0], c.quat[1], c.quat[2], c.quat[3])), Vector3(c.pos[0], c.pos[1], c.pos[2]))
	bonecos = b
	grade = g
	ambiente = e
	nevoa_perto = nevoa.near
	nevoa_longe = nevoa.far
	_alvo = alvo()

func carregar_paredes(arquivo: String, nos: Dictionary) -> void:  # export/paredes.json: as 99 paredes com o nó do GLB
	for w: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(arquivo)):
		var n = nos.get(w.no)
		if not n is GeometryInstance3D: continue
		var p := Parede.new()
		p.no = n
		p.nome = w.nome
		p.a = Vector2(w.a[0], w.a[1])
		p.b = Vector2(w.b[0], w.b[1])
		p.n = Vector3(w.n[0], w.n[1], w.n[2])
		p.y0 = w.y0
		p.y1 = w.y1
		p.op = 1.0 if p.no.visible else 0.0  # o export saiu com as paredes da vista padrão já apagadas
		paredes.append(p)

func apagadas() -> Array[String]:
	var r: Array[String] = []
	for p in paredes:
		if not p.no.visible or p.no.transparency > 0.5: r.append(p.nome)
	return r

func alvo() -> Vector3:  # sala-fechada.html:1333: o peito do escolhido, nunca abaixo de 0,6 sobre o chão
	var p := bonecos.sel.no.position
	return Vector3(p.x, maxf(p.y + bonecos.sel.alt * 0.65, grade.seco(p.x, p.z) + 0.6), p.z)

func alvo_atual() -> Vector3:
	return _alvo

func salta() -> void:  # vai direto ao alvo, sem o lerp (atravessou a porta)
	_alvo = alvo()

func _process(dt: float) -> void:
	if fixa: return
	# controle (sala-fechada.html:1462): analógico direito gira e inclina, direcional cima e baixo aproxima e afasta
	if not MenuOpcoes.aberto:  # com o menu aberto o direcional navega no menu
		az -= (_rs.x if absf(_rs.x) >= Bonecos.ZONA else 0.0) * 2.2 * dt
		polar = clampf(polar - (_rs.y if absf(_rs.y) >= Bonecos.ZONA else 0.0) * 1.4 * dt, POLAR_MIN, POLAR_MAX)
		dist = clampf(dist * (1.0 + _zoom * 1.5 * dt), DIST_MIN, DIST_MAX)
	_alvo = _alvo.lerp(alvo(), minf(1.0, dt * SEGUE))
	poe()
	_some_paredes(dt)

func poe() -> void:  # sala-fechada.html:1314-1318
	position = _alvo + Vector3(dist * sin(polar) * sin(az), dist * cos(polar), dist * sin(polar) * cos(az))
	look_at(_alvo)
	if ambiente:
		var k := maxf(0.0, dist - DIST0)
		ambiente.fog_depth_begin = nevoa_perto + k
		ambiente.fog_depth_end = nevoa_longe + k

func _unhandled_input(ev: InputEvent) -> void:  # sala-fechada.html:1319-1331
	if ev is InputEventJoypadMotion:
		var m := ev as InputEventJoypadMotion
		if m.axis == JOY_AXIS_RIGHT_X: _rs.x = m.axis_value
		elif m.axis == JOY_AXIS_RIGHT_Y: _rs.y = m.axis_value
	elif ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
		var sinal := 1.0 if (ev as InputEventJoypadButton).button_index == JOY_BUTTON_DPAD_DOWN else -1.0
		_zoom = sinal if ev.pressed else 0.0
	if ev is InputEventMouseMotion and (ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		var r := (ev as InputEventMouseMotion).relative
		az -= r.x * GIRA_X
		polar = clampf(polar - r.y * GIRA_Y, POLAR_MIN, POLAR_MAX)
	elif ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		dist = clampf(dist * (1.1 if (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN else 0.9), DIST_MIN, DIST_MAX)

static func _tapa(f: Parede, t: Vector3, c: Vector3) -> bool:  # a linha t->c cruza o segmento da parede entre y0 e y1 (sala-fechada.html:1564)
	var dx := c.x - t.x
	var dz := c.z - t.z
	var ex := f.b.x - f.a.x
	var ez := f.b.y - f.a.y
	var den := dx * ez - dz * ex
	if absf(den) < 1e-9: return false
	var s := ((f.a.x - t.x) * ez - (f.a.y - t.z) * ex) / den
	var u := ((f.a.x - t.x) * dz - (f.a.y - t.z) * dx) / den
	if s <= 0 or s > 1 or u < 0 or u > 1: return false
	var y := t.y + s * (c.y - t.y)
	return y > f.y0 and y < f.y1

func _some_paredes(dt: float) -> void:  # sala-fechada.html:1578-1590: some quando a câmera está fora ou a parede tapa o corpo
	var c := position
	var p := bonecos.sel.no.position
	var dx := c.x - p.x
	var dz := c.z - p.z
	var l := maxf(Vector2(dx, dz).length(), 1e-6)
	var pts: Array[Vector3] = []
	for h: float in [0.1, 0.65, 0.95]:
		for sd: float in [-0.5, 0.0, 0.5]: pts.append(Vector3(p.x + (-dz / l) * sd, p.y + bonecos.sel.alt * h, p.z + (dx / l) * sd))
	for f in paredes:
		var fora := Vector3(c.x - f.a.x, 0, c.z - f.a.y).dot(f.n) < 0
		var tapa := false
		if not fora:
			for q in pts:
				if _tapa(f, q, c):
					tapa = true
					break
		var quer := 0.0 if fora or tapa else 1.0
		var op := clampf(f.op + signf(quer - f.op) * minf(absf(quer - f.op), dt / SOME_EM), 0.0, 1.0)
		if op == f.op: continue
		f.op = op
		f.no.visible = op > 0.0
		f.no.transparency = 1.0 - op  # transparência por instância: vale com qualquer material (inclusive o da luz assada)
