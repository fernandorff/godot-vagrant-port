class_name Luzes
extends Node3D
## As luzes da sala-fechada.html: tochas fixas, sol e céu, clarões do golpe e das magias, tocha na mão (T), brasas,
## poeira e fumaça. A cena configura de cima (campos abaixo) e chama montar(); a cada quadro escolhe quais fontes fazem
## sombra e passa as fontes para o shader dos bonecos e da fumaça.

const SEMPRE := AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))  # caixa de culling enorme = nunca é cortado
const FORA := 2  # camada dos objetos ao ar livre: só o sol e a luz do céu iluminam essa camada
const CAMADA_BONECOS := 4  # os bonecos também recebem o sol (o shader deles multiplica pelo fora: 0 na caverna)

# configuração (vem da cena)
var energia_ponto := 1.15
var atenuacao := 0.9
var cor_three := true
var caso := 1
var modo_sombra := "suave"
var pcss := false
var tremor_on := true
var some := true
var antes := false  # "Como antes": luz plana, o boneco nunca some
var fumaca_on := true
var meta: Dictionary
var bonecos: Bonecos
var camera: CameraOrbita
var grade: Grade
var salas: Array[MeshInstance3D] = []
var mats_boneco: Array[ShaderMaterial] = []
var discos: Array[MeshInstance3D] = []

var luzes: Array[OmniLight3D] = []
var tochas: Array[Fonte] = []  # as tochas fixas acesas, da mais perto do herói para a mais longe
var claroes: Array[Fonte] = []  # clarões do golpe e das magias (sala-fechada.html:1212-1222)
var brasas: Array[CPUParticles3D] = []
var poeira: MultiMeshInstance3D
var poeira0 := PackedVector3Array()
var fumaca: MeshInstance3D
var sol: DirectionalLight3D
var tempo := 0.0
var chamas_on := true
var particulas_on := true

func perto_de(p: Vector3, raio: float) -> Fonte:  # a tocha fixa ou braseiro mais perto no chão, a até raio (PERTO_FIXA 2)
	var melhor: Fonte = null
	var d := raio * raio
	for c in tochas:
		var q := Vector2(c.luz.position.x - p.x, c.luz.position.z - p.z).length_squared()
		if q < d:
			d = q
			melhor = c
	return melhor

func montar() -> void:
	_luzes()
	_levas()
	_particulas()
	_fumaca()

func _col(h: String) -> Color:  # com cor_three, codifica em sRGB para a decodificação do Godot devolver o valor bruto do Three
	return Color(h).linear_to_srgb() if cor_three else Color(h)

func _textura_chama() -> ImageTexture:  # o mesmo degradê radial do canvas "brilho" do Three (sala-fechada.html:616)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color("#fff6d0"), Color("#ffc060"), Color(1, 110 / 255.0, 30 / 255.0, 0.35), Color(1, 80 / 255.0, 20 / 255.0, 0.0)])
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, g.sample(clampf(Vector2(x - 31.5, y - 31.5).length() / 32.0, 0.0, 1.0)))
	if cor_three: img.linear_to_srgb()
	return ImageTexture.create_from_image(img)

