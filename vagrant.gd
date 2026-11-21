extends Node3D
# Etapa 1 da sala-fechada.html (Three.js) no Godot: geometria, texturas e bonecos vêm dos GLB exportados da própria página
# (exportar.mjs); luzes, névoa e câmera vêm de export/cena.json. Sem fumaça, água animada, chamas, brasas, PCSS, SSAO,
# luz assada nem boneco que some no escuro (próximas etapas, ver RESULTADO.md).
# Uso: godot --path . -- --caso=N [--saida=arq.json] [--png=arq.png]   (sem --saida: abre e roda solto)
#  caso 1: sombras como no Three (2 luzes de ponto + sol); caso 2: como "sombras=nao" do Three (luzes de ponto sem sombra,
#  o sol mantém a sombra, linha 693 do html); caso 3: nenhuma sombra (extra).

const SEMPRE := AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))  # caixa de culling enorme = nunca é cortado (frustumCulled=false)
const AQUECIMENTO := 2.0
const MEDICAO := 10.0
const FORA := 2  # camada dos objetos ao ar livre: só o sol e a luz do céu iluminam essa camada (a sala em Lambert nunca vê sol nem céu)
var energia_ponto := 1.15 # escala sobre a intensidade do Three; calibrada em 20/11 com cor_three no chão perto do braseiro (28 contra 28); --energia=X muda
var atenuacao := 0.9      # --atenuacao=X muda; 0,9 equilibra perto, pilar e chão longe contra a queda (1-d/10)^2 do Three r117 (medido 20/11)
var cor_three := true     # contas de cor como o Three r117 (sem conversão sRGB, valor bruto na tela); --cor=godot volta ao normal

var caso := 1
var curva := 1.5          # --curva=X: curva da névoa por profundidade (1 = linear)
var nevoa := true         # --nevoa=0 desliga (diagnóstico)
var claro := false        # --claro=1: diagnóstico, luz ambiente branca e sem névoa (só para conferir texturas e bonecos)
var cam_arg := ""         # --cam=px,py,pz,qx,qy,qz,qw: câmera igual a outra do Three (diagnóstico)
var rapido := false
var igualar := false  # --igualar=1: desenha exatamente os objetos que o Three desenhou no quadro padrão (ver RESULTADO.md)
var saida := ""
var png := ""
var meta: Dictionary
var nos := {}
var modo_sombra := "suave"     # nao | dura | suave (padrão "suave" desde 18/11, sala-fechada.html:1912); --sombras=X muda
var pcss := false              # sombra com penumbra (difusa=pcss da página); --pcss=1 liga
var tremor_on := true
var lm_on := false             # difusa=lightmap da página; --lm=1 liga (assa ao ligar)
var lm = null                  # luz_assada.gd
var salas: Array[MeshInstance3D] = []  # as peças texturizadas da sala (daSala() do Three)
var mats_boneco: Array[ShaderMaterial] = []
var discos: Array[MeshInstance3D] = []  # a mancha escura sob cada boneco (some com ele, sala-fechada.html:1657)
var some := true               # bonecos somem fora da luz (padrão da página); --some=0 desliga
var antes := false             # --antes=1: "Como antes" da página, luz plana e o boneco nunca some
var fumaca_on := true
var camera: CameraOrbita
var orbita_arg := ""           # --orbita=az,dist,polar (como o window.sala.gira da página)
var grade: Grade
var bonecos: Bonecos
var pronto := false            # a medição só começa depois de montar tudo (a luz assada leva alguns segundos)
var ssao := false              # difusa=ssao da página; --ssao=1 liga
var ssao_forca := 16.0         # --ssao-forca=X; 16 (o máximo do Godot) escurece a vista do braseiro em 5,1%, o Three em 4,9% (medido 20/11)
var menu: MenuOpcoes
var efeitos: Efeitos            # efeitos.gd: os módulos dos candidatos, ligados pelo menu F1
var sala_raiz: Node3D
var bonecos_raiz: Node3D
var portas: Portas
var rio: Rio
var iluminacao: Luzes          # luzes.gd: tochas, sol, clarões, tocha na mão, brasas, poeira e fumaça
var t := 0.0
var dts: Array[float] = []
var porseg: Array[int] = []
var cont := 0
var tacum := 0.0
var faltando := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--caso="): caso = int(a.substr(7))
		elif a.begins_with("--saida="): saida = a.substr(8)
		elif a.begins_with("--png="): png = a.substr(6)
		elif a == "--rapido": rapido = true
		elif a.begins_with("--claro="): claro = a.substr(8) == "1"
		elif a.begins_with("--cam="): cam_arg = a.substr(6)
		elif a.begins_with("--curva="): curva = float(a.substr(8))
		elif a.begins_with("--nevoa="): nevoa = a.substr(8) == "1"
		elif a.begins_with("--igualar="): igualar = a.substr(10) == "1"
		elif a.begins_with("--energia="): energia_ponto = float(a.substr(10))
		elif a.begins_with("--atenuacao="): atenuacao = float(a.substr(12))
		elif a.begins_with("--cor="): cor_three = a.substr(6) == "three"
		elif a.begins_with("--sombras="): modo_sombra = a.substr(10)
		elif a.begins_with("--pcss="): pcss = a.substr(7) == "1"
		elif a.begins_with("--some="): some = a.substr(7) == "1"
		elif a.begins_with("--antes="):
			antes = a.substr(8) == "1"
			if antes: some = false
		elif a.begins_with("--fumaca="): fumaca_on = a.substr(9) == "1"
		elif a.begins_with("--orbita="):  # az,dist,polar (como o window.sala.gira da página)
			orbita_arg = a.substr(9)
		elif a.begins_with("--lm="): lm_on = a.substr(5) == "1"
		elif a.begins_with("--ssao="): ssao = a.substr(7) == "1"
		elif a.begins_with("--ssao-forca="): ssao_forca = float(a.substr(13))
	if caso == 2 or caso == 3: modo_sombra = "nao"  # casos da etapa 1: 2 = sombras=nao do Three (sol mantém), 3 = nenhuma
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	var vp := get_viewport()
	for q in 4:
		vp.set_positional_shadow_atlas_quadrant_subdiv(q, Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16)  # casas de 512 px, como o mapa de 512 do Three
	meta = JSON.parse_string(FileAccess.get_file_as_string("res://export/cena.json"))
	_ambiente()
	_sala()
	grade = Grade.new("res://export/grade.json")
	print("GRADE ", grade.W, "x", grade.H, ": ", grade.confere())
	_bonecos()
	_iluminacao()
	_camera()
	iluminacao.camera = camera
	camera.carregar_paredes("res://export/paredes.json", nos)
	if lm_on: await _por_lm(true)
	pronto = true
	_efeitos()
	_menu()
	portas = Portas.new()
	add_child(portas)
	portas.montar(nos, bonecos, camera, grade)
	rio = Rio.new()
	add_child(rio)
	rio.montar(nos, bonecos, meta, cor_three)
	bonecos.usa = _usa_perto
	bonecos.usa_fixa = _usa_fixa
	bonecos.peso_trocou.connect(func(p: String) -> void: menu.aviso("Peso do boneco: " + p))
	if await _testes(): return
	if "--diag" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1.0).timeout
		_diag()

