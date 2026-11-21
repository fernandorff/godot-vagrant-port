class_name Grade
extends RefCounted
# A grade de andar da sala-fechada.html (export/grade.json, gerado por exportar-bonecos.mjs): caminho() e seco() da página.
# A água fica de fora (etapa 8): passo para célula molhada custa 3,5, como CUSTO_AGUA, mas o chão é sempre o seco.

const VIZ := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
var W: int
var H: int
var CEL: float
var PASSO: float
var NX: int
var NZ: int
var celulas: Array
var alt: PackedFloat32Array
var testes: Array
var bloq: PackedByteArray
var letras: PackedStringArray     # export/letras.json: a letra de cada casa (s.letra da página)
var fora_letras := ",:TRrbhH"     # FORA de planta-mundo.js:13: ar livre

func _init(arquivo: String) -> void:
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(arquivo))
	W = g.W; H = g.H; CEL = g.CEL; PASSO = g.PASSO; NX = g.NX; NZ = g.NZ
	celulas = g.celulas
	alt = PackedFloat32Array(g.alt)
	bloq = PackedByteArray(g.bloq)
	testes = g.testes
	if FileAccess.file_exists("res://export/letras.json"):
		var l: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://export/letras.json"))
		letras = PackedStringArray(l.linhas)
		fora_letras = l.FORA

func letra(c: Vector2i) -> String:
	if c.y < 0 or c.y >= letras.size() or c.x < 0 or c.x >= letras[c.y].length(): return "#"
	return letras[c.y][c.x]

# foraDe() de planta-mundo.js:576: quanto sol (x) e céu (y) chega ao boneco nessa casa; caverna 0, dentro da casa só um pouco de céu
func fora_de(p: Vector3) -> Vector2:
	var l := letra(Vector2i(floori(p.x / CEL), floori(p.z / CEL)))
	if not l in fora_letras: return Vector2.ZERO
	return Vector2(1.0, 0.3) if l == "h" else Vector2.ONE

# molha() da planta mundo (planta-mundo.js:33 e 95-96): o leito fica abaixo da água até 1,75 tile do centro do rio;
# com y, só quem está no nível da água (na ponte, não). A única água da planta mundo é o rio.
const AGUA_Y := 0.04

static func rio_x(z: float) -> float:  # centro do rio em tiles, RIO(z) da página em células de 2
	return (35.0 + 1.6 * sin(z / 2.0 * 0.17 + 0.6)) * 2.0

static func molha(p: Vector3) -> bool:
	return absf(p.x - rio_x(p.z)) < 1.75 and p.y <= AGUA_Y + 0.1

func pisa(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H and int(celulas[c.y * W + c.x].p) == 1

# shortcut: altura interpolada numa amostra de 0,25 tile da seco() da página; a borda de um degrau vira rampa de 0,25. Trocar pelo porte de seco() se um pé flutuar.
func seco(x: float, z: float) -> float:
	var fx := clampf(x / PASSO, 0.0, NX - 1.001)
	var fz := clampf(z / PASSO, 0.0, NZ - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var ax := fx - ix
	var az := fz - iz
	var a := lerpf(alt[iz * NX + ix], alt[iz * NX + ix + 1], ax)
	var b := lerpf(alt[(iz + 1) * NX + ix], alt[(iz + 1) * NX + ix + 1], ax)
	return lerpf(a, b, az)

# shortcut: P.bloqueia() da página na amostra mais próxima de 0,25 tile; um obstáculo fino pode escapar entre amostras
func bloqueia(x: float, z: float) -> bool:
	var ix := clampi(roundi(x / PASSO), 0, NX - 1)
	var iz := clampi(roundi(z / PASSO), 0, NZ - 1)
	return bloq[iz * NX + ix] == 1

# sala-fechada.html:1405: a pegada (4 pontos a RAIO 0,6) fica em chão andável, a até um degrau de y (no ar: até 0,6 acima dos pés)
func livre(x: float, z: float, y: float, ar: bool) -> bool:
	for o in [Vector2(0.6, 0), Vector2(-0.6, 0), Vector2(0, 0.6), Vector2(0, -0.6)]:
		var px: float = x + o.x
		var pz: float = z + o.y
		if not pisa(Vector2i(floori(px / CEL), floori(pz / CEL))) or bloqueia(px, pz): return false
		var d := seco(px, pz)
		if (d > y + 0.6) if ar else (absf(d - y) >= 0.6): return false
	return true

# sala-fechada.html:1342: a rota mais barata; fila ordenada por custo, custos iguais na ordem de chegada (mesmas rotas da página)
func caminho(de: Vector2i, para: Vector2i) -> Array:
	var veio := {de: null}
	var custo := {de: 0.0}
	var fila := [[de, 0.0]]
	while fila.size():
		var it: Array = fila.pop_front()
		var c: Vector2i = it[0]
		if it[1] > custo[c]: continue
		if c == para: break
		var v: Array = celulas[c.y * W + c.x].v
		for i in 4:
			var passo: float = v[i]
			if passo == 0.0: continue
			var n: Vector2i = c + VIZ[i]
			var g: float = custo[c] + passo
			if custo.has(n) and custo[n] <= g: continue
			veio[n] = c
			custo[n] = g
			var k := fila.size()
			while k and fila[k - 1][1] > g: k -= 1
			fila.insert(k, [n, g])
	if not veio.has(para): return []
	var rota := []
	var c = para
	while c != null and c != de:
		rota.push_front(c)
		c = veio[c]
	return rota

func confere() -> String:  # as rotas da página (gravadas no export) contra as daqui
	var ok := 0
	for t in testes:
		var r := caminho(Vector2i(t.de[0], t.de[1]), Vector2i(t.para[0], t.para[1]))
		var esperado: Array = t.rota if t.rota != null else []
		var igual := r.size() == esperado.size()
		if igual:
			for i in r.size():
				if r[i] != Vector2i(esperado[i][0], esperado[i][1]): igual = false
		if igual: ok += 1
	return "%d de %d rotas iguais à página" % [ok, testes.size()]