func _sprite(tex: Texture2D, alfa: float) -> MeshInstance3D:  # Sprite aditivo, sem luz e sem névoa (SpriteMaterial do Three)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.disable_fog = true
	m.no_depth_test = false
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1, alfa)
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func _luzes() -> void:
	# uma luz real por tocha acesa (sala-fechada.html:652), tremor por fase (linha 655), chama + halo aditivos (643-644)
	var tex := _textura_chama()
	var cor := _col(meta.luzes[0].cor)
	var alcance: float = meta.luzes[0].distancia
	var alvo := Vector3(meta.unidades[0].pos[0], meta.unidades[0].pos[1], meta.unidades[0].pos[2])
	for f in meta.fogos:  # todas, também as apagadas: a tecla E acende e apaga
		var p := Vector3(f.chama[0], f.chama[1], f.chama[2])
		var o := OmniLight3D.new()
		o.position = p
		o.light_color = cor
		o.omni_range = alcance
		o.omni_attenuation = atenuacao
		o.shadow_bias = 0.032 / alcance * 10.0
		add_child(o)
		luzes.append(o)
		var tam: float = 1.5 if f.braseiro else 0.9
		var sp := _sprite(tex, 1.0)
		sp.position = p
		add_child(sp)
		var halo := _sprite(tex, 0.22)
		halo.position = p
		halo.scale = Vector3.ONE * (5.0 if f.braseiro else 3.5)
		add_child(halo)
		var fo := Fonte.new(Fonte.Tipo.TOCHA, o, Color(meta.luzes[0].cor), alcance)
		fo.chama_sprite = sp
		fo.halo = halo
		fo.forca = f.forca
		fo.tamanho = tam
		fo.fase = f.i * 1.37
		fo.braseiro = f.braseiro
		fo.apagada = f.apagada
		tochas.append(fo)
	tochas.sort_custom(func(a: Fonte, b: Fonte) -> bool: return a.luz.position.distance_squared_to(alvo) < b.luz.position.distance_squared_to(alvo))  # as 2 mais perto do herói projetam sombra (sala-fechada.html:1642-1643)
	aplicar_sombras()
	var s: Dictionary = meta.sol
	sol = DirectionalLight3D.new()
	sol.light_color = _col(s.cor)
	sol.light_energy = s.intensidade
	sol.light_cull_mask = FORA | CAMADA_BONECOS
	sol.shadow_enabled = s.castShadow and caso != 3
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 64.0
	var vies: Array = Array(OS.get_cmdline_user_args()).filter(func(x: String) -> bool: return x.begins_with("--sol-vies="))
	if vies.size(): sol.shadow_bias = float(vies[0].substr(11))  # diagnóstico
	add_child(sol)
	sol.look_at_from_position(Vector3(s.pos[0], s.pos[1], s.pos[2]), Vector3(s.alvo[0], s.alvo[1], s.alvo[2]), Vector3.UP)
	var h: Dictionary = meta.hemisferio  # luz do céu (HemisphereLight): luz direcional para baixo só no ar livre, quebra-galho
	var ceu := DirectionalLight3D.new()
	ceu.light_color = _col(h.ceu)
	ceu.light_energy = h.intensidade
	ceu.light_cull_mask = FORA
	ceu.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(ceu)
	ceu.look_at_from_position(Vector3.ZERO, Vector3.DOWN, Vector3.RIGHT)

# ---- fontes de luz (sala-fechada.html:1601-1646): primeiro as 2 que fazem sombra (a tocha na mão do escolhido, depois as
# tochas fixas mais perto do alvo da câmera), depois o resto por prioridade (clarão, tocha na mão, fixa) e distância ----
func fontes() -> Array[Fonte]:
	var t := camera.alvo_atual()
	var perto: Array[Fonte] = tochas.filter(func(c: Fonte) -> bool: return c.intensidade > 0.0)
	perto.sort_custom(func(a: Fonte, b: Fonte) -> bool: return a.luz.position.distance_squared_to(t) < b.luz.position.distance_squared_to(t))
	var primeiro: Array[Fonte] = []
	if bonecos.sel.leva.intensidade > 0.0: primeiro.append(bonecos.sel.leva)
	for c in perto:
		if primeiro.size() >= 2: break
		primeiro.append(c)
	var resto: Array[Fonte] = []
	var todas: Array[Fonte] = claroes + perto  # tocha apagada não entra (luz() da página só pega fontes que brilham)
	for u in bonecos.unidades:
		if u.leva.intensidade > 0.0: todas.append(u.leva)
	for c in todas:
		if not c in primeiro: resto.append(c)
	resto.sort_custom(func(a: Fonte, b: Fonte) -> bool:
		if a.prioridade() != b.prioridade(): return a.prioridade() > b.prioridade()
		return a.luz.position.distance_squared_to(t) < b.luz.position.distance_squared_to(t))
	return primeiro + resto