# ---- conferências pela linha de comando (cada uma imprime números para comparar com a página e fecha o Godot) ----
func _arg(nome: String) -> String:  # valor de --nome=valor, "" se não veio
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % nome): return a.substr(nome.length() + 3)
	return ""

func _print_png(arq: String) -> void:
	if arq != "": get_viewport().get_texture().get_image().save_png(arq)

func _testes() -> bool:
	var args := OS.get_cmdline_user_args()
	var u := bonecos.sel
	if _arg("segurar") != "":  # --segurar=tecla,segundos: aperta uma tecla de andar e imprime onde parou
		var w := _arg("segurar").split(",")
		var ev := InputEventKey.new()
		ev.physical_keycode = OS.find_keycode_from_string(w[0])
		ev.keycode = ev.physical_keycode
		ev.pressed = true
		Input.parse_input_event(ev)
		var p0 := u.no.position
		await get_tree().create_timer(float(w[1])).timeout
		print("SEGURAR andou %s, gesto %s, v %.2f" % [u.no.position - p0, u.atual, u.v])
		ev = ev.duplicate()
		ev.pressed = false
		Input.parse_input_event(ev)
		await get_tree().create_timer(1.5).timeout
		print("SOLTOU pos %s, gesto %s, v %.2f" % [u.no.position, u.atual, u.v])
		_print_png(png)
	elif "--opcoes" in args:  # cada opção do menu duas vezes pelo mesmo sinal do clique; a cena tem de voltar igual
		for par: Array in [[&"sombras", "dura"], [&"sombras", "nao"], [&"sombras", "suave"], [&"pcss", true], [&"pcss", false],
				[&"ssao", true], [&"ssao", false], [&"some", false], [&"some", true], [&"particulas", false], [&"particulas", true],
				[&"fumaca", false], [&"fumaca", true], [&"lm", true], [&"lm", false], [&"tremor", false], [&"tremor", true],
				[&"chamas", false], [&"chamas", true], [&"claro", true], [&"claro", false]]:
			menu.opcao_mudou.emit(par[0], par[1])
			await get_tree().create_timer(0.3).timeout
		await get_tree().create_timer(2.0).timeout
		print("OPCOES 21 trocas sem erro; luzes com sombra: %d" % iluminacao.tochas.filter(func(c: Fonte) -> bool: return c.luz.shadow_enabled).size())
		_print_png(png)
	elif "--porta" in args:  # leva o escolhido até a porta de fora, aperta E e espera atravessar; depois volta
		u.no.position = Vector3(94.0, grade.seco(94.0, 45.0), 45.0)
		u.c = Vector2i(47, 22)
		await get_tree().process_frame
		print("PORTA perto: %s" % (portas.perto() != null))
		bonecos.usa.call()
		await get_tree().create_timer(1.0).timeout
		print("PORTA paredes da casa: %d" % portas.paredes_casa.size())
		print("PORTA atravessou: pos %s, rot %.2f, casa visivel %s, fora visivel %s" % [u.no.position, u.no.rotation.y, portas.g_casa.visible, portas.g_fora.visible])
		_print_png(png)
		bonecos.usa.call()
		await get_tree().create_timer(1.0).timeout
		print("PORTA voltou: pos %s, casa visivel %s" % [u.no.position, portas.g_casa.visible])
	elif "--fixa" in args:  # perto de uma tocha fixa: E apaga, E acende
		var f: Fonte = iluminacao.tochas[0]
		u.no.position = Vector3(f.luz.position.x + 1.0, 0.0, f.luz.position.z)
		u.no.position.y = grade.seco(u.no.position.x, u.no.position.z)
		await get_tree().process_frame
		bonecos.usa.call()
		await get_tree().create_timer(0.3).timeout
		print("FIXA apagada %s, luz %s, energia %.2f, chama %s, poeira %.1f" % [f.apagada, f.luz.visible, f.luz.light_energy, f.chama_sprite.visible, _brilho_poeira()])
		bonecos.usa.call()
		await get_tree().create_timer(0.3).timeout
		print("FIXA apagada %s, luz %s, energia %.2f, chama %s, poeira %.1f" % [f.apagada, f.luz.visible, f.luz.light_energy, f.chama_sprite.visible, _brilho_poeira()])
	elif _arg("peso") != "":  # --peso=leve|medio|pesado: segura S 2 s com esse peso
		while Unidade.peso != _arg("peso"): Unidade.troca_peso()
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_S
		ev.pressed = true
		Input.parse_input_event(ev)
		var t0 := u.no.position
		await get_tree().create_timer(2.0).timeout
		print("PESO %s andou %.2f" % [Unidade.peso, (u.no.position - t0).length()])
	elif "--rio" in args:  # dentro do rio, segura S 2 s: o passo cai para 0,65 e os pés fazem anéis
		var z := 50.0
		u.no.position = Vector3(Grade.rio_x(z), grade.seco(Grade.rio_x(z), z), z)
		u.c = Vector2i(floori(u.no.position.x / grade.CEL), floori(z / grade.CEL))
		await get_tree().create_timer(1.0).timeout  # assenta antes de andar (a página faz o mesmo: 60 quadros)
		print("RIO antes: pouso %.2f, pulando %s" % [u.pouso, u.pulando])
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_S
		ev.pressed = true
		Input.parse_input_event(ev)
		var p0 := u.no.position
		await get_tree().create_timer(2.0).timeout
		var aneis := rio.aneis.slots.filter(func(a: Vector4) -> bool: return a.z > 0.0).size()
		print("RIO andou %.2f, lento %.2f, molhado %s, y %.3f, anéis %d, gotas %d" % [(u.no.position - p0).length(), u.lento, Grade.molha(u.no.position), u.no.position.y, aneis, rio.vivas])
		_print_png(png)
	elif "--toque-teste" in args:  # dedo arrastado na metade esquerda anda; toque no A pula; dedo na direita gira a câmera
		var tela := get_viewport().get_visible_rect().size
		var toque := func(i: int, p: Vector2, apertado: bool) -> void:
			var e := InputEventScreenTouch.new(); e.index = i; e.position = p; e.pressed = apertado; Input.parse_input_event(e)
		var arrasta := func(i: int, p: Vector2) -> void:
			var e := InputEventScreenDrag.new(); e.index = i; e.position = p; Input.parse_input_event(e)
		var p0 := u.no.position
		toque.call(0, Vector2(200, 500), true)
		arrasta.call(0, Vector2(200, 400))
		await get_tree().create_timer(1.5).timeout
		toque.call(0, Vector2(200, 400), false)
		var andou := (u.no.position - p0).length()
		await get_tree().create_timer(0.8).timeout
		var az0 := camera.az
		toque.call(1, Vector2(700, 300), true)
		arrasta.call(1, Vector2(790, 300))
		await get_tree().create_timer(0.8).timeout
		toque.call(1, Vector2(790, 300), false)
		var a_pos := tela + Vector2(-110, -110)
		toque.call(2, a_pos, true)
		await get_tree().create_timer(0.15).timeout
		var pulou := u.pulando
		toque.call(2, a_pos, false)
		print("TOQUE andou %.2f, câmera girou %.2f rad, pulou %s" % [andou, camera.az - az0, pulou])
	elif "--menu-toque" in args:  # celular: toque no ☰ abre o menu, toque numa caixa muda a opção, toque em Fechar fecha
		menu.opcao_mudou.connect(func(k: StringName, v: Variant) -> void: print("  menu: %s = %s" % [k, v]))
		var toca_em := func(p: Vector2) -> void:
			for apertado: bool in [true, false]:
				var e := InputEventScreenTouch.new(); e.index = 0; e.position = p; e.pressed = apertado; Input.parse_input_event(e)
				await get_tree().create_timer(0.1).timeout
		var tq: Toque = get_children().filter(func(c: Node) -> bool: return c is Toque)[0]
		var menu_bt: Control = tq._bases.filter(func(par: Array) -> bool: return par[1][0] == "Menu")[0][0]
		await toca_em.call(menu_bt.get_global_rect().get_center())
		await get_tree().create_timer(0.3).timeout
		var caixa: CheckBox = menu._lista.get_children().filter(func(c: Node) -> bool: return c is CheckBox)[0]
		print("MENU-TOQUE aberto %s, caixa '%s' em %s" % [MenuOpcoes.aberto, caixa.text, caixa.get_global_rect()])
		await toca_em.call(caixa.get_global_rect().get_center())
		await get_tree().create_timer(0.3).timeout
		await toca_em.call(menu._fechar.get_global_rect().get_center())
		await get_tree().create_timer(0.3).timeout
		print("MENU-TOQUE caixa marcada %s, menu aberto no fim %s, botões de toque visíveis %s" % [caixa.button_pressed, MenuOpcoes.aberto, menu_bt.visible])
		_print_png(png)
	elif "--mistura" in args:  # formato da mistura entre 2 poses paradas do pulo (0,5 s): fração do caminho em 20/50/80% do tempo
		var an0 := u.player.get_animation(u.clipe_atual())
		var sk := u.player.get_node(u.player.root_node).get_node(NodePath(an0.track_get_path(0).get_concatenated_names())) as Skeleton3D
		var fases: Dictionary = u.poses["parado"]
		set_process(false)
		bonecos.set_process(false)
		u.mistura(fases["agacha"], 0.0)
		for i in 10: await get_tree().process_frame
		var osso := 1
		var qa := sk.get_bone_pose_rotation(osso)
		var t0 := Time.get_ticks_usec()
		u.mistura(fases["topo"], 0.5)
		var amostras: Array = []
		while Time.get_ticks_usec() - t0 < 700000:
			await get_tree().process_frame
			amostras.append([(Time.get_ticks_usec() - t0) / 500000.0, sk.get_bone_pose_rotation(osso)])
		var qb: Quaternion = amostras[-1][1]
		var total := qa.angle_to(qb)
		var linha: Array = []
		for alvo: float in [0.2, 0.5, 0.8]:
			for a: Array in amostras:
				if a[0] >= alvo: linha.append("%.0f%% do tempo: %.2f" % [alvo * 100, qa.angle_to(a[1]) / maxf(total, 1e-6)]); break
		print("MISTURA (ângulo total %.3f rad) %s" % [total, linha])
	elif "--gestos-todos" in args:  # cada boneco toca cada gesto 0,6 s; conta as poses distintas do 2º osso do seu esqueleto
		for b: Unidade in bonecos.unidades:
			var an0 := b.player.get_animation(b.clipe_atual())
			var sk := b.player.get_node(b.player.root_node).get_node(NodePath(an0.track_get_path(0).get_concatenated_names())) as Skeleton3D
			var linha: Array = []
			for g: String in b.gestos:
				b.toca(g)
				var vistas := {}
				for i in 36:
					await get_tree().process_frame
					vistas[str(sk.get_bone_pose_rotation(1).get_euler().snappedf(0.001))] = true
				linha.append("%s %d" % [g, vistas.size()])
				b.toca("parado")
			print("GESTOS %s: %s" % [b.nome, linha])
	elif "--controle-real" in args:  # ouve o controle de verdade até o Back (ou 30 s): cada botão e eixo, o menu e onde o herói foi
		print("CONTROLE-REAL: aperte os botões agora (Back encerra); aparelhos: %s" % [Input.get_connected_joypads().map(func(d: int) -> String: return Input.get_joy_name(d))])
		menu.opcao_mudou.connect(func(k: StringName, v: Variant) -> void: print("  menu: %s = %s" % [k, v]))
		var p0 := u.no.position
		var az0 := camera.az
		if _arg("sinal") != "": FileAccess.open(_arg("sinal"), FileAccess.WRITE).store_string("ouvindo")  # o stdout sai em blocos: o script do controle espera este arquivo
		var fim := Time.get_ticks_msec() + 30000
		var an0 := u.player.get_animation(u.clipe_atual())  # o esqueleto que o player anima (o da trilha)
		var esq := u.player.get_node(u.player.root_node).get_node(NodePath(an0.track_get_path(0).get_concatenated_names())) as Skeleton3D
		var poses_por_gesto := {}  # gesto (ou fase do pulo) -> rotações distintas de um osso: >1 = o esqueleto mexe
		var gestos_no_menu := {}  # o que o herói fez com o menu aberto (deve ficar vazio)
		var andou_no_menu := 0.0
		var antes := u.no.position
		while Time.get_ticks_msec() < fim and not Input.is_joy_button_pressed(0, JOY_BUTTON_BACK):
			await get_tree().process_frame
			var g: String = u.atual if u.atual != "" else "pose"
			if not poses_por_gesto.has(g): poses_por_gesto[g] = {}
			poses_por_gesto[g][str(esq.get_bone_pose_rotation(1).get_euler().snappedf(0.001))] = true
			if MenuOpcoes.aberto:
				andou_no_menu += (u.no.position - antes).length()
				if u.atual != "parado": gestos_no_menu[u.atual] = true
			antes = u.no.position
		print("CONTROLE-REAL fim: herói andou %.2f, câmera girou %.2f rad, escolhido %s, peso %s; com o menu aberto andou %.2f, gestos %s; menu aberto no fim: %s" % [(u.no.position - p0).length(), camera.az - az0, bonecos.sel.nome, Unidade.peso, andou_no_menu, gestos_no_menu.keys(), MenuOpcoes.aberto])
		print("CONTROLE-REAL poses distintas por gesto: %s" % [poses_por_gesto.keys().map(func(k: String) -> String: return "%s %d" % [k, poses_por_gesto[k].size()])])
		get_tree().quit()
	elif "--controle" in args:  # o controle por eventos: analógico anda, A pula, X golpe, LB troca, RS gira a câmera
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXIS_LEFT_Y
		ev.axis_value = 1.0
		Input.parse_input_event(ev)
		var p0 := u.no.position
		await get_tree().create_timer(2.0).timeout
		print("CONTROLE analógico andou %s" % (u.no.position - p0))
		ev = ev.duplicate()
		ev.axis_value = 0.0
		Input.parse_input_event(ev)
		await get_tree().create_timer(1.0).timeout
		var az0 := camera.az
		var rs := InputEventJoypadMotion.new()
		rs.axis = JOY_AXIS_RIGHT_X
		rs.axis_value = 1.0
		Input.parse_input_event(rs)
		await get_tree().create_timer(0.5).timeout
		rs = rs.duplicate()
		rs.axis_value = 0.0
		Input.parse_input_event(rs)
		print("CONTROLE câmera girou %.2f rad" % (camera.az - az0))
		for b: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER]:
			var bt := InputEventJoypadButton.new()
			bt.button_index = b
			bt.pressed = true
			Input.parse_input_event(bt)
			await get_tree().create_timer(0.1).timeout
			print("CONTROLE botão %d: gesto %s, pulando %s, escolhido %s" % [b, u.atual, u.pulando, bonecos.sel.nome])
			bt = bt.duplicate()
			bt.pressed = false
			Input.parse_input_event(bt)
			await get_tree().create_timer(1.6).timeout
	elif "--efeitos-teste" in args:  # cada módulo liga e desliga 2 vezes pelo menu; nenhum nó pode sobrar
		for g: String in efeitos.grupos():
			for k: String in efeitos.do_grupo(g):
				for vez in 2:
					if efeitos.modulos[k].exclusivo: menu.opcao_mudou.emit(StringName("efeito:" + g), k)
					else: menu.opcao_mudou.emit(StringName("efeito+:" + k), true)
					for i in 5: await get_tree().process_frame
					if efeitos.modulos[k].exclusivo: menu.opcao_mudou.emit(StringName("efeito:" + g), "")
					else: menu.opcao_mudou.emit(StringName("efeito+:" + k), false)
					for i in 3: await get_tree().process_frame
				print("EFEITO ", k, " ok, sobrando ", efeitos.get_child_count())
		print("EFEITOS %d módulos, não carregaram: %s" % [efeitos.modulos.size(), efeitos.erros])
	elif "--tocha" in args:  # acende a tocha na mão de cada boneco, um por vez
		for b in bonecos.unidades:
			bonecos.sel = b
			b.leva.ligada = true
			await get_tree().create_timer(1.2).timeout
			print("TOCHA %s: chama %s, pés %s" % [b.nome, b.leva.chama, b.no.position])
			if png != "": _print_png(png.replace(".png", "-%s.png" % b.nome.replace(" ", "")))
			b.leva.ligada = false
	elif _arg("acao") != "":  # --acao=golpe|fogo|raio: dispara, print no meio do clarão, tempo até voltar ao parado
		var tipo := _arg("acao")
		var espera := Bonecos.GOLPE_ACERTA if tipo == "golpe" else Bonecos.MAGIA_SAI
		if tipo == "golpe": bonecos.ataca(u)
		else: bonecos.conjura(u, tipo)
		await get_tree().create_timer(espera + 0.03).timeout
		print("ACAO %s: clarões %d, gesto %s, energia %.2f" % [tipo, iluminacao.claroes.size(), u.atual, iluminacao.claroes[0].luz.light_energy if iluminacao.claroes.size() else 0.0])
		_print_png(png)
		var t1 := Time.get_ticks_msec()
		while u.atual != "parado": await get_tree().process_frame
		print("ACAO voltou ao parado %.2f s depois do início; clarões %d" % [(Time.get_ticks_msec() - t1) / 1000.0 + espera + 0.03, iluminacao.claroes.size()])
	elif "--pular" in args:  # altura máxima, tempo até o fim do pouso e fases
		var y0 := u.no.position.y
		var t0 := Time.get_ticks_msec()
		var topo := 0.0
		var fases: Array[String] = []
		u.pula(false)
		while u.pulando or u.pouso > 0.0:
			await get_tree().process_frame
			topo = maxf(topo, u.no.position.y - y0)
			var ca := String(u.clipe_atual())
			if fases.is_empty() or fases[-1] != ca: fases.append(ca)
		print("PULO altura %.3f, %.3f s até o fim do pouso, fases %s, gesto %s" % [topo, (Time.get_ticks_msec() - t0) / 1000.0, fases, u.atual])
	elif _arg("andar") != "":  # --andar=cx,cz: anda até a casa; tempo e posição ao chegar
		var w := _arg("andar").split(",")
		u.vai_para(Vector2i(int(w[0]), int(w[1])))
		var t0 := Time.get_ticks_msec()
		print("ANDAR rota ", u.rota.size(), " casas")
		var meio := _arg("png-andando")
		var quadros: Array = []  # [ms do quadro, velocidade, trocou de casa] para achar o tranco ao trocar de casa
		var p_ant := u.no.position
		var c_ant := u.c
		var t_ant := Time.get_ticks_usec()
		while u.rota.size():
			await get_tree().process_frame
			var agora := Time.get_ticks_usec()
			var dt_ms := (agora - t_ant) / 1000.0
			var pos := u.no.position
			quadros.append([dt_ms, Vector2(pos.x - p_ant.x, pos.z - p_ant.z).length() / maxf(dt_ms / 1000.0, 0.0001), u.c != c_ant])
			t_ant = agora
			p_ant = pos
			c_ant = u.c
			if meio != "" and Time.get_ticks_msec() - t0 > 1500:
				_print_png(meio)
				meio = ""
		if "--tranco" in args: _relata_tranco(quadros)
		print("ANDAR chegou em %.2f s, pos %s, rot %.3f, gesto %s" % [(Time.get_ticks_msec() - t0) / 1000.0, u.no.position, u.no.rotation.y, u.atual])
		await get_tree().create_timer(1.0).timeout
		_print_png(png)
	else:
		return false
	get_tree().quit()
	return true

