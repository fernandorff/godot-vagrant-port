class_name Bonecos
extends Node3D
## Os 8 bonecos da sala-fechada.html: escolha, clique, teclado, pulo, golpe e magias.
## Pede os clarões para a cena pelo sinal clarao_pedido (a luz é da cena, sala-fechada.html:1212-1222).

signal clarao_pedido(pos: Vector3, cor: String, pico: float, alcance: float, duracao: float, pulsos: int)
signal peso_trocou(peso: String)

const TECLAS := {KEY_W: Vector2(0, -1), KEY_UP: Vector2(0, -1), KEY_S: Vector2(0, 1), KEY_DOWN: Vector2(0, 1),
	KEY_A: Vector2(-1, 0), KEY_LEFT: Vector2(-1, 0), KEY_D: Vector2(1, 0), KEY_RIGHT: Vector2(1, 0)}  # DIR da página
const GOLPE_ACERTA := 0.35       # s até o golpe acertar (sala-fechada.html:1218)
const MAGIA_SAI := 0.9           # s até a magia sair (sala-fechada.html:1220)
const RAIO_PEGA := 0.8           # shortcut: cilindro de raio 0,8 no lugar da caixa "pega" da página; trocar se errar o clique no Minotauro
const ARRASTO_CLIQUE := 6.0      # px: menos que isso é clique; mais é órbita da câmera
const ZONA := 0.2                # zona morta dos analógicos (sala-fechada.html:1413)

var unidades: Array[Unidade] = []
var sel: Unidade
var grade: Grade
var az_camera := 0.0             # a órbita da câmera: o teclado anda em relação a ela
var _arrasto := 0.0
var eixos := {}                  # eixo do controle -> valor, pelos eventos (assim o teste por parse_input_event vale igual)
var usa_fixa: Callable           # RS apertado: só a tocha fixa perto (na página o RS não abre porta)
var usa: Callable                # E: a cena tenta a porta e a tocha fixa perto; devolve false se não havia nada (aí E troca)

static func so_do_boneco(an: Animation, nome: String) -> void:
	# o glTF põe em cada clipe trilhas paradas de TODOS os esqueletos; sem tirá-las, o player de cada boneco
	# regravava a pose dos outros a cada quadro e ninguém se mexia (medido 21/11: 228 trilhas, 28 variam)
	var prefixo := nome.get_slice("_", 0) + "_"  # u0_c3 -> "u0_", o mesmo prefixo dos ossos u0_b*
	for i in range(an.get_track_count() - 1, -1, -1):
		if not an.track_get_path(i).get_concatenated_subnames().begins_with(prefixo): an.remove_track(i)

static func curva_s() -> Curve:  # a mistura do crossFade do Three: começa e termina devagar (inclinação zero nas pontas)
	var c := Curve.new()
	c.add_point(Vector2(0, 0), 0.0, 0.0)
	c.add_point(Vector2(1, 1), 0.0, 0.0)
	return c

# Uma AnimationTree por boneco: uma Transição com uma entrada por clipe (a mistura em curva S) e o ritmo (TimeScale).
# O AnimationPlayer só guarda os clipes.
func _arvore(p: AnimationPlayer, l: AnimationLibrary, raiz: Node, raiz_anim: Node) -> AnimationTree:
	var bt := AnimationNodeBlendTree.new()
	var tr := AnimationNodeTransition.new()
	tr.xfade_curve = curva_s()
	tr.allow_transition_to_self = true
	bt.add_node(&"troca", tr)
	var i := 0
	for nome: StringName in l.get_animation_list():
		var na := AnimationNodeAnimation.new()
		na.animation = nome
		bt.add_node(nome, na)
		tr.add_input(nome)
		bt.connect_node(&"troca", i, nome)
		i += 1
	bt.add_node(&"ritmo", AnimationNodeTimeScale.new())
	bt.connect_node(&"ritmo", 0, &"troca")
	bt.connect_node(&"output", 0, &"ritmo")
	var arv := AnimationTree.new()
	raiz.add_child(arv)
	arv.tree_root = bt
	arv.anim_player = arv.get_path_to(p)
	arv.root_node = arv.get_path_to(raiz_anim)
	p.active = false
	arv.active = true
	return arv