func clarao(pos: Vector3, cor: String, pico: float, alcance: float, duracao: float, pulsos: int) -> void:  # sala-fechada.html:1214
	var o := OmniLight3D.new()
	o.position = pos
	o.light_color = _col(cor)
	o.omni_range = alcance
	o.omni_attenuation = atenuacao
	o.light_energy = pico * energia_ponto
	add_child(o)
	var c := Fonte.new(Fonte.Tipo.CLARAO, o, Color(cor), alcance)
	c.pico = pico
	c.intensidade = pico
	c.duracao = duracao
	c.pulsos = pulsos
	claroes.append(c)

# ---- tocha na mão, tecla T (sala-fechada.html:1240-1246, 1286-1301 e 1614-1631) ----
const LEVA_COR := "#ffcc8c"     # Color(1; 0,8; 0,55)
const LEVA_FORCA := 1.5
const LEVA_ALCANCE := 11.0
const FAISCAS := 6

func _levas() -> void:
	var tex := _textura_chama()
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = _col("#4a3020")
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = _col("#3a3632")
	for m: StandardMaterial3D in [madeira, ferro]:
		m.roughness = 1.0
		m.metallic_specular = 0.0
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(1, 0.6, 0.24), Color(0, 0, 0)])  # 0xff9a3c, aditivo
	for u in bonecos.unidades:
		var o := OmniLight3D.new()
		o.light_color = _col(LEVA_COR)
		o.omni_range = LEVA_ALCANCE
		o.omni_attenuation = atenuacao
		o.shadow_bias = 0.032 / LEVA_ALCANCE * 10.0
		o.light_energy = 0.0
		o.visible = false
		add_child(o)
		var l := Fonte.new(Fonte.Tipo.LEVA, o, Color(LEVA_COR), LEVA_ALCANCE)
		l.forca = LEVA_FORCA
		l.fase = randf() * 9.0
		l.lado = int(u.mao.lado)
		l.chama_sprite = _sprite(tex, 1.0)
		l.chama_sprite.visible = false
		add_child(l.chama_sprite)
		u.leva = l
		if int(u.mao.mao) < 0: continue  # sem mão: a luz fica ao lado do ombro, como na página
		var prefixo := u.no.name.get_slice("_", 0)
		var sk: Skeleton3D = null
		for k: Skeleton3D in u.no.find_children("*", "Skeleton3D", true, false):
			if k.find_bone("%s_b%d" % [prefixo, int(u.mao.mao)]) >= 0: sk = k
		if sk == null:
			push_warning("sem esqueleto com a mão de " + u.nome)
			continue
		var g := Node3D.new()
		g.add_child(_cilindro(0.07, 0.045, 1.0, 0.2, madeira))
		g.add_child(_cilindro(0.12, 0.08, 0.2, 0.75, ferro))
		g.visible = false
		add_child(g)
		l.modelo = g
		var pts := CPUParticles3D.new()  # 6 brasas que saem da chama e sobem 0,9 por segundo
		pts.amount = FAISCAS
		pts.lifetime = 1.2
		pts.lifetime_randomness = 0.667
		pts.direction = Vector3.UP
		pts.spread = 15.0
		pts.initial_velocity_min = 0.9
		pts.initial_velocity_max = 0.95
		pts.gravity = Vector3.ZERO
		pts.color_ramp = rampa
		var q := QuadMesh.new()
		q.size = Vector2.ONE * 0.07 * 0.466
		q.material = _material_ponto()
		pts.mesh = q
		pts.emitting = false
		add_child(pts)
		l.faiscas = pts
		if u.mao.escudo != null: l.escudo = u.no.find_child(u.mao.escudo, true, false) as Node3D
		var md := Segura.new()
		md.u = u
		md.mao = sk.find_bone("%s_b%d" % [prefixo, int(u.mao.mao)])
		md.ombro = sk.find_bone("%s_b%d" % [prefixo, int(u.mao.ombro)])
		sk.add_child(md)

func _cilindro(topo: float, base: float, altura: float, y: float, m: Material) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = topo
	cm.bottom_radius = base
	cm.height = altura
	cm.radial_segments = 6
	cm.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = m
	mi.position.y = y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # criada depois das sombras na página: não projeta
	return mi