func _relata_tranco(q: Array) -> void:  # --tranco: quadro lento ou velocidade que cai, perto da troca de casa?
	var meio := q.slice(10, q.size() - 10)  # sem a partida e a chegada
	var ms: Array = meio.map(func(x: Array) -> float: return x[0])
	var vs: Array = meio.map(func(x: Array) -> float: return x[1])
	ms.sort(); vs.sort()
	var ms_med: float = ms[ms.size() / 2]
	var v_med: float = vs[vs.size() / 2]
	var lentos := 0; var lentos_troca := 0; var quedas := 0; var quedas_troca := 0; var trocas := 0
	for i in range(10, q.size() - 10):
		var perto: bool = q[i][2] or q[i - 1][2] or q[i + 1][2]
		if q[i][2]: trocas += 1
		if q[i][0] > ms_med * 1.8:
			lentos += 1
			if perto: lentos_troca += 1
		if q[i][1] < v_med * 0.6:
			quedas += 1
			if perto: quedas_troca += 1
	print("TRANCO quadros %d, trocas de casa %d | ms mediano %.2f, quadros lentos (>1,8x) %d, perto da troca %d | velocidade mediana %.2f, quedas (<0,6x) %d, perto da troca %d" % [meio.size(), trocas, ms_med, lentos, lentos_troca, v_med, quedas, quedas_troca])
	var amostra: Array = []
	for i in range(10, q.size() - 10):
		if q[i][2]: amostra.append("%s" % [q.slice(i - 3, i + 4).map(func(x: Array) -> String: return "%.1fms/%.2f%s" % [x[0], x[1], "*" if x[2] else ""])])
		if amostra.size() == 3: break
	for a: String in amostra: print("  em volta da troca: ", a)

