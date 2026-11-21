class_name MenuOpcoes
extends CanvasLayer
## Menu F1 da cena: liga e desliga cada efeito na hora, sem reiniciar. Não sabe o que cada opção faz:
## avisa a cena pelo sinal opcao_mudou (o sinal sobe) e a cena aplica.

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

func _ready() -> void:
	var a := InputEventJoypadButton.new()  # o ui_accept padrão do Godot não tem o A do controle (medido 21/11)
	a.button_index = JOY_BUTTON_A
	InputMap.action_add_event(&"ui_accept", a)
	_fps = Label.new()
	_fps.position = Vector2(1100, 8)
	_fps.add_theme_font_size_override("font_size", 18)
	add_child(_fps)
	var dica := Label.new()
	dica.text = "F1: opções"
	dica.position = Vector2(8, 8)
	dica.add_theme_font_size_override("font_size", 16)
	add_child(dica)
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
	_rolagem = ScrollContainer.new()  # cabe quando os módulos dos efeitos entrarem
	_rolagem.custom_minimum_size = Vector2(380, 640)
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caixa_v.add_child(_rolagem)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rolagem.add_child(_lista)
	_fechar = Button.new()  # no celular não há F1 nem Start: o menu fecha por aqui
	_fechar.text = "Fechar"
	_fechar.visible = false
	_fechar.pressed.connect(_alterna)
	caixa_v.add_child(_fechar)
	_dica = dica

## Celular: letras e alvos grandes (dedo), painel quase da altura da tela, botão Fechar e dica sem "F1".
func modo_toque() -> void:
	var t := Theme.new()
	t.default_font_size = 30
	for icone: StringName in [&"checked", &"unchecked"]:  # a caixinha padrão tem ~16 px: pequena para o dedo
		var img := ThemeDB.get_default_theme().get_icon(icone, &"CheckBox").get_image()
		img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_BILINEAR)
		t.set_icon(icone, &"CheckBox", ImageTexture.create_from_image(img))
	_painel.theme = t
	_rolagem.custom_minimum_size = Vector2(760, 560)
	_painel.position = Vector2(260, 20)
	_fechar.visible = true
	_fechar.custom_minimum_size = Vector2(0, 80)
	_dica.text = "Menu: opções"
	_toque = true
	for c: Node in _lista.get_children():
		if c is Control: (c as Control).custom_minimum_size.y = 72

func _process(dt: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()
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
	# foco no primeiro item: o direcional e o A (ui_up/ui_down/ui_accept) navegam pelo controle
	var primeiro := _lista.get_children().filter(func(c: Node) -> bool: return c is BaseButton)
	if aberto and not primeiro.is_empty(): (primeiro[0] as Control).grab_focus()
	elif not aberto: get_viewport().gui_release_focus()

func aviso(texto: String) -> void:  # recado curto no rodapé por 2 s (o aviso.mostrar da página)
	_aviso.text = texto
	_aviso_t = 2.0

func titulo(texto: String) -> void:
	var t := Label.new()
	t.text = texto
	if not _toque: t.add_theme_font_size_override("font_size", 15)
	_lista.add_child(t)

func caixa(chave: StringName, texto: String, ligada: bool) -> void:
	var c := CheckBox.new()
	c.text = texto
	c.button_pressed = ligada
	c.toggled.connect(func(on: bool) -> void: opcao_mudou.emit(chave, on))
	if _toque: c.custom_minimum_size.y = 72
	_lista.add_child(c)

func escolha(chave: StringName, textos: Dictionary, atual: String) -> void:  # valor -> texto
	var ob := OptionButton.new()
	var valores: Array = textos.keys()
	for v: String in valores: ob.add_item(textos[v])
	ob.selected = valores.find(atual)
	ob.item_selected.connect(func(i: int) -> void: opcao_mudou.emit(chave, valores[i]))
	if _toque: ob.custom_minimum_size.y = 72
	_lista.add_child(ob)