func _leva(dt: float) -> void:
	for u in bonecos.unidades:
		var l := u.leva
		var tr := _tremor(tempo, l.fase) if tremor_on else 1.0
		l.braco += ((1.0 if l.ligada else 0.0) - l.braco) * minf(1.0, dt * 10.0)  # o braço leva ~0,2 s para subir e descer
		if l.modelo == null:
			l.chama = u.frente(0.4, u.alt * 0.8) + Vector3(cos(u.no.rotation.y) * 0.7, 0, -sin(u.no.rotation.y) * 0.7)
		else:
			l.modelo.visible = l.ligada
			if l.escudo: l.escudo.visible = not l.ligada  # o braço do escudo segura a tocha
			l.faiscas.emitting = l.ligada and brasas.size() > 0 and brasas[0].visible
			l.faiscas.position = l.chama
		l.intensidade = l.forca * tr if l.ligada else 0.0
		l.luz.position = l.chama
		l.luz.visible = l.ligada
		l.chama_sprite.visible = l.ligada
		l.chama_sprite.position = l.chama
		l.chama_sprite.scale = Vector3(0.6, 0.85 * tr, 1.0)

func _tremor(t: float, s: float) -> float:  # sala-fechada.html:655
	return 1.0 + 0.1 * sin(t * 9.1 + s) + 0.06 * sin(t * 23.3 + s * 3.0) + 0.05 * sin(t * 3.3 + s * 7.0)

func _process(dt: float) -> void:
	tempo += dt
	_leva(dt)
	for c in tochas:
		var f := _tremor(tempo, c.fase) if tremor_on else 1.0
		c.intensidade = 0.0 if c.apagada else c.forca * f  # apagada: sem chama, halo, brasas nem luz (sala-fechada.html:1610)
		c.luz.visible = not c.apagada
		if c.apagada: c.luz.shadow_enabled = false  # fora da lista de fontes: ninguém mais mexe nela
		c.chama_sprite.visible = chamas_on and not c.apagada
		c.halo.visible = chamas_on and not c.apagada
		if c.brasas: c.brasas.emitting = particulas_on and not c.apagada
		c.chama_sprite.scale = Vector3(c.tamanho * (0.9 + 0.1 * f), c.tamanho * 1.4 * f, 1.0)  # sala-fechada.html:1608
	for i in range(claroes.size() - 1, -1, -1):  # sala-fechada.html:1611: o clarão cai ao quadrado; o raio pisca em pulsos
		var c := claroes[i]
		c.tempo += dt
		var k := c.tempo / c.duracao
		if k >= 1.0:
			c.luz.queue_free()
			claroes.remove_at(i)
			continue
		c.intensidade = c.pico * pow(1.0 - k, 2.0) * (0.35 if c.pulsos > 1 and sin(k * c.pulsos * PI * 2.0) < 0.0 else 1.0)
	var lista := fontes()
	for i in lista.size():  # a luz real de cada fonte; só as 2 primeiras da lista projetam sombra (sala-fechada.html:1636-1646)
		var c := lista[i]
		c.luz.light_energy = c.intensidade * energia_ponto
		c.luz.shadow_enabled = modo_sombra != "nao" and i < 2 and c.intensidade > 0.0
	var fs := []
	var fc := []
	for c in lista.slice(0, 24):
		fs.append(Vector4(c.luz.position.x, c.luz.position.y, c.luz.position.z, c.intensidade))
		fc.append(Vector4(c.cor.r, c.cor.g, c.cor.b, c.alcance))
	if poeira and poeira.visible:
		for i in poeira0.size():
			var v := poeira0[i] + Vector3(0.15 * sin(tempo * 0.3 + i), 0.2 * sin(tempo * 0.2 + i * 1.7), 0)
			poeira.multimesh.set_instance_transform(i, Transform3D(Basis(), v))
	if fumaca and fumaca.visible:  # as 6 primeiras luzes, como o MAX do fumaca.js
		var sm: ShaderMaterial = fumaca.material_override
		var lp := []
		var lc := []
		var la := []
		for c in lista.slice(0, 6):
			lp.append(c.luz.position)
			var cc: Color = c.cor * c.intensidade
			lc.append(Vector3(cc.r, cc.g, cc.b))
			la.append(c.alcance)
		sm.set_shader_parameter("tempo", tempo)
		sm.set_shader_parameter("luz_pos", lp)
		sm.set_shader_parameter("luz_cor", lc)
		sm.set_shader_parameter("luz_alc", la)
		sm.set_shader_parameter("n_luz", lp.size())
	for dm in discos:  # opacidade 0,5 x min(1, luz no boneco / 0,05), com a luz medida 1,5 acima do disco
		var p := dm.global_position + Vector3(0, 1.5, 0)
		var lz := 0.0
		for i in fs.size():
			var f: Vector4 = fs[i]
			var d := p.distance_to(Vector3(f.x, f.y, f.z))
			var j := clampf(1.0 - pow(d / fc[i].w, 2.0), 0.0, 1.0)
			lz += f.w * j * j * 16.0 / (d * d + 16.0) * maxf(fc[i].x, maxf(fc[i].y, fc[i].z))
		var m3: BaseMaterial3D = dm.material_override
		m3.albedo_color.a = 0.5 * minf(1.0, lz / 0.05) if some else 0.5
		if some and grade:  # ao ar livre o sol e o céu também mostram o disco (planta-mundo.js:630)
			var fo := grade.fora_de(dm.global_position)
			m3.albedo_color.a = maxf(m3.albedo_color.a, 0.5 * minf(1.0, float(meta.HORA.si) * fo.x + float(meta.HORA.ci) * fo.y))
		if Grade.molha(dm.global_position): m3.albedo_color.a = 0.0  # o disco afundaria com ele (sala-fechada.html:1700)
	for m in mats_boneco:
		m.set_shader_parameter("fogos", fs)
		m.set_shader_parameter("fogos_cor", fc)
		m.set_shader_parameter("n_fogos", fs.size())
		m.set_shader_parameter("some", some)
		m.set_shader_parameter("antes", antes)

