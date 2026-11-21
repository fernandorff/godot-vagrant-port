class_name Toque
extends CanvasLayer
## Controles de toque para celular: dois joysticks e botões que viram eventos de controle de videogame
## (Input.parse_input_event), então o jogo usa o mesmo código do controle. Metade esquerda da tela: anda;
## metade direita: gira a câmera; botões à direita (A pula, X golpe, B fogo, Y tocha, LB/RB trocam, RT corre, Start menu).

const RAIO := 90.0  # px: quanto o dedo afasta para o analógico chegar a 1
const BOTOES := [  # [texto, botão ou eixo, posição a partir do canto inferior direito]
	["A", JOY_BUTTON_A, Vector2(-110, -110)], ["X", JOY_BUTTON_X, Vector2(-220, -150)], ["B", JOY_BUTTON_B, Vector2(-110, -230)],
	["Y", JOY_BUTTON_Y, Vector2(-220, -270)], ["LB", JOY_BUTTON_LEFT_SHOULDER, Vector2(-330, -330)],
	["RB", JOY_BUTTON_RIGHT_SHOULDER, Vector2(-110, -350)], ["Corre", -1, Vector2(-330, -200)], ["☰", JOY_BUTTON_START, Vector2(-80, -500)], ["⛶", -2, Vector2(-200, 0)],
]

var _dedos := {}  # índice do toque -> "esq", "dir" ou o botão
var _origem := {}  # índice -> onde o dedo encostou
var _corre := false
var _bases: Array = []  # [Control, botão]

func _ready() -> void:
	for b: Array in BOTOES:
		var c := Button.new()
		c.text = b[0]
		c.focus_mode = Control.FOCUS_NONE
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE  # o toque é tratado em _input
		c.add_theme_font_size_override("font_size", 26)
		c.size = Vector2(84, 84)
		c.modulate.a = 0.55
		add_child(c)
		_bases.append([c, b])
	get_viewport().size_changed.connect(_posiciona)
	_posiciona()

func _posiciona() -> void:
	var t := get_viewport().get_visible_rect().size
	for par: Array in _bases:
		var o: Vector2 = par[1][2]
		(par[0] as Control).position = (Vector2(t.x + o.x, 40) if o.y == 0 else t + o) - Vector2(42, 42)  # y 0 = no alto da tela

func _botao_em(p: Vector2) -> Array:
	for par: Array in _bases:
		if (par[0] as Control).get_rect().grow(8).has_point(p): return par
	return []

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouse and ev.device == InputEvent.DEVICE_ID_EMULATION:  # o clique que o Godot gera do toque escolhia boneco por baixo do joystick
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed:
			var par := _botao_em(t.position)
			if not par.is_empty():
				_dedos[t.index] = par
				_aperta(par[1][1], true)
				(par[0] as Control).modulate.a = 0.95
			else:
				_dedos[t.index] = "esq" if t.position.x < get_viewport().get_visible_rect().size.x * 0.5 else "dir"
				_origem[t.index] = t.position
		elif _dedos.has(t.index):
			var d = _dedos[t.index]
			if d is Array:
				_aperta(d[1][1], false)
				(d[0] as Control).modulate.a = 0.55
			else:
				_eixos(d, Vector2.ZERO)
			_dedos.erase(t.index)
			_origem.erase(t.index)
		get_viewport().set_input_as_handled()
	elif ev is InputEventScreenDrag and _origem.has(ev.index):
		var dr := ev as InputEventScreenDrag
		_eixos(_dedos[dr.index], ((dr.position - _origem[dr.index]) / RAIO).limit_length(1.0))
		get_viewport().set_input_as_handled()

func _aperta(botao: int, apertado: bool) -> void:
	if botao == -2:  # tela cheia (no navegador só vale dentro de um toque) e celular deitado
		if not apertado: return
		var cheia := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if cheia else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if OS.has_feature("web") and not cheia: JavaScriptBridge.eval("screen.orientation && screen.orientation.lock && screen.orientation.lock('landscape').catch(()=>{})")
		return
	if botao == -1:  # "Corre" liga e desliga o RT
		if not apertado: return
		_corre = not _corre
		_eixo(JOY_AXIS_TRIGGER_RIGHT, 1.0 if _corre else 0.0)
		return
	var e := InputEventJoypadButton.new()
	e.button_index = botao
	e.pressed = apertado
	Input.parse_input_event(e)

func _eixos(lado: String, v: Vector2) -> void:
	_eixo(JOY_AXIS_LEFT_X if lado == "esq" else JOY_AXIS_RIGHT_X, v.x)
	_eixo(JOY_AXIS_LEFT_Y if lado == "esq" else JOY_AXIS_RIGHT_Y, v.y)

func _eixo(eixo: int, valor: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = eixo
	e.axis_value = valor
	Input.parse_input_event(e)