func montar(raiz: Node, lib: AnimationLibrary, raiz_anim: Node, defs: Array, g: Grade) -> void:
	grade = g
	for d: Dictionary in defs:
		var p := AnimationPlayer.new()  # um AnimationPlayer por boneco, como um mixer do Three por boneco
		var l := AnimationLibrary.new()
		for gesto: String in d.gestos:
			for nome: String in d.gestos[gesto]:
				if l.has_animation(nome): continue
				var an: Animation = lib.get_animation(nome)
				an.length = d.duracoes[nome]  # a duração do clipe do Three (o glTF só guarda até a última chave)
				an.loop_mode = Animation.LOOP_LINEAR if gesto == "parado" else Animation.LOOP_NONE  # só o parado repete; andar alterna as metades
				so_do_boneco(an, nome)
				l.add_animation(nome, an)
		for modo: String in d.poses:
			if d.poses[modo] == null: continue
			for fase: String in d.poses[modo]:
				var nome_pose: String = d.poses[modo][fase]
				var ap: Animation = lib.get_animation(nome_pose)
				ap.length = d.duracoes[nome_pose]
				ap.loop_mode = Animation.LOOP_LINEAR  # poeFase: LoopRepeat
				so_do_boneco(ap, nome_pose)
				l.add_animation(nome_pose, ap)
		raiz.add_child(p)
		p.root_node = p.get_path_to(raiz_anim)
		p.add_animation_library("", l)
		var arv := _arvore(p, l, raiz, raiz_anim)
		unidades.append(Unidade.new(d, raiz.find_child(d.no, true, false) as Node3D, p, arv, grade))
	sel = unidades[0]

func _process(dt: float) -> void:  # sala-fechada.html:1678-1692: rotas, depois conduz() (pulo, teclado, quem anda sem rota)
	if unidades.is_empty(): return
	var corre := Input.is_key_pressed(KEY_SHIFT) or eixo_pad(JOY_AXIS_TRIGGER_RIGHT) > 0.5  # RT segurado corre
	for u in unidades:
		u.anda_rota(u == sel and corre, dt)
	var eixo := Vector2.ZERO
	for k: Key in TECLAS:
		if Input.is_physical_key_pressed(k): eixo += TECLAS[k]
	eixo += Vector2(eixo_pad(JOY_AXIS_LEFT_X), eixo_pad(JOY_AXIS_LEFT_Y))  # analógico esquerdo anda
	eixo = eixo.limit_length(1.0)
	for u in unidades:
		u.voa(dt)
	for u in unidades:
		if u != sel: u.solta()
	if sel: sel.dirige(eixo.x, eixo.y, corre, az_camera)
	for u in unidades:
		if u.rota.is_empty(): u.rola(dt)
	for u in unidades:  # planta-mundo.js:627: sol e céu chegam devagar (sair do túnel não é um interruptor)
		u.fora += (grade.fora_de(u.no.position) - u.fora) * minf(1.0, dt * 3.0)
		for m in u.mats: m.set_shader_parameter("fora", u.fora)

func eixo_pad(e: JoyAxis) -> float:
	var v: float = eixos.get(e, 0.0)
	return 0.0 if absf(v) < ZONA or MenuOpcoes.aberto else v