func aplicar_sombras() -> void:
	# sala-fechada.html:692-699: só as 2 primeiras luzes projetam; dura = mapa 128 sem filtro, suave = 512 com PCF
	var q := RenderingServer.SHADOW_QUALITY_HARD if modo_sombra == "dura" else RenderingServer.SHADOW_QUALITY_SOFT_HIGH
	RenderingServer.positional_soft_shadow_filter_set_quality(q)
	get_viewport().positional_shadow_atlas_size = 1024 if modo_sombra == "dura" else 4096  # casas de 128 ou 512 px (subdivisão 16)
	for i in tochas.size():
		var l: OmniLight3D = tochas[i].luz
		l.shadow_enabled = modo_sombra != "nao" and i < 2
		l.light_size = 0.4 if pcss else 0.0  # PCSS_LUZ 0.4 da página (raio da tocha em tiles); 0 = sombra sem penumbra
	if sol: sol.shadow_enabled = meta.sol.castShadow and caso != 3

func _material_ponto() -> StandardMaterial3D:  # PointsMaterial aditivo do Three: cor por ponto, sem luz e sem névoa
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true  # valor bruto, como o Three
	m.disable_fog = true
	return m

func _particulas() -> void:
	# brasas: 10 por tocha acesa, sobem e apagam, renascem na chama (sala-fechada.html:981-989 e 1662-1667)
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([Color(1, 0.45, 0.12), Color(0, 0, 0)])
	for c in tochas:
		var b := CPUParticles3D.new()
		b.amount = 10
		b.lifetime = 2.4
		b.lifetime_randomness = 0.667  # vida de 0,8 a 2,4 s
		b.direction = Vector3.UP
		b.spread = 14.0  # lateral de +-0,2 contra subida de 0,7 a 1,5
		b.initial_velocity_min = 0.7
		b.initial_velocity_max = 1.5
		b.gravity = Vector3.ZERO
		b.color_ramp = rampa
		var q := QuadMesh.new()
		q.size = Vector2.ONE * 0.09 * 0.466  # ponto do Three: size x 360 / distância px = size x tan(25°) no mundo (fov 50, 720 px)
		q.material = _material_ponto()
		b.mesh = q
		b.position = c.luz.position
		b.preprocess = 2.4
		add_child(b)
		brasas.append(b)
		c.brasas = b
	# poeira: 350 grãos parados no ar, tingidos uma vez pelas tochas perto (só aparecem na luz), balançando devagar
	# shortcut: o Three sorteia as células da planta e a altura até o teto; aqui sorteia vértices de chão da sala e 0,3 a 4,0 acima
	var chao := PackedVector3Array()
	for mi in salas:
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		for i in vs.size():
			if (mi.global_transform.basis * ns[i]).normalized().y > 0.9: chao.append(mi.global_transform * vs[i])
	if chao.is_empty(): return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = 350
	var q2 := QuadMesh.new()
	q2.size = Vector2.ONE * 0.06 * 0.466
	var mp := _material_ponto()
	mp.albedo_color = Color(1, 1, 1, 0.7)
	q2.material = mp
	mm.mesh = q2
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 350:
		var v := chao[rng.randi() % chao.size()] + Vector3(rng.randf_range(-1, 1), 0.3 + rng.randf() * 3.7, rng.randf_range(-1, 1))
		poeira0.append(v)
		mm.set_instance_transform(i, Transform3D(Basis(), v))
	poeira = MultiMeshInstance3D.new()
	poeira.multimesh = mm
	poeira.custom_aabb = SEMPRE
	add_child(poeira)
	tinge()

