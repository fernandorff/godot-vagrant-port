class_name MenuOpcoes
extends CanvasLayer
## Menu de opções da cena (F1, Start ou o botão Menu no celular): os grupos da página (sala-fechada.html:243-250)
## abrem e fecham como sanfona, um por vez. Não sabe o que cada opção faz: avisa a cena pelo sinal opcao_mudou
## (o sinal sobe) e a cena aplica. poe() muda o valor mostrado sem avisar (a cena mudou por outro caminho: tecla, E).

signal opcao_mudou(chave: StringName, valor: Variant)

static var aberto := false  # com o menu aberto, bonecos e câmera ignoram o controle (o controle navega no menu)

var _painel: PanelContainer
var _lista: VBoxContainer
var _fps: Label
var _aviso: Label
var _aviso_t := 0.0
var _rolagem: ScrollContainer
var _fechar: Button
var _dica: Label
var _toque := false
var _grupo: VBoxContainer          # onde os itens novos entram
var _grupos: Array = []            # [cabeçalho Button, VBoxContainer]
var _ctl := {}                     # chave -> controle (CheckBox, OptionButton ou SpinBox), para poe()
var _valores := {}                 # chave de escolha -> lista de valores
var medidas: Callable              # devolve o texto do canto (a cena escolhe o que medir)

func _ready() -> void:
	var a := InputEventJoypadButton.new()  # o ui_accept padrão do Godot não tem o A do controle (medido 21/11)
	a.button_index = JOY_BUTTON_A
	InputMap.action_add_event(&"ui_accept", a)
	_fps = Label.new()
	_fps.add_theme_font_size_override("font_size", 18)
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps.position = Vector2(-290, 8)
	_fps.size = Vector2(280, 0)
	add_child(_fps)
	_dica = Label.new()
	_dica.text = "F1: opções"
	_dica.position = Vector2(8, 8)
	_dica.add_theme_font_size_override("font_size", 16)
	add_child(_dica)
	_aviso = Label.new()
	_aviso.position = Vector2(500, 660)
	_aviso.add_theme_font_size_override("font_size", 18)
	add_child(_aviso)
	_painel = PanelContainer.new()
	_painel.position = Vector2(8, 36)
	_painel.visible = false
	add_child(_painel)
	var caixa_v := VBoxContainer.new()
	_painel.add_child(caixa_v)
	_rolagem = ScrollContainer.new()
	_rolagem.custom_minimum_size = Vector2(460, 640)
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caixa_v.add_child(_rolagem)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rolagem.add_child(_lista)
	_grupo = _lista
	_fechar = Button.new()  # no celular não há F1 nem Start: o menu fecha por aqui
	_fechar.text = "Fechar"
	_fechar.visible = false
	_fechar.pressed.connect(_alterna)
	caixa_v.add_child(_fechar)

## Celular: letras e alvos grandes (dedo), painel quase da altura da tela, botão Fechar e dica sem "F1".
func modo_toque() -> void:
	var t := Theme.new()
	t.default_font_size = 30
	for icone: StringName in [&"checked", &"unchecked"]:  # a caixinha padrão tem ~16 px: pequena para o dedo
		var img := ThemeDB.get_default_theme().get_icon(icone, &"CheckBox").get_image()
		img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_BILINEAR)
		t.set_icon(icone, &"CheckBox", ImageTexture.create_from_image(img))
	_painel.theme = t
	_rolagem.custom_minimum_size = Vector2(900, 560)
	_painel.position = Vector2(190, 20)
	_fechar.visible = true
	_fechar.custom_minimum_size = Vector2(0, 80)
	_dica.text = "Menu: opções"
	_toque = true

func _alto(c: Control) -> void:  # alvo de dedo
	if _toque: c.custom_minimum_size.y = 72

func _process(dt: float) -> void:
	_fps.text = medidas.call() if medidas.is_valid() else "%d fps" % Engine.get_frames_per_second()
	_aviso_t -= dt
	_aviso.visible = _aviso_t > 0.0

func _input(ev: InputEvent) -> void:  # B fecha o menu antes do jogo ver o botão (senão solta fogo)
	if aberto and ev is InputEventJoypadButton and ev.pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_B:
		_alterna()
		get_viewport().set_input_as_handled()

func _unhandled_input(ev: InputEvent) -> void:
	var start: bool = ev is InputEventJoypadButton and ev.pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_START
	if start or ev is InputEventKey and ev.pressed and not ev.echo and (ev as InputEventKey).keycode == KEY_F1:
		_alterna()