func _diag() -> void:  # soma os triângulos das malhas visíveis na árvore e dentro do frustum da câmera (conferência do contador)
	var cam := get_viewport().get_camera_3d()
	var planos := cam.get_frustum()
	var total := 0
	var dentro := 0
	var n_dentro := 0
	var lista := []
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or not m.is_visible_in_tree(): continue
		var tris := 0
		for i in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(i)
			var idx = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
		var box: AABB = m.global_transform * m.get_aabb()
		var ok := true
		for p in planos:
			var pos := box.get_support(-p.normal)
			if p.distance_to(pos) > 0.0:
				ok = false
				break
		total += tris
		if ok:
			dentro += tris
			n_dentro += 1
			lista.append([tris, String(m.name), m.layers, m.cast_shadow])
	lista.sort_custom(func(a, b): return a[0] > b[0])
	var tocando := 0
	var pos_anim := []
	for ap in find_children("*", "AnimationPlayer", true, false):
		var a := ap as AnimationPlayer
		if a.is_playing():
			tocando += 1
			pos_anim.append(snappedf(a.current_animation_position, 0.01))
	print("DIAG AnimationPlayers tocando: ", tocando, " posicoes(s): ", pos_anim, " esqueletos: ", find_children("*", "Skeleton3D", true, false).size())
	print("DIAG total visivel na arvore: ", total, " | dentro do frustum: ", dentro, " em ", n_dentro, " malhas")
	for e in lista.slice(0, 12): print("  ", e)
	get_tree().quit()