func tinge() -> void:  # tinge() da página (sala-fechada.html:948): cada grão pega a cor das tochas acesas perto; chamar ao acender ou apagar
	if poeira == null: return
	for i in poeira0.size():
		var k := 0.0
		for c in tochas: if not c.apagada: k += c.forca * pow(maxf(0.0, 1.0 - poeira0[i].distance_to(c.luz.position) / 10.0), 2.0)
		k = minf(1.2, k)
		poeira.multimesh.set_instance_color(i, Color(k * 0.9, k * 0.75, k * 0.6))

func _fumaca() -> void:  # parâmetros lidos da página em 20/11 (export/fumaca.json: caixa, fontes, cor, densidade)
	var f: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://export/fumaca.json"))
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)  # ruído: G aleatório, R = G deslocado (37,17), como a página
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var g := PackedByteArray()
	g.resize(256 * 256)
	for i in g.size(): g[i] = rng.randi() % 256
	for y in 256:
		for x in 256:
			img.set_pixel(x, y, Color8(g[((y + 17) & 255) * 256 + ((x + 37) & 255)], g[y * 256 + x], 0, 255))
	var sm := ShaderMaterial.new()
	sm.shader = load("res://fumaca.gdshader")
	sm.set_shader_parameter("ruido_tex", ImageTexture.create_from_image(img))
	sm.set_shader_parameter("cmin", Vector3(f.min[0], f.min[1], f.min[2]))
	sm.set_shader_parameter("cmax", Vector3(f.max[0], f.max[1], f.max[2]))
	sm.set_shader_parameter("cor", Vector3(f.cor[0], f.cor[1], f.cor[2]))
	sm.set_shader_parameter("amb", Vector3(f.amb[0], f.amb[1], f.amb[2]))
	sm.set_shader_parameter("dens", f.dens)
	sm.set_shader_parameter("altura", f.alt)
	sm.set_shader_parameter("cob", f.cob)
	var fs := []
	for x in f.fontes: fs.append(Vector4(x[0], x[1], x[2], x[3]))
	sm.set_shader_parameter("fonte", fs)
	sm.set_shader_parameter("n_fonte", fs.size())
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	fumaca = MeshInstance3D.new()
	fumaca.mesh = q
	sm.render_priority = Material.RENDER_PRIORITY_MAX  # por cima das chamas e halos (renderOrder 999 da página)
	fumaca.material_override = sm
	fumaca.custom_aabb = SEMPRE
	fumaca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fumaca.visible = fumaca_on
	add_child(fumaca)
