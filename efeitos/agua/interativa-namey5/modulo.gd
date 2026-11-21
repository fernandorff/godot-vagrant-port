extends Node
# godot-interactive-water (Namey5, MIT): equação da onda na placa de vídeo em dois SubViewports que se copiam (pingue-pongue)
# + superfície com refração em tela e espalhamento por profundidade. Adaptado: os pés dos bonecos no lugar do mouse,
# grade num quadrado do mundo sobre a poça, simulação a 60 passos por segundo (o original roda um passo por quadro).

const NOME := "Água interativa (Namey5, onda na placa de vídeo)"
const EXCLUSIVO := true
const VISTA := "bonecos"
const C := preload("../comum/agua_comum.gd")
const N := 1024          # tamanho da grade, igual ao original (o shader da superfície supõe 1024)
const PASSO := 1.0 / 60.0

var rio: MeshInstance3D
var mat: ShaderMaterial
var mat_sim: ShaderMaterial
var sim: SubViewport
var buf: SubViewport
var aneis := C.Aneis.new()  # reaproveita o relógio dos passos (entrar, parado a cada 1,3 s) para saber quando empurrar
var pes: Array = []
var regiao := Vector3()
var acum := 0.0
var visto := 0

func ligar(cena: Node3D) -> void:
	pes = C.pes(cena)
	var lado := maxf(C.POCA_TAM.x, C.POCA_TAM.y)
	regiao = Vector3(C.POCA_CENTRO.x - lado / 2.0, C.POCA_CENTRO.z - lado / 2.0, lado)
	# pingue-pongue: sim desenha a partir de buf; buf copia sim (o original faz o mesmo com ViewportTexture por caminho)
	sim = _vp("Simulacao")
	buf = _vp("Copia")
	add_child(sim)
	sim.add_child(buf)
	mat_sim = ShaderMaterial.new()
	mat_sim.shader = load("res://efeitos/agua/interativa-namey5/water_simulation.gdshader")
	var r_sim := _ret(buf.get_texture())
	r_sim.material = mat_sim
	sim.add_child(r_sim)
	buf.add_child(_ret(sim.get_texture()))
	mat = ShaderMaterial.new()
	mat.shader = load("res://efeitos/agua/interativa-namey5/water.gdshader")
	var n := FastNoiseLite.new()  # waves_map de materials/water.tres: simplex, 2 oitavas, mapa normal
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.fractal_octaves = 2
	var t := NoiseTexture2D.new()
	t.noise = n
	t.seamless = true
	t.as_normal_map = true
	mat.set_shader_parameter("waves_map", t)
	mat.set_shader_parameter("ripples_map", sim.get_texture())
	mat.set_shader_parameter("regiao", regiao)
	mat.set_shader_parameter("scattering", Color(1, 0.398236, 0.411946))
	mat.set_shader_parameter("displacement_height", 0.01)  # 0,1 no original (piscina de 4 x 6); aqui água rasa
	rio = C.rio(cena)
	if rio == null:
		push_error("agua/interativa-namey5: nó n184 (rio) não encontrado")
	else:
		rio.material_override = mat
	C.criar_poca(self, 96).material_override = mat

func _vp(nome: String) -> SubViewport:
	var v := SubViewport.new()
	v.name = nome
	v.size = Vector2i(N, N)
	v.disable_3d = true
	v.render_target_update_mode = SubViewport.UPDATE_DISABLED
	v.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	return v

func _ret(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = Vector2(N, N)
	return r

func desligar() -> void:
	if rio != null and rio.material_override == mat:
		rio.material_override = null

func _process(dt: float) -> void:
	if visto == 0 and aneis.tempo > 2.5 and OS.has_environment("AGUA_DIAG"):  # diagnóstico: grava a grade de ondas
		visto = 1
		var img := sim.get_texture().get_image()
		img.save_png(OS.get_environment("AGUA_DIAG"))
		var mn := 1.0
		var mx := 0.0
		for y in range(0, N, 4):
			for x in range(0, N, 4):
				var r := img.get_pixel(x, y).r
				mn = minf(mn, r)
				mx = maxf(mx, r)
		print("AGUA_DIAG altura (0..1, repouso 0,5): min ", mn, " max ", mx)
	acum += dt
	if acum < PASSO:
		return
	var passo := acum
	acum = 0.0
	var antes := aneis.slots.duplicate()
	aneis.atualizar(passo, pes, C.na_poca)
	var empurra: Array[Vector4] = []
	for i in 8: empurra.append(Vector4(0, 0, 0, 0))
	var k := 0
	for i in aneis.slots.size():  # anel novo neste passo = pé empurrando a água agora
		var a: Vector4 = aneis.slots[i]
		if a != antes[i] and k < 8:
			empurra[k] = Vector4((a.x - regiao.x) / regiao.z, (a.y - regiao.y) / regiao.z, minf(1.0, a.w), 0.0)
			k += 1
	mat_sim.set_shader_parameter("pes", empurra)
	sim.render_target_update_mode = SubViewport.UPDATE_ONCE
	buf.render_target_update_mode = SubViewport.UPDATE_ONCE