func _col(h: String) -> Color:  # com cor_three, codifica em sRGB para a decodificação do Godot devolver o valor bruto do Three
	return Color(h).linear_to_srgb() if cor_three else Color(h)

func _cru(tex: Texture2D) -> Texture2D:  # textura com o valor bruto do PNG depois da decodificação sRGB do Godot (como o Three r117)
	var img := tex.get_image()
	if img.is_compressed(): img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	img.linear_to_srgb()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _lut_cru() -> ImageTexture:  # desfaz a codificação sRGB da saída: a tela recebe o valor linear, como o outputEncoding Linear do Three r117
	var img := Image.create(256, 1, false, Image.FORMAT_RGBF)
	for x in 256:
		var v := Color(x / 255.0, x / 255.0, x / 255.0).srgb_to_linear()
		img.set_pixel(x, 0, v)
	return ImageTexture.create_from_image(img)

func _ambiente() -> void:
	var h: Dictionary = meta.HORA
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var m := ProceduralSkyMaterial.new()  # quebra-galho do domo de céu (shader do Three, 960 triângulos): gradiente zênite -> horizonte
	m.sky_top_color = _col(h.zen)
	m.sky_horizon_color = _col(h.hor)
	m.ground_horizon_color = _col(h.hor)
	m.ground_bottom_color = _col(h.hor) * 0.3
	m.sky_curve = 0.55
	var sky := Sky.new()
	sky.sky_material = m
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR  # escuridão total: luz ambiente zero (intensidade da AmbientLight do Three = 0)
	e.ambient_light_color = Color.WHITE if claro else _col(meta.ambiente.cor)
	e.ambient_light_energy = 1.0 if claro else meta.ambiente.intensidade
	e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	if cor_three:
		e.adjustment_enabled = true
		e.adjustment_color_correction = _lut_cru()
	e.fog_enabled = nevoa and not claro  # Fog linear do Three (near/far) -> névoa por profundidade do Godot
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = _col(meta.fog.cor)
	e.fog_density = 1.0
	e.fog_depth_begin = meta.fog.near
	e.fog_depth_end = meta.fog.far
	e.fog_depth_curve = curva
	e.fog_sky_affect = 0.0  # o domo do Three tem fog:false
	_aplicar_ssao(e)
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)