func _alterna() -> void:
	_painel.visible = not _painel.visible
	aberto = _painel.visible
	if aberto and not _grupos.is_empty(): (_grupos[0][0] as Control).grab_focus()  # o direcional e o A navegam
	elif not aberto: get_viewport().gui_release_focus()

func esta_aberto() -> bool:
	return _painel.visible

## Abre um grupo (e fecha os outros); devolve o cabeçalho.
func abre_grupo(i: int) -> Button:
	for k in _grupos.size(): (_grupos[k][1] as Control).visible = k == i
	return _grupos[i][0]

func aviso(texto: String) -> void:  # recado curto no rodapé por 2 s (o aviso.mostrar da página)
	_aviso.text = texto
	_aviso_t = 2.0

# ---- itens ----

func grupo(texto: String, resumo: String) -> void:  # um grupo da página: cabeçalho que abre e fecha os itens
	var b := Button.new()
	b.text = "[+] %s  (%s)" % [texto, resumo]  # sem ▸: a fonte da web não tem o símbolo
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_alto(b)
	_lista.add_child(b)
	var v := VBoxContainer.new()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_child(v)
	m.visible = false  # o grupo nasce fechado
	_lista.add_child(m)
	var i := _grupos.size()
	_grupos.append([b, m])
	b.pressed.connect(func() -> void:
		var abrir := not m.visible
		for k in _grupos.size(): (_grupos[k][1] as Control).visible = abrir and k == i
		for k in _grupos.size(): (_grupos[k][0] as Button).text = ("[-]" if (_grupos[k][1] as Control).visible else "[+]") + (_grupos[k][0] as Button).text.substr(3))
	_grupo = v

func titulo(texto: String) -> void:
	var t := Label.new()
	t.text = texto
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	if not _toque: t.add_theme_font_size_override("font_size", 15)
	_grupo.add_child(t)

func info(texto: String) -> void:  # leitura sem ação (lista de teclas, o que ficou de fora)
	var t := Label.new()
	t.text = texto
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 22 if _toque else 13)
	t.modulate.a = 0.8
	_grupo.add_child(t)

func caixa(chave: StringName, texto: String, ligada: bool) -> void:
	var c := CheckBox.new()
	c.text = texto
	c.button_pressed = ligada
	c.toggled.connect(func(on: bool) -> void: opcao_mudou.emit(chave, on))
	_alto(c)
	_grupo.add_child(c)
	_ctl[chave] = c

func escolha(chave: StringName, textos: Dictionary, atual: String, rotulo := "") -> void:  # valor -> texto
	if rotulo != "": titulo(rotulo)
	var ob := OptionButton.new()
	var valores: Array = textos.keys()
	for v: String in valores: ob.add_item(textos[v])
	ob.selected = valores.find(atual)
	ob.item_selected.connect(func(i: int) -> void: opcao_mudou.emit(chave, valores[i]))
	ob.fit_to_longest_item = false
	ob.clip_text = true
	if _toque:  # a lista que abre não herda o tema do painel: letra e espaço de dedo nela também
		ob.get_popup().add_theme_font_size_override("font_size", 30)
		ob.get_popup().add_theme_constant_override("v_separation", 36)
	_alto(ob)
	_grupo.add_child(ob)
	_ctl[chave] = ob
	_valores[chave] = valores

func campo(chave: StringName, texto: String, valor: int, botao: String) -> void:  # número + botão (a semente e Sortear)
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = texto
	h.add_child(l)
	var s := SpinBox.new()
	s.min_value = 1
	s.max_value = 9999
	s.value = valor
	s.value_changed.connect(func(v: float) -> void: opcao_mudou.emit(chave, int(v)))
	h.add_child(s)
	var b := Button.new()
	b.text = botao
	b.pressed.connect(func() -> void: opcao_mudou.emit(StringName(String(chave) + ":botao"), true))
	h.add_child(b)
	_alto(h)
	_grupo.add_child(h)
	_ctl[chave] = s

func botao(chave: StringName, texto: String) -> void:  # ação (copiar relatório)
	var b := Button.new()
	b.text = texto
	b.pressed.connect(func() -> void: opcao_mudou.emit(chave, true))
	_alto(b)
	_grupo.add_child(b)

## Mostra o valor sem emitir o sinal (a cena já aplicou).
func poe(chave: StringName, valor: Variant) -> void:
	var c: Control = _ctl.get(chave)
	if c is CheckBox: (c as CheckBox).set_pressed_no_signal(valor)
	elif c is OptionButton: (c as OptionButton).selected = (_valores[chave] as Array).find(valor)
	elif c is SpinBox: (c as SpinBox).set_value_no_signal(valor)

func controle(chave: StringName) -> Control:
	return _ctl.get(chave)