func _unhandled_input(ev: InputEvent) -> void:
	_controle(ev)
	if ev is InputEventKey and ev.pressed and not ev.echo and sel:
		match (ev as InputEventKey).keycode:
			KEY_SPACE: sel.pula(Input.is_key_pressed(KEY_SHIFT))
			KEY_K: ataca(sel)
			KEY_F: conjura(sel, "fogo")
			KEY_R: conjura(sel, "raio")
			KEY_T: sel.leva.ligada = not sel.leva.ligada
			KEY_Q: troca(-1)
			KEY_E: if not (usa.is_valid() and usa.call()): troca(1)
			KEY_P: peso_trocou.emit(Unidade.troca_peso())
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed: _arrasto = 0.0
		elif _arrasto < ARRASTO_CLIQUE: clique(get_viewport().get_camera_3d(), (ev as InputEventMouseButton).position)
	if ev is InputEventMouseMotion and (ev as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		_arrasto += (ev as InputEventMouseMotion).relative.length()

# Controle (sala-fechada.html:1408-1416, mapa padrão Xbox/PlayStation): A pula, X golpe, B fogo, LT raio, Y tocha,
# LB/RB e direcional dos lados trocam o boneco, RS apertado mexe na tocha fixa perto. A câmera lê o analógico direito.
func _controle(ev: InputEvent) -> void:
	if ev is InputEventJoypadMotion:
		var m := ev as InputEventJoypadMotion
		var antes: float = eixos.get(m.axis, 0.0)
		eixos[m.axis] = m.axis_value
		if m.axis == JOY_AXIS_TRIGGER_LEFT and m.axis_value > 0.5 and antes <= 0.5 and sel and not MenuOpcoes.aberto: conjura(sel, "raio")
	elif ev is InputEventJoypadButton and ev.pressed and sel and not MenuOpcoes.aberto:
		match (ev as InputEventJoypadButton).button_index:
			JOY_BUTTON_A: sel.pula(eixo_pad(JOY_AXIS_TRIGGER_RIGHT) > 0.5)
			JOY_BUTTON_X: ataca(sel)
			JOY_BUTTON_B: conjura(sel, "fogo")
			JOY_BUTTON_Y: sel.leva.ligada = not sel.leva.ligada
			JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_DPAD_LEFT: troca(-1)
			JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_RIGHT: troca(1)
			JOY_BUTTON_RIGHT_STICK: if usa_fixa.is_valid(): usa_fixa.call()

func troca(passo: int) -> void:  # Q e E
	sel = unidades[(unidades.find(sel) + passo + unidades.size()) % unidades.size()]

# sala-fechada.html:1218-1222
func ataca(u: Unidade) -> void:
	u.toca("golpe")
	await get_tree().create_timer(GOLPE_ACERTA).timeout
	clarao_pedido.emit(u.frente(1.4, u.alt * 0.55), "#ffc890", 5.0, 9.0, 0.3, 1)

func conjura(u: Unidade, tipo: String) -> void:
	u.toca("magia")
	await get_tree().create_timer(MAGIA_SAI).timeout
	if tipo == "fogo": clarao_pedido.emit(u.frente(2.2, u.alt * 0.6), "#ff7a20", 9.0, 14.0, 0.5, 1)
	else: clarao_pedido.emit(u.frente(2.2, u.alt * 0.9), "#8ab8ff", 10.0, 16.0, 0.45, 3)

# sala-fechada.html:1358: num boneco escolhe; no chão, o escolhido anda até a casa
func clique(camera: Camera3D, tela: Vector2) -> void:
	var o := camera.project_ray_origin(tela)
	var d := camera.project_ray_normal(tela)
	var melhor: Unidade = null
	var t_melhor := 1e9
	for u in unidades:
		var p := u.no.global_position
		for k in 12:
			var y := p.y + u.alt * (k + 0.5) / 12.0
			var t := (y - o.y) / d.y if absf(d.y) > 1e-5 else -1.0
			if t <= 0.0: continue
			var q := o + d * t
			if Vector2(q.x - p.x, q.z - p.z).length() < RAIO_PEGA and t < t_melhor:
				t_melhor = t
				melhor = u
	var chao := Vector3.INF
	var t := 0.0
	while t < 250.0:  # o raio desce até tocar o chão (a página só testa bonecos e chão: atravessa parede)
		var q := o + d * t
		if q.y <= grade.seco(q.x, q.z):
			chao = q
			break
		t += 0.05
	if melhor and t_melhor <= t:
		sel = melhor
		return
	if chao == Vector3.INF or sel == null: return
	var casa := Vector2i(floori(chao.x / grade.CEL), floori(chao.z / grade.CEL))
	for u in unidades:
		if u != sel and u.c == casa: return
	sel.vai_para(casa)