func _indexar(n: Node) -> void:
	nos[String(n.name)] = n
	for c in n.get_children():
		_indexar(c)

func _filtro(raiz: Node, mipmap: bool) -> void:
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat is BaseMaterial3D:
				if cor_three and mat.albedo_texture and not mat.has_meta("cru"):
					mat.albedo_texture = _cru(mat.albedo_texture)
					mat.set_meta("cru", true)
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS if mipmap else BaseMaterial3D.TEXTURE_FILTER_NEAREST

func _sala() -> void:
	var raiz: Node = (load("res://export/sala.glb") as PackedScene).instantiate()
	sala_raiz = raiz
	add_child(raiz)
	_indexar(raiz)
	for nome in meta.nos:
		var n: Node = nos.get(nome)
		if n == null:
			faltando += 1
			continue
		var info: Dictionary = meta.nos[nome]
		if n is Node3D: n.visible = info.vis
		if n is GeometryInstance3D:
			n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if info.cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.layers = FORA if info.sol else 1
			if info.get("mat") == "MeshLambertMaterial" and n is MeshInstance3D and n.mesh:  # Lambert do r117 = luz por vértice, sem brilho
				for i in n.mesh.get_surface_count():
					var mt: Material = n.mesh.surface_get_material(i)
					if mt is BaseMaterial3D:
						mt.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
						mt.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
						mt.vertex_color_use_as_albedo = true  # vertexColors:true (sala-fechada.html:471): sombreado do VSTools por vértice, valor bruto
						if not info.fora and mt.albedo_texture and mt.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not n in salas: salas.append(n)  # daSala() do Three
			if info.nocull: n.custom_aabb = SEMPRE  # frustumCulled=false do Three (o rio)
			if igualar and info.tipo == "Mesh":
				if info.desenha: n.custom_aabb = SEMPRE  # o Three desenhou (esfera de limite mais folgada que a AABB): desenha igual
				else: n.visible = false
	_filtro(raiz, true)  # nearest; o Three usa nearest sem mipmap na sala e mipmap linear no mundo: aqui nearest com mipmap em tudo

func _bonecos() -> void:
	var raiz: Node = (load("res://export/bonecos.glb") as PackedScene).instantiate()
	bonecos_raiz = raiz
	add_child(raiz)
	_filtro(raiz, false)
	var base: AnimationPlayer = raiz.find_child("AnimationPlayer", true, false)
	if base == null:
		print("AVISO: sem AnimationPlayer nos bonecos")
		return
	bonecos = Bonecos.new()
	bonecos.name = "Bonecos"
	bonecos.process_priority = -1  # anda antes da câmera e das luzes, como o quadro() da página
	add_child(bonecos)
	bonecos.montar(raiz, base.get_animation_library(""), base.get_node(base.root_node), meta.unidades, grade)
	base.active = false  # o player do .glb, parado, regravava a pose inicial em todos os ossos a cada quadro (medido 21/11)
	
	base.queue_free()
	var sh: Shader = load("res://boneco.gdshader")
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).custom_aabb = SEMPRE
		for i in mi.mesh.get_surface_count():  # as peças texturizadas (corpo, arma, escudo) ganham o shader do boneco
			var orig = mi.mesh.surface_get_material(i)
			if orig is BaseMaterial3D and not orig.albedo_texture and orig.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				mi.material_override = orig.duplicate()  # um por disco: cada um some com o seu boneco
				discos.append(mi)
				continue
			if not (orig is BaseMaterial3D and orig.albedo_texture): continue
			var sm := ShaderMaterial.new()
			sm.shader = sh
			sm.set_shader_parameter("tex", orig.albedo_texture)
			sm.set_shader_parameter("scissor", orig.alpha_scissor_threshold)
			sm.set_shader_parameter("usa_cor_vertice", orig.vertex_color_use_as_albedo)
			sm.set_shader_parameter("cor_luz", Color(meta.luzes[0].cor))  # valor bruto (uniform sem conversão de cor)
			sm.set_shader_parameter("atenuacao_godot", atenuacao)
			sm.set_shader_parameter("ver_sombra", "--ver-sombra" in OS.get_cmdline_user_args())
			mi.set_surface_override_material(i, sm)
			mats_boneco.append(sm)  # as malhas dos bonecos têm frustumCulled=false no Three: sempre desenhadas
			var s: Dictionary = meta.sol
			var hm: Dictionary = meta.hemisferio
			sm.set_shader_parameter("sol_cor", _v3(Color(s.cor)) * float(s.intensidade))  # valor bruto, como cor_luz
			sm.set_shader_parameter("sol_dir", (Vector3(s.pos[0], s.pos[1], s.pos[2]) - Vector3(s.alvo[0], s.alvo[1], s.alvo[2])).normalized())
			sm.set_shader_parameter("hemi_ceu", _v3(Color(hm.ceu)) * float(hm.intensidade))
			sm.set_shader_parameter("hemi_chao", _v3(Color(hm.chao)) * float(hm.intensidade))
		(mi as MeshInstance3D).layers = 1 | Luzes.CAMADA_BONECOS
		if (mi as MeshInstance3D).skin == null or "--corpo-sem-sombra" in OS.get_cmdline_user_args(): (mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # na página só o corpo (SkinnedMesh) projeta
	for u in bonecos.unidades:  # cada boneco com os seus materiais (para o fora de cada um)
		for mi in u.no.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(i) as ShaderMaterial
				if m: u.mats.append(m)
		if u.mats.is_empty(): push_warning("sem materiais do corpo para " + u.nome)

static func _v3(c: Color) -> Vector3:  # valor bruto num vec3 (Color num uniform pode ser convertido)
	return Vector3(c.r, c.g, c.b)

func _iluminacao() -> void:  # a configuração desce para o nó das luzes; o pedido de clarão sobe dos bonecos
	iluminacao = Luzes.new()
	for k in ["energia_ponto", "atenuacao", "cor_three", "caso", "modo_sombra", "pcss", "tremor_on", "some", "antes", "fumaca_on",
			"meta", "bonecos", "salas", "mats_boneco", "discos", "grade"]:
		iluminacao.set(k, get(k))
	add_child(iluminacao)
	iluminacao.montar()
	bonecos.clarao_pedido.connect(iluminacao.clarao)

func _efeitos() -> void:  # contrato dos módulos (godot-candidatos/CONTRATO-MODULOS.md, seção 3)
	efeitos = Efeitos.new()
	efeitos.name = "Efeitos"
	efeitos.ambiente = _env()
	efeitos.camera = camera
	efeitos.luzes = iluminacao.luzes
	efeitos.sol = iluminacao.sol
	efeitos.sala = sala_raiz
	efeitos.bonecos = bonecos_raiz
	efeitos.nos = nos
	efeitos.meta = meta
	efeitos.claro = claro
	add_child(efeitos)
	efeitos.montar()
	for k in _arg("efeitos").split(",", false): efeitos.ligar(k)
	if _arg("leva") == "1": bonecos.sel.leva.ligada = true  # --leva=1: tocha na mão acesa desde o início (medição)  # --efeitos=grupo/candidato,...: liga já na abertura (prints)

func _input(ev: InputEvent) -> void:  # --controle-real: mostra cada botão e cada eixo que chega
	if not "--controle-real" in OS.get_cmdline_user_args(): return
	if ev is InputEventJoypadButton: print("  botão %d %s (foco: %s)" % [ev.button_index, "aperta" if ev.pressed else "solta", get_viewport().gui_get_focus_owner()])
	elif ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.5: print("  eixo %d %.2f" % [ev.axis, ev.axis_value])

func _brilho_poeira() -> float:  # soma do vermelho dos grãos (teste --fixa)
	var s := 0.0
	for i in iluminacao.poeira0.size(): s += iluminacao.poeira.multimesh.get_instance_color(i).r
	return s

func _usa_fixa() -> bool:
	var f := iluminacao.perto_de(bonecos.sel.no.position, 2.0)
	if f == null: return false
	f.apagada = not f.apagada
	iluminacao.tinge()
	return true

func _usa_perto() -> bool:  # tecla E (sala-fechada.html:1388): a porta perto, senão a tocha fixa perto
	if portas.perto():
		portas.alterna()
		return true
	return _usa_fixa()

func _camera() -> void:
	camera = CameraOrbita.new()
	camera.process_priority = -1  # depois dos bonecos, antes das luzes
	add_child(camera)
	camera.iniciar(meta.camera, bonecos, grade, _env(), meta.fog)
	if orbita_arg != "":
		var o := orbita_arg.split(",")
		camera.az = float(o[0])
		camera.dist = float(o[1])
		camera.polar = float(o[2])
	camera.fixa = cam_arg != ""
	var olhar := _arg("olhar")  # --olhar=x,y,z: vira a câmera para um ponto (diagnóstico)
	if olhar != "":
		camera.fixa = true
		var w := olhar.split(",")
		camera.look_at(Vector3(float(w[0]), float(w[1]), float(w[2])))
	var vistas := {"braseiro": [Vector3(21.0, 6.5, 21.0), Vector3(29.0, 3.0, 12.0)], "bonecos": [Vector3(22.0, 3.43, 15.87), Vector3(22.0, 1.9, 7.0)]}
	if vistas.has(_arg("vista")):  # --vista=braseiro|bonecos: as vistas dos candidatos (godot-candidatos/vagrant.gd:13)
		camera.fixa = true
		camera.look_at_from_position(vistas[_arg("vista")][0], vistas[_arg("vista")][1], Vector3.UP)
	if cam_arg != "":
		var v := cam_arg.split(",")
		camera.global_transform = Transform3D(Basis(Quaternion(float(v[3]), float(v[4]), float(v[5]), float(v[6]))), Vector3(float(v[0]), float(v[1]), float(v[2])))

func _aplicar_ssao(e: Environment) -> void:
	# SSAO do Godot no lugar do de 2 passes da página (sala-fechada.html:774): RAIO 1.2, e escurece também a luz direta,
	# porque a página multiplica a imagem pronta (aqui a luz ambiente é zero, então só a luz direta existe)
	e.ssao_enabled = ssao
	e.ssao_radius = 1.2
	e.ssao_intensity = ssao_forca
	e.ssao_light_affect = 1.0
	e.ssao_ao_channel_affect = 1.0

func _por_lm(on: bool) -> void:
	if on and lm == null:
		lm = load("res://luz_assada.gd").new()
		await lm.assar(self, meta, salas)
		lm.compor(meta)
		print("LUZ ASSADA: %d pontos, %d malhas, %.0f ms" % [lm.pares.size(), lm.malhas.size(), lm.ms])
		if "--dump-lm" in OS.get_cmdline_user_args():  # diagnóstico: posição e lm de cada vértice, para comparar com o Three
			var out := []
			for m in lm.malhas:
				var arr: Array = m.malha_lm.surface_get_arrays(0)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var cs: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM0]
				for i in vs.size():
					var w: Vector3 = m.mi.global_transform * vs[i]
					out.append([snappedf(w.x, 0.01), snappedf(w.y, 0.01), snappedf(w.z, 0.01), snappedf(cs[i * 4], 0.0001)])
			var f := FileAccess.open("lm-godot.json", FileAccess.WRITE)
			f.store_string(JSON.stringify(out))
			f.close()
	if lm: lm.ligar(on)

func _menu() -> void:  # F1 abre e fecha; cada opção troca na hora, sem reiniciar
	menu = MenuOpcoes.new()
	add_child(menu)
	if DisplayServer.is_touchscreen_available() or "--toque" in OS.get_cmdline_user_args():  # celular: joysticks na tela e menu grande
		add_child(Toque.new())
		menu.modo_toque()
	menu.titulo("Sombras das tochas")
	menu.escolha(&"sombras", {"nao": "Sem sombra", "dura": "Dura (128 px, sem filtro)", "suave": "Suave (512 px, filtrada)"}, modo_sombra)
	menu.caixa(&"pcss", "Penumbra (PCSS)", pcss)
	menu.caixa(&"ssao", "Oclusão de ambiente (SSAO)", ssao)
	menu.escolha(&"bonecos", {"some": "Bonecos: somem fora da luz", "direta": "Bonecos: só luz direta (lado escuro preto)",
		"antes": "Bonecos: como antes (sempre aparecem)"}, "antes" if antes else "some" if some else "direta")
	menu.caixa(&"particulas", "Brasas e poeira", true)
	menu.caixa(&"fumaca", "Fumaça 3D (raios no ruído)", fumaca_on)
	menu.caixa(&"lm", "Luz assada (rebatida das tochas)", lm_on)
	menu.caixa(&"tremor", "Tremor das chamas", tremor_on)
	menu.caixa(&"chamas", "Chamas e halos", true)
	menu.caixa(&"claro", "Luz clara (diagnóstico)", claro)
	efeitos.por_no_menu(menu)
	menu.opcao_mudou.connect(_aplicar_opcao)

func _aplicar_opcao(chave: StringName, valor: Variant) -> void:
	var il := iluminacao
	match chave:
		&"sombras":
			il.modo_sombra = valor
			il.aplicar_sombras()
		&"pcss":
			il.pcss = valor
			il.aplicar_sombras()
		&"ssao":
			ssao = valor
			_aplicar_ssao(_env())
		&"some": il.some = valor
		&"bonecos":  # sala-fechada.html:217
			il.some = valor == "some"
			il.antes = valor == "antes"
		&"particulas":
			il.particulas_on = valor
			for b in il.brasas: b.visible = valor
			if il.poeira: il.poeira.visible = valor
		&"fumaca":
			il.fumaca_on = valor
			if il.fumaca: il.fumaca.visible = valor
		&"lm":
			lm_on = valor
			_por_lm(valor)
		&"tremor": il.tremor_on = valor
		&"chamas":
			il.chamas_on = valor
		&"claro":
			var e := _env()
			e.ambient_light_color = Color.WHITE if valor else _col(meta.ambiente.cor)
			e.ambient_light_energy = 1.0 if valor else meta.ambiente.intensidade
			e.fog_enabled = nevoa and not valor
			efeitos.claro = valor
		_:
			if String(chave).begins_with("efeito"): efeitos.opcao(chave, valor)

func _env() -> Environment:
	for c in get_children():
		if c is WorldEnvironment: return c.environment
	return null

func _process(dt: float) -> void:
	bonecos.az_camera = camera.az
	if saida == "" or not pronto or _arg("andar") != "" or "--controle-real" in OS.get_cmdline_user_args():  # o teste do controle fecha sozinho
		return
	t += dt
	if rapido and t > 1.5:  # só o print (calibração de brilho)
		if "--apagadas" in OS.get_cmdline_user_args(): print("APAGADAS ", JSON.stringify(camera.apagadas()))
		get_viewport().get_texture().get_image().save_png(png)
		get_tree().quit()
		return
	if t < AQUECIMENTO:
		return
	dts.append(dt * 1000.0)
	tacum += dt * 1000.0
	cont += 1
	while tacum >= (porseg.size() + 1) * 1000.0:
		porseg.append(cont)
		cont = 0
	if tacum < MEDICAO * 1000.0:
		return
	set_process(false)
	var vp := get_viewport()
	var ord := dts.duplicate()
	ord.sort()
	var p99: float = ord[mini(dts.size() - 1, int(floor(dts.size() * 0.99)))]
	var sombreadas := iluminacao.luzes.filter(func(l): return l.visible and l.shadow_enabled).size()
	var b := {"caso": caso, "versao": Engine.get_version_info().string,
		"renderizador": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(),
		"quadros": dts.size(), "segundosMedidos": snappedf(tacum / 1000.0, 0.01), "fpsMedio": snappedf(dts.size() / (tacum / 1000.0), 0.01),
		"fpsPorSegundo": porseg, "msMedio": snappedf(tacum / dts.size(), 0.01), "msP99": snappedf(p99, 0.01), "fps1pctLow": snappedf(1000.0 / p99, 0.01),
		"igualar": igualar, "luzesPonto": iluminacao.luzes.filter(func(l): return l.visible).size(), "luzesPontoComSombra": sombreadas, "solComSombra": iluminacao.sol.shadow_enabled, "nosFaltando": faltando,
		"primVisivel": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"primSombra": vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"drawVisivel": vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"drawSombra": vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"primitivasPorQuadro": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"drawCalls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"janela": {"pos": [DisplayServer.window_get_position().x, DisplayServer.window_get_position().y], "tam": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
			"modo": DisplayServer.window_get_mode(), "vsync": DisplayServer.window_get_vsync_mode(), "maxFps": Engine.max_fps}}
	if png != "":
		get_viewport().get_texture().get_image().save_png(png)
	var f := FileAccess.open(saida, FileAccess.WRITE)
	f.store_string(JSON.stringify(b))
	f.close()
	get_tree().quit()
